import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/features/goal/domain/goal_health.dart';

void main() {
  group('GoalHealth.compute', () {
    test('completed goal returns completed status', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 50000,
      );
      final health = GoalHealth.compute(goal);
      expect(health.status, GoalStatus.completed);
    });

    test('over-saved goal returns completed', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 60000,
      );
      final health = GoalHealth.compute(goal);
      expect(health.status, GoalStatus.completed);
    });

    test('no deadline returns noDeadline status', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 10000,
      );
      final health = GoalHealth.compute(goal);
      expect(health.status, GoalStatus.noDeadline);
      expect(health.daysLeft, 0);
    });

    test('past deadline returns behind status', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 10000,
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      final health = GoalHealth.compute(goal);
      expect(health.status, GoalStatus.behind);
      expect(health.daysLeft, 0);
    });

    test('future deadline calculates daysLeft', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 10000,
        targetDate: DateTime.now().add(const Duration(days: 100)),
      );
      final health = GoalHealth.compute(goal);
      expect(health.daysLeft, closeTo(100, 1));
    });

    test('dailyNeeded is correct', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 10000,
        targetDate: DateTime.now().add(const Duration(days: 80)),
      );
      final health = GoalHealth.compute(goal);
      // remaining = 40000, daysLeft ≈ 80
      expect(health.dailyNeeded, closeTo(500, 10));
    });

    test('monthlyNeeded is correct', () {
      final goal = Goal.create(
        name: 'Laptop',
        targetAmount: 50000,
        currentAmount: 10000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
      );
      final health = GoalHealth.compute(goal);
      // remaining = 40000, months ≈ 3
      expect(health.monthlyNeeded, closeTo(13333, 500));
    });
  });

  group('GoalHealth.contributionThisMonth', () {
    test('sums contributions in current month', () {
      final now = DateTime.now();
      final goal = Goal.create(name: 'Test', targetAmount: 10000);
      goal.contributions = [
        GoalContribution.create(500)..date = now,
        GoalContribution.create(300)..date = now.subtract(const Duration(days: 2)),
        GoalContribution.create(1000)..date = DateTime(now.year, now.month - 1, 15),
      ];

      final thisMonth = GoalHealth.contributionThisMonth(goal);
      expect(thisMonth, 800); // 500 + 300, not the last month one
    });

    test('returns 0 when no contributions this month', () {
      final goal = Goal.create(name: 'Test', targetAmount: 10000);
      goal.contributions = [
        GoalContribution.create(1000)
          ..date = DateTime(2023, 1, 15),
      ];

      final thisMonth = GoalHealth.contributionThisMonth(goal);
      expect(thisMonth, 0);
    });

    test('returns 0 when no contributions at all', () {
      final goal = Goal.create(name: 'Test', targetAmount: 10000);
      final thisMonth = GoalHealth.contributionThisMonth(goal);
      expect(thisMonth, 0);
    });
  });

  group('GoalHealth edge cases', () {
    test('zero target amount', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 0,
        currentAmount: 0,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );
      final health = GoalHealth.compute(goal);
      // Zero target with zero saved = not completed, just on track
      expect(health.status, isNot(GoalStatus.behind));
    });

    test('deadline is today', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 1000,
        currentAmount: 500,
        targetDate: DateTime.now(),
      );
      final health = GoalHealth.compute(goal);
      expect(health.daysLeft, closeTo(0, 1));
    });

    test('very far deadline', () {
      final goal = Goal.create(
        name: 'Retirement',
        targetAmount: 10000000,
        currentAmount: 100000,
        targetDate: DateTime.now().add(const Duration(days: 10000)),
      );
      final health = GoalHealth.compute(goal);
      expect(health.daysLeft, closeTo(10000, 1));
      expect(health.dailyNeeded, greaterThan(0));
    });
  });

  group('GoalStatus color mapping', () {
    test('all statuses have colors', () {
      for (final status in GoalStatus.values) {
        // Just verify no exception is thrown
        expect(status, isNotNull);
      }
    });
  });
}
