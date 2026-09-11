import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_period_ledger_entry.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_constraint_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/budget/domain/budget_overview_aggregate.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerBudgetStaleDataIntegrationTests();
}

/// Registers deterministic fixture-backed coverage in [app_test.dart].
///
/// Keeping this suite in its own library avoids coupling the fixture to app
/// onboarding state while the app test still runs the required full command.
void registerBudgetStaleDataIntegrationTests() {
  late _BudgetFixture fixture;
  late ProviderContainer container;

  setUp(() async {
    fixture = await _BudgetFixture.create();
    container = ProviderContainer(
      overrides: [
        isarServiceProvider.overrideWithValue(fixture.isarService),
        gamificationServiceProvider.overrideWithValue(null),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await fixture.close();
  });

  testWidgets(
    'monthly spend resets across no-write boundary and surfaces converge',
    (tester) async {
      final budget = fixture.makeBudget(
        id: 1,
        name: 'January Boundary',
        amount: 10000,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.dayWise,
      );
      await fixture.putBudget(budget);
      await fixture.putTransaction(
        fixture.makeTransaction(
          date: DateTime(2024, 1, 15, 12),
          amount: 3000,
        ),
      );

      final january = await _readCurrent(container, DateTime(2024, 1, 31));
      expect(january.snapshot.spent, 3000);
      expect(january.snapshot.periodStart, DateTime(2024, 1, 1));
      expect(
        january.snapshot.periodEnd,
        DateTime(2024, 1, 31, 23, 59, 59, 999999),
      );
      expect(january.aggregate.totalRemaining, 7000);

      // No Isar write occurs between these reads. This is the reported stale
      // dashboard-mini-card reproduction: February must not retain January's
      // 3,000 spent / 7,000 remaining values.
      final february = await _readCurrent(
        container,
        DateTime(2024, 2, 1),
        reason: BudgetRefreshReason.dateBoundary,
      );
      expect(february.snapshot.spent, 0);
      expect(february.snapshot.periodStart, DateTime(2024, 2, 1));
      expect(
        february.snapshot.periodEnd,
        DateTime(2024, 2, 29, 23, 59, 59, 999999),
      );
      expect(february.snapshot.remaining, 10000);
      expect(february.aggregate.totalRemaining, 10000);
      expect(february.aggregate.progress, 0);
      expect(
        february.constraint.budgetSnapshot!.occurrenceKey,
        february.snapshot.occurrenceKey,
      );
      expect(
        february.dashboard.budgets.single.snapshot.occurrenceKey,
        february.snapshot.occurrenceKey,
      );
      expect(february.dashboard.budgets.single.snapshot.spent, 0);
      _expectNonBudgetDashboardPreserved(
        january.dashboard,
        february.dashboard,
      );
    },
  );

  testWidgets(
    'resume, pull, navigation, transaction CRUD/recategorization, and budget CRUD share refresh result',
    (tester) async {
      final trackedTag = Tag()
        ..id = 10
        ..name = 'Budget tag';
      final otherTag = Tag()
        ..id = 11
        ..name = 'Other tag';
      await fixture.putTags([trackedTag, otherTag]);

      final budget = fixture.makeBudget(
        id: 2,
        name: 'Tracked February',
        amount: 1000,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 29),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.tagWise,
      )..budgetTags.add(trackedTag);
      await fixture.putBudget(budget);

      final date = DateTime(2024, 2, 10);
      final initial = await _readCurrent(container, date);
      expect(initial.snapshot.spent, 0);

      for (final reason in [
        BudgetRefreshReason.appResumed,
        BudgetRefreshReason.manual,
        BudgetRefreshReason.navigation,
      ]) {
        final refreshed = await _readCurrent(container, date, reason: reason);
        expect(
          refreshed.snapshot.occurrenceKey,
          initial.snapshot.occurrenceKey,
        );
        expect(refreshed.snapshot.spent, 0);
        expect(
          refreshed.constraint.budgetSnapshot!.occurrenceKey,
          refreshed.snapshot.occurrenceKey,
        );
        expect(refreshed.dashboard.budgets.single.snapshot.spent, 0);
        _expectNonBudgetDashboardPreserved(
          initial.dashboard,
          refreshed.dashboard,
        );
      }

      final transaction = fixture.makeTransaction(
        date: DateTime(2024, 2, 5, 9),
        amount: 125,
      )..tags.add(trackedTag);
      await fixture.putTransaction(transaction);
      final afterCreate = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.transactionChanged,
      );
      expect(afterCreate.snapshot.spent, 125);

      transaction.amount = 225;
      await fixture.putTransaction(transaction);
      final afterEdit = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.transactionChanged,
      );
      expect(afterEdit.snapshot.spent, 225);

      // Recategorization here is a tag-scope move. Removing the budget tag
      // must immediately remove transaction from current spend.
      transaction.tags.remove(trackedTag);
      transaction.tags.add(otherTag);
      await fixture.putTransaction(transaction);
      final afterRecategorize = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.transactionChanged,
      );
      expect(afterRecategorize.snapshot.spent, 0);

      await fixture.putTransaction(transaction, delete: true);
      final afterDelete = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.transactionChanged,
      );
      expect(afterDelete.snapshot.spent, 0);

      final created = fixture.makeBudget(
        id: Isar.autoIncrement,
        name: 'Created budget',
        amount: 500,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 29),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.dayWise,
      );
      await container.read(budgetServiceProvider).save(created);
      final afterCreateBudget = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.budgetCrud,
      );
      expect(
        afterCreateBudget.snapshots.map((s) => s.budgetName),
        contains('Created budget'),
      );

      created.amount = 750;
      await container.read(budgetServiceProvider).save(created);
      final afterEditBudget = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.budgetCrud,
      );
      expect(
        afterEditBudget.snapshots
            .singleWhere((s) => s.budgetId == created.id)
            .limit,
        750,
      );

      await container.read(budgetServiceProvider).archiveBudget(created.id);
      final afterArchive = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.budgetCrud,
      );
      expect(
        afterArchive.snapshots.any((s) => s.budgetId == created.id),
        false,
      );

      // Keep one unrelated active budget so final projection can prove the
      // deleted record is absent without accepting an empty/stale surface.
      await fixture.putBudget(
        fixture.makeBudget(
          id: 3,
          name: 'Unaffected budget',
          amount: 250,
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 29),
          recurrence: BudgetRecurrence.monthly,
          budgetType: BudgetType.dayWise,
        ),
      );
      await container.read(budgetServiceProvider).deleteBudget(budget.id);
      final afterDeleteBudget = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.budgetCrud,
      );
      expect(
        afterDeleteBudget.snapshots.any((s) => s.budgetId == budget.id),
        false,
      );
      expect(
        afterDeleteBudget.dashboard.budgets
            .any((b) => b.budget.id == budget.id),
        false,
      );
      expect(
        afterDeleteBudget.dashboard.totalExpense,
        afterCreateBudget.dashboard.totalExpense,
      );
    },
  );

  testWidgets(
    'mixed periods and zero limit produce safe period-aware mini-card aggregate',
    (tester) async {
      final evaluation = DateTime(2024, 2, 10);
      final budgets = [
        fixture.makeBudget(
          id: 20,
          name: 'Daily',
          amount: 100,
          start: DateTime(2024, 2, 10),
          end: DateTime(2024, 2, 10),
          recurrence: BudgetRecurrence.daily,
          budgetType: BudgetType.dayWise,
        ),
        fixture.makeBudget(
          id: 21,
          name: 'Weekly',
          amount: 200,
          start: DateTime(2024, 2, 4),
          end: DateTime(2024, 2, 10),
          recurrence: BudgetRecurrence.weekly,
          budgetType: BudgetType.dayWise,
        ),
        fixture.makeBudget(
          id: 22,
          name: 'Monthly',
          amount: 300,
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 29),
          recurrence: BudgetRecurrence.monthly,
          budgetType: BudgetType.dayWise,
        ),
        fixture.makeBudget(
          id: 23,
          name: 'Yearly',
          amount: 400,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
          recurrence: BudgetRecurrence.yearly,
          budgetType: BudgetType.dayWise,
        ),
        fixture.makeBudget(
          id: 24,
          name: 'Zero',
          amount: 0,
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 29),
          recurrence: BudgetRecurrence.monthly,
          budgetType: BudgetType.dayWise,
        ),
      ];
      for (final budget in budgets) {
        await fixture.putBudget(budget);
      }

      final current = await _readCurrent(container, evaluation);
      final aggregate = current.aggregate;
      expect(aggregate.totalLimit, 1000);
      expect(aggregate.totalSpent, 0);
      expect(aggregate.totalRemaining, 1000);
      expect(aggregate.progress, 0);
      expect(aggregate.progress.isFinite, true);
      expect(aggregate.dailyAllowance.isFinite, true);
      expect(aggregate.isCompatibleMonthly, false);
      expect(
        current.snapshots.map((s) => s.periodStart).toSet().length,
        greaterThan(1),
      );
    },
  );

  testWidgets(
    'completed one-time, recurring, and archived history preserves dates, limits, status, and keys',
    (tester) async {
      final historyTag = Tag()
        ..id = 30
        ..name = 'History tag';
      await fixture.putTags([historyTag]);

      final oneTime = fixture.makeBudget(
        id: 31,
        name: 'One-time met',
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 10),
        recurrence: BudgetRecurrence.none,
        budgetType: BudgetType.tagWise,
      )..budgetTags.add(historyTag);
      final recurring = fixture.makeBudget(
        id: 32,
        name: 'Recurring exceeded',
        amount: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.tagWise,
      )..budgetTags.add(historyTag);
      final archived = fixture.makeBudget(
        id: 33,
        name: 'Archived equal',
        amount: 75,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.tagWise,
        archived: true,
      )..budgetTags.add(historyTag);
      await fixture.putBudget(oneTime);
      await fixture.putBudget(recurring);
      await fixture.putBudget(archived);
      final historyFirst = fixture.makeTransaction(
        date: DateTime(2024, 1, 5),
        amount: 100,
      )..tags.add(historyTag);
      final historySecond = fixture.makeTransaction(
        date: DateTime(2024, 1, 20),
        amount: 50,
      )..tags.add(historyTag);
      await fixture.putTransaction(historyFirst);
      await fixture.putTransaction(historySecond);

      final current = await _readCurrent(
        container,
        DateTime(2024, 2, 1),
        reason: BudgetRefreshReason.dateBoundary,
      );
      expect(
        current.snapshots
            .where((entry) => {31, 32, 33}.contains(entry.budgetId)),
        hasLength(1),
        reason: 'Only recurring budget current occurrence may remain active',
      );

      final history =
          await container.read(budgetServiceProvider).getBudgetHistory(
                evaluationDate: DateTime(2024, 2, 1),
              );
      final entries = history
          .where((entry) => {31, 32, 33}.contains(entry.budgetId))
          .toList();
      expect(
        entries.map((entry) => entry.occurrenceKey).toSet().length,
        entries.length,
      );
      expect(entries, isNotEmpty);
      final currentKeys =
          current.snapshots.map((entry) => entry.occurrenceKey).toSet();
      final historyKeys = entries.map((entry) => entry.occurrenceKey).toSet();
      expect(
        currentKeys.intersection(historyKeys),
        isEmpty,
        reason: 'Current and completed history must not duplicate occurrences',
      );

      final oneTimeEntry = entries.firstWhere((entry) => entry.budgetId == 31);
      expect(oneTimeEntry.periodStart, DateTime(2024, 1, 1));
      expect(oneTimeEntry.periodEnd, DateTime(2024, 1, 10, 23, 59, 59, 999));
      expect(oneTimeEntry.limit, 100);
      expect(oneTimeEntry.spent, 100);
      expect(oneTimeEntry.status, BudgetPeriodStatus.met);

      final recurringEntry =
          entries.firstWhere((entry) => entry.budgetId == 32);
      expect(recurringEntry.periodStart, DateTime(2024, 1, 1));
      expect(
        recurringEntry.periodEnd,
        DateTime(2024, 1, 31, 23, 59, 59, 999999),
      );
      expect(recurringEntry.limit, 100);
      expect(recurringEntry.spent, 150);
      expect(recurringEntry.status, BudgetPeriodStatus.exceeded);

      final archivedEntry = entries.firstWhere((entry) => entry.budgetId == 33);
      expect(archivedEntry.status, BudgetPeriodStatus.exceeded);
      expect(archivedEntry.limitIsKnown, true);

      final sourceTransactions =
          await fixture.database.transactions.where().findAll();
      final sourceById = {
        for (final transaction in sourceTransactions)
          transaction.id: transaction,
      };
      expect(sourceById[historyFirst.id]?.amount, 100);
      expect(sourceById[historyFirst.id]?.date, DateTime(2024, 1, 5));
      expect(sourceById[historySecond.id]?.amount, 50);
      expect(sourceById[historySecond.id]?.date, DateTime(2024, 1, 20));
    },
  );

  testWidgets(
    'refresh failure hides stale read and retry restores coherent current data',
    (tester) async {
      final budget = fixture.makeBudget(
        id: 40,
        name: 'Retry budget',
        amount: 1000,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 29),
        recurrence: BudgetRecurrence.monthly,
        budgetType: BudgetType.dayWise,
      );
      await fixture.putBudget(budget);
      final date = DateTime(2024, 2, 10);
      final healthy = await _readCurrent(container, date);
      expect(healthy.snapshot.spent, 0);

      fixture.isarService.failReads = true;
      container.read(budgetRefreshProvider.notifier).refresh(
            BudgetRefreshReason.manual,
            evaluationDate: date,
          );
      await expectLater(
        container.read(budgetPeriodSnapshotsProvider.future),
        throwsA(isA<StateError>()),
      );

      // Retry uses same shared coordinator. It must rebuild from source, not
      // return the pre-failure snapshot as if it were current.
      fixture.isarService.failReads = false;
      final retried = await _readCurrent(
        container,
        date,
        reason: BudgetRefreshReason.retry,
      );
      expect(retried.snapshot.occurrenceKey, healthy.snapshot.occurrenceKey);
      expect(retried.dashboard.budgets.single.snapshot.spent, 0);
      expect(
        retried.constraint.budgetSnapshot!.occurrenceKey,
        retried.snapshot.occurrenceKey,
      );
    },
  );
}

void _expectNonBudgetDashboardPreserved(
  DashboardData before,
  DashboardData after,
) {
  expect(after.transactions.length, before.transactions.length);
  expect(after.accounts.length, before.accounts.length);
  expect(after.accountBalances, before.accountBalances);
  expect(after.recurringExpenses.length, before.recurringExpenses.length);
  expect(after.goals.length, before.goals.length);
  expect(after.totalIncome, before.totalIncome);
  expect(after.totalExpense, before.totalExpense);
  expect(after.totalBalance, before.totalBalance);
  expect(after.netWorth, before.netWorth);
  expect(after.pendingSmsCount, before.pendingSmsCount);
}

class _CurrentSurface {
  final List<BudgetPeriodSnapshot> snapshots;
  final BudgetPeriodSnapshot snapshot;
  final BudgetConstraintSnapshot constraint;
  final BudgetOverviewAggregate aggregate;
  final DashboardData dashboard;

  const _CurrentSurface({
    required this.snapshots,
    required this.snapshot,
    required this.constraint,
    required this.aggregate,
    required this.dashboard,
  });
}

Future<_CurrentSurface> _readCurrent(
  ProviderContainer container,
  DateTime evaluationDate, {
  BudgetRefreshReason? reason,
}) async {
  final refreshNotifier = container.read(budgetRefreshProvider.notifier);
  refreshNotifier.refresh(
    reason ?? BudgetRefreshReason.navigation,
    evaluationDate: evaluationDate,
  );
  final snapshots = await container.read(budgetPeriodSnapshotsProvider.future);
  final constraints = await container.read(budgetConstraintsProvider.future);
  final refresh = container.read(budgetRefreshProvider);
  final dashboard = DashboardData(
    transactions: const [],
    accounts: const [],
    accountBalances: const {},
    budgets: snapshots.map(BudgetWithProgress.fromSnapshot).toList(),
    recurringExpenses: const [],
    goals: const [],
    totalIncome: 1200,
    totalExpense: 225,
    totalBalance: 975,
    netWorth: 975,
    pendingSmsCount: 0,
    budgetEvaluationDate: refresh.evaluationDate,
    budgetGeneration: refresh.generation,
  );
  expect(snapshots, isNotEmpty);
  expect(constraints, isNotEmpty);
  expect(constraints.length, snapshots.length);
  for (final constraint in constraints) {
    final snapshot =
        snapshots.singleWhere((s) => s.budgetId == constraint.budgetId);
    expect(constraint.budgetSnapshot!.occurrenceKey, snapshot.occurrenceKey);
    expect(constraint.spent, snapshot.spent);
    expect(constraint.limit, snapshot.limit);
  }
  return _CurrentSurface(
    snapshots: snapshots,
    snapshot: snapshots.first,
    constraint: constraints.first,
    aggregate: BudgetOverviewAggregate.fromSnapshots(snapshots),
    dashboard: dashboard,
  );
}

class _BudgetFixture {
  final Isar database;
  final Directory directory;
  final _FixtureIsarService isarService;

  _BudgetFixture._(this.database, this.directory)
      : isarService = _FixtureIsarService(database);

  static Future<_BudgetFixture> create() async {
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    final directory = await Directory.systemTemp.createTemp('budget_e2e_');
    final database = await Isar.open(
      [
        AccountSchema,
        BudgetSchema,
        BudgetCategoryAllocationSchema,
        BudgetPeriodLedgerEntrySchema,
        CategorySchema,
        RecurringTransactionSchema,
        TagSchema,
        TransactionSchema,
      ],
      directory: directory.path,
    );
    return _BudgetFixture._(database, directory);
  }

  Future<void> close() async {
    if (database.isOpen) await database.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  }

  Budget makeBudget({
    required int id,
    required String name,
    required double amount,
    required DateTime start,
    required DateTime end,
    required BudgetRecurrence recurrence,
    required BudgetType budgetType,
    bool archived = false,
  }) {
    return Budget()
      ..id = id
      ..name = name
      ..amount = amount
      ..startDate = start
      ..endDate = end
      ..recurrence = recurrence
      ..budgetType = budgetType
      ..isArchived = archived;
  }

  Transaction makeTransaction({
    required DateTime date,
    required double amount,
  }) {
    return Transaction()
      ..date = date
      ..amount = amount
      ..isExpense = true
      ..isTransfer = false
      ..isSettlement = false;
  }

  Future<void> putBudget(Budget budget) async {
    await database.writeTxn(() async {
      await database.budgets.put(budget);
      await budget.categories.save();
      await budget.budgetTags.save();
      await budget.allocations.save();
    });
  }

  Future<void> putTags(List<Tag> tags) async {
    await database.writeTxn(() => database.tags.putAll(tags));
  }

  Future<void> putTransaction(
    Transaction transaction, {
    bool delete = false,
  }) async {
    await database.writeTxn(() async {
      if (delete) {
        await database.transactions.delete(transaction.id);
      } else {
        await database.transactions.put(transaction);
        await transaction.category.save();
        await transaction.tags.save();
      }
    });
  }
}

class _FixtureIsarService extends IsarService {
  final Isar database;
  bool failReads = false;

  _FixtureIsarService(this.database);

  @override
  Future<Isar> getInstance() async {
    if (failReads) throw StateError('injected budget refresh failure');
    return database;
  }
}
