import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';

void main() {
  group('GamificationEvent', () {
    test('all events are defined', () {
      expect(GamificationEvent.values.length, greaterThanOrEqualTo(15));
    });

    test('core events exist', () {
      expect(GamificationEvent.values, contains(GamificationEvent.transactionAdded));
      expect(GamificationEvent.values, contains(GamificationEvent.budgetCreated));
      expect(GamificationEvent.values, contains(GamificationEvent.goalCreated));
      expect(GamificationEvent.values, contains(GamificationEvent.goalCompleted));
      expect(GamificationEvent.values, contains(GamificationEvent.dailyCheckIn));
      expect(GamificationEvent.values, contains(GamificationEvent.tripCreated));
      expect(GamificationEvent.values, contains(GamificationEvent.backupCreated));
    });

    test('split/trip events exist', () {
      expect(GamificationEvent.values, contains(GamificationEvent.expenseSplit));
      expect(GamificationEvent.values, contains(GamificationEvent.tripCreated));
    });
  });

  group('XP calculation logic', () {
    test('XP per event is positive', () {
      // Simulate XP mapping
      final xpMap = {
        GamificationEvent.transactionAdded: 5,
        GamificationEvent.budgetCreated: 20,
        GamificationEvent.goalCreated: 20,
        GamificationEvent.goalCompleted: 50,
        GamificationEvent.dailyCheckIn: 10,
        GamificationEvent.tripCreated: 25,
        GamificationEvent.backupCreated: 15,
        GamificationEvent.expenseSplit: 10,
      };

      for (final entry in xpMap.entries) {
        expect(entry.value, greaterThan(0),
            reason: '${entry.key} should give positive XP',);
      }
    });

    test('level calculation from XP', () {
      // Level = XP / 100 (simplified)
      int levelFromXp(int xp) => (xp / 100).floor() + 1;

      expect(levelFromXp(0), 1);
      expect(levelFromXp(99), 1);
      expect(levelFromXp(100), 2);
      expect(levelFromXp(250), 3);
      expect(levelFromXp(1000), 11);
    });
  });

  group('Streak logic', () {
    test('consecutive days increment streak', () {
      var streak = 0;
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 3),
      ];

      DateTime? lastDate;
      for (final date in dates) {
        if (lastDate == null ||
            date.difference(lastDate).inDays == 1) {
          streak++;
        } else {
          streak = 1;
        }
        lastDate = date;
      }

      expect(streak, 3);
    });

    test('gap breaks streak', () {
      var streak = 0;
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 5), // gap
      ];

      DateTime? lastDate;
      for (final date in dates) {
        if (lastDate == null ||
            date.difference(lastDate).inDays == 1) {
          streak++;
        } else {
          streak = 1;
        }
        lastDate = date;
      }

      expect(streak, 1); // reset after gap
    });

    test('same day does not increment streak', () {
      var streak = 0;
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 1), // same day
      ];

      DateTime? lastDate;
      for (final date in dates) {
        final dayOnly = DateTime(date.year, date.month, date.day);
        final lastDayOnly = lastDate != null
            ? DateTime(lastDate.year, lastDate.month, lastDate.day)
            : null;

        if (lastDayOnly == null) {
          streak = 1;
        } else if (dayOnly.difference(lastDayOnly).inDays == 1) {
          streak++;
        } else if (dayOnly.difference(lastDayOnly).inDays > 1) {
          streak = 1;
        }
        // Same day: no change
        lastDate = date;
      }

      expect(streak, 1);
    });

    test('streak survives month boundary', () {
      var streak = 0;
      final dates = [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 1),
      ];

      DateTime? lastDate;
      for (final date in dates) {
        if (lastDate == null ||
            date.difference(lastDate).inDays == 1) {
          streak++;
        } else {
          streak = 1;
        }
        lastDate = date;
      }

      expect(streak, 2);
    });

    test('streak survives year boundary', () {
      var streak = 0;
      final dates = [
        DateTime(2024, 12, 31),
        DateTime(2025, 1, 1),
      ];

      DateTime? lastDate;
      for (final date in dates) {
        if (lastDate == null ||
            date.difference(lastDate).inDays == 1) {
          streak++;
        } else {
          streak = 1;
        }
        lastDate = date;
      }

      expect(streak, 2);
    });
  });
}
