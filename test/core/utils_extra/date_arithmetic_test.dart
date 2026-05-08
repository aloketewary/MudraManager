import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

void main() {
  group('addMonths — month-end clamping', () {
    test('Jan 31 + 1 month = Feb 28 (non-leap)', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 1, 31), 1);
      expect(result, equals(DateTime(2025, 2, 28)));
    });

    test('Jan 31 + 1 month = Feb 29 (leap year)', () {
      final result = DateArithmetic.addMonths(DateTime(2024, 1, 31), 1);
      expect(result, equals(DateTime(2024, 2, 29)));
    });

    test('Mar 31 + 1 month = Apr 30', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 3, 31), 1);
      expect(result, equals(DateTime(2025, 4, 30)));
    });

    test('Jan 15 + 1 month = Feb 15 (no clamping needed)', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 1, 15), 1);
      expect(result, equals(DateTime(2025, 2, 15)));
    });

    test('Dec + 1 month = Jan next year', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 12, 15), 1);
      expect(result, equals(DateTime(2026, 1, 15)));
    });

    test('Jan + 12 months = Jan next year', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 1, 31), 12);
      expect(result, equals(DateTime(2026, 1, 31)));
    });

    test('Feb 28 + 1 month = Mar 28 (not Mar 31)', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 2, 28), 1);
      expect(result, equals(DateTime(2025, 3, 28)));
    });
  });

  group('addMonths — preferDay', () {
    test('preferDay 31 restores to month end', () {
      // Feb 28 + 1 month with preferDay 31 → Mar 31
      final result = DateArithmetic.addMonths(
        DateTime(2025, 2, 28),
        1,
        preferDay: 31,
      );
      expect(result, equals(DateTime(2025, 3, 31)));
    });

    test('preferDay 31 clamps in April', () {
      final result = DateArithmetic.addMonths(
        DateTime(2025, 3, 31),
        1,
        preferDay: 31,
      );
      expect(result, equals(DateTime(2025, 4, 30)));
    });

    test('preferDay 15 always lands on 15', () {
      final result = DateArithmetic.addMonths(
        DateTime(2025, 1, 31),
        1,
        preferDay: 15,
      );
      expect(result, equals(DateTime(2025, 2, 15)));
    });
  });

  group('subtractMonths', () {
    test('Mar 31 - 1 month = Feb 28', () {
      final result = DateArithmetic.subtractMonths(DateTime(2025, 3, 31), 1);
      expect(result, equals(DateTime(2025, 2, 28)));
    });

    test('Jan 15 - 1 month = Dec 15 previous year', () {
      final result = DateArithmetic.subtractMonths(DateTime(2025, 1, 15), 1);
      expect(result, equals(DateTime(2024, 12, 15)));
    });

    test('Mar 31 - 1 month = Feb 29 (leap year)', () {
      final result = DateArithmetic.subtractMonths(DateTime(2024, 3, 31), 1);
      expect(result, equals(DateTime(2024, 2, 29)));
    });
  });

  group('addYears', () {
    test('Feb 29 + 1 year = Feb 28 (non-leap)', () {
      final result = DateArithmetic.addYears(DateTime(2024, 2, 29), 1);
      expect(result, equals(DateTime(2025, 2, 28)));
    });

    test('Feb 29 + 4 years = Feb 29 (leap)', () {
      final result = DateArithmetic.addYears(DateTime(2024, 2, 29), 4);
      expect(result, equals(DateTime(2028, 2, 29)));
    });

    test('Jan 1 + 1 year = Jan 1', () {
      final result = DateArithmetic.addYears(DateTime(2025, 1, 1), 1);
      expect(result, equals(DateTime(2026, 1, 1)));
    });
  });

  group('edge cases', () {
    test('add 0 months returns same date', () {
      final date = DateTime(2025, 6, 15);
      expect(DateArithmetic.addMonths(date, 0), equals(date));
    });

    test('add negative months goes backward', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 3, 15), -2);
      expect(result, equals(DateTime(2025, 1, 15)));
    });

    test('add 24 months = 2 years', () {
      final result = DateArithmetic.addMonths(DateTime(2025, 1, 31), 24);
      expect(result, equals(DateTime(2027, 1, 31)));
    });
  });
}
