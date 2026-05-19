import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

final analyticsServiceProvider =
    Provider.autoDispose<AdvancedAnalyticsService>((ref) {
  return AdvancedAnalyticsService();
});

final analyticsTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  ref.watch(transactionChangeProvider);
  final txnService = ref.watch(transactionProvider);
  return await txnService.getAllForDashBoard();
});

final predictedSpendingProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final service = ref.watch(analyticsServiceProvider);
  return service.predictMonthlySpending(transactions);
});

final financialHealthProvider =
    FutureProvider.autoDispose<FinancialHealthScore>((
  ref,
) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  ref.watch(accountChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  final totalBalance = await ref.watch(totalAccountBalanceProvider.future);
  return service.calculateHealthScore(transactions, totalBalance);
});

final categoryTrendsProvider =
    FutureProvider.autoDispose<Map<String, CategoryTrend>>((
  ref,
) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final service = ref.watch(analyticsServiceProvider);
  return service.getCategoryTrends(transactions);
});

/// Categories with rising spending trend — sorted by change percentage.
final risingCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryTrend>>((ref) async {
  final trends = await ref.watch(categoryTrendsProvider.future);
  return trends.values
      .where((t) => t.direction == TrendDirection.rising && t.thisMonth > 0)
      .toList()
    ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
});

/// Categories with anomalous spending this month.
final anomalyCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryTrend>>((ref) async {
  final trends = await ref.watch(categoryTrendsProvider.future);
  return trends.values.where((t) => t.isAnomaly).toList()
    ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
});

final spendingByDayProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final service = ref.watch(analyticsServiceProvider);
  return service.getSpendingByDayOfWeek(transactions);
});

final monthlyExpenseTrendsProvider =
    FutureProvider.autoDispose<Map<String, List<double>>>((
  ref,
) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final now = DateTime.now();

  final categoryMonthlyData = <String, List<double>>{};

  // OPTIMIZED: Single pass aggregation instead of nested loops
  for (final tx in transactions) {
    if (!tx.isExpense) continue;

    // Calculate month index (0 = 11 months ago, 11 = this month)
    final monthDiff =
        (now.year - tx.date.year) * 12 + (now.month - tx.date.month);

    if (monthDiff >= 0 && monthDiff < 12) {
      final categoryName = tx.category.value?.name ?? 'Uncategorized';
      categoryMonthlyData.putIfAbsent(
        categoryName,
        () => List<double>.filled(12, 0.0),
      );
      categoryMonthlyData[categoryName]![11 - monthDiff] += tx.effectiveAmount;
    }
  }

  return categoryMonthlyData;
});


final cashFlowForecastProvider =
    FutureProvider.autoDispose<CashFlowForecast>((ref) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final service = ref.watch(analyticsServiceProvider);
  return service.forecastCashFlow(transactions);
});

final taxEstimationServiceProvider =
    Provider.autoDispose<TaxEstimationService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TaxEstimationService(isarService);
});

final taxEstimationProvider =
    FutureProvider.autoDispose<TaxEstimate>((ref) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(taxEstimationServiceProvider);
  return await service.estimateForFY(TaxEstimationService.currentFYStartYear());
});
