import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_service.dart';

void main() {
  group('MonthlyRecapData computed getters', () {
    test('prevMonthSavings = income - expense', () {
      final data = _makeRecap(prevMonthIncome: 50000, prevMonthExpense: 35000);
      expect(data.prevMonthSavings, 15000);
    });

    test('prevMonthSavings negative when overspent', () {
      final data = _makeRecap(prevMonthIncome: 20000, prevMonthExpense: 30000);
      expect(data.prevMonthSavings, -10000);
    });

    test('incomeChange percentage correct', () {
      final data = _makeRecap(
        totalIncome: 60000,
        prevMonthIncome: 50000,
      );
      expect(data.incomeChange, 20.0); // (60k-50k)/50k * 100
    });

    test('incomeChange 0 when no prev income', () {
      final data = _makeRecap(totalIncome: 50000, prevMonthIncome: 0);
      expect(data.incomeChange, 0);
    });

    test('expenseChange percentage correct', () {
      final data = _makeRecap(
        totalExpense: 40000,
        prevMonthExpense: 50000,
      );
      expect(data.expenseChange, -20.0); // (40k-50k)/50k * 100
    });

    test('expenseChange 0 when no prev expense', () {
      final data = _makeRecap(totalExpense: 30000, prevMonthExpense: 0);
      expect(data.expenseChange, 0);
    });
  });

  group('BudgetUtilization', () {
    test('percentage correct', () {
      final b = BudgetUtilization('Food', 10000, 7500);
      expect(b.percentage, 75.0);
    });

    test('overBudget when spent > allocated', () {
      final b = BudgetUtilization('Food', 10000, 12000);
      expect(b.overBudget, true);
      expect(b.percentage, 120.0);
    });

    test('not overBudget when under', () {
      final b = BudgetUtilization('Food', 10000, 8000);
      expect(b.overBudget, false);
    });

    test('percentage 0 when allocated is 0', () {
      final b = BudgetUtilization('Empty', 0, 500);
      expect(b.percentage, 0);
    });
  });

  group('CategorySpend', () {
    test('creates with all fields', () {
      final c = CategorySpend('Food', 5000, 25.0);
      expect(c.name, 'Food');
      expect(c.amount, 5000);
      expect(c.percentage, 25.0);
    });
  });

  group('TransactionSummary', () {
    test('creates with all fields', () {
      final t = TransactionSummary('Groceries', 'Food', 1500, DateTime(2024, 6, 15));
      expect(t.description, 'Groceries');
      expect(t.category, 'Food');
      expect(t.amount, 1500);
    });
  });

  group('Recap edge cases', () {
    test('zero everything', () {
      final data = _makeRecap();
      expect(data.prevMonthSavings, 0);
      expect(data.incomeChange, 0);
      expect(data.expenseChange, 0);
      expect(data.savingsRate, 0);
    });

    test('savings rate calculation', () {
      final data = _makeRecap(savingsRate: 30.0);
      expect(data.savingsRate, 30.0);
    });

    test('spending velocity: first half vs second half', () {
      final data = _makeRecap(firstHalfSpend: 15000, secondHalfSpend: 25000);
      expect(data.secondHalfSpend, greaterThan(data.firstHalfSpend));
    });

    test('weekday vs weekend avg', () {
      final data = _makeRecap(weekdayAvg: 800, weekendAvg: 1200);
      expect(data.weekendAvg, greaterThan(data.weekdayAvg));
    });

    test('recurring vs one-time split', () {
      final data = _makeRecap(recurringExpense: 5000, oneTimeExpense: 15000);
      final total = data.recurringExpense + data.oneTimeExpense;
      final recurPct = data.recurringExpense / total * 100;
      expect(recurPct, 25.0);
    });
  });
}

MonthlyRecapData _makeRecap({
  double totalIncome = 0,
  double totalExpense = 0,
  double savingsRate = 0,
  double avgDailySpend = 0,
  double prevMonthIncome = 0,
  double prevMonthExpense = 0,
  double weekdayAvg = 0,
  double weekendAvg = 0,
  double firstHalfSpend = 0,
  double secondHalfSpend = 0,
  double recurringExpense = 0,
  double oneTimeExpense = 0,
}) {
  return MonthlyRecapData(
    month: DateTime(2024, 6, 1),
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netSavings: totalIncome - totalExpense,
    savingsRate: savingsRate,
    avgDailySpend: avgDailySpend,
    transactionCount: 0,
    topCategories: [],
    incomeCategories: [],
    topTransactions: [],
    topIncomeTransactions: [],
    budgetsKept: 0,
    budgetsTotal: 0,
    budgetDetails: [],
    achievementsUnlocked: 0,
    currentStreak: 0,
    longestStreak: 0,
    dailySpending: {},
    weekdayAvg: weekdayAvg,
    weekendAvg: weekendAvg,
    prevMonthIncome: prevMonthIncome,
    prevMonthExpense: prevMonthExpense,
    firstHalfSpend: firstHalfSpend,
    secondHalfSpend: secondHalfSpend,
    recurringExpense: recurringExpense,
    oneTimeExpense: oneTimeExpense,
    accountBreakdown: [],
    categoryByFrequency: [],
  );
}
