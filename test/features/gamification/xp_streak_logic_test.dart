import 'package:flutter_test/flutter_test.dart';

/// Tests for the XP formula and level-up logic.
/// These test the FORMULAS independently — the service integration
/// is tested in gamification_logic_test.dart.
void main() {
  group('XP Formula: _xpForNext', () {
    // Formula: 100 + (level * level * 25)
    int xpForNext(int level) => 100 + (level * level * 25);

    test('level 1 requires 125 XP', () {
      expect(xpForNext(1), 125);
    });

    test('level 2 requires 200 XP', () {
      expect(xpForNext(2), 200);
    });

    test('level 5 requires 725 XP', () {
      expect(xpForNext(5), 725);
    });

    test('level 10 requires 2600 XP', () {
      expect(xpForNext(10), 2600);
    });

    test('level 20 requires 10100 XP', () {
      expect(xpForNext(20), 10100);
    });

    test('XP requirement increases with level', () {
      for (int i = 1; i < 50; i++) {
        expect(xpForNext(i + 1), greaterThan(xpForNext(i)));
      }
    });
  });

  group('Streak XP: _calculateStreakXP', () {
    // Formula from gamification_service.dart
    int calculateStreakXP(int streak) {
      if (streak >= 100) return 50;
      if (streak >= 30) return 30;
      if (streak >= 7) return 20;
      if (streak >= 3) return 10;
      return 5;
    }

    test('streak 1 gives 5 XP', () {
      expect(calculateStreakXP(1), 5);
    });

    test('streak 2 gives 5 XP', () {
      expect(calculateStreakXP(2), 5);
    });

    test('streak 3 gives 10 XP', () {
      expect(calculateStreakXP(3), 10);
    });

    test('streak 6 gives 10 XP', () {
      expect(calculateStreakXP(6), 10);
    });

    test('streak 7 gives 20 XP', () {
      expect(calculateStreakXP(7), 20);
    });

    test('streak 29 gives 20 XP', () {
      expect(calculateStreakXP(29), 20);
    });

    test('streak 30 gives 30 XP', () {
      expect(calculateStreakXP(30), 30);
    });

    test('streak 99 gives 30 XP', () {
      expect(calculateStreakXP(99), 30);
    });

    test('streak 100 gives 50 XP', () {
      expect(calculateStreakXP(100), 50);
    });

    test('streak 500 gives 50 XP', () {
      expect(calculateStreakXP(500), 50);
    });
  });

  group('Level-up detection', () {
    // Simulates addXP logic
    ({int level, int currentXP}) simulateLevelUp(
      int startLevel,
      int startXP,
      int addedXP,
    ) {
      int xpForNext(int level) => 100 + (level * level * 25);

      int level = startLevel;
      int currentXP = startXP + addedXP;

      while (currentXP >= xpForNext(level)) {
        currentXP -= xpForNext(level);
        level++;
      }

      return (level: level, currentXP: currentXP);
    }

    test('no level up when XP below threshold', () {
      final result = simulateLevelUp(1, 0, 50);
      expect(result.level, 1);
      expect(result.currentXP, 50);
    });

    test('level up from 1 to 2 at 125 XP', () {
      final result = simulateLevelUp(1, 0, 125);
      expect(result.level, 2);
      expect(result.currentXP, 0);
    });

    test('overflow XP carries to next level', () {
      final result = simulateLevelUp(1, 0, 150);
      expect(result.level, 2);
      expect(result.currentXP, 25); // 150 - 125 = 25
    });

    test('double level up possible with large XP', () {
      // Level 1: 125 XP, Level 2: 200 XP. Total for 2 levels = 325
      final result = simulateLevelUp(1, 0, 325);
      expect(result.level, 3);
      expect(result.currentXP, 0);
    });

    test('partial XP at high level', () {
      // Level 10 needs 2600 XP
      final result = simulateLevelUp(10, 2000, 500);
      expect(result.level, 10);
      expect(result.currentXP, 2500);
    });

    test('level up at high level', () {
      // Level 10 needs 2600 XP
      final result = simulateLevelUp(10, 2500, 200);
      // 2500 + 200 = 2700 >= 2600 → level 11, currentXP = 100
      expect(result.level, 11);
      expect(result.currentXP, 100);
    });
  });

  group('Consecutive day detection', () {
    bool isSameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    bool isConsecutiveDay(DateTime last, DateTime now) {
      final d1 = DateTime(last.year, last.month, last.day);
      final d2 = DateTime(now.year, now.month, now.day);
      return d2.difference(d1).inDays == 1;
    }

    test('same day detected', () {
      final a = DateTime(2025, 6, 15, 10, 30);
      final b = DateTime(2025, 6, 15, 22, 45);
      expect(isSameDay(a, b), true);
    });

    test('different day not same', () {
      final a = DateTime(2025, 6, 15);
      final b = DateTime(2025, 6, 16);
      expect(isSameDay(a, b), false);
    });

    test('consecutive days detected', () {
      final a = DateTime(2025, 6, 15);
      final b = DateTime(2025, 6, 16);
      expect(isConsecutiveDay(a, b), true);
    });

    test('same day is not consecutive', () {
      final a = DateTime(2025, 6, 15, 10, 0);
      final b = DateTime(2025, 6, 15, 23, 0);
      expect(isConsecutiveDay(a, b), false);
    });

    test('two days apart is not consecutive', () {
      final a = DateTime(2025, 6, 15);
      final b = DateTime(2025, 6, 17);
      expect(isConsecutiveDay(a, b), false);
    });

    test('month boundary consecutive', () {
      final a = DateTime(2025, 6, 30);
      final b = DateTime(2025, 7, 1);
      expect(isConsecutiveDay(a, b), true);
    });

    test('year boundary consecutive', () {
      final a = DateTime(2025, 12, 31);
      final b = DateTime(2026, 1, 1);
      expect(isConsecutiveDay(a, b), true);
    });
  });

  group('Grace period detection', () {
    bool withinGracePeriod(DateTime last, DateTime now) {
      final d1 = DateTime(last.year, last.month, last.day);
      final d2 = DateTime(now.year, now.month, now.day);
      final daysDiff = d2.difference(d1).inDays;
      final hoursDiff = now.difference(last).inHours;
      return daysDiff == 1 && hoursDiff > 24 && hoursDiff <= 48;
    }

    test('exactly 25 hours apart on consecutive day = grace', () {
      final last = DateTime(2025, 6, 15, 22, 0);
      final now = DateTime(2025, 6, 16, 23, 0); // daysDiff=1, 25h apart
      expect(withinGracePeriod(last, now), true);
    });

    test('23 hours apart on same day = not grace', () {
      final last = DateTime(2025, 6, 15, 1, 0);
      final now = DateTime(2025, 6, 15, 23, 0);
      expect(withinGracePeriod(last, now), false);
    });

    test('49 hours apart = not grace (too late)', () {
      final last = DateTime(2025, 6, 15, 10, 0);
      final now = DateTime(2025, 6, 17, 11, 0); // 49h, but daysDiff=2
      expect(withinGracePeriod(last, now), false);
    });

    test('consecutive day but only 20 hours = not grace (under 24h)', () {
      final last = DateTime(2025, 6, 15, 22, 0);
      final now = DateTime(2025, 6, 16, 18, 0); // daysDiff=1, but only 20h
      expect(withinGracePeriod(last, now), false);
    });
  });
}
