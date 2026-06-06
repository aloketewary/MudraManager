import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/recap/data/monthly_recap_service.dart';

void main() {
  group('MonthlyRecapData fields', () {
    test('netSavings = income - expense', () {
      final data = _makeRecap(totalIncome: 50000, totalExpense: 35000);
      expect(data.netSavings, 15000);
    });

    test('netSavings negative when overspent', () {
      final data = _makeRecap(totalIncome: 20000, totalExpense: 30000);
      expect(data.netSavings, -10000);
    });

    test('savingsRate stored correctly', () {
      final data = _makeRecap(savingsRate: 30.0);
      expect(data.savingsRate, 30.0);
    });

    test('prevMonthIncome and prevMonthExpense stored', () {
      final data = _makeRecap(prevMonthIncome: 40000, prevMonthExpense: 25000);
      expect(data.prevMonthIncome, 40000);
      expect(data.prevMonthExpense, 25000);
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
      expect(data.netSavings, 0);
      expect(data.savingsRate, 0);
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
}) {
  return MonthlyRecapData(
    month: DateTime(2024, 6, 1),
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netSavings: totalIncome - totalExpense,
    savingsRate: savingsRate,
    avgDailySpend: avgDailySpend,
    transactionCount: 0,
    budgetDetails: [],
    topTransactions: [],
    prevMonthIncome: prevMonthIncome,
    prevMonthExpense: prevMonthExpense,
    prevSavingsRate: 0,
    financialScore: 50,
    financialScoreDelta: 0,
    insight: RecapInsight(lines: []),
    achievements: [],
    categoryChanges: [],
  );
}
