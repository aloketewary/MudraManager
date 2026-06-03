import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/briefing_selector.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 0);

  group('SuppressionEngine.shouldSuppress', () {
    test('does not suppress when history is empty', () {
      expect(
        SuppressionEngine.shouldSuppress(
          candidate: const BriefingSelection(
            trigger: BriefingTrigger.budgetBreach,
            params: {},
          ),
          history: [],
          now: now,
        ),
        false,
      );
    });

    test('does not suppress after 24h', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 25)),
          magnitude: 1000,
        ),
      ];
      expect(
        SuppressionEngine.shouldSuppress(
          candidate: const BriefingSelection(
            trigger: BriefingTrigger.budgetBreach,
            params: {},
          ),
          history: history,
          now: now,
          currentMagnitude: 1000,
        ),
        false,
      );
    });

    test('suppresses same trigger within 24h with <5% magnitude change', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 6)),
          magnitude: 1000,
        ),
      ];
      expect(
        SuppressionEngine.shouldSuppress(
          candidate: const BriefingSelection(
            trigger: BriefingTrigger.budgetBreach,
            params: {},
          ),
          history: history,
          now: now,
          currentMagnitude: 1020, // 2% change
        ),
        true,
      );
    });

    test('does not suppress when magnitude changes >=5%', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 6)),
          magnitude: 1000,
        ),
      ];
      expect(
        SuppressionEngine.shouldSuppress(
          candidate: const BriefingSelection(
            trigger: BriefingTrigger.budgetBreach,
            params: {},
          ),
          history: history,
          now: now,
          currentMagnitude: 1100, // 10% change
        ),
        false,
      );
    });

    test('does not suppress different trigger', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 2)),
          magnitude: 1000,
        ),
      ];
      expect(
        SuppressionEngine.shouldSuppress(
          candidate: const BriefingSelection(
            trigger: BriefingTrigger.billDueToday,
            params: {},
          ),
          history: history,
          now: now,
          currentMagnitude: 1000,
        ),
        false,
      );
    });
  });

  group('SuppressionEngine.recordFiring', () {
    test('adds new record to empty history', () {
      final result = SuppressionEngine.recordFiring(
        history: [],
        fired: const BriefingSelection(
          trigger: BriefingTrigger.budgetBreach,
          params: {},
        ),
        now: now,
        magnitude: 1500,
      );

      expect(result.length, 1);
      expect(result.first.trigger, BriefingTrigger.budgetBreach);
      expect(result.first.magnitude, 1500);
      expect(result.first.consecutiveDays, 1);
    });

    test('increments consecutiveDays for same trigger within 36h', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 20)),
          magnitude: 1000,
          consecutiveDays: 3,
        ),
      ];

      final result = SuppressionEngine.recordFiring(
        history: history,
        fired: const BriefingSelection(
          trigger: BriefingTrigger.budgetBreach,
          params: {},
        ),
        now: now,
        magnitude: 1100,
      );

      expect(result.first.consecutiveDays, 4);
    });

    test('resets consecutiveDays after gap >36h', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.budgetBreach,
          firedAt: now.subtract(const Duration(hours: 48)),
          magnitude: 1000,
          consecutiveDays: 5,
        ),
      ];

      final result = SuppressionEngine.recordFiring(
        history: history,
        fired: const BriefingSelection(
          trigger: BriefingTrigger.budgetBreach,
          params: {},
        ),
        now: now,
        magnitude: 1100,
      );

      expect(result.first.consecutiveDays, 1);
    });

    test('prunes records older than 30 days', () {
      final history = [
        SuppressionRecord(
          trigger: BriefingTrigger.netNegative,
          firedAt: now.subtract(const Duration(days: 45)),
          magnitude: 500,
        ),
        SuppressionRecord(
          trigger: BriefingTrigger.billDueToday,
          firedAt: now.subtract(const Duration(days: 5)),
          magnitude: 2000,
        ),
      ];

      final result = SuppressionEngine.recordFiring(
        history: history,
        fired: const BriefingSelection(
          trigger: BriefingTrigger.budgetBreach,
          params: {},
        ),
        now: now,
        magnitude: 1000,
      );

      // netNegative (45 days old) should be pruned
      expect(result.any((r) => r.trigger == BriefingTrigger.netNegative), false);
      expect(result.any((r) => r.trigger == BriefingTrigger.billDueToday), true);
      expect(result.any((r) => r.trigger == BriefingTrigger.budgetBreach), true);
    });
  });
}
