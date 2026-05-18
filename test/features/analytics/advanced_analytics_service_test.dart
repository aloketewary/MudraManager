import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/transactions/data/transaction_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:logger/logger.dart';

class FakeTransactionService extends TransactionService {
  final List<Transaction> transactions;

  FakeTransactionService(this.transactions)
      : super(IsarService(), AppLog(Logger(), 'Fake'), null);

  @override
  Future<List<Transaction>> getAllForDashBoard() async {
    return transactions;
  }
}

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

  group('AdvancedAnalyticsService Optimization Tests (No Mocks)', () {
    test('predictMonthlySpending aggregates correctly in single pass', () async {
      final now = DateTime.now();
      final txs = [
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 1000),
        createTx(date: DateTime(now.year, now.month - 1, 15), amount: 500),
        createTx(date: DateTime(now.year, now.month - 2, 5), amount: 2000),
        createTx(date: DateTime(now.year, now.month - 4, 5), amount: 5000), // Should be ignored (>3 months)
        createTx(date: now, amount: 800), // Should be ignored (current month)
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 1000, isExpense: false), // Should be ignored (income)
      ];

      final service = AdvancedAnalyticsService(FakeTransactionService(txs));

      final prediction = await service.predictMonthlySpending();

      // (1500 + 2000) / 2 = 1750
      expect(prediction, 1750.0);
    });

    test('forecastCashFlow aggregates correctly in single pass', () async {
      final now = DateTime.now();
      final txs = [
        // Current month
        createTx(date: now, amount: 2000, isExpense: false),
        createTx(date: now, amount: 1000, isExpense: true),
        // Last month (1)
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 5000, isExpense: false),
        createTx(date: DateTime(now.year, now.month - 1, 15), amount: 3000, isExpense: true),
        // 2 months ago (2)
        createTx(date: DateTime(now.year, now.month - 2, 5), amount: 4000, isExpense: false),
        createTx(date: DateTime(now.year, now.month - 2, 10), amount: 2000, isExpense: true),
      ];

      final service = AdvancedAnalyticsService(FakeTransactionService(txs));

      final forecast = await service.forecastCashFlow();

      expect(forecast.currentMonthIncome, 2000.0);
      expect(forecast.currentMonthExpense, 1000.0);
      expect(forecast.incomeHistory[0], 5000.0); // 1 month ago
      expect(forecast.incomeHistory[1], 4000.0); // 2 months ago
      expect(forecast.expenseHistory[0], 3000.0);
      expect(forecast.expenseHistory[1], 2000.0);
    });

    test('getCategoryTrends aggregates correctly in single pass', () async {
      final now = DateTime.now();

      final txs = [
        createTx(date: now, amount: 100, categoryName: 'Food'),
        createTx(date: now, amount: 200, categoryName: 'Food'),
        createTx(date: now, amount: 50, categoryName: 'Transport'),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 300, categoryName: 'Food'),
      ];

      final service = AdvancedAnalyticsService(FakeTransactionService(txs));

      final trends = await service.getCategoryTrends();

      expect(trends['Food']?.thisMonth, 300.0);
      expect(trends['Food']?.lastMonth, 300.0);
      expect(trends['Transport']?.thisMonth, 50.0);
      expect(trends['Transport']?.lastMonth, 0.0);
    });

    test('calculateHealthScore aggregates correctly in single pass', () async {
      final now = DateTime.now();
      final txs = [
        createTx(date: now, amount: 10000, isExpense: false),
        createTx(date: now, amount: 4000, isExpense: true),
        createTx(date: DateTime(now.year, now.month - 1, 10), amount: 5000, isExpense: true), // Ignore
      ];

      final service = AdvancedAnalyticsService(FakeTransactionService(txs));

      final health = await service.calculateHealthScore(20000);

      expect(health.savingsRate, 60.0); // (10000-4000)/10000 * 100
      expect(health.expenseRatio, 40.0); // 4000/10000 * 100
    });

    group('Regression Checks', () {
      test('forecastCashFlow handles transfer exclusion', () async {
        final now = DateTime.now();
        final txs = [
          createTx(date: now, amount: 1000, isTransfer: true),
          createTx(date: now, amount: 500, isExpense: false),
        ];

        final service = AdvancedAnalyticsService(FakeTransactionService(txs));
        final forecast = await service.forecastCashFlow();

        expect(forecast.currentMonthIncome, 500.0);
        expect(forecast.currentMonthExpense, 0.0);
      });
    });
  });
}
