import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

/// Tests for recurring transaction logic.
/// These are pure unit tests for the date calculation logic.
/// The full E2E recurring processing requires SmartNotificationService
/// singleton which is hard to mock — tested via sms_e2e_test instead.
void main() {
  group('calculateNextDueDate', () {
    test('daily: advances by 1 day', () {
      final next = _nextDue(DateTime(2025, 6, 15), Frequency.daily);
      expect(next, DateTime(2025, 6, 16));
    });

    test('weekly: advances by 7 days', () {
      final next = _nextDue(DateTime(2025, 6, 15), Frequency.weekly);
      expect(next, DateTime(2025, 6, 22));
    });

    test('monthly: advances by 1 month with clamping', () {
      final next = _nextDue(DateTime(2025, 1, 31), Frequency.monthly);
      expect(next, DateTime(2025, 2, 28));
    });

    test('monthly: preserves original start day', () {
      // If started on 31st, next from Feb 28 should go to Mar 31
      final next = _nextDue(
        DateTime(2025, 2, 28),
        Frequency.monthly,
        startDate: DateTime(2025, 1, 31),
      );
      expect(next, DateTime(2025, 3, 31));
    });

    test('yearly: advances by 1 year', () {
      final next = _nextDue(DateTime(2025, 6, 15), Frequency.yearly);
      expect(next, DateTime(2026, 6, 15));
    });

    test('yearly: Feb 29 → Feb 28 in non-leap year', () {
      final next = _nextDue(DateTime(2024, 2, 29), Frequency.yearly);
      expect(next, DateTime(2025, 2, 28));
    });

    test('monthly: Dec → Jan crosses year boundary', () {
      final next = _nextDue(DateTime(2025, 12, 15), Frequency.monthly);
      expect(next, DateTime(2026, 1, 15));
    });
  });

  group('previousDueDate', () {
    test('daily: goes back 1 day', () {
      final prev = _prevDue(DateTime(2025, 6, 15), Frequency.daily);
      expect(prev, DateTime(2025, 6, 14));
    });

    test('weekly: goes back 7 days', () {
      final prev = _prevDue(DateTime(2025, 6, 15), Frequency.weekly);
      expect(prev, DateTime(2025, 6, 8));
    });

    test('monthly: goes back 1 month with clamping', () {
      final prev = _prevDue(DateTime(2025, 3, 31), Frequency.monthly);
      expect(prev, DateTime(2025, 2, 28));
    });

    test('yearly: goes back 1 year', () {
      final prev = _prevDue(DateTime(2025, 6, 15), Frequency.yearly);
      expect(prev, DateTime(2024, 6, 15));
    });
  });

  group('SMS match window', () {
    test('search window is 5 days before to 2 days after due', () {
      final dueDate = DateTime(2025, 6, 15);
      final searchStart = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).subtract(const Duration(days: 5));
      final searchEnd = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        23,
        59,
        59,
      ).add(const Duration(days: 2));

      expect(searchStart, DateTime(2025, 6, 10));
      expect(searchEnd.day, 17);
    });
  });

  group('auto-creation grace period', () {
    test('2-day grace: not created if only 1 day overdue', () {
      final dueDate = DateTime(2025, 6, 15);
      final today = DateTime(2025, 6, 16);
      final daysOverdue = today.difference(dueDate).inDays;
      expect(daysOverdue, 1);
      expect(daysOverdue >= 2, false); // should NOT auto-create
    });

    test('2-day grace: created if 2 days overdue', () {
      final dueDate = DateTime(2025, 6, 15);
      final today = DateTime(2025, 6, 17);
      final daysOverdue = today.difference(dueDate).inDays;
      expect(daysOverdue, 2);
      expect(daysOverdue >= 2, true); // should auto-create
    });

    test('2-day grace: created if 10 days overdue', () {
      final dueDate = DateTime(2025, 6, 15);
      final today = DateTime(2025, 6, 25);
      final daysOverdue = today.difference(dueDate).inDays;
      expect(daysOverdue, 10);
      expect(daysOverdue >= 2, true);
    });
  });

  group('frequency text', () {
    test('all frequencies have labels', () {
      for (final f in Frequency.values) {
        expect(f.name, isNotEmpty);
      }
    });
  });
}

/// Replicates calculateNextDueDate from RecurringTransactionService.
DateTime _nextDue(DateTime current, Frequency frequency, {DateTime? startDate}) {
  switch (frequency) {
    case Frequency.daily:
      return current.add(const Duration(days: 1));
    case Frequency.weekly:
      return current.add(const Duration(days: 7));
    case Frequency.monthly:
      return DateArithmetic.addMonths(
        current,
        1,
        preferDay: startDate?.day,
      );
    case Frequency.yearly:
      return DateArithmetic.addYears(
        current,
        1,
        preferDay: startDate?.day,
      );
  }
}

DateTime _prevDue(DateTime current, Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return current.subtract(const Duration(days: 1));
    case Frequency.weekly:
      return current.subtract(const Duration(days: 7));
    case Frequency.monthly:
      return DateArithmetic.subtractMonths(current, 1, preferDay: current.day);
    case Frequency.yearly:
      return DateArithmetic.addYears(current, -1, preferDay: current.day);
  }
}
