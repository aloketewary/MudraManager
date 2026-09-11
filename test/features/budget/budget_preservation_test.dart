import 'dart:io';

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
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late BudgetService budgetService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('budget_preservation_');
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
      AppLog(getLogger(), 'BudgetPreservationTest'),
      null,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<Category> seedCategory(
    String name, {
    Category? parent,
  }) async {
    final category = Category()
      ..name = name
      ..iconName = 'circle'
      ..categoryType = CategoryType.expense;
    if (parent != null) category.parentCategory.value = parent;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
      if (parent != null) await category.parentCategory.save();
    });
    return category;
  }

  Future<Tag> seedTag(String name) async {
    final tag = Tag()..name = name;
    await isar.writeTxn(() => isar.tags.put(tag));
    return tag;
  }

  Future<Transaction> seedTransaction({
    required DateTime date,
    required double amount,
    bool isExpense = true,
    bool isTransfer = false,
    bool isSettlement = false,
    double? convertedAmount,
    double? myShare,
    Category? category,
    List<Tag> tags = const [],
  }) async {
    final transaction = Transaction.create(
      date: date,
      amount: amount,
      isExpense: isExpense,
      isTransfer: isTransfer,
      convertedAmount: convertedAmount,
    )
      ..isSettlement = isSettlement
      ..myShare = myShare;
    if (category != null) transaction.category.value = category;
    transaction.tags.addAll(tags);
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
      if (category != null) await transaction.category.save();
      if (tags.isNotEmpty) await transaction.tags.save();
    });
    return transaction;
  }

  Budget makeBudget({
    BudgetType type = BudgetType.dayWise,
    double amount = 1000,
    DateTime? start,
    DateTime? end,
    BudgetRecurrence recurrence = BudgetRecurrence.none,
  }) {
    return Budget()
      ..name = 'Preservation budget'
      ..amount = amount
      ..startDate = start ?? DateTime(2024, 3, 1)
      ..endDate = end ?? DateTime(2024, 3, 31)
      ..budgetType = type
      ..recurrence = recurrence;
  }

  group('Property 2: eligible-spend preservation', () {
    test(
        'generated transaction cases preserve expense exclusions and base rules',
        () async {
      final budget = makeBudget(
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );
      await isar.writeTxn(() => isar.budgets.put(budget));

      // NOT C(X): only ordinary in-range expense contributes to spend.
      final cases = <({
        double amount,
        bool expense,
        bool transfer,
        bool settlement,
        DateTime date,
        double? converted,
        double? share
      })>[
        (
          amount: 100,
          expense: true,
          transfer: false,
          settlement: false,
          date: DateTime(2024, 3, 10),
          converted: null,
          share: null,
        ),
        (
          amount: 200,
          expense: true,
          transfer: true,
          settlement: false,
          date: DateTime(2024, 3, 10),
          converted: null,
          share: null,
        ),
        (
          amount: 300,
          expense: true,
          transfer: false,
          settlement: true,
          date: DateTime(2024, 3, 10),
          converted: null,
          share: null,
        ),
        (
          amount: 400,
          expense: false,
          transfer: false,
          settlement: false,
          date: DateTime(2024, 3, 10),
          converted: null,
          share: null,
        ),
        (
          amount: 500,
          expense: true,
          transfer: false,
          settlement: false,
          date: DateTime(2024, 4, 1),
          converted: null,
          share: null,
        ),
        (
          amount: 90,
          expense: true,
          transfer: false,
          settlement: false,
          date: DateTime(2024, 3, 11),
          converted: 120,
          share: 50,
        ),
      ];
      for (final item in cases) {
        await seedTransaction(
          date: item.date,
          amount: item.amount,
          isExpense: item.expense,
          isTransfer: item.transfer,
          isSettlement: item.settlement,
          convertedAmount: item.converted,
          myShare: item.share,
        );
      }

      final spent = await budgetService.calculateSpentAmount(
        budget,
        start: DateTime(2024, 3, 1),
        end: DateTime(2024, 3, 31),
      );

      // Ordinary 100 + shared expense's effective personal share 50.
      expect(spent, 150);
    });

    test('category and parent-category scopes remain selective', () async {
      final parent = await seedCategory('Food');
      final child = await seedCategory('Groceries', parent: parent);
      final other = await seedCategory('Transport');
      await seedTransaction(
        date: DateTime(2024, 3, 5),
        amount: 100,
        category: child,
      );
      await seedTransaction(
        date: DateTime(2024, 3, 6),
        amount: 200,
        category: other,
      );

      final budget = makeBudget(type: BudgetType.categoryWise)
        ..categories.add(parent);
      await isar.writeTxn(() async {
        await isar.budgets.put(budget);
        await budget.categories.save();
      });

      final spent = await BudgetSpentCalculator.calculate(
        isar,
        budget,
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(spent, 100);
    });

    test('tag scope counts matching transaction once', () async {
      final vacation = await seedTag('Vacation');
      final work = await seedTag('Work');
      await seedTransaction(
        date: DateTime(2024, 3, 5),
        amount: 100,
        tags: [vacation, work],
      );
      await seedTransaction(
        date: DateTime(2024, 3, 6),
        amount: 200,
        tags: [work],
      );

      final budget = makeBudget(type: BudgetType.tagWise)
        ..budgetTags.add(vacation);
      await isar.writeTxn(() async {
        await isar.budgets.put(budget);
        await budget.budgetTags.save();
      });

      final spent = await BudgetSpentCalculator.calculate(
        isar,
        budget,
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(spent, 100);
    });
  });

  group('Property 2: valid periods and derived state', () {
    test('valid recurrence cases keep current date inside one period', () {
      final cases = <(BudgetRecurrence, DateTime, DateTime, DateTime)>[
        (
          BudgetRecurrence.none,
          DateTime(2024, 3, 1),
          DateTime(2024, 3, 31),
          DateTime(2024, 3, 15),
        ),
        (
          BudgetRecurrence.daily,
          DateTime(2024, 3, 10),
          DateTime(2024, 3, 10),
          DateTime(2024, 3, 10),
        ),
        (
          BudgetRecurrence.weekly,
          DateTime(2024, 3, 4),
          DateTime(2024, 3, 10),
          DateTime(2024, 3, 7),
        ),
        (
          BudgetRecurrence.monthly,
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
          DateTime(2024, 3, 15),
        ),
        (
          BudgetRecurrence.yearly,
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
          DateTime(2025, 6, 15),
        ),
      ];

      for (final (recurrence, start, end, now) in cases) {
        final budget = makeBudget(
          recurrence: recurrence,
          start: start,
          end: end,
        );
        final (periodStart, periodEnd) = budget.getCurrentPeriodRange(now);
        expect(
          !now.isBefore(periodStart) && !now.isAfter(periodEnd),
          isTrue,
          reason: '$recurrence: $periodStart..$periodEnd for $now',
        );
        expect(
            periodEnd.difference(periodStart).inDays, greaterThanOrEqualTo(0));
      }
    });

    test('remaining, over-limit, pace, forecast, urgency stay deterministic',
        () {
      final cases = <({
        double spent,
        double remaining,
        bool breached,
        BudgetState state
      })>[
        (spent: 500, remaining: 500, breached: false, state: BudgetState.ok),
        (spent: 1000, remaining: 0, breached: false, state: BudgetState.warn),
        (
          spent: 1200,
          remaining: -200,
          breached: true,
          state: BudgetState.breach
        ),
      ];
      for (final item in cases) {
        final snapshot = BudgetStateMachine.computeSnapshot(
          BudgetConstraintInput(
            budgetId: 1,
            budgetName: 'Preservation',
            budgetAmount: 1000,
            totalSpent: item.spent,
            spentInLast7Days: item.spent,
            daysPassed: 10,
            daysLeft: 20,
            totalDays: 30,
          ),
        );
        expect(snapshot.remaining, item.remaining);
        expect(snapshot.isBreached, item.breached);
        expect(snapshot.state, item.state);
        expect(snapshot.percentage, item.spent / 1000);
        expect(snapshot.currentDailySpend, item.spent / 7);
        expect(snapshot.allowedDailySpend, 1000 / 30);
        expect(snapshot.daysLeft, 20);
        expect(snapshot.daysPassed, 10);
        expect(snapshot.totalDays, 30);
        expect(snapshot.urgency, isNotNull);
      }

      final forecast = BudgetStateMachine.computeSnapshot(
        const BudgetConstraintInput(
          budgetId: 2,
          budgetName: 'Forecast',
          budgetAmount: 1000,
          totalSpent: 500,
          spentInLast7Days: 420,
          daysPassed: 10,
          daysLeft: 10,
          totalDays: 20,
        ),
      );
      expect(forecast.isForecastVisible, isTrue);
      expect(forecast.daysUntilLimit, 9);
      expect(forecast.recoverySignal, isNotNull);
    });
  });

  group('Property 2: persistence and safe empty/history behavior', () {
    test('save, edit, archive, and delete preserve service contract', () async {
      final budget = makeBudget(amount: 1000);
      await budgetService.save(budget);
      expect(budget.id, isNot(equals(Isar.autoIncrement)));

      final saved = await budgetService.getBudget(budget.id);
      expect(saved?.amount, 1000);
      expect(saved?.isArchived, isFalse);

      budget.amount = 1500;
      await budgetService.save(budget);
      expect((await budgetService.getBudget(budget.id))?.amount, 1500);

      await budgetService.archiveBudget(budget.id);
      expect((await budgetService.getBudget(budget.id))?.isArchived, isTrue);
      final archived = await budgetService.getArchivedBudgets();
      expect(archived, hasLength(1));
      expect(archived.single.status, BudgetPeriodStatus.met);

      await budgetService.deleteBudget(budget.id);
      expect(await budgetService.getBudget(budget.id), isNull);
      expect(await budgetService.getArchivedBudgets(), isEmpty);
    });

    test('empty current and history results stay empty, not stale', () async {
      expect(await budgetService.getBudgetsWithProgress(), isEmpty);
      expect(await budgetService.getArchivedBudgets(), isEmpty);
    });
  });

  group('Property 2: dashboard preservation', () {
    DashboardData makeDashboard({
      double income = 1000,
      double expense = 400,
      double balance = 600,
      double netWorth = 600,
      int pendingSms = 0,
    }) {
      return DashboardData(
        transactions: const [],
        accounts: const [],
        accountBalances: const {},
        budgets: const [],
        recurringExpenses: const [],
        goals: const [],
        totalIncome: income,
        totalExpense: expense,
        totalBalance: balance,
        netWorth: netWorth,
        pendingSmsCount: pendingSms,
      );
    }

    test('identical refresh snapshots suppress duplicate publication', () {
      final first = makeDashboard();
      final repeated = makeDashboard();
      expect(first == repeated, isTrue);
      expect(first.hashCode, repeated.hashCode);
    });

    test('non-budget dashboard totals remain render-relevant', () {
      final first = makeDashboard();
      expect(first, isNot(equals(makeDashboard(income: 1200))));
      expect(first, isNot(equals(makeDashboard(expense: 500))));
      expect(first, isNot(equals(makeDashboard(balance: 700))));
      expect(first, isNot(equals(makeDashboard(netWorth: 700))));
      expect(first, isNot(equals(makeDashboard(pendingSms: 1))));
    });
  });
}
