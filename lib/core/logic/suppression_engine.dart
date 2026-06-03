import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';

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

/// Determines whether a briefing candidate should be suppressed.
///
/// Rules:
/// - Same trigger suppressed if fired within 24h AND magnitude change < 5%
/// - After 7 consecutive days of same trigger, shift narrative framing
/// - Never suppress newlyViolated transitions
abstract final class SuppressionEngine {
  static bool shouldSuppress({
    required BriefingSelection candidate,
    required List<SuppressionRecord> history,
    required DateTime now,
    double? currentMagnitude,
  }) {
    final matching = history.where(
      (r) => r.trigger == candidate.trigger,
    );
    if (matching.isEmpty) return false;

    final last = matching.last;
    final hoursSince = now.difference(last.firedAt).inHours;

    // Never suppress if >24h since last fire
    if (hoursSince >= 24) return false;

    // Never suppress if magnitude changed ≥5%
    if (currentMagnitude != null && last.magnitude != null) {
      final change = (currentMagnitude - last.magnitude!).abs();
      final pct = last.magnitude! > 0 ? change / last.magnitude! : 1.0;
      if (pct >= 0.05) return false;
    }

    // Suppress: same trigger, <24h, <5% magnitude change
    return true;
  }

  /// Updates history after a briefing fires. Returns updated list.
  static List<SuppressionRecord> recordFiring({
    required List<SuppressionRecord> history,
    required BriefingSelection fired,
    required DateTime now,
    double? magnitude,
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
        magnitude: magnitude,
        consecutiveDays: hoursSince < 36
            ? existing.consecutiveDays + 1
            : 1,
      );
    } else {
      updated.add(SuppressionRecord(
        trigger: fired.trigger,
        firedAt: now,
        magnitude: magnitude,
      ),);
    }

    // Prune records older than 30 days
    updated.removeWhere(
      (r) => now.difference(r.firedAt).inDays > 30,
    );

    return updated;
  }
}
