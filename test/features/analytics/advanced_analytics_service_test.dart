import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/category.dart';

void main() {
  late AdvancedAnalyticsService service;

  setUp(() {
    service = AdvancedAnalyticsService();
  });

  Transaction createTx({
    required DateTime date,
    required double amount,
    bool isExpense = true,
    String? categoryName,
    bool isSettlement = false,
    bool isTransfer = false,
  }) {
    final tx = Transaction.create(
      date: date,
      amount: amount,
      isExpense: isExpense,
      description: 'Test',
    );
    tx.category.value = Category()..name = categoryName ?? 'Test';
    tx.isSettlement = isSettlement;
    tx.isTransfer = isTransfer;
    return tx;
  }

  test('predictMonthlySpending calculates average of last 3 months', () async {
    final now = DateTime.now();
    final txs = [
      createTx(date: DateTime(now.year, now.month - 1, 10), amount: 1000),
      createTx(date: DateTime(now.year, now.month - 1, 20), amount: 500),
      createTx(date: DateTime(now.year, now.month - 2, 10), amount: 2000),
      createTx(date: DateTime(now.year, now.month - 4, 10), amount: 5000), // Should be ignored
    ];

    final result = await service.predictMonthlySpending(txs);
    // (1500 + 2000) / 2 = 1750
    expect(result, 1750);
  });

  test('getCategoryTrends identifies rising and falling trends', () async {
    final now = DateTime.now();
    final txs = [
      // Food: Rising (100 -> 200 -> 300)
      createTx(date: DateTime(now.year, now.month, 1), amount: 300, categoryName: 'Food'),
      createTx(date: DateTime(now.year, now.month - 1, 1), amount: 200, categoryName: 'Food'),
      createTx(date: DateTime(now.year, now.month - 2, 1), amount: 100, categoryName: 'Food'),

      // Rent: Stable (1000 -> 1000 -> 1000)
      createTx(date: DateTime(now.year, now.month, 1), amount: 1000, categoryName: 'Rent'),
      createTx(date: DateTime(now.year, now.month - 1, 1), amount: 1000, categoryName: 'Rent'),
      createTx(date: DateTime(now.year, now.month - 2, 1), amount: 1000, categoryName: 'Rent'),
    ];

    final trends = await service.getCategoryTrends(txs);

    expect(trends['Food']?.direction, TrendDirection.rising);
    expect(trends['Rent']?.direction, TrendDirection.stable);
  });

  test('calculateHealthScore returns zero for no income', () async {
    final now = DateTime.now();
    final txs = [
      createTx(date: now, amount: 1000, isExpense: true),
    ];

    final score = await service.calculateHealthScore(txs, 5000);
    expect(score.score, 0);
    expect(score.rating, 'Poor');
  });

  test('calculateHealthScore calculates correct score for good profile', () async {
    final now = DateTime.now();
    final txs = [
      createTx(date: now, amount: 10000, isExpense: false), // Income
      createTx(date: now, amount: 2000, isExpense: true),  // Expense
    ];

    // Total balance 60k (6x monthly expense)
    final score = await service.calculateHealthScore(txs, 60000);

    expect(score.score, greaterThanOrEqualTo(80));
    expect(score.rating, 'Excellent');
  });
}
