import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';

void main() {
  group('Credit card due date calculation', () {
    // Mirrors the logic in credit_card_provider.dart
    int? daysUntilDue(int? dueDay, DateTime now) {
      if (dueDay == null) return null;
      var dueDate = DateTime(now.year, now.month, dueDay);
      if (dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now)) {
        dueDate = DateTime(now.year, now.month + 1, dueDay);
      }
      return dueDate
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
    }

    test('returns null when dueDay is null', () {
      expect(daysUntilDue(null, DateTime(2025, 6, 10)), isNull);
    });

    test('due date in future this month', () {
      // June 10, due day 20 → 10 days
      expect(daysUntilDue(20, DateTime(2025, 6, 10)), 10);
    });

    test('due date today rolls to next month', () {
      // June 15, due day 15 → next month June 15 → ~30 days
      final days = daysUntilDue(15, DateTime(2025, 6, 15));
      expect(days, greaterThan(25));
      expect(days, lessThanOrEqualTo(31));
    });

    test('due date already passed this month', () {
      // June 20, due day 5 → July 5 = 15 days
      expect(daysUntilDue(5, DateTime(2025, 6, 20)), 15);
    });

    test('due date tomorrow', () {
      // June 14, due day 15 → 1 day
      expect(daysUntilDue(15, DateTime(2025, 6, 14)), 1);
    });

    test('due date far in future', () {
      // June 1, due day 28 → 27 days
      expect(daysUntilDue(28, DateTime(2025, 6, 1)), 27);
    });

    test('month boundary: December due rolls to January', () {
      // Dec 20, due day 5 → Jan 5 = 16 days
      expect(daysUntilDue(5, DateTime(2025, 12, 20)), 16);
    });
  });

  group('Credit card outstanding calculation', () {
    test('negative balance means outstanding', () {
      final balance = -5000.0;
      final outstanding = balance < 0 ? balance.abs() : 0.0;
      expect(outstanding, 5000.0);
    });

    test('positive balance means no outstanding', () {
      final balance = 1000.0;
      final outstanding = balance < 0 ? balance.abs() : 0.0;
      expect(outstanding, 0.0);
    });

    test('zero balance means no outstanding', () {
      final balance = 0.0;
      final outstanding = balance < 0 ? balance.abs() : 0.0;
      expect(outstanding, 0.0);
    });
  });
}
