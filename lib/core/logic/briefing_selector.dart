import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';

/// A candidate briefing signal with its trigger, params, and route.
/// Kept for backward compatibility with DashboardState.briefing field.
class BriefingSelection {
  final Insight insight;
  final String? actionRoute;

  const BriefingSelection({
    required this.insight,
    this.actionRoute,
  });

  /// Convenience accessors for existing UI code.
  Map<String, dynamic> get params => insight.context;
}

/// Selects the single highest-priority insight from candidates.
/// Returns null when the system should be silent.
///
/// Flow: generators emit → suppression filters → priority sorts → one wins.
abstract final class BriefingSelector {
  static BriefingSelection? select(
    List<Insight> insights, {
    List<SuppressionRecord> suppressionHistory = const [],
    DateTime? now,
  }) {
    if (insights.isEmpty) return null;

    final currentTime = now ?? DateTime.now();

    // Apply suppression
    final active = insights.where((i) {
      return !SuppressionEngine.shouldSuppress(
        insight: i,
        history: suppressionHistory,
        now: currentTime,
      );
    }).toList();

    if (active.isEmpty) return null;

    // Sort by effective priority (today: trigger.priority)
    active.sort(
      (a, b) => b.effectivePriority.compareTo(a.effectivePriority),
    );

    final winner = active.first;
    return BriefingSelection(
      insight: winner,
      actionRoute: winner.actionRoute,
    );
  }
}
