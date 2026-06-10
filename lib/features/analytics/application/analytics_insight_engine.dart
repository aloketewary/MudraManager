import 'package:mudra_manager/features/analytics/application/insight_rules.dart';
import 'package:mudra_manager/features/analytics/data/analytics_aggregation_service.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_period.dart';
import 'package:mudra_manager/features/analytics/domain/insight_rule.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

/// Pure engine that evaluates insight rules against aggregates.
///
/// No Riverpod. No Flutter. No side effects.
/// Testable with plain unit tests.
class AnalyticsInsightEngine {
  const AnalyticsInsightEngine(this._rules);

  final List<InsightRule> _rules;

  /// Default rule set for the app.
  static const defaultRules = [
    TopCategoryRule(),
    NewCategoryRule(),
    CategoryStoppedRule(),
    SpendingPatternRule(),
    SpendingForecastRule(),
  ];

  /// Standard engine with all default rules.
  static const standard = AnalyticsInsightEngine(defaultRules);

  /// Evaluate all rules and return non-null facts.
  List<NarrativeFact> generate(
    AnalyticsAggregates aggregates, {
    AnalyticsPeriod? period,
  }) {
    return _rules
        .map((r) => r.evaluate(aggregates, period: period))
        .whereType<NarrativeFact>()
        .toList();
  }
}
