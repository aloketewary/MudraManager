import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

/// Identifies each rule for suppression, dismissal, and telemetry.
enum InsightRuleId {
  topCategory,
  newCategory,
  categoryStopped,
  weekendPeak,
  weekdayPeak,
  spendingForecast,
}

/// Contract for a single insight rule.
///
/// Rules are pure: no Riverpod, no Flutter, no side effects.
/// Return null when data is insufficient — no pseudo-confidence.
abstract class InsightRule {
  InsightRuleId get id;

  /// Evaluate aggregates and optionally produce a fact.
  /// [periodKey] provides context for period-gated rules.
  NarrativeFact? evaluate(
    AnalyticsAggregates aggregates, {
    String? periodKey,
  });
}
