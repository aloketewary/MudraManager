import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late BudgetService budgetService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('budget_bug_exploration_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();

    isar = await Isar.open(
      [
        BudgetSchema,
        BudgetCategoryAllocationSchema,
        CategorySchema,
        TagSchema,
        TransactionSchema,
        AccountSchema,
        RecurringTransactionSchema,
        ExchangeRateSchema,
      ],
      directory: tempDir.path,
    );
    budgetService = BudgetService(
      IsarService(),
      AppLog(getLogger(), 'BudgetBugExplorationTest'),
      null,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  Budget makeBudget({
    int id = 1,
    double amount = 10000,
    DateTime? start,
    DateTime? end,
    BudgetRecurrence recurrence = BudgetRecurrence.monthly,
    bool archived = false,
  }) {
    return Budget()
      ..id = id
      ..name = 'Exploration budget'
      ..amount = amount
      ..startDate = start ?? DateTime(2024, 1, 1)
      ..endDate = end ?? DateTime(2024, 1, 31)
      ..budgetType = BudgetType.dayWise
      ..recurrence = recurrence
      ..isArchived = archived;
  }

  BudgetWithProgress progress(
    Budget budget, {
    required double spent,
    required DateTime start,
    required DateTime end,
  }) {
    return BudgetWithProgress(
      budget: budget,
      spent: spent,
      categorySpendings: const [],
      startDate: start,
      endDate: end,
    );
  }

  DashboardData dashboard(List<BudgetWithProgress> budgets) {
    return DashboardData(
      transactions: const [],
      accounts: const [],
      accountBalances: const {},
      budgets: budgets,
      recurringExpenses: const [],
      goals: const [],
      totalIncome: 0,
      totalExpense: 0,
      totalBalance: 0,
      netWorth: 0,
      pendingSmsCount: 0,
    );
  }

  test(
    'counterexample: January snapshot remains equal after February boundary without DB write',
    () {
      final budget = makeBudget();
      final january = dashboard([
        progress(
          budget,
          spent: 3000,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
      ]);
      final february = dashboard([
        progress(
          budget,
          spent: 0,
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 29),
        ),
      ]);

      // Unfixed counterexample: DashboardData.== returns true here because
      // list lengths and unrelated dashboard totals are unchanged. A live
      // dashboard can therefore retain January 3,000 spent / 7,000 remaining
      // on February 1, while budget providers calculate February 0 / 10,000.
      expect(january, isNot(equals(february)));
    },
  );

  test(
      'counterexamples: each render-relevant budget field is ignored by equality',
      () {
    final baseBudget = makeBudget();
    final base = dashboard([
      progress(
        baseBudget,
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);

    final changedSpent = dashboard([
      progress(
        makeBudget(),
        spent: 200,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final changedPeriod = dashboard([
      progress(
        makeBudget(),
        spent: 100,
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 29),
      ),
    ]);
    final changedAmount = dashboard([
      progress(
        makeBudget(amount: 12000),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final changedRecurrence = dashboard([
      progress(
        makeBudget(recurrence: BudgetRecurrence.weekly),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final changedArchiveState = dashboard([
      progress(
        makeBudget(archived: true),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final changedIdentity = dashboard([
      progress(
        makeBudget(id: 2),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final category = Category()
      ..id = 7
      ..name = 'Food'
      ..iconName = 'food'
      ..categoryType = CategoryType.expense;
    final changedBreakdown = DashboardData(
      transactions: const [],
      accounts: const [],
      accountBalances: const {},
      budgets: [
        BudgetWithProgress(
          budget: makeBudget(),
          spent: 100,
          categorySpendings: [
            CategorySpending(category: category, allocated: 500, spent: 100),
          ],
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        ),
      ],
      recurringExpenses: const [],
      goals: const [],
      totalIncome: 0,
      totalExpense: 0,
      totalBalance: 0,
      netWorth: 0,
      pendingSmsCount: 0,
    );

    // Unfixed counterexamples: all pairs compare equal despite changed
    // amount, recurrence, period, spent, identity, archive state, or
    // category breakdown.
    expect(base, isNot(equals(changedSpent)));
    expect(base, isNot(equals(changedPeriod)));
    expect(base, isNot(equals(changedAmount)));
    expect(base, isNot(equals(changedRecurrence)));
    expect(base, isNot(equals(changedArchiveState)));
    expect(base, isNot(equals(changedIdentity)));
    expect(base, isNot(equals(changedBreakdown)));
  });

  test(
      'counterexamples: CRUD and transaction changes can be suppressed by cache equality',
      () {
    final originalBudget = makeBudget();
    final original = dashboard([
      progress(
        originalBudget,
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);

    final edited = dashboard([
      progress(
        makeBudget(amount: 15000),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final archived = dashboard([
      progress(
        makeBudget(archived: true),
        spent: 100,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final transactionChanged = dashboard([
      progress(
        makeBudget(),
        spent: 400,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final created = dashboard([
      ...original.budgets,
      progress(
        makeBudget(id: 2),
        spent: 0,
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      ),
    ]);
    final deleted = dashboard(const []);

    // Create/delete alter list length and are noticed; edit/archive and a
    // budget-affecting transaction keep length unchanged and are suppressed.
    // This is the refresh-path disagreement: DB/provider work can complete,
    // but dashboard/mini-card retains old data after the same event.
    expect(original, isNot(equals(created))); // create
    expect(original, isNot(equals(deleted))); // delete
    expect(original, isNot(equals(edited))); // edit
    expect(original, isNot(equals(archived))); // archive
    expect(original, isNot(equals(transactionChanged))); // transaction edit
  });

  test('counterexample: mini-card mixed periods use device calendar-month math',
      () {
    final now = DateTime.now();
    final snapshots = <BudgetWithProgress>[
      progress(
        makeBudget(id: 1, amount: 100),
        spent: 20,
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day),
      ),
      progress(
        makeBudget(
          id: 2,
          amount: 200,
          recurrence: BudgetRecurrence.weekly,
        ),
        spent: 50,
        start: now.subtract(const Duration(days: 3)),
        end: now.add(const Duration(days: 3)),
      ),
      progress(
        makeBudget(id: 3, amount: 300),
        spent: 100,
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      progress(
        makeBudget(
          id: 4,
          amount: 400,
          recurrence: BudgetRecurrence.yearly,
        ),
        spent: 200,
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31),
      ),
      progress(
        makeBudget(
          id: 5,
          amount: 500,
          recurrence: BudgetRecurrence.none,
        ),
        spent: 100,
        start: now.subtract(const Duration(days: 10)),
        end: now.add(const Duration(days: 19)),
      ),
    ];

    final totalRemaining = snapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.budget.amount - snapshot.spent,
    );
    final daysInCalendarMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeftInCalendarMonth = daysInCalendarMonth - now.day + 1;
    final unfixedDaily = totalRemaining / daysLeftInCalendarMonth;
    final periodAwareDaily = snapshots.fold<double>(0, (sum, snapshot) {
      final remaining = snapshot.budget.amount - snapshot.spent;
      final daysLeft = snapshot.endDate.difference(now).inDays + 1;
      return sum + (remaining > 0 && daysLeft > 0 ? remaining / daysLeft : 0);
    });

    // Unfixed counterexample: card calls this "Monthly Budget" and computes
    // one calendar-month daily value for daily/weekly/monthly/yearly/custom
    // periods. Correct aggregate must use each snapshot's period semantics.
    expect(unfixedDaily, closeTo(periodAwareDaily, 0.0001));
  });

  test(
      'counterexample: zero total budget produces non-finite mini-card percentage',
      () {
    final totalBudget = 0.0;
    final totalSpent = 0.0;

    // Exact current BudgetOverviewCard expression. Unfixed output is NaN,
    // which can reach ProgressRing/TweenAnimationBuilder instead of safe
    // zero/unknown progress.
    final percent = (totalSpent / totalBudget * 100).clamp(0.0, 100.0);
    expect(percent.isFinite, isTrue);
  });

  test(
      'counterexample: ended one-time budget is removed from current path with no history entry',
      () async {
    final ended = makeBudget(
      start: DateTime(2020, 1, 1),
      end: DateTime(2020, 1, 31),
      recurrence: BudgetRecurrence.none,
    );
    await isar.writeTxn(() => isar.budgets.put(ended));

    final container = ProviderContainer(
      overrides: [
        isarServiceProvider.overrideWithValue(IsarService()),
        gamificationServiceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    final current = await container.read(budgetWithProgressProvider.future);

    // Unfixed counterexample: current provider filters ended one-time budgets,
    // while no reachable history UI/provider exposes this final period.
    expect(current.any((entry) => entry.$1.id == ended.id), isTrue);
  });

  test(
      'counterexample: prior recurring periods are not reachable from active history',
      () async {
    final recurring = makeBudget(
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      recurrence: BudgetRecurrence.monthly,
    );
    await isar.writeTxn(() => isar.budgets.put(recurring));

    final current = await budgetService.getBudgetsWithProgress();
    final archivedHistory = await budgetService.getArchivedBudgets();

    // Unfixed counterexample: active recurring budget exposes one current
    // snapshot only; prior completed occurrences have no reachable history.
    expect(current.length + archivedHistory.length, greaterThan(1));
  });

  test(
      'counterexample: archived recurring budget has one aggregate, not prior period history',
      () async {
    final archivedRecurring = makeBudget(
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 31),
      recurrence: BudgetRecurrence.monthly,
      archived: true,
    );
    await isar.writeTxn(() => isar.budgets.put(archivedRecurring));

    final summaries = await budgetService.getArchivedBudgets();

    // Unfixed counterexample: archivedBudgetsProvider returns one summary per
    // budget, with whole-original-range spend and boolean wasUnderBudget; it
    // does not retain each completed recurring occurrence with dates/status.
    expect(summaries.length, greaterThan(1));
  });

  test('counterexample: January 31 monthly recurrence drifts after short month',
      () {
    final budget = makeBudget(
      start: DateTime(2024, 1, 31),
      end: DateTime(2024, 1, 31),
      recurrence: BudgetRecurrence.monthly,
    );

    final (start, end) = budget.getCurrentPeriodRange(DateTime(2024, 3, 15));

    // Unfixed counterexample: Jan 31 → Feb 29 → Mar 29 because recurrence
    // advances the already-clamped date and loses original day-31 anchor.
    expect(start, DateTime(2024, 3, 31));
    expect(end, DateTime(2024, 3, 31));
  });

  test('counterexample: non-leap January 31 recurrence also loses anchor', () {
    final budget = makeBudget(
      start: DateTime(2023, 1, 31),
      end: DateTime(2023, 1, 31),
      recurrence: BudgetRecurrence.monthly,
    );

    final (start, end) = budget.getCurrentPeriodRange(DateTime(2023, 3, 15));

    // Unfixed counterexample: expected March 31, observed March 28 after
    // Jan 31 → Feb 28 → Mar 28 drift.
    expect(start, DateTime(2023, 3, 31));
    expect(end, DateTime(2023, 3, 31));
  });

  test('exact period end is current and boundary transactions count once',
      () async {
    final start = DateTime(2024, 2, 1);
    final end = DateTime(2024, 2, 29);
    final budget = makeBudget(
      recurrence: BudgetRecurrence.none,
      start: start,
      end: end,
    );
    await isar.writeTxn(() => isar.budgets.put(budget));

    final atStart = Transaction.create(
      date: start,
      amount: 100,
      isExpense: true,
    );
    final atEnd = Transaction.create(
      date: end,
      amount: 200,
      isExpense: true,
    );
    final afterEnd = Transaction.create(
      date: end.add(const Duration(days: 1)),
      amount: 400,
      isExpense: true,
    );
    await isar.writeTxn(() async {
      await isar.transactions.put(atStart);
      await isar.transactions.put(atEnd);
      await isar.transactions.put(afterEnd);
    });

    final (currentStart, currentEnd) = budget.getCurrentPeriodRange(end);
    final spent = await BudgetSpentCalculator.calculate(
      isar,
      budget,
      currentStart,
      currentEnd,
    );

    // Baseline observation: this boundary path currently passes (300, not
    // 700). Keep it as preservation/characterization evidence beside failing
    // month-anchor tests; exact end remains part of exploration coverage.
    expect(currentStart, start);
    expect(currentEnd, end);
    expect(spent, 300);
  });
}
