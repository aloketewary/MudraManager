import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

final analyticsServiceProvider = Provider<AdvancedAnalyticsService>((ref) {
  final txnService = ref.watch(transactionProvider);
  return AdvancedAnalyticsService(txnService);
});

final predictedSpendingProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.predictMonthlySpending();
});

final financialHealthProvider = FutureProvider<FinancialHealthScore>((
  ref,
) async {
  final service = ref.watch(analyticsServiceProvider);
  final totalBalance = await ref.watch(totalAccountBalanceProvider.future);
  return await service.calculateHealthScore(totalBalance);
});

final categoryTrendsProvider = FutureProvider<Map<String, CategoryTrend>>((
  ref,
) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCategoryTrends();
});

final spendingByDayProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getSpendingByDayOfWeek();
});

final monthlyExpenseTrendsProvider = FutureProvider<Map<String, List<double>>>((
  ref,
) async {
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
        categoryMonthlyData[categoryName] = List<double>.generate(12, (_) => 0.0);
      }
      categoryMonthlyData[categoryName]![11 - i] += tx.amount;
    }
  }

  return categoryMonthlyData;
});
