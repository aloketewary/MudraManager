import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';

void main() {
  const service = AnalyticsAggregationService();

  List<Transaction> makeTransactions({
    required DateTime start,
    int expenseCount = 5,
    int incomeCount = 1,
    double expenseAmount = 1000,
    double incomeAmount = 50000,
  }) {
    final txns = <Transaction>[];
    for (int i = 0; i < expenseCount; i++) {
      txns.add(
        Transaction.create(
          date: start.add(Duration(days: i)),
          amount: expenseAmount,
          isExpense: true,
          description: 'Expense $i',
        ),
      );
    }
    for (int i = 0; i < incomeCount; i++) {
      txns.add(
        Transaction.create(
          date: start.add(Duration(days: i)),
          amount: incomeAmount,
          isExpense: false,
          description: 'Income $i',
        ),
      );
    }
    return txns;
  }

  group('AnalyticsAggregationService.compute', () {
    test('empty transactions return zero aggregates', () {
      final result = service.compute(
        transactions: [],
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 30),
        periodType: 'Month',
      );

      expect(result.totalIncome, 0);
      expect(result.totalExpense, 0);
      expect(result.savingsRate, 0);
      expect(result.avgDailySpend, 0);
    });

    test('computes income and expense totals correctly', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);
      final txns = makeTransactions(
        start: start,
        expenseCount: 10,
        expenseAmount: 500,
        incomeCount: 1,
        incomeAmount: 30000,
      );

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.totalExpense, 5000); // 10 * 500
      expect(result.totalIncome, 30000);
    });

    test('savings rate calculated correctly', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);
      final txns = makeTransactions(
        start: start,
        expenseCount: 1,
        expenseAmount: 7000,
        incomeCount: 1,
        incomeAmount: 10000,
      );

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      // savings = (10000 - 7000) / 10000 * 100 = 30%
      expect(result.savingsRate, closeTo(30.0, 0.1));
    });

    test('savings rate is 0 when no income', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);
      final txns = makeTransactions(
        start: start,
        expenseCount: 5,
        expenseAmount: 1000,
        incomeCount: 0,
      );

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.savingsRate, 0);
    });

    test('avg daily spend calculated correctly', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30); // 30 days
      final txns = makeTransactions(
        start: start,
        expenseCount: 3,
        expenseAmount: 1000,
        incomeCount: 0,
      );

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      // 3000 / 30 days = 100/day
      expect(result.avgDailySpend, closeTo(100, 1));
    });

    test('transactions outside period are excluded', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      final txns = [
        // Inside period
        Transaction.create(
          date: DateTime(2025, 6, 15),
          amount: 1000,
          isExpense: true,
          description: 'In',
        ),
        // Outside period (before)
        Transaction.create(
          date: DateTime(2025, 5, 30),
          amount: 5000,
          isExpense: true,
          description: 'Out before',
        ),
        // Outside period (after)
        Transaction.create(
          date: DateTime(2025, 7, 1),
          amount: 5000,
          isExpense: true,
          description: 'Out after',
        ),
      ];

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.totalExpense, 1000); // only the in-period one
    });

    test('category breakdown groups correctly', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      final food1 = Transaction.create(
        date: DateTime(2025, 6, 5),
        amount: 500,
        isExpense: true,
        description: 'Food 1',
      );
      final food2 = Transaction.create(
        date: DateTime(2025, 6, 10),
        amount: 300,
        isExpense: true,
        description: 'Food 2',
      );
      final transport = Transaction.create(
        date: DateTime(2025, 6, 7),
        amount: 200,
        isExpense: true,
        description: 'Transport',
      );

      // Note: without Isar links, category.value?.name is null → 'Uncategorized'
      final result = service.compute(
        transactions: [food1, food2, transport],
        start: start,
        end: end,
        periodType: 'Month',
      );

      // All go to 'Uncategorized' since category link isn't loaded in unit test
      expect(result.categoryBreakdown['Uncategorized'], 1000);
    });

    test('daysInPeriod calculated correctly for month', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      final result = service.compute(
        transactions: [],
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.daysInPeriod, 30);
    });

    test('daysInPeriod for week', () {
      final start = DateTime(2025, 6, 9); // Monday
      final end = DateTime(2025, 6, 15); // Sunday

      final result = service.compute(
        transactions: [],
        start: start,
        end: end,
        periodType: 'Week',
      );

      expect(result.daysInPeriod, 7);
    });

    test('spending by day of week populated', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      // June 2 is Monday, June 7 is Saturday
      final txns = [
        Transaction.create(
          date: DateTime(2025, 6, 2), // Mon
          amount: 100,
          isExpense: true,
          description: 'Mon spend',
        ),
        Transaction.create(
          date: DateTime(2025, 6, 7), // Sat
          amount: 500,
          isExpense: true,
          description: 'Sat spend',
        ),
      ];

      final result = service.compute(
        transactions: txns,
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.spendingByDayOfWeek['Mon'], 100);
      expect(result.spendingByDayOfWeek['Sat'], 500);
      expect(result.spendingByDayOfWeek['Tue'], 0);
    });

    test('transfer transactions excluded via affectsStats', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      final transfer = Transaction.create(
        date: DateTime(2025, 6, 10),
        amount: 10000,
        isExpense: true,
        description: 'Transfer',
        isTransfer: true,
      );
      final regular = Transaction.create(
        date: DateTime(2025, 6, 10),
        amount: 500,
        isExpense: true,
        description: 'Regular',
      );

      final result = service.compute(
        transactions: [transfer, regular],
        start: start,
        end: end,
        periodType: 'Month',
      );

      // Transfer has affectsStats = false, so only regular counts
      expect(result.totalExpense, 500);
    });

    test('previous month comparison populated for Month periodType', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 15); // mid-month

      // Last month expense
      final lastMonthTxn = Transaction.create(
        date: DateTime(2025, 5, 10),
        amount: 2000,
        isExpense: true,
        description: 'Last month',
      );
      final thisMonthTxn = Transaction.create(
        date: DateTime(2025, 6, 5),
        amount: 1000,
        isExpense: true,
        description: 'This month',
      );

      final result = service.compute(
        transactions: [lastMonthTxn, thisMonthTxn],
        start: start,
        end: end,
        periodType: 'Month',
      );

      expect(result.previousPartialExpense, isNotNull);
      expect(result.previousPartialExpense, 2000);
    });

    test('previous month comparison null for non-Month periodType', () {
      final start = DateTime(2025, 6, 9);
      final end = DateTime(2025, 6, 15);

      final result = service.compute(
        transactions: [],
        start: start,
        end: end,
        periodType: 'Week',
      );

      expect(result.previousPartialExpense, isNull);
      expect(result.previousFullExpense, isNull);
    });
  });

  group('AdvancedAnalyticsService.calculateHealthScore', () {
    test('returns 0 score when no income', () {
      final service = AdvancedAnalyticsService();
      final score = service.calculateHealthScore([], 10000);
      expect(score.score, 0);
      expect(score.rating, 'Poor');
    });

    test('high savings rate gives high savings points', () {
      final service = AdvancedAnalyticsService();
      final now = DateTime.now();
      final txns = [
        Transaction.create(
          date: now,
          amount: 100000,
          isExpense: false,
          description: 'Salary',
        ),
        Transaction.create(
          date: now,
          amount: 30000,
          isExpense: true,
          description: 'Expenses',
        ),
      ];

      final score = service.calculateHealthScore(txns, 500000);
      // savings rate = 70%, expense ratio = 30%
      // Should get: 30 (savings) + 30 (spending) + 20 (no debt) + 20 (emergency) = 100
      expect(score.score, 100);
      expect(score.rating, 'Excellent');
    });

    test('insights are factual not advisory', () {
      final service = AdvancedAnalyticsService();
      final now = DateTime.now();
      final txns = [
        Transaction.create(
          date: now,
          amount: 10000,
          isExpense: false,
          description: 'Salary',
        ),
        Transaction.create(
          date: now,
          amount: 8000,
          isExpense: true,
          description: 'Expenses',
        ),
      ];

      final score = service.calculateHealthScore(txns, 5000);
      // Verify no motivational/advisory language
      for (final insight in score.insights) {
        expect(insight.contains('Try'), false);
        expect(insight.contains('Aim'), false);
        expect(insight.contains('Keep'), false);
        expect(insight.contains('Build'), false);
        expect(insight.contains('Start'), false);
        expect(insight.contains('Work on'), false);
      }
    });
  });
}
