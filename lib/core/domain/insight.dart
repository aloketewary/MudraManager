import 'package:mudra_manager/core/domain/financial_states.dart';

/// A single insight emitted by a generator.
///
/// Generators own facts (magnitude, confidence, context).
/// Selectors own relevance (priority comes from trigger).
/// Generators discover. Selectors decide.
class Insight {
  final BriefingTrigger trigger;

  /// Which generator produced this. For diagnostics and suppression scoping.
  final String source;

  /// Domain-specific magnitude (₹ amount, days overdue, etc).
  /// Not normalized across domains — used only for suppression comparison
  /// within the same trigger type.
  final double magnitude;

  /// 0.0–1.0. How trustworthy this insight is given available data.
  /// Gated by data sufficiency (days elapsed, activity threshold).
  final double confidence;

  /// Domain-specific context for narrative rendering.
  final Map<String, dynamic> context;

  /// Optional deep-link route when user taps the briefing.
  final String? actionRoute;

  const Insight({
    required this.trigger,
    required this.source,
    required this.magnitude,
    required this.confidence,
    this.context = const {},
    this.actionRoute,
  });

  /// Effective priority for selection. Today: just trigger.priority.
  /// Tomorrow: trigger.priority * confidence * freshness.
  int get effectivePriority => trigger.priority;

  @override
  String toString() =>
      'Insight(${trigger.name}, source=$source, mag=$magnitude, conf=$confidence)';
}
