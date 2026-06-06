import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/suppression_engine.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 0);

  Insight _makeInsight(BriefingTrigger trigger, {double magnitude = 0}) {
    return Insight(
      trigger: trigger,
      source: 'test',
      magnitude: magnitude,
      confidence: 1.0,
    );
  }

  group('SuppressionEngine.shouldSuppress', () {
    test('does not suppress when history is empty', () {
      expect(
        SuppressionEngine.shouldSuppress(
          insight: _makeInsight(BriefingTrigger.budgetBreach),
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
          insight: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1000),
          history: history,
          now: now,
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
          insight: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1020),
          history: history,
          now: now,
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
          insight: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1100),
          history: history,
          now: now,
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
          insight: _makeInsight(BriefingTrigger.billDueToday, magnitude: 1000),
          history: history,
          now: now,
        ),
        false,
      );
    });
  });

  group('SuppressionEngine.recordFiring', () {
    test('adds new record to empty history', () {
      final result = SuppressionEngine.recordFiring(
        history: [],
        fired: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1500),
        now: now,
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
        fired: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1100),
        now: now,
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
        fired: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1100),
        now: now,
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
        fired: _makeInsight(BriefingTrigger.budgetBreach, magnitude: 1000),
        now: now,
      );

      // netNegative (45 days old) should be pruned
      expect(result.any((r) => r.trigger == BriefingTrigger.netNegative), false);
      expect(result.any((r) => r.trigger == BriefingTrigger.billDueToday), true);
      expect(result.any((r) => r.trigger == BriefingTrigger.budgetBreach), true);
    });
  });
}
