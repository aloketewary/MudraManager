import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';

/// Record of a previously fired briefing trigger.
class SuppressionRecord {
  final BriefingTrigger trigger;
  final DateTime firedAt;
  final double? magnitude;
  int consecutiveDays;

  SuppressionRecord({
    required this.trigger,
    required this.firedAt,
    this.magnitude,
    this.consecutiveDays = 1,
  });
}

/// Determines whether an insight should be suppressed.
///
/// Rules:
/// - Same trigger suppressed if fired within 24h AND magnitude change < 5%
/// - Never suppress newlyViolated transitions
abstract final class SuppressionEngine {
  static bool shouldSuppress({
    required Insight insight,
    required List<SuppressionRecord> history,
    required DateTime now,
  }) {
    final matching = history.where(
      (r) => r.trigger == insight.trigger,
    );
    if (matching.isEmpty) return false;

    final last = matching.last;
    final hoursSince = now.difference(last.firedAt).inHours;

    // Never suppress if >24h since last fire
    if (hoursSince >= 24) return false;

    // Never suppress if magnitude changed ≥5%
    if (last.magnitude != null && last.magnitude! > 0) {
      final change = (insight.magnitude - last.magnitude!).abs();
      final pct = change / last.magnitude!;
      if (pct >= 0.05) return false;
    }

    // Suppress: same trigger, <24h, <5% magnitude change
    return true;
  }

  /// Updates history after an insight fires. Returns updated list.
  static List<SuppressionRecord> recordFiring({
    required List<SuppressionRecord> history,
    required Insight fired,
    required DateTime now,
  }) {
    final updated = List<SuppressionRecord>.from(history);

    final existingIdx = updated.indexWhere(
      (r) => r.trigger == fired.trigger,
    );

    if (existingIdx >= 0) {
      final existing = updated[existingIdx];
      final hoursSince = now.difference(existing.firedAt).inHours;
      updated[existingIdx] = SuppressionRecord(
        trigger: fired.trigger,
        firedAt: now,
        magnitude: fired.magnitude,
        consecutiveDays: hoursSince < 36
            ? existing.consecutiveDays + 1
            : 1,
      );
    } else {
      updated.add(SuppressionRecord(
        trigger: fired.trigger,
        firedAt: now,
        magnitude: fired.magnitude,
      ),);
    }

    // Prune records older than 30 days
    updated.removeWhere(
      (r) => now.difference(r.firedAt).inDays > 30,
    );

    return updated;
  }
}
