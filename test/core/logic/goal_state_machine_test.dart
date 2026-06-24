import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/logic/goal_state_machine.dart';

void main() {
  final now = DateTime(2025, 6, 15);

  group('GoalStateMachine.recentPace', () {
    test('returns 0 when no contributions', () {
      expect(GoalStateMachine.recentPace([], now), 0);
    });

    test('uses 90-day rolling average when recent data exists', () {
      final contributions = [
        GoalContributionData(amount: 3000, date: now.subtract(const Duration(days: 10))),
        GoalContributionData(amount: 6000, date: now.subtract(const Duration(days: 40))),
        GoalContributionData(amount: 9000, date: now.subtract(const Duration(days: 70))),
      ];
      // Total in 90 days = 18000, divided by 3 months = 6000/mo
      expect(GoalStateMachine.recentPace(contributions, now), 6000);
    });

    test('falls back to lifetime average when all contributions older than 90 days', () {
      final contributions = [
        GoalContributionData(amount: 5000, date: now.subtract(const Duration(days: 120))),
        GoalContributionData(amount: 5000, date: now.subtract(const Duration(days: 180))),
      ];
      // Total = 10000, first contribution 180 days ago = 6 months, avg = 10000/6 ≈ 1666
      final pace = GoalStateMachine.recentPace(contributions, now);
      expect(pace, closeTo(1666.67, 1));
    });

    test('returns total when history is less than 1 month', () {
      final contributions = [
        GoalContributionData(amount: 5000, date: now.subtract(const Duration(days: 95))),
      ];
      // Only 1 contribution at 95 days ago (outside 90d window) → lifetime fallback
      // 5000 / (95/30) ≈ 1578
      final pace = GoalStateMachine.recentPace(contributions, now);
      expect(pace, closeTo(1578.95, 1));
    });

    test('returns total if lifetime is under 30 days (all old)', () {
      // Edge: single contribution at 100 days → lifetime = 100/30 = 3.33 months
      final contributions = [
        GoalContributionData(amount: 10000, date: now.subtract(const Duration(days: 100))),
      ];
      final pace = GoalStateMachine.recentPace(contributions, now);
      expect(pace, closeTo(3000, 50));
    });

    test('mixes recent and old contributions correctly', () {
      final contributions = [
        GoalContributionData(amount: 2000, date: now.subtract(const Duration(days: 30))),
        GoalContributionData(amount: 50000, date: now.subtract(const Duration(days: 200))),
      ];
      // Only 2000 is within 90 days → 2000 / 3 = 666.67
      final pace = GoalStateMachine.recentPace(contributions, now);
      expect(pace, closeTo(666.67, 1));
    });
  });

  group('GoalStateMachine.neededPerMonth', () {
    test('returns 0 when no deadline', () {
      expect(GoalStateMachine.neededPerMonth(50000, null, now), 0);
    });

    test('returns full remaining when past deadline', () {
      final pastDate = now.subtract(const Duration(days: 10));
      expect(GoalStateMachine.neededPerMonth(50000, pastDate, now), 50000);
    });

    test('calculates correctly for future deadline', () {
      final futureDate = now.add(const Duration(days: 90));
      // 50000 / (90/30) = 50000/3 ≈ 16666.67
      final needed = GoalStateMachine.neededPerMonth(50000, futureDate, now);
      expect(needed, closeTo(16666.67, 1));
    });

    test('handles deadline 1 day away', () {
      final tomorrow = now.add(const Duration(days: 1));
      // 50000 / (1/30) = 50000 * 30 = 1500000
      final needed = GoalStateMachine.neededPerMonth(50000, tomorrow, now);
      expect(needed, closeTo(1500000, 100));
    });

    test('returns 0 remaining when already saved enough', () {
      final futureDate = now.add(const Duration(days: 60));
      expect(GoalStateMachine.neededPerMonth(0, futureDate, now), 0);
    });
  });

  group('GoalStateMachine.paceGap', () {
    test('returns 0 when needed is 0', () {
      expect(GoalStateMachine.paceGap(5000, 0), 0);
    });

    test('positive gap when ahead', () {
      expect(GoalStateMachine.paceGap(8000, 5000), 3000);
    });

    test('negative gap when behind', () {
      expect(GoalStateMachine.paceGap(3000, 5000), -2000);
    });

    test('zero gap when exactly matching', () {
      expect(GoalStateMachine.paceGap(5000, 5000), 0);
    });
  });

  group('GoalStateMachine.needsAttention', () {
    test('completed goals never need attention', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 1.0,
          gap: -5000,
          daysRemaining: 10,
          predictedDate: now.add(const Duration(days: 999)),
          targetDate: now.add(const Duration(days: 30)),
        ),
        false,
      );
    });

    test('negative gap triggers attention', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 0.5,
          gap: -1000,
          daysRemaining: 200,
          predictedDate: null,
          targetDate: now.add(const Duration(days: 200)),
        ),
        true,
      );
    });

    test('near deadline (<90 days) triggers attention', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 0.3,
          gap: 500,
          daysRemaining: 60,
          predictedDate: null,
          targetDate: now.add(const Duration(days: 60)),
        ),
        true,
      );
    });

    test('predicted after target triggers attention', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 0.5,
          gap: 500,
          daysRemaining: 200,
          predictedDate: now.add(const Duration(days: 300)),
          targetDate: now.add(const Duration(days: 200)),
        ),
        true,
      );
    });

    test('healthy goal does not need attention', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 0.5,
          gap: 2000,
          daysRemaining: 200,
          predictedDate: now.add(const Duration(days: 150)),
          targetDate: now.add(const Duration(days: 200)),
        ),
        false,
      );
    });

    test('null predicted and target does not trigger', () {
      expect(
        GoalStateMachine.needsAttention(
          progressPercent: 0.5,
          gap: 1000,
          daysRemaining: 200,
          predictedDate: null,
          targetDate: null,
        ),
        false,
      );
    });
  });

  group('GoalStateMachine.sortPriority', () {
    test('completed goals sort last', () {
      expect(
        GoalStateMachine.sortPriority(
          progressPercent: 1.0,
          gap: 0,
          daysRemaining: 0,
          hasDeadline: true,
        ),
        100,
      );
    });

    test('behind pace sorts first', () {
      expect(
        GoalStateMachine.sortPriority(
          progressPercent: 0.3,
          gap: -2000,
          daysRemaining: 200,
          hasDeadline: true,
        ),
        0,
      );
    });

    test('near deadline sorts second', () {
      expect(
        GoalStateMachine.sortPriority(
          progressPercent: 0.5,
          gap: 1000,
          daysRemaining: 60,
          hasDeadline: true,
        ),
        1,
      );
    });

    test('on track with deadline sorts third', () {
      expect(
        GoalStateMachine.sortPriority(
          progressPercent: 0.5,
          gap: 1000,
          daysRemaining: 200,
          hasDeadline: true,
        ),
        2,
      );
    });

    test('no deadline sorts fourth', () {
      expect(
        GoalStateMachine.sortPriority(
          progressPercent: 0.3,
          gap: 0,
          daysRemaining: 0,
          hasDeadline: false,
        ),
        3,
      );
    });
  });

  group('GoalStateMachine.suggestedDeposit', () {
    test('uses last contribution amount when history exists', () {
      final contributions = [
        GoalContributionData(amount: 3000, date: now.subtract(const Duration(days: 30))),
        GoalContributionData(amount: 5000, date: now.subtract(const Duration(days: 60))),
      ];
      // Most recent = 3000
      expect(GoalStateMachine.suggestedDeposit(contributions, 4000), 3000);
    });

    test('rounds up neededPerMonth to 500 when no history', () {
      expect(GoalStateMachine.suggestedDeposit([], 4200), 4500);
    });

    test('rounds to 500 when neededPerMonth is exactly on boundary', () {
      expect(GoalStateMachine.suggestedDeposit([], 3000), 3000);
    });

    test('returns 1000 default when no history and no needed', () {
      expect(GoalStateMachine.suggestedDeposit([], 0), 1000);
    });
  });

  group('GoalStateMachine.predictedCompletion', () {
    test('returns null when progress is 0', () {
      expect(
        GoalStateMachine.predictedCompletion(
          progressPercent: 0,
          creationDate: now.subtract(const Duration(days: 60)),
          now: now,
          contributionCount: 5,
        ),
        null,
      );
    });

    test('returns null when fewer than 3 contributions', () {
      expect(
        GoalStateMachine.predictedCompletion(
          progressPercent: 0.5,
          creationDate: now.subtract(const Duration(days: 60)),
          now: now,
          contributionCount: 2,
        ),
        null,
      );
    });

    test('returns null when less than 30 days elapsed', () {
      expect(
        GoalStateMachine.predictedCompletion(
          progressPercent: 0.5,
          creationDate: now.subtract(const Duration(days: 20)),
          now: now,
          contributionCount: 5,
        ),
        null,
      );
    });

    test('returns null when elapsed is 0', () {
      expect(
        GoalStateMachine.predictedCompletion(
          progressPercent: 0.5,
          creationDate: now,
          now: now,
          contributionCount: 5,
        ),
        null,
      );
    });

    test('calculates predicted date correctly', () {
      final creation = now.subtract(const Duration(days: 60));
      // 50% in 60 days → full in 120 days from creation
      final predicted = GoalStateMachine.predictedCompletion(
        progressPercent: 0.5,
        creationDate: creation,
        now: now,
        contributionCount: 5,
      );
      expect(predicted, creation.add(const Duration(days: 120)));
    });

    test('handles low progress correctly', () {
      final creation = now.subtract(const Duration(days: 90));
      // 10% in 90 days → full in 900 days from creation
      final predicted = GoalStateMachine.predictedCompletion(
        progressPercent: 0.1,
        creationDate: creation,
        now: now,
        contributionCount: 4,
      );
      expect(predicted, creation.add(const Duration(days: 900)));
    });
  });

  group('GoalStateMachine.daysRemaining', () {
    test('returns 0 when no deadline', () {
      expect(GoalStateMachine.daysRemaining(null, now), 0);
    });

    test('returns 0 when past deadline', () {
      final past = now.subtract(const Duration(days: 5));
      expect(GoalStateMachine.daysRemaining(past, now), 0);
    });

    test('returns correct days for future deadline', () {
      final future = now.add(const Duration(days: 45));
      expect(GoalStateMachine.daysRemaining(future, now), 45);
    });
  });
}
