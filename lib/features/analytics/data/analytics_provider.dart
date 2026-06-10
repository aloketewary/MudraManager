import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';
import 'package:mudra_manager/features/analytics/data/tax_opportunity_service.dart';
import 'package:mudra_manager/features/analytics/data/tax_deduction_provider.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

final analyticsServiceProvider =
    Provider.autoDispose<AdvancedAnalyticsService>((ref) {
  return AdvancedAnalyticsService();
});

final analyticsAggregationServiceProvider =
    Provider.autoDispose<AnalyticsAggregationService>((ref) {
  return const AnalyticsAggregationService();
});

final analyticsTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  ref.watch(transactionChangeProvider);
  final txnService = ref.watch(transactionProvider);
  return await txnService.getAllForDashBoard();
});

/// Primary computation root for analytics.
final analyticsAggregatesProvider =
    FutureProvider.autoDispose.family<AnalyticsAggregates, String>((
  ref,
  periodKey,
) async {
  final transactions = await ref.watch(analyticsTransactionsProvider.future);
  final service = ref.watch(analyticsAggregationServiceProvider);

  final now = DateTime.now();
  DateTime start;
  DateTime end = now;

  if (periodKey.contains('_')) {
    final parts = periodKey.split('_');
    start = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0]));
    final endDate = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));
    end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  } else {
    switch (periodKey) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        start = now.subtract(const Duration(days: 6));
        break;
      case 'Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(2000);
    }
  }

  return service.compute(
    transactions: transactions,
    start: start,
    end: end,
    periodType: periodKey.contains('_') ? 'Custom' : periodKey,
  );
});

/// Fine-grained subscription for Metrics section.
final analyticsMetricsProvider =
    FutureProvider.autoDispose.family<AnalyticsAggregates, String>((
  ref,
  periodKey,
) async {
  return ref.watch(analyticsAggregatesProvider(periodKey).future);
});

/// Fine-grained subscription for Chart section.
final analyticsChartProvider =
    FutureProvider.autoDispose.family<AnalyticsAggregates, String>((
  ref,
  periodKey,
) async {
  return ref.watch(analyticsAggregatesProvider(periodKey).future);
});

/// Derived narrative facts from aggregates.
final analyticsNarrativeFactsProvider =
    FutureProvider.autoDispose.family<List<NarrativeFact>, String>((
  ref,
  periodKey,
) async {
  final aggregates =
      await ref.watch(analyticsAggregatesProvider(periodKey).future);
  final facts = <NarrativeFact>[];

  // 1. Threshold for significance (Materiality)
  const minSpendThreshold = 100.0;

  // 2. Identify top spending category
  if (aggregates.categoryBreakdown.isNotEmpty) {
    final sorted = aggregates.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value > minSpendThreshold) {
      facts.add(
        TopCategoryFact(
          category: top.key,
          percentage: (top.value / aggregates.totalExpense) * 100,
        ),
      );
    }
  }

  // 3. New / Disappeared Categories (Requires comparison month)
  if (periodKey == 'Month') {
    final trends = aggregates.monthlyExpenseTrends;
    for (final entry in trends.entries) {
      final history = entry.value;
      if (history.length >= 2) {
        final current = history.last;
        final previous = history[history.length - 2];

        if (current > minSpendThreshold && previous == 0) {
          facts.add(
            NewSpendingCategoryFact(category: entry.key, amount: current),
          );
        } else if (current == 0 && previous > minSpendThreshold) {
          facts.add(
            CategoryStoppedFact(category: entry.key, previousAmount: previous),
          );
        }
      }
    }
  }

  // 4. Identify spending patterns (days)
  final byDay = aggregates.spendingByDayOfWeek;
  const minDailySpend = 50.0;
  if (byDay.values.any((v) => v > minDailySpend)) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final peakDay =
        days.reduce((a, b) => (byDay[a] ?? 0) > (byDay[b] ?? 0) ? a : b);

    final weekdayTotal = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
        .fold(0.0, (s, d) => s + (byDay[d] ?? 0));
    final weekendTotal =
        ['Sat', 'Sun'].fold(0.0, (s, d) => s + (byDay[d] ?? 0));

    if (weekendTotal / 2 > (weekdayTotal / 5) * 1.5) {
      facts.add(WeekendPeakFact(peakDay: peakDay));
    } else if (weekdayTotal / 5 > (weekendTotal / 2) * 1.5) {
      facts.add(WeekdayPeakFact(peakDay: peakDay));
    }
  }

  // 5. Forecast (Gate: min 7 days elapsed)
  final now = DateTime.now();
  if (periodKey == 'Month' && now.day >= 7) {
    final projected =
        aggregates.avgDailySpend * DateTime(now.year, now.month + 1, 0).day;
    final previousTotal = aggregates.previousFullExpense;

    if (previousTotal != null && previousTotal > 0) {
      final variance = projected - previousTotal;
      if (variance.abs() > (previousTotal * 0.05)) {
        // Only if > 5% change
        facts.add(
          SpendingForecastFact(
            projectedAmount: projected,
            variance: variance,
            comparisonPeriod: 'last month',
          ),
        );
      }
    }
  }

  return facts;
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

final taxOpportunitiesProvider =
    FutureProvider.autoDispose<List<TaxOpportunity>>((ref) async {
  final estimate = await ref.watch(taxEstimationProvider.future);
  final profile = ref.watch(taxDeductionProfileProvider).value;
  const service = TaxOpportunityService();
  return service.detect(
    TaxOpportunityContext(estimate: estimate, profile: profile),
  );
});
