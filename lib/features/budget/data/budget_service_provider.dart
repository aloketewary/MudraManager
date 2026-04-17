import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('BudgetService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return BudgetService(isarService, log, gamificationService);
});

final budgetStreamProvider = StreamProvider.autoDispose<List<Budget>>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return service.watchAllBudgets();
});

final budgetWithProgressProvider =
    StreamProvider.autoDispose<List<(Budget, double, DateTime, DateTime)>>(
        (ref) async* {
  final budgetService = ref.watch(budgetServiceProvider);
  final isar = await ref.read(isarServiceProvider).getInstance();

  await for (final budgets in isar.budgets
      .where()
      .isArchivedEqualTo(false)
      .watch(fireImmediately: true)) {
    final List<(Budget, double, DateTime, DateTime)> result = [];
    final now = DateTime.now();
    for (final budget in budgets) {
      // Filter out expired one-time budgets
      if (budget.recurrence == BudgetRecurrence.none &&
          budget.endDate.isBefore(
            DateTime(now.year, now.month, now.day, 23, 59, 59),
          )) {
        continue;
      }

      final (s, e) = budget.getCurrentPeriodRange(now);
      final spent = await budgetService.calculateSpentAmount(
        budget,
        start: s,
        end: e,
      );
      result.add((budget, spent, s, e));
    }
    yield result;
  }
});

final budgetsWithProgressProvider =
    StreamProvider.autoDispose<List<BudgetWithProgress>>((ref) {
  return ref.watch(budgetServiceProvider).watchBudgetsWithProgress();
});

final archivedBudgetsProvider =
    FutureProvider.autoDispose<List<ArchivedBudgetSummary>>((ref) async {
  final service = ref.watch(budgetServiceProvider);
  return service.getArchivedBudgets();
});

class BudgetService {
  final IsarService isarService;
  final AppLog log;
  final GamificationService? gamificationService;

  BudgetService(this.isarService, this.log, this.gamificationService);

  Stream<List<Budget>> watchAllBudgets() async* {
    final isar = await isarService.getInstance();
    yield* isar.budgets
        .where()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Future<double> calculateSpentAmount(
    Budget budget, {
    DateTime? start,
    DateTime? end,
  }) async {
    final isar = await isarService.getInstance();
    final s = start ?? budget.startDate;
    final e = end ?? budget.endDate;

    final categoryIds = budget.categories.map((c) => c.id).toList();

    final transactions = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .dateBetween(s, e)
        .findAll();

    final spent = transactions
        .where(
          (t) =>
              t.category.value != null &&
              categoryIds.contains(t.category.value!.id),
        )
        .fold<double>(0.0, (sum, t) => sum + t.baseAmount);

    return spent;
  }

  Stream<List<BudgetWithProgress>> watchBudgetsWithProgress() async* {
    final isar = await isarService.getInstance();
    await for (final budgets in isar.budgets
        .where()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)) {
      final now = DateTime.now();

      // ── 1. Load all links in parallel per budget ──
      await Future.wait(
        budgets.map((b) async {
          await b.categories.load();
          await b.allocations.load();
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
      final allExpenses = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .dateBetween(earliest, latest)
          .findAll();

      // Pre-load category links for filtering
      await Future.wait(allExpenses.map((t) => t.category.load()));

      // ── 4. Index by category ID for O(1) lookup ──
      // Also index child category transactions under their parent ID
      final expensesByCat = <int, List<Transaction>>{};
      for (final t in allExpenses) {
        final cat = t.category.value;
        if (cat == null) continue;
        final catId = cat.id;
        expensesByCat.putIfAbsent(catId, () => []).add(t);

        // If this category has a parent, also index under parent
        await cat.parentCategory.load();
        final parentId = cat.parentCategory.value?.id;
        if (parentId != null && parentId != catId) {
          expensesByCat.putIfAbsent(parentId, () => []).add(t);
        }
      }

      // ── 5. Compute per-budget with zero additional queries ──
      final List<BudgetWithProgress> list = [];
      for (final budget in budgets) {
        final (s, e) = budgetRanges[budget.id]!;

        // Handle tag-wise budgets
        if (budget.budgetType == BudgetType.tagWise) {
          await budget.budgetTags.load();
          final tagIds = budget.budgetTags.map((t) => t.id).toSet();
          if (tagIds.isEmpty) continue;

          // Filter expenses that have any of the budget's tags
          double totalSpent = 0;
          for (final t in allExpenses) {
            if (t.date.isBefore(s) || t.date.isAfter(e)) continue;
            await t.tags.load();
            if (t.tags.any((tag) => tagIds.contains(tag.id))) {
              totalSpent += t.baseAmount;
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
            ),
          );
          continue;
        }

        double totalSpent = 0;
        final catSpendings = <CategorySpending>[];

        if (budget.allocations.isNotEmpty) {
          // Category-wise: use allocations
          for (final alloc in budget.allocations) {
            final cat = alloc.category.value;
            if (cat == null) continue; // deleted category — skip
            final catTxns = expensesByCat[cat.id] ?? [];
            final spent = catTxns
                .where((t) => !t.date.isBefore(s) && !t.date.isAfter(e))
                .fold<double>(0.0, (sum, t) => sum + t.baseAmount);

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
          // No allocations (dayWise, festival, travel): show all category spending
          final periodExpenses = allExpenses
              .where((t) => !t.date.isBefore(s) && !t.date.isAfter(e))
              .toList();
          final catMap = <int, (Category, double)>{};
          for (final t in periodExpenses) {
            final cat = t.category.value;
            if (cat == null) continue;
            final existing = catMap[cat.id];
            catMap[cat.id] = (cat, (existing?.$2 ?? 0) + t.baseAmount);
            totalSpent += t.baseAmount;
          }
          for (final entry in catMap.entries) {
            catSpendings.add(
              CategorySpending(
                category: entry.value.$1,
                allocated: budget.amount * (entry.value.$2 / (totalSpent > 0 ? totalSpent : 1)),
                spent: entry.value.$2,
              ),
            );
          }
          catSpendings.sort((a, b2) => b2.spent.compareTo(a.spent));
        }

        // Detect deleted categories
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
          ),
        );
      }
      yield list;
    }
  }

  Future<void> save(Budget bud, {List<BudgetCategoryAllocation> newAllocations = const []}) async {
    final isar = await isarService.getInstance();
    final isNew = bud.id == Isar.autoIncrement;
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
    log.i('Budget saved: ${bud.name} with ${newAllocations.length} allocations');
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
    return await isar.budgets.get(budgetId);
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
        .findAll();
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

  Future<List<ArchivedBudgetSummary>> getArchivedBudgets() async {
    final isar = await isarService.getInstance();
    final budgets = await isar.budgets
        .filter()
        .isArchivedEqualTo(true)
        .sortByStartDateDesc()
        .findAll();

    final results = <ArchivedBudgetSummary>[];
    for (final budget in budgets) {
      await budget.categories.load();
      final spent = await calculateSpentAmount(budget);
      results.add(ArchivedBudgetSummary(
        budget: budget,
        spent: spent,
        wasUnderBudget: spent <= budget.amount,
      ));
    }
    return results;
  }
}

class CategorySpending {
  final Category category;
  final double allocated;
  final double spent;

  CategorySpending({
    required this.category,
    required this.allocated,
    required this.spent,
  });
}

class BudgetWithProgress {
  final Budget budget;
  final double spent;
  final List<CategorySpending> categorySpendings;
  final DateTime startDate;
  final DateTime endDate;
  final bool hasInvalidCategories;

  BudgetWithProgress({
    required this.budget,
    required this.spent,
    required this.categorySpendings,
    required this.startDate,
    required this.endDate,
    this.hasInvalidCategories = false,
  });
}

class ArchivedBudgetSummary {
  final Budget budget;
  final double spent;
  final bool wasUnderBudget;

  ArchivedBudgetSummary({
    required this.budget,
    required this.spent,
    required this.wasUnderBudget,
  });
}
