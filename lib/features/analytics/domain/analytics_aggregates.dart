import 'package:fl_chart/fl_chart.dart';

/// Unified analytics computation result.
///
/// Pure data model — no business logic, no Flutter widgets, no Riverpod.
/// Produced by [AnalyticsAggregationService], consumed by UI sections and InsightEngine.
class AnalyticsAggregates {
  final double totalIncome;
  final double totalExpense;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<FlSpot> savingsSpots;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> incomeCategoryBreakdown;
  final Map<String, List<double>> monthlyExpenseTrends;
  final Map<String, double> spendingByDayOfWeek;
  final double savingsRate;
  final double avgDailySpend;
  final int daysInPeriod;
  final double? previousPartialExpense;
  final double? previousFullExpense;

  const AnalyticsAggregates({
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.savingsSpots,
    required this.categoryBreakdown,
    required this.incomeCategoryBreakdown,
    required this.monthlyExpenseTrends,
    required this.spendingByDayOfWeek,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.daysInPeriod,
    this.previousPartialExpense,
    this.previousFullExpense,
  });
}
