import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Unified results from AnalyticsAggregationService.
class AnalyticsAggregates {
  final double totalIncome;
  final double totalExpense;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final List<FlSpot> savingsSpots;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> incomeCategoryBreakdown;
  final Map<String, List<double>> monthlyExpenseTrends; // last 12 months
  final Map<String, double> spendingByDayOfWeek;
  final double savingsRate;
  final double avgDailySpend;
  final int daysInPeriod;
  final double? previousPartialExpense; // For fair comparison (same days)
  final double? previousFullExpense; // For projection comparison

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

/// Service that performs single-pass aggregation over transactions
/// to ensure consistent data across all analytics components.
class AnalyticsAggregationService {
  const AnalyticsAggregationService();

  AnalyticsAggregates compute({
    required List<Transaction> transactions,
    required DateTime start,
    required DateTime end,
    required String periodType, // 'Today', 'Week', 'Month', 'Year', 'Custom'
  }) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;
    final Map<String, double> categoryBreakdown = {};
    final Map<String, double> incomeCategoryBreakdown = {};
    final Map<int, double> periodIncomeMap = {};
    final Map<int, double> periodExpenseMap = {};
    final Map<String, double> dayOfWeekMap = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // For 12-month trends
    final Map<String, List<double>> monthlyTrends = {};
    final trendStart = DateTime(now.year, now.month - 11, 1);

    // For comparison logic
    double prevPartialExpense = 0;
    double prevFullExpense = 0;
    final isMonthly = periodType == 'Month';
    DateTime? prevStart;
    DateTime? prevEndPartial;
    DateTime? prevEndFull;

    if (isMonthly) {
      prevStart = DateTime(start.year, start.month - 1, 1);
      final daysElapsed = end.day;
      prevEndPartial =
          DateTime(prevStart.year, prevStart.month, daysElapsed, 23, 59, 59);
      prevEndFull =
          DateTime(prevStart.year, prevStart.month + 1, 0, 23, 59, 59);
    }

    for (final txn in transactions) {
      if (!txn.affectsStats) continue;

      final amt = txn.effectiveAmount;
      final catName = txn.category.value?.name ?? 'Uncategorized';

      // Primary period pass
      final isWithinPeriod =
          !txn.date.isBefore(start) && !txn.date.isAfter(end);
      if (isWithinPeriod) {
        if (txn.isExpense) {
          expense += amt;
          categoryBreakdown[catName] = (categoryBreakdown[catName] ?? 0) + amt;

          final dayName = daysOfWeek[txn.date.weekday - 1];
          dayOfWeekMap[dayName] = (dayOfWeekMap[dayName] ?? 0) + amt;

          final periodIdx = _getPeriodIndex(txn.date, start, periodType);
          periodExpenseMap[periodIdx] =
              (periodExpenseMap[periodIdx] ?? 0) + amt;
        } else {
          income += amt;
          incomeCategoryBreakdown[catName] =
              (incomeCategoryBreakdown[catName] ?? 0) + amt;

          final periodIdx = _getPeriodIndex(txn.date, start, periodType);
          periodIncomeMap[periodIdx] = (periodIncomeMap[periodIdx] ?? 0) + amt;
        }
      }

      // Comparison passes
      if (isMonthly && prevStart != null) {
        if (txn.isExpense && !txn.date.isBefore(prevStart)) {
          if (!txn.date.isAfter(prevEndFull!)) {
            prevFullExpense += amt;
            if (!txn.date.isAfter(prevEndPartial!)) {
              prevPartialExpense += amt;
            }
          }
        }
      }

      // 12-month trend pass
      if (txn.isExpense && !txn.date.isBefore(trendStart)) {
        final monthDiff =
            (now.year - txn.date.year) * 12 + (now.month - txn.date.month);
        if (monthDiff >= 0 && monthDiff < 12) {
          monthlyTrends.putIfAbsent(
            catName,
            () => List<double>.filled(12, 0.0),
          );
          monthlyTrends[catName]![11 - monthDiff] += amt;
        }
      }
    }

    final daysInPeriod = end.difference(start).inDays + 1;
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final savingsSpots = <FlSpot>[];

    final spotCount = _getSpotCount(periodType, daysInPeriod);
    for (int i = 0; i < spotCount; i++) {
      final inc = periodIncomeMap[i] ?? 0;
      final exp = periodExpenseMap[i] ?? 0;
      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
      savingsSpots.add(FlSpot(i.toDouble(), inc - exp));
    }

    return AnalyticsAggregates(
      totalIncome: income,
      totalExpense: expense,
      incomeSpots: incomeSpots,
      expenseSpots: expenseSpots,
      savingsSpots: savingsSpots,
      categoryBreakdown: categoryBreakdown,
      incomeCategoryBreakdown: incomeCategoryBreakdown,
      monthlyExpenseTrends: monthlyTrends,
      spendingByDayOfWeek: dayOfWeekMap,
      savingsRate: income > 0 ? ((income - expense) / income) * 100 : 0.0,
      avgDailySpend: expense / (daysInPeriod > 0 ? daysInPeriod : 1),
      daysInPeriod: daysInPeriod,
      previousPartialExpense: isMonthly ? prevPartialExpense : null,
      previousFullExpense: isMonthly ? prevFullExpense : null,
    );
  }

  int _getPeriodIndex(DateTime date, DateTime start, String periodType) {
    return switch (periodType) {
      'Today' => date.hour,
      'Year' => date.month - 1,
      _ => date.difference(start).inDays,
    };
  }

  int _getSpotCount(String periodType, int daysInPeriod) {
    return switch (periodType) {
      'Today' => 24,
      'Year' => 12,
      _ => daysInPeriod,
    };
  }
}
