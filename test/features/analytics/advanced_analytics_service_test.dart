import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/category.dart';

class FakeCategory extends Category {
  final String _name;
  FakeCategory(this._name);

  @override
  String get name => _name;
}

void main() {
  Transaction createTx({
    required DateTime date,
    required double amount,
    bool isExpense = true,
    bool isTransfer = false,
    String? categoryName,
  }) {
    final tx = Transaction.create(
      date: date,
      amount: amount,
      isExpense: isExpense,
    );
    tx.isTransfer = isTransfer;
    if (categoryName != null) {
      tx.category.value = FakeCategory(categoryName);
    }
    return tx;
  }

  group('AdvancedAnalyticsService Optimization Tests', () {
    final service = AdvancedAnalyticsService();

    test('predictMonthlySpending aggregates correctly in single pass', () {
      final now = DateTime.now();
      final txs = [
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 1000),
        createTx(date: DateTime(now.year, now.month - 1, 15), amount: 500),
        createTx(date: DateTime(now.year, now.month - 2, 5), amount: 2000),
        createTx(date: DateTime(now.year, now.month - 4, 5), amount: 5000),
        createTx(date: now, amount: 800),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 1000, isExpense: false),
      ];

      final prediction = service.predictMonthlySpending(txs);

      // (1500 + 2000) / 2 = 1750
      expect(prediction, 1750.0);
    });

    test('forecastCashFlow aggregates correctly in single pass', () {
      final now = DateTime.now();
      final txs = [
        createTx(date: now, amount: 2000, isExpense: false),
        createTx(date: now, amount: 1000, isExpense: true),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 5000, isExpense: false),
        createTx(date: DateTime(now.year, now.month - 1, 15), amount: 3000, isExpense: true),
        createTx(date: DateTime(now.year, now.month - 2, 5), amount: 4000, isExpense: false),
        createTx(date: DateTime(now.year, now.month - 2, 10), amount: 2000, isExpense: true),
      ];

      final forecast = service.forecastCashFlow(txs);

      expect(forecast.currentMonthIncome, 2000.0);
      expect(forecast.currentMonthExpense, 1000.0);
      expect(forecast.incomeHistory[0], 5000.0);
      expect(forecast.incomeHistory[1], 4000.0);
      expect(forecast.expenseHistory[0], 3000.0);
      expect(forecast.expenseHistory[1], 2000.0);
    });

    test('getCategoryTrends aggregates correctly in single pass', () {
      final now = DateTime.now();
      final txs = [
        createTx(date: now, amount: 100, categoryName: 'Food'),
        createTx(date: now, amount: 200, categoryName: 'Food'),
        createTx(date: now, amount: 50, categoryName: 'Transport'),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 300, categoryName: 'Food'),
      ];

      final trends = service.getCategoryTrends(txs);

      expect(trends['Food']?.thisMonth, 300.0);
      expect(trends['Food']?.lastMonth, 300.0);
      expect(trends['Transport']?.thisMonth, 50.0);
      expect(trends['Transport']?.lastMonth, 0.0);
    });

    test('calculateHealthScore aggregates correctly in single pass', () {
      final now = DateTime.now();
      final txs = [
        createTx(date: now, amount: 10000, isExpense: false),
        createTx(date: now, amount: 4000, isExpense: true),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 5000, isExpense: true),
      ];

      final health = service.calculateHealthScore(txs, 20000);

      expect(health.savingsRate, 60.0);
      expect(health.expenseRatio, 40.0);
    });

    group('Regression Checks', () {
      test('forecastCashFlow handles transfer exclusion', () {
        final now = DateTime.now();
        final txs = [
          createTx(date: now, amount: 1000, isTransfer: true),
          createTx(date: now, amount: 500, isExpense: false),
        ];

        final forecast = service.forecastCashFlow(txs);

        expect(forecast.currentMonthIncome, 500.0);
        expect(forecast.currentMonthExpense, 0.0);
      });
    });
  });
}
