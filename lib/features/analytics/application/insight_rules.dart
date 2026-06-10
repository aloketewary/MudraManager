import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/analytics/domain/insight_rule.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

/// Identifies the top spending category when it exceeds materiality threshold.
class TopCategoryRule implements InsightRule {
  const TopCategoryRule({this.minSpendThreshold = 100.0});

  final double minSpendThreshold;

  @override
  InsightRuleId get id => InsightRuleId.topCategory;

  @override
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    if (aggregates.categoryBreakdown.isEmpty) return null;
    if (aggregates.totalExpense <= 0) return null;

    final sorted = aggregates.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    if (top.value <= minSpendThreshold) return null;

    return TopCategoryFact(
      category: top.key,
      percentage: (top.value / aggregates.totalExpense) * 100,
    );
  }
}

/// Detects categories that appeared this month with no prior spending.
class NewCategoryRule implements InsightRule {
  const NewCategoryRule({this.minSpendThreshold = 100.0});

  final double minSpendThreshold;

  @override
  InsightRuleId get id => InsightRuleId.newCategory;

  @override
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    if (period?.isMonthly != true) return null;

    final trends = aggregates.monthlyExpenseTrends;
    for (final entry in trends.entries) {
      final history = entry.value;
      if (history.length >= 2) {
        final current = history.last;
        final previous = history[history.length - 2];
        if (current > minSpendThreshold && previous == 0) {
          return NewSpendingCategoryFact(
            category: entry.key,
            amount: current,
          );
        }
      }
    }
    return null;
  }
}

/// Detects categories that had spending last month but none this month.
class CategoryStoppedRule implements InsightRule {
  const CategoryStoppedRule({this.minSpendThreshold = 100.0});

  final double minSpendThreshold;

  @override
  InsightRuleId get id => InsightRuleId.categoryStopped;

  @override
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    if (period?.isMonthly != true) return null;

    final trends = aggregates.monthlyExpenseTrends;
    for (final entry in trends.entries) {
      final history = entry.value;
      if (history.length >= 2) {
        final current = history.last;
        final previous = history[history.length - 2];
        if (current == 0 && previous > minSpendThreshold) {
          return CategoryStoppedFact(
            category: entry.key,
            previousAmount: previous,
          );
        }
      }
    }
    return null;
  }
}

/// Detects weekend spending peak pattern.
class SpendingPatternRule implements InsightRule {
  const SpendingPatternRule({this.minDailySpend = 50.0});

  final double minDailySpend;

  @override
  InsightRuleId get id => InsightRuleId.weekendPeak;

  @override
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    final byDay = aggregates.spendingByDayOfWeek;
    if (!byDay.values.any((v) => v > minDailySpend)) return null;

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final peakDay =
        days.reduce((a, b) => (byDay[a] ?? 0) > (byDay[b] ?? 0) ? a : b);

    final weekdayTotal =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].fold(0.0, (s, d) => s + (byDay[d] ?? 0));
    final weekendTotal =
        ['Sat', 'Sun'].fold(0.0, (s, d) => s + (byDay[d] ?? 0));

    final weekendAvg = weekendTotal / 2;
    final weekdayAvg = weekdayTotal / 5;

    if (weekendAvg > weekdayAvg * 1.5) {
      return WeekendPeakFact(peakDay: peakDay);
    } else if (weekdayAvg > weekendAvg * 1.5) {
      return WeekdayPeakFact(peakDay: peakDay);
    }
    return null;
  }
}

/// Projects month-end spending and compares to previous month.
/// Gated: requires 7+ days elapsed and >5% variance.
class SpendingForecastRule implements InsightRule {
  const SpendingForecastRule();

  @override
  InsightRuleId get id => InsightRuleId.spendingForecast;

  @override
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    if (period?.isMonthly != true) return null;

    final now = DateTime.now();
    if (now.day < 7) return null;

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projected = aggregates.avgDailySpend * daysInMonth;
    final previousTotal = aggregates.previousFullExpense;

    if (previousTotal == null || previousTotal <= 0) return null;

    final variance = projected - previousTotal;
    if (variance.abs() <= previousTotal * 0.05) return null;

    return SpendingForecastFact(
      projectedAmount: projected,
      variance: variance,
      comparisonPeriod: 'last month',
    );
  }
}
