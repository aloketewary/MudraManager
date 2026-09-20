import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:mudra_manager/features/budget/data/budget_period_ledger_service.dart';
import 'package:mudra_manager/features/gamification/domain/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/data/gamification_service.dart';

import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';

export 'package:mudra_manager/core/domain/budget_period_snapshot.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('BudgetService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return BudgetService(isarService, log, gamificationService);
});

final budgetStreamProvider = StreamProvider.autoDispose<List<Budget>>((ref) {
  ref.watch(budgetRefreshProvider);
  final service = ref.watch(budgetServiceProvider);
  return service.watchAllBudgets();
});

/// Canonical current-period data source for all budget consumers.
final budgetPeriodSnapshotsProvider =
    FutureProvider.autoDispose<List<BudgetPeriodSnapshot>>((ref) async {
  final refresh = ref.watch(budgetRefreshProvider);
  final service = ref.watch(budgetServiceProvider);
  final snapshots = await service.getBudgetPeriodSnapshots(
    evaluationDate: refresh.evaluationDate,
  );
  // A collection event can arrive while this read is in flight. Never
  // publish data under an older generation.
  if (!ref.mounted ||
      ref.read(budgetRefreshProvider).generation != refresh.generation) {
    return const <BudgetPeriodSnapshot>[];
  }
  return snapshots;
});

final budgetWithProgressProvider =
    FutureProvider.autoDispose<List<(Budget, double, DateTime, DateTime)>>(
        (ref) async {
  final snapshots = await ref.watch(budgetPeriodSnapshotsProvider.future);
  return snapshots
      .map(
        (snapshot) => (
          snapshot.budget,
          snapshot.spent,
          snapshot.periodStart,
          snapshot.periodEnd,
        ),
      )
      .toList();
});

final budgetsWithProgressProvider =
    FutureProvider.autoDispose<List<BudgetWithProgress>>((ref) async {
  final snapshots = await ref.watch(budgetPeriodSnapshotsProvider.future);
  return snapshots.map(BudgetWithProgress.fromSnapshot).toList();
});

final budgetHistoryProvider =
    FutureProvider.autoDispose<List<BudgetHistoryEntry>>((ref) async {
  final refresh = ref.watch(budgetRefreshProvider);
  final service = ref.watch(budgetServiceProvider);
  final entries = await service.getBudgetHistory(
    evaluationDate: refresh.evaluationDate,
  );
  if (!ref.mounted ||
      ref.read(budgetRefreshProvider).generation != refresh.generation) {
    return const <BudgetHistoryEntry>[];
  }
  return entries;
});

class BudgetService {
  final IsarService isarService;
  final AppLog log;
  final GamificationService? gamificationService;
  final DateTime Function() _now;

  BudgetService(
    this.isarService,
    this.log,
    this.gamificationService, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Stream<List<Budget>> watchAllBudgets() async* {
    final isar = await isarService.getInstance();
    yield* isar.budgets
        .where()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .withDecryption();
  }

  Future<double> calculateSpentAmount(
    Budget budget, {
    DateTime? start,
    DateTime? end,
  }) async {
    final isar = await isarService.getInstance();
    return BudgetSpentCalculator.calculate(
      isar,
      budget,
      start ?? budget.startDate,
      end ?? budget.endDate,
    );
  }

  Future<List<BudgetWithProgress>> getBudgetsWithProgress({
    DateTime? evaluationDate,
  }) async {
    final isar = await isarService.getInstance();
    final budgets = await isar.budgets
        .where()
        .isArchivedEqualTo(false)
        .findAll()
        .withDecryption();

    final now = evaluationDate ?? _now();
    final today = DateArithmetic.startOfDay(now);
    budgets.removeWhere((budget) {
      if (budget.recurrence != BudgetRecurrence.none) return false;
      final (_, periodEnd) = budget.getCurrentPeriodRange(today);
      return DateArithmetic.startOfDay(periodEnd).isBefore(today);
    });

    // ── 1. Load all links in parallel per budget ──
    await Future.wait(
      budgets.map((b) async {
        await b.categories.load();
        await b.allocations.load();
        await b.budgetTags.load();
        await Future.wait(b.allocations.map((a) => a.category.load()));
      }),
    );

    // ── 2. Find widest date range across all budgets ──
    DateTime earliest = now;
    DateTime latest = now;
    final budgetRanges = <int, (DateTime, DateTime)>{};
    for (final budget in budgets) {
      final (s, e) = budget.getCurrentPeriodRange(now);
      budgetRanges[budget.id] = (s, e);
      if (s.isBefore(earliest)) earliest = s;
      if (e.isAfter(latest)) latest = e;
    }

    // ── 3. Single query: all expenses in the widest range ──
    // Exclude transfers/settlements — they don't count as budget spend.
    final allExpenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .isSettlementEqualTo(false)
        .dateBetween(earliest, latest)
        .findAll();

    // Pre-load category links for filtering
    await Future.wait(allExpenses.map((t) => t.category.load()));

    // ── 4. Index by category ID for O(1) lookup ──
    final expensesByCat = <int, List<Transaction>>{};
    for (final t in allExpenses) {
      final cat = t.category.value;
      if (cat == null) continue;
      final catId = cat.id;
      expensesByCat.putIfAbsent(catId, () => []).add(t);

      await cat.parentCategory.load();
      final parentId = cat.parentCategory.value?.id;
      if (parentId != null && parentId != catId) {
        expensesByCat.putIfAbsent(parentId, () => []).add(t);
      }
    }

    // ── 5. Compute per-budget ──
    final List<BudgetWithProgress> list = [];
    for (final budget in budgets) {
      final (s, e) = budgetRanges[budget.id]!;

      // Handle tag-wise budgets
      if (budget.budgetType == BudgetType.tagWise) {
        final tagIds = budget.budgetTags.map((t) => t.id).toSet();
        double totalSpent = 0;
        if (tagIds.isNotEmpty) {
          for (final t in allExpenses) {
            if (t.date.isBefore(s) || t.date.isAfter(e)) continue;
            await t.tags.load();
            if (t.tags.any((tag) => tagIds.contains(tag.id))) {
              totalSpent += t.effectiveAmount;
            }
          }
        }
        if (totalSpent > budget.amount) {
          PluginService().emitBudget(totalSpent, budget.amount);
        }
        list.add(
          BudgetWithProgress(
            budget: budget,
            spent: totalSpent,
            categorySpendings: [],
            startDate: s,
            endDate: e,
            snapshot: BudgetPeriodSnapshot.fromBudget(
              budget: budget,
              evaluationDate: now,
              periodStart: s,
              periodEnd: e,
              spent: totalSpent,
            ),
          ),
        );
        continue;
      }

      double totalSpent = 0;
      final catSpendings = <CategorySpending>[];

      if (budget.allocations.isNotEmpty) {
        for (final alloc in budget.allocations) {
          final cat = alloc.category.value;
          if (cat == null) continue;
          final catTxns = expensesByCat[cat.id] ?? [];
          final spent = catTxns
              .where((t) => !t.date.isBefore(s) && !t.date.isAfter(e))
              .fold<double>(0.0, (sum, t) => sum + t.effectiveAmount);
          totalSpent += spent;
          catSpendings.add(
            CategorySpending(
              category: cat,
              allocated: alloc.amount,
              spent: spent,
            ),
          );
        }
      } else {
        final periodExpenses = allExpenses
            .where((t) => !t.date.isBefore(s) && !t.date.isAfter(e))
            .toList();
        final catMap = <int, (Category, double)>{};
        for (final t in periodExpenses) {
          final cat = t.category.value;
          if (cat == null) continue;
          final existing = catMap[cat.id];
          catMap[cat.id] = (cat, (existing?.$2 ?? 0) + t.effectiveAmount);
          totalSpent += t.effectiveAmount;
        }
        for (final entry in catMap.entries) {
          catSpendings.add(
            CategorySpending(
              category: entry.value.$1,
              allocated: budget.amount *
                  (entry.value.$2 / (totalSpent > 0 ? totalSpent : 1)),
              spent: entry.value.$2,
            ),
          );
        }
        catSpendings.sort((a, b2) => b2.spent.compareTo(a.spent));
      }

      final expectedAllocCount = budget.allocations.length;
      final validAllocCount = catSpendings.length;
      final hasInvalid = budget.budgetType == BudgetType.categoryWise &&
          expectedAllocCount > 0 &&
          validAllocCount < expectedAllocCount;

      if (totalSpent > budget.amount) {
        PluginService().emitBudget(totalSpent, budget.amount);
      }

      list.add(
        BudgetWithProgress(
          budget: budget,
          spent: totalSpent,
          categorySpendings: catSpendings,
          startDate: s,
          endDate: e,
          hasInvalidCategories: hasInvalid,
          snapshot: BudgetPeriodSnapshot.fromBudget(
            budget: budget,
            evaluationDate: now,
            periodStart: s,
            periodEnd: e,
            spent: totalSpent,
            categorySpendings: catSpendings,
          ),
        ),
      );
    }
    return list;
  }

  /// Canonical snapshot adapter used by dashboard, progress, constraints,
  /// portfolio, detail, and history consumers.
  Future<List<BudgetPeriodSnapshot>> getBudgetPeriodSnapshots({
    DateTime? evaluationDate,
  }) async {
    await finalizeCompletedBudgetPeriods(evaluationDate: evaluationDate);
    final progress = await getBudgetsWithProgress(
      evaluationDate: evaluationDate ?? _now(),
    );
    return progress.map((entry) => entry.snapshot).toList(growable: false);
  }

  /// Persists completed occurrences without cloning recurring Budget rows.
  ///
  /// A recurring budget remains one mutable definition. Each ended occurrence
  /// is an immutable ledger fact, while the next occurrence is computed from
  /// the same definition by [getCurrentPeriodRange]. Existing ledger keys are
  /// skipped before spending is recalculated, making repeated refreshes cheap.
  Future<void> finalizeCompletedBudgetPeriods({
    DateTime? evaluationDate,
  }) async {
    final isar = await isarService.getInstance();
    final evaluationDay = DateArithmetic.startOfDay(evaluationDate ?? _now());
    final budgets = await isar.budgets.where().findAll().withDecryption();
    final existingKeys = (await isar.budgetPeriodLedgerEntrys.where().findAll())
        .map((entry) => entry.occurrenceKey)
        .toSet();
    final ledgerService = BudgetPeriodLedgerService(isarService);

    for (final budget in budgets) {
      final occurrenceCount =
          budget.recurrence == BudgetRecurrence.none ? 1 : 1200;
      for (var occurrence = 0; occurrence < occurrenceCount; occurrence++) {
        final (rangeStart, rangeEnd) = _periodAt(budget, occurrence);
        final periodStart = DateArithmetic.startOfDay(rangeStart);
        final periodEnd = DateArithmetic.endOfDay(rangeEnd);
        final endDay = DateArithmetic.startOfDay(periodEnd);

        // The period ending today is still active and must remain current.
        if (!endDay.isBefore(evaluationDay)) break;

        final occurrenceKey = BudgetPeriodLedgerEntry.buildOccurrenceKey(
          budget.id,
          periodStart,
          periodEnd,
        );
        if (existingKeys.contains(occurrenceKey)) continue;

        final snapshot = BudgetPeriodSnapshot.fromBudget(
          budget: budget,
          evaluationDate: evaluationDay,
          periodStart: periodStart,
          periodEnd: periodEnd,
          spent: await calculateSpentAmount(
            budget,
            start: periodStart,
            end: periodEnd,
          ),
        );
        await ledgerService.finalizeSnapshot(
          snapshot,
          occurrenceIndex: occurrence,
        );
        existingKeys.add(occurrenceKey);
      }
    }
  }

  Future<void> save(
    Budget bud, {
    List<BudgetCategoryAllocation> newAllocations = const [],
  }) async {
    final isNew = bud.id == Isar.autoIncrement;
    final isar = await isarService.getInstance();

    try {
      bud.encryptFields();
      await isar.writeTxn(() async {
        await isar.budgets.put(bud);
        await bud.categories.save();
        await bud.budgetTags.save();
        for (final alloc in newAllocations) {
          alloc.budget.value = bud;
          await isar.budgetCategoryAllocations.put(alloc);
          await alloc.category.save();
          await alloc.budget.save();
        }
      });
    } finally {
      // Keep caller-owned model readable after the encrypted write. Parent
      // and child screens can share this instance through navigation.
      bud.decryptFields();
    }

    log.i(
      'Budget saved: ${bud.name} with ${newAllocations.length} allocations',
    );
    if (isNew) {
      await gamificationService?.track(GamificationEvent.budgetCreated);
    }
  }

  /// Delete a budget and all its allocations
  Future<void> deleteBudget(int budgetId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      // Remove allocations
      final allocs = await isar.budgetCategoryAllocations
          .filter()
          .budget((q) => q.idEqualTo(budgetId))
          .findAll();
      for (final a in allocs) {
        await isar.budgetCategoryAllocations.delete(a.id);
      }
      // Remove budget itself
      await isar.budgets.delete(budgetId);
    });
    log.i('Budget deleted: $budgetId');
  }

  /// Fetch a single budget by ID
  Future<Budget?> getBudget(int budgetId) async {
    final isar = await isarService.getInstance();
    return await isar.budgets.get(budgetId).withDecryption();
  }

  // Archiving
  Future<void> archiveBudget(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final b = await isar.budgets.get(id);
      if (b != null) {
        b.isArchived = true;
        await isar.budgets.put(b);
      }
    });
  }

  Future<List<Budget>> getFilterBudget(DateTime now) async {
    final isar = await isarService.getInstance();
    final budgets = await isar.budgets
        .filter()
        .startDateLessThan(now)
        .and()
        .endDateGreaterThan(now)
        .findAll()
        .withDecryption();
    return budgets;
  }

  Future<void> deleteAllocation(
    List<BudgetCategoryAllocation> allocList,
  ) async {
    final isar = await isarService.getInstance();
    final allocIds = allocList.map((elem) => elem.id).toList();
    await isar.writeTxn(() async {
      await isar.budgetCategoryAllocations.deleteAll(allocIds);
    });
  }

  (DateTime, DateTime) _periodAt(Budget budget, int occurrence) {
    if (occurrence == 0 || budget.recurrence == BudgetRecurrence.none) {
      return (budget.startDate, budget.endDate);
    }
    return switch (budget.recurrence) {
      BudgetRecurrence.daily => (
          budget.startDate.add(Duration(days: occurrence)),
          budget.endDate.add(Duration(days: occurrence)),
        ),
      BudgetRecurrence.weekly => (
          budget.startDate.add(Duration(days: occurrence * 7)),
          budget.endDate.add(Duration(days: occurrence * 7)),
        ),
      BudgetRecurrence.monthly => (
          DateArithmetic.addMonths(
            budget.startDate,
            occurrence,
            preferDay: budget.startDate.day,
          ),
          DateArithmetic.addMonths(
            budget.endDate,
            occurrence,
            preferDay: budget.endDate.day,
          ),
        ),
      BudgetRecurrence.yearly => (
          DateArithmetic.addYears(
            budget.startDate,
            occurrence,
            preferDay: budget.startDate.day,
          ),
          DateArithmetic.addYears(
            budget.endDate,
            occurrence,
            preferDay: budget.endDate.day,
          ),
        ),
      BudgetRecurrence.none => (budget.startDate, budget.endDate),
    };
  }

  Future<List<ArchivedBudgetSummary>> getArchivedBudgets({
    DateTime? evaluationDate,
  }) async {
    final isar = await isarService.getInstance();
    final evaluationDay = DateArithmetic.startOfDay(evaluationDate ?? _now());
    final budgets = await isar.budgets.where().findAll().withDecryption();

    final results = <ArchivedBudgetSummary>[];
    final seen = <String>{};
    for (final budget in budgets) {
      // Active non-recurring budgets are not history until their period ends.
      if (!budget.isArchived && budget.recurrence == BudgetRecurrence.none) {
        if (!DateArithmetic.startOfDay(budget.endDate)
            .isBefore(evaluationDay)) {
          continue;
        }
      }

      await budget.categories.load();
      final occurrenceCount =
          budget.recurrence == BudgetRecurrence.none ? 1 : 1200;
      for (var occurrence = 0; occurrence < occurrenceCount; occurrence++) {
        final (rangeStart, rangeEnd) = _periodAt(budget, occurrence);
        final endDay = DateArithmetic.startOfDay(rangeEnd);
        // Active recurring occurrence ending today is still current. Keep it
        // out of history; archived budgets retain their final visible period.
        if (!budget.isArchived && !endDay.isBefore(evaluationDay)) break;
        if (budget.isArchived && endDay.isAfter(evaluationDay)) break;

        final snapshot = BudgetPeriodSnapshot.fromBudget(
          budget: budget,
          evaluationDate: evaluationDay,
          periodStart: rangeStart,
          periodEnd: rangeEnd,
          spent: await calculateSpentAmount(
            budget,
            start: rangeStart,
            end: rangeEnd,
          ),
        );
        if (seen.add(snapshot.occurrenceKey)) {
          results.add(ArchivedBudgetSummary(snapshot: snapshot));
        }
      }
    }
    results.sort((a, b) {
      final byEnd = b.periodEnd.compareTo(a.periodEnd);
      if (byEnd != 0) return byEnd;
      final byBudget = a.budget.id.compareTo(b.budget.id);
      return byBudget != 0
          ? byBudget
          : a.snapshot.occurrenceKey.compareTo(b.snapshot.occurrenceKey);
    });
    return results;
  }

  /// Completed non-recurring periods excluded from current snapshots.
  /// Stable occurrence keys prevent current/history duplication.
  Future<List<BudgetPeriodSnapshot>> getCompletedBudgetSnapshots({
    DateTime? evaluationDate,
  }) async {
    final isar = await isarService.getInstance();
    final evaluationDay = DateArithmetic.startOfDay(evaluationDate ?? _now());
    final budgets = await isar.budgets.where().findAll().withDecryption();
    final results = <BudgetPeriodSnapshot>[];
    final seen = <String>{};

    for (final budget in budgets) {
      if (budget.recurrence != BudgetRecurrence.none && !budget.isArchived) {
        continue;
      }
      if (!budget.isArchived &&
          !DateArithmetic.startOfDay(budget.endDate).isBefore(evaluationDay)) {
        continue;
      }
      await budget.categories.load();
      final snapshot = BudgetPeriodSnapshot.fromBudget(
        budget: budget,
        evaluationDate: evaluationDay,
        periodStart: budget.startDate,
        periodEnd: budget.endDate,
        spent: await calculateSpentAmount(
          budget,
          start: budget.startDate,
          end: budget.endDate,
        ),
      );
      if (seen.add(snapshot.occurrenceKey)) results.add(snapshot);
    }
    results.sort((a, b) {
      final byEnd = b.periodEnd.compareTo(a.periodEnd);
      return byEnd != 0 ? byEnd : a.budgetId.compareTo(b.budgetId);
    });
    return results;
  }

  /// Unified completed-period source for history UI.
  Future<List<BudgetHistoryEntry>> getBudgetHistory({
    DateTime? evaluationDate,
  }) async {
    await finalizeCompletedBudgetPeriods(evaluationDate: evaluationDate);
    final isar = await isarService.getInstance();
    final day = DateArithmetic.startOfDay(evaluationDate ?? _now());
    final byKey = <String, BudgetHistoryEntry>{};

    // Ledger rows win: they preserve limit-at-period after later edits or
    // deletion. Derived rows fill older data not yet finalized into ledger.
    final ledgerEntries = await isar.budgetPeriodLedgerEntrys.where().findAll();
    for (final entry in ledgerEntries) {
      if (entry.isFinalized &&
          DateArithmetic.startOfDay(entry.periodEnd).isBefore(day)) {
        byKey[entry.occurrenceKey] = BudgetHistoryEntry.fromLedger(entry);
      }
    }

    final completed = await getCompletedBudgetSnapshots(
      evaluationDate: evaluationDate,
    );
    for (final snapshot in completed) {
      byKey.putIfAbsent(
        snapshot.occurrenceKey,
        () => BudgetHistoryEntry.fromSnapshot(snapshot),
      );
    }

    final archived = await getArchivedBudgets(
      evaluationDate: evaluationDate,
    );
    for (final summary in archived) {
      byKey.putIfAbsent(
        summary.snapshot.occurrenceKey,
        () => BudgetHistoryEntry.fromSnapshot(summary.snapshot),
      );
    }

    final result = byKey.values.toList();
    result.sort((a, b) {
      final byEnd = b.periodEnd.compareTo(a.periodEnd);
      if (byEnd != 0) return byEnd;
      final byBudget = a.budgetId.compareTo(b.budgetId);
      return byBudget != 0
          ? byBudget
          : a.occurrenceKey.compareTo(b.occurrenceKey);
    });
    return result;
  }
}

class BudgetWithProgress {
  final Budget budget;
  final double spent;
  final List<CategorySpending> categorySpendings;
  final DateTime startDate;
  final DateTime endDate;
  final bool hasInvalidCategories;
  final BudgetPeriodSnapshot snapshot;

  BudgetWithProgress({
    required this.budget,
    required this.spent,
    required this.categorySpendings,
    required this.startDate,
    required this.endDate,
    this.hasInvalidCategories = false,
    BudgetPeriodSnapshot? snapshot,
  }) : snapshot = snapshot ??
            BudgetPeriodSnapshot.fromBudget(
              budget: budget,
              evaluationDate: startDate,
              periodStart: startDate,
              periodEnd: endDate,
              spent: spent,
              categorySpendings: categorySpendings,
            );

  BudgetWithProgress.fromSnapshot(this.snapshot)
      : budget = snapshot.budget,
        spent = snapshot.spent,
        categorySpendings = snapshot.categorySpendings,
        startDate = snapshot.periodStart,
        endDate = snapshot.periodEnd,
        hasInvalidCategories = false;
}

class ArchivedBudgetSummary {
  final BudgetPeriodSnapshot snapshot;
  final Budget budget;
  final double spent;

  ArchivedBudgetSummary({required this.snapshot})
      : budget = snapshot.budget,
        spent = snapshot.spent;

  BudgetPeriodStatus get status => snapshot.status;
  DateTime get periodStart => snapshot.periodStart;
  DateTime get periodEnd => snapshot.periodEnd;
}

enum BudgetHistoryValueSource {
  persisted,
  legacyBestAvailable,
  unknown,
}

class BudgetHistoryEntry {
  final String occurrenceKey;
  final int budgetId;
  final String budgetName;
  final BudgetRecurrence recurrence;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double limit;
  final double spent;
  final BudgetPeriodStatus? status;
  final bool limitIsKnown;
  final BudgetHistoryValueSource valueSource;

  const BudgetHistoryEntry({
    required this.occurrenceKey,
    required this.budgetId,
    required this.budgetName,
    required this.recurrence,
    required this.periodStart,
    required this.periodEnd,
    required this.limit,
    required this.spent,
    required this.status,
    required this.limitIsKnown,
    this.valueSource = BudgetHistoryValueSource.legacyBestAvailable,
  });

  factory BudgetHistoryEntry.fromSnapshot(BudgetPeriodSnapshot snapshot) {
    return BudgetHistoryEntry(
      occurrenceKey: snapshot.occurrenceKey,
      budgetId: snapshot.budgetId,
      budgetName: snapshot.budgetName,
      recurrence: snapshot.recurrence,
      periodStart: snapshot.periodStart,
      periodEnd: snapshot.periodEnd,
      limit: snapshot.limit,
      spent: snapshot.spent,
      status: snapshot.status,
      limitIsKnown: true,
      valueSource: BudgetHistoryValueSource.legacyBestAvailable,
    );
  }

  factory BudgetHistoryEntry.fromLedger(BudgetPeriodLedgerEntry entry) {
    final status = switch (entry.status) {
      BudgetPeriodLedgerStatus.met => BudgetPeriodStatus.met,
      BudgetPeriodLedgerStatus.exceeded => BudgetPeriodStatus.exceeded,
      BudgetPeriodLedgerStatus.unknown => null,
    };
    return BudgetHistoryEntry(
      occurrenceKey: entry.occurrenceKey,
      budgetId: entry.budgetId,
      budgetName: entry.budgetName,
      recurrence: entry.recurrence,
      periodStart: entry.periodStart,
      periodEnd: entry.periodEnd,
      limit: entry.limitAtPeriod,
      spent: entry.finalSpent,
      status: status,
      limitIsKnown: entry.limitIsKnown,
      valueSource: entry.limitIsKnown
          ? BudgetHistoryValueSource.persisted
          : BudgetHistoryValueSource.unknown,
    );
  }
}
