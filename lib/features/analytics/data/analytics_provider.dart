import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

final analyticsServiceProvider =
    Provider.autoDispose<AdvancedAnalyticsService>((ref) {
  final txnService = ref.watch(transactionProvider);
  return AdvancedAnalyticsService(txnService);
});

final predictedSpendingProvider =
    FutureProvider.autoDispose<double>((ref) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  return await service.predictMonthlySpending();
});

final financialHealthProvider =
    FutureProvider.autoDispose<FinancialHealthScore>((
  ref,
) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  final totalBalance = await ref.watch(totalAccountBalanceProvider.future);
  return await service.calculateHealthScore(totalBalance);
});

final categoryTrendsProvider =
    FutureProvider.autoDispose<Map<String, CategoryTrend>>((
  ref,
) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCategoryTrends();
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
  ref.watch(transactionChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  return await service.getSpendingByDayOfWeek();
});

final monthlyExpenseTrendsProvider =
    FutureProvider.autoDispose<Map<String, List<double>>>((
  ref,
) async {
  ref.watch(transactionChangeProvider);
  final transactionService = ref.watch(transactionProvider);
  final transactions = await transactionService.getAllForDashBoard();
  final now = DateTime.now();

  final categoryMonthlyData = <String, List<double>>{};

  for (int i = 11; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    final monthTxns = transactions.where(
      (tx) =>
          tx.isExpense &&
          tx.date.year == month.year &&
          tx.date.month == month.month,
    );

    for (var tx in monthTxns) {
      final categoryName = tx.category.value?.name ?? 'Uncategorized';
      if (!categoryMonthlyData.containsKey(categoryName)) {
        categoryMonthlyData[categoryName] =
            List<double>.generate(12, (_) => 0.0);
      }
      categoryMonthlyData[categoryName]![11 - i] += tx.effectiveAmount;
    }
  }

  return categoryMonthlyData;
});


final cashFlowForecastProvider =
    FutureProvider.autoDispose<CashFlowForecast>((ref) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(analyticsServiceProvider);
  return await service.forecastCashFlow();
});
