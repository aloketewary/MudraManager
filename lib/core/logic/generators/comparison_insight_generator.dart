import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

/// Emits insights by comparing current month spending against a baseline month.
///
/// Two signal types only:
/// - Threshold breach: category already exceeded last month's total
/// - Pace acceleration: category running ≥2× faster than baseline
///
/// Gating: requires ≥7 days elapsed AND ≥20% of baseline activity.
/// Generators discover facts. Selectors decide relevance.
class ComparisonInsightGenerator implements InsightGenerator {
  final String? actionRoute;

  const ComparisonInsightGenerator({this.actionRoute});

  @override
  String get source => 'comparison';

  @override
  List<Insight> generate(Facts facts) {
    final categories = facts.categoryComparison;
    if (categories == null || categories.isEmpty) return [];

    // Gate: insufficient data below 7 days
    if (facts.dayOfMonth < 7) return [];

    final insights = <Insight>[];

    for (final entry in categories.entries) {
      final cat = entry.value;

      // Skip categories with negligible baseline
      if (cat.lastMonthTotal <= 0) continue;

      // Gate: require ≥20% of baseline activity before emitting
      if (cat.currentMonthSpend < cat.lastMonthTotal * 0.20) continue;

      // ── Threshold breach ──
      // Current month spend already exceeds last month's TOTAL
      // AND there are still ≥5 days remaining in the month
      if (cat.currentMonthSpend > cat.lastMonthTotal &&
          facts.daysRemaining >= 5) {
        final over = cat.currentMonthSpend - cat.lastMonthTotal;
        insights.add(Insight(
          trigger: BriefingTrigger.spendingThresholdBreach,
          source: source,
          magnitude: over,
          confidence: _confidence(facts.dayOfMonth),
          context: {
            'category': cat.name,
            'currentSpend': cat.currentMonthSpend,
            'lastMonthTotal': cat.lastMonthTotal,
            'over': over,
            'daysRemaining': facts.daysRemaining,
          },
          actionRoute: actionRoute,
        ),);
        // Don't also emit acceleration for same category — breach is stronger
        continue;
      }

      // ── Pace acceleration ──
      // Current pace ≥2× baseline pace, with valid pace data
      if (cat.baselinePace > 0 &&
          cat.currentPace > 0 &&
          cat.currentPace >= cat.baselinePace * 2.0) {
        final multiplier = cat.currentPace / cat.baselinePace;
        insights.add(Insight(
          trigger: BriefingTrigger.spendingAcceleration,
          source: source,
          magnitude: (cat.currentPace - cat.baselinePace) * facts.daysRemaining,
          confidence: _confidence(facts.dayOfMonth),
          context: {
            'category': cat.name,
            'currentPace': cat.currentPace,
            'baselinePace': cat.baselinePace,
            'multiplier': multiplier,
            'projectedTotal': cat.currentPace * facts.daysInMonth,
          },
          actionRoute: actionRoute,
        ),);
      }
    }

    return insights;
  }

  /// Confidence ramps with days elapsed.
  /// Day 7-14: partial (0.7). Day 15+: full (0.95).
  double _confidence(int dayOfMonth) {
    if (dayOfMonth >= 15) return 0.95;
    if (dayOfMonth >= 7) return 0.7;
    return 0.4; // should not reach here due to gate
  }
}
