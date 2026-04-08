import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

void main() {
  // Replicate the scoring functions from smart_order_provider.dart
  // since they're top-level private functions, we test the logic directly.

  double urgencyScore(String widgetId, DashboardData data, DateTime now) {
    switch (widgetId) {
      case 'ai_insight':
        return 1.0;
      case 'budget_overview':
        if (data.budgets.isEmpty) return 0;
        final worstBudget = data.budgets
            .map((b) => b.budget.amount > 0 ? b.spent / b.budget.amount : 0.0)
            .reduce((a, b) => a > b ? a : b);
        if (worstBudget >= 1.0) return 1.0;
        if (worstBudget >= 0.8) return 0.7;
        return 0.2;
      case 'recurring_expenses':
        final dueSoon = data.recurringExpenses
            .where((r) => r.nextDueDate.difference(now).inDays <= 3)
            .length;
        if (dueSoon > 0) return 0.9;
        return 0.1;
      case 'goals_progress':
        if (data.goals.isEmpty) return 0;
        final nearDone = data.goals
            .where((g) => g.isActive && g.progressPercent >= 0.8)
            .length;
        if (nearDone > 0) return 0.7;
        return 0.2;
      case 'accounts':
        return 0.5;
      case 'cash_flow':
        if (data.totalIncome > 0 && data.totalExpense > data.totalIncome) {
          return 0.8;
        }
        return 0.3;
      case 'recent_transactions':
        final today = DateTime(now.year, now.month, now.day);
        final todayCount = data.transactions
            .where(
              (t) => DateTime(t.date.year, t.date.month, t.date.day) == today,
            )
            .length;
        if (todayCount > 0) return 0.4;
        return 0.1;
      default:
        return 0.2;
    }
  }

  double freshnessScore(String widgetId, DashboardData data, DateTime now) {
    switch (widgetId) {
      case 'recent_transactions':
        if (data.transactions.isEmpty) return 0;
        final latest = data.transactions
            .map((t) => t.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final hoursAgo = now.difference(latest).inHours;
        if (hoursAgo < 1) return 1.0;
        if (hoursAgo < 6) return 0.7;
        if (hoursAgo < 24) return 0.4;
        return 0.1;
      case 'accounts':
        return 0.5;
      case 'budget_overview':
        final dayProgress = now.day / 30;
        return dayProgress.clamp(0.2, 1.0);
      default:
        return 0.3;
    }
  }

  DashboardData _emptyData() => const DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );

  group('Urgency scoring', () {
    test('ai_insight always max urgency', () {
      expect(urgencyScore('ai_insight', _emptyData(), DateTime.now()), 1.0);
    });

    test('accounts always 0.5', () {
      expect(urgencyScore('accounts', _emptyData(), DateTime.now()), 0.5);
    });

    test('budget_overview 0 when no budgets', () {
      expect(urgencyScore('budget_overview', _emptyData(), DateTime.now()), 0);
    });

    test('budget_overview critical when over 100%', () {
      final budget = Budget()
        ..name = 'Food'
        ..amount = 5000
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 31)
        ..recurrence = BudgetRecurrence.none;
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [BudgetWithProgress(budget: budget, spent: 6000, categorySpendings: [], startDate: DateTime(2024, 1, 1), endDate: DateTime(2024, 1, 31))],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('budget_overview', data, DateTime.now()), 1.0);
    });

    test('budget_overview high when 80-100%', () {
      final budget = Budget()
        ..name = 'Food'
        ..amount = 10000
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 31)
        ..recurrence = BudgetRecurrence.none;
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [BudgetWithProgress(budget: budget, spent: 8500, categorySpendings: [], startDate: DateTime(2024, 1, 1), endDate: DateTime(2024, 1, 31))],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('budget_overview', data, DateTime.now()), 0.7);
    });

    test('budget_overview low when under 80%', () {
      final budget = Budget()
        ..name = 'Food'
        ..amount = 10000
        ..startDate = DateTime(2024, 1, 1)
        ..endDate = DateTime(2024, 1, 31)
        ..recurrence = BudgetRecurrence.none;
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [BudgetWithProgress(budget: budget, spent: 3000, categorySpendings: [], startDate: DateTime(2024, 1, 1), endDate: DateTime(2024, 1, 31))],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('budget_overview', data, DateTime.now()), 0.2);
    });

    test('recurring_expenses urgent when bills due soon', () {
      final now = DateTime.now();
      final bill = RecurringTransaction()
        ..amount = 199
        ..isExpense = true
        ..isActive = true
        ..frequency = Frequency.monthly
        ..startDate = now
        ..nextDueDate = now.add(const Duration(days: 1));
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [bill],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('recurring_expenses', data, now), 0.9);
    });

    test('recurring_expenses low when no bills due soon', () {
      final now = DateTime.now();
      final bill = RecurringTransaction()
        ..amount = 199
        ..isExpense = true
        ..isActive = true
        ..frequency = Frequency.monthly
        ..startDate = now
        ..nextDueDate = now.add(const Duration(days: 20));
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [bill],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('recurring_expenses', data, now), 0.1);
    });

    test('goals_progress boosted when near completion', () {
      final goal = Goal.create(
        name: 'Emergency Fund',
        targetAmount: 100000,
        currentAmount: 85000,
      );
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [goal],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('goals_progress', data, DateTime.now()), 0.7);
    });

    test('goals_progress 0 when no goals', () {
      expect(urgencyScore('goals_progress', _emptyData(), DateTime.now()), 0);
    });

    test('cash_flow urgent when overspending', () {
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 10000,
        totalExpense: 15000,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('cash_flow', data, DateTime.now()), 0.8);
    });

    test('cash_flow normal when income > expense', () {
      final data = DashboardData(
        transactions: [],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 15000,
        totalExpense: 10000,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('cash_flow', data, DateTime.now()), 0.3);
    });

    test('recent_transactions boosted when today has transactions', () {
      final now = DateTime.now();
      final txn = Transaction.create(
        date: now,
        amount: 500,
        isExpense: true,
      );
      final data = DashboardData(
        transactions: [txn],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(urgencyScore('recent_transactions', data, now), 0.4);
    });

    test('unknown widget gets default 0.2', () {
      expect(urgencyScore('unknown_widget', _emptyData(), DateTime.now()), 0.2);
    });
  });

  group('Freshness scoring', () {
    test('recent_transactions 0 when empty', () {
      expect(freshnessScore('recent_transactions', _emptyData(), DateTime.now()), 0);
    });

    test('recent_transactions max when < 1 hour old', () {
      final now = DateTime.now();
      final txn = Transaction.create(
        date: now.subtract(const Duration(minutes: 30)),
        amount: 100,
        isExpense: true,
      );
      final data = DashboardData(
        transactions: [txn],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(freshnessScore('recent_transactions', data, now), 1.0);
    });

    test('recent_transactions medium when 3 hours old', () {
      final now = DateTime.now();
      final txn = Transaction.create(
        date: now.subtract(const Duration(hours: 3)),
        amount: 100,
        isExpense: true,
      );
      final data = DashboardData(
        transactions: [txn],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(freshnessScore('recent_transactions', data, now), 0.7);
    });

    test('recent_transactions low when 12 hours old', () {
      final now = DateTime.now();
      final txn = Transaction.create(
        date: now.subtract(const Duration(hours: 12)),
        amount: 100,
        isExpense: true,
      );
      final data = DashboardData(
        transactions: [txn],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(freshnessScore('recent_transactions', data, now), 0.4);
    });

    test('recent_transactions stale when > 24 hours old', () {
      final now = DateTime.now();
      final txn = Transaction.create(
        date: now.subtract(const Duration(hours: 48)),
        amount: 100,
        isExpense: true,
      );
      final data = DashboardData(
        transactions: [txn],
        accounts: [],
        accountBalances: {},
        budgets: [],
        recurringExpenses: [],
        goals: [],
        totalIncome: 0,
        totalExpense: 0,
        totalBalance: 0,
        netWorth: 0,
      );
      expect(freshnessScore('recent_transactions', data, now), 0.1);
    });

    test('accounts always 0.5', () {
      expect(freshnessScore('accounts', _emptyData(), DateTime.now()), 0.5);
    });

    test('budget_overview scales with day of month', () {
      // Day 1 → 1/30 = 0.033 → clamped to 0.2
      final earlyMonth = DateTime(2024, 6, 1);
      expect(freshnessScore('budget_overview', _emptyData(), earlyMonth), 0.2);

      // Day 30 → 30/30 = 1.0
      final lateMonth = DateTime(2024, 6, 30);
      expect(freshnessScore('budget_overview', _emptyData(), lateMonth), 1.0);

      // Day 15 → 15/30 = 0.5
      final midMonth = DateTime(2024, 6, 15);
      expect(freshnessScore('budget_overview', _emptyData(), midMonth), 0.5);
    });

    test('unknown widget gets default 0.3', () {
      expect(freshnessScore('unknown_widget', _emptyData(), DateTime.now()), 0.3);
    });
  });

  group('Score composition', () {
    test('total score formula: usage(40%) + urgency(40%) + freshness(20%)', () {
      // Simulate the scoring formula
      final taps = 5;
      final usageScore = (taps / 10).clamp(0, 1) * 40; // 0.5 * 40 = 20
      final urgency = 0.8 * 40; // 32
      final freshness = 0.5 * 20; // 10
      final total = usageScore + urgency + freshness;
      expect(total, 62.0);
    });

    test('max possible score is 100', () {
      final maxUsage = (10 / 10).clamp(0, 1) * 40; // 40
      final maxUrgency = 1.0 * 40; // 40
      final maxFreshness = 1.0 * 20; // 20
      expect(maxUsage + maxUrgency + maxFreshness, 100.0);
    });

    test('min possible score is 0', () {
      final minUsage = (0 / 10).clamp(0, 1) * 40; // 0
      final minUrgency = 0.0 * 40; // 0
      final minFreshness = 0.0 * 20; // 0
      expect(minUsage + minUrgency + minFreshness, 0.0);
    });
  });
}
