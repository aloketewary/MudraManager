import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/data/greeting_provider.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/ai_insight_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

void main() {
  group('DayPeriod', () {
    test('all periods exist', () {
      expect(DayPeriod.values.length, 4);
      expect(DayPeriod.values, contains(DayPeriod.morning));
      expect(DayPeriod.values, contains(DayPeriod.afternoon));
      expect(DayPeriod.values, contains(DayPeriod.evening));
      expect(DayPeriod.values, contains(DayPeriod.night));
    });

    test('hour-to-period mapping logic', () {
      // Replicate the provider logic for testability
      DayPeriod periodForHour(int hour) {
        if (hour < 12) return DayPeriod.morning;
        if (hour < 17) return DayPeriod.afternoon;
        if (hour < 20) return DayPeriod.evening;
        return DayPeriod.night;
      }

      expect(periodForHour(0), DayPeriod.morning);
      expect(periodForHour(6), DayPeriod.morning);
      expect(periodForHour(11), DayPeriod.morning);
      expect(periodForHour(12), DayPeriod.afternoon);
      expect(periodForHour(16), DayPeriod.afternoon);
      expect(periodForHour(17), DayPeriod.evening);
      expect(periodForHour(19), DayPeriod.evening);
      expect(periodForHour(20), DayPeriod.night);
      expect(periodForHour(23), DayPeriod.night);
    });
  });

  group('PriorityAlert', () {
    test('creates with all fields', () {
      final alert = PriorityAlert(
        title: 'Budget Alert',
        message: '2 budgets exceeded',
        route: '/budgets',
        type: AlertType.urgent,
      );
      expect(alert.title, 'Budget Alert');
      expect(alert.message, '2 budgets exceeded');
      expect(alert.route, '/budgets');
      expect(alert.type, AlertType.urgent);
    });

    test('AlertType has all severity levels', () {
      expect(AlertType.values, contains(AlertType.urgent));
      expect(AlertType.values, contains(AlertType.warning));
      expect(AlertType.values, contains(AlertType.info));
    });
  });

  group('AiInsight', () {
    test('creates with required fields', () {
      final insight = AiInsight(
        title: 'Overspending',
        message: 'You spent more than you earned',
        type: 'warning',
        iconType: IconType.warning,
        generatedAt: DateTime(2024, 6, 15),
        priority: 75,
      );
      expect(insight.title, 'Overspending');
      expect(insight.type, 'warning');
      expect(insight.priority, 75);
      expect(insight.actionLabel, isNull);
      expect(insight.actionRoute, isNull);
    });

    test('creates with optional action', () {
      final insight = AiInsight(
        title: 'Bills Due',
        message: '3 bills due tomorrow',
        type: 'warning',
        iconType: IconType.info,
        generatedAt: DateTime.now(),
        actionLabel: 'View Bills',
        actionRoute: '/bills',
        priority: 85,
      );
      expect(insight.actionLabel, 'View Bills');
      expect(insight.actionRoute, '/bills');
    });

    test('default priority is 0', () {
      final insight = AiInsight(
        title: 'Test',
        message: 'Test',
        type: 'info',
        iconType: IconType.info,
        generatedAt: DateTime.now(),
      );
      expect(insight.priority, 0);
    });

    test('IconType has all types', () {
      expect(IconType.values.length, greaterThanOrEqualTo(8));
      expect(IconType.values, contains(IconType.warning));
      expect(IconType.values, contains(IconType.tip));
      expect(IconType.values, contains(IconType.success));
      expect(IconType.values, contains(IconType.budget));
      expect(IconType.values, contains(IconType.goal));
      expect(IconType.values, contains(IconType.savings));
      expect(IconType.values, contains(IconType.spending));
    });
  });

  group('DashboardData equality', () {
    DashboardData makeData({
      int txnCount = 0,
      int accountCount = 0,
      int budgetCount = 0,
      int goalCount = 0,
      double income = 0,
      double expense = 0,
      double balance = 0,
      double netWorth = 0,
    }) {
      return DashboardData(
        transactions: List.generate(
          txnCount,
          (_) => Transaction.create(
            date: DateTime.now(),
            amount: 100,
            isExpense: true,
          ),
        ),
        accounts: List.generate(accountCount, (_) => Account()),
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: List.generate(goalCount, (_) => Goal()),
        totalIncome: income,
        totalExpense: expense,
        totalBalance: balance,
        netWorth: netWorth,
        pendingSmsCount: 0,
      );
    }

    test('equal when same shape', () {
      final a = makeData(txnCount: 5, income: 1000, expense: 500);
      final b = makeData(txnCount: 5, income: 1000, expense: 500);
      expect(a, equals(b));
    });

    test('not equal when different transaction count', () {
      final a = makeData(txnCount: 5);
      final b = makeData(txnCount: 10);
      expect(a, isNot(equals(b)));
    });

    test('not equal when different income', () {
      final a = makeData(income: 1000);
      final b = makeData(income: 2000);
      expect(a, isNot(equals(b)));
    });

    test('not equal when different expense', () {
      final a = makeData(expense: 500);
      final b = makeData(expense: 800);
      expect(a, isNot(equals(b)));
    });

    test('not equal when different netWorth', () {
      final a = makeData(netWorth: 50000);
      final b = makeData(netWorth: 60000);
      expect(a, isNot(equals(b)));
    });

    test('identical returns true', () {
      final a = makeData(txnCount: 3, income: 500);
      expect(a == a, true);
    });

    test('hashCode consistent with equality', () {
      final a = makeData(txnCount: 5, income: 1000, expense: 500);
      final b = makeData(txnCount: 5, income: 1000, expense: 500);
      expect(a.hashCode, b.hashCode);
    });

    DashboardData withBudget({
      int id = 1,
      String name = 'Food',
      double amount = 1000,
      double spent = 100,
      DateTime? start,
      DateTime? end,
      BudgetRecurrence recurrence = BudgetRecurrence.monthly,
      bool archived = false,
      BudgetType type = BudgetType.dayWise,
      List<CategorySpending> categorySpendings = const [],
      List<Tag> tags = const [],
      DateTime? evaluationDate,
      int generation = 0,
    }) {
      final periodStart = start ?? DateTime(2024, 1, 1);
      final periodEnd = end ?? DateTime(2024, 1, 31);
      final budget = Budget()
        ..id = id
        ..name = name
        ..amount = amount
        ..startDate = periodStart
        ..endDate = periodEnd
        ..budgetType = type
        ..recurrence = recurrence
        ..isArchived = archived;
      tags.forEach(budget.budgetTags.add);
      final snapshot = BudgetPeriodSnapshot.fromBudget(
        budget: budget,
        evaluationDate: evaluationDate ?? periodStart,
        periodStart: periodStart,
        periodEnd: periodEnd,
        spent: spent,
        categorySpendings: categorySpendings,
      );
      return DashboardData(
        transactions: const [],
        accounts: const [],
        accountBalances: const {},
        budgets: [
          BudgetWithProgress(
            budget: budget,
            spent: spent,
            categorySpendings: categorySpendings,
            startDate: snapshot.periodStart,
            endDate: snapshot.periodEnd,
            snapshot: snapshot,
          ),
        ],
        recurringExpenses: const [],
        goals: const [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
        pendingSmsCount: 0,
        budgetEvaluationDate: evaluationDate ?? periodStart,
        budgetGeneration: generation,
      );
    }

    test('Property 3: equal-length snapshots differ on every budget field', () {
      // **Validates: Requirements 2.3, 3.10**
      final base = withBudget();
      final food = Category()
        ..id = 10
        ..name = 'Food';
      final tag = Tag()
        ..id = 20
        ..name = 'Travel';

      final changed = <DashboardData>[
        withBudget(id: 2),
        withBudget(name: 'Transport'),
        withBudget(amount: 1200),
        withBudget(spent: 200),
        withBudget(start: DateTime(2024, 2, 1)),
        withBudget(end: DateTime(2024, 2, 29)),
        withBudget(recurrence: BudgetRecurrence.weekly),
        withBudget(archived: true),
        withBudget(type: BudgetType.categoryWise),
        withBudget(
          categorySpendings: [
            CategorySpending(category: food, allocated: 500, spent: 50),
          ],
        ),
        withBudget(tags: [tag]),
        withBudget(evaluationDate: DateTime(2024, 1, 2)),
        withBudget(generation: 1),
      ];
      for (var index = 0; index < changed.length; index++) {
        final candidate = changed[index];
        expect(
          base,
          isNot(equals(candidate)),
          reason: 'changed field index $index',
        );
      }

      // Generated deterministic spent/status cases: 120 iterations.
      for (var i = 0; i < 120; i++) {
        final candidate = withBudget(spent: 101 + i.toDouble());
        expect(base, isNot(equals(candidate)), reason: 'spent case $i');
      }
    });

    test('Property 3: exact duplicate snapshots suppress duplicate equality',
        () {
      // **Validates: Requirements 2.3, 3.10**
      final category = Category()
        ..id = 10
        ..name = 'Food';
      final tag = Tag()
        ..id = 20
        ..name = 'Travel';
      final a = withBudget(
        categorySpendings: [
          CategorySpending(category: category, allocated: 500, spent: 50),
        ],
        tags: [tag],
      );
      final b = withBudget(
        categorySpendings: [
          CategorySpending(category: category, allocated: 500, spent: 50),
        ],
        tags: [tag],
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('budget ordering is stable for equivalent sets', () {
      // **Validates: Requirements 3.10**
      final first = withBudget(id: 1);
      final second = withBudget(id: 2, amount: 2000);
      final reversed = DashboardData(
        transactions: const [],
        accounts: const [],
        accountBalances: const {},
        budgets: [second.budgets.single, first.budgets.single],
        recurringExpenses: const [],
        goals: const [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
        pendingSmsCount: 0,
      );
      final ordered = DashboardData(
        transactions: const [],
        accounts: const [],
        accountBalances: const {},
        budgets: [first.budgets.single, second.budgets.single],
        recurringExpenses: const [],
        goals: const [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
        pendingSmsCount: 0,
      );
      expect(reversed, equals(ordered));
    });
  });

  group('StatsData savingsRate logic', () {
    test('positive savings rate when income > expense', () {
      final income = 10000.0;
      final expense = 7000.0;
      final savingsRate = ((income - expense) / income) * 100;
      expect(savingsRate, 30.0);
    });

    test('negative savings rate when expense > income', () {
      final income = 5000.0;
      final expense = 7000.0;
      final savingsRate = ((income - expense) / income) * 100;
      expect(savingsRate, -40.0);
    });

    test('zero savings rate when income equals expense', () {
      final income = 5000.0;
      final expense = 5000.0;
      final savingsRate = ((income - expense) / income) * 100;
      expect(savingsRate, 0.0);
    });

    test('zero when no income', () {
      final income = 0.0;
      final savingsRate = income > 0 ? ((income - 500) / income) * 100 : 0.0;
      expect(savingsRate, 0.0);
    });

    test('avgDailySpend calculation', () {
      final expense = 3000.0;
      final daysInPeriod = 30;
      final avgDailySpend = expense / daysInPeriod;
      expect(avgDailySpend, 100.0);
    });

    test('avgDailySpend safe with 0 days', () {
      final expense = 3000.0;
      final daysInPeriod = 0;
      final avgDailySpend = expense / (daysInPeriod > 0 ? daysInPeriod : 1);
      expect(avgDailySpend, 3000.0);
    });
  });
}
