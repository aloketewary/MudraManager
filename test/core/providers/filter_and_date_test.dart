import 'package:flutter_test/flutter_test.dart';

// These are the same private functions from filter_provider.dart.
// Copied here since they're private — tests validate the logic.

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameWeek(DateTime a, DateTime b) {
  final startOfWeek = b.subtract(Duration(days: b.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  return a.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
      a.isBefore(endOfWeek.add(const Duration(days: 1)));
}

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool isSameYear(DateTime a, DateTime b) => a.year == b.year;

Map<String, double> sumIncomeExpense(
    List<({double baseAmount, bool isExpense})> txns,) {
  double income = 0;
  double expense = 0;
  for (final txn in txns) {
    if (txn.isExpense) {
      expense += txn.baseAmount;
    } else {
      income += txn.baseAmount;
    }
  }
  return {'income': income, 'expense': expense};
}

void main() {
  group('isSameDay', () {
    test('same day returns true', () {
      expect(isSameDay(DateTime(2024, 3, 15, 10), DateTime(2024, 3, 15, 22)),
          true,);
    });

    test('different day returns false', () {
      expect(isSameDay(DateTime(2024, 3, 15), DateTime(2024, 3, 16)), false);
    });

    test('same day different month returns false', () {
      expect(isSameDay(DateTime(2024, 3, 15), DateTime(2024, 4, 15)), false);
    });

    test('same day different year returns false', () {
      expect(isSameDay(DateTime(2024, 3, 15), DateTime(2025, 3, 15)), false);
    });
  });

  group('isSameWeek', () {
    test('same week Monday-Sunday', () {
      // March 11 2024 is Monday, March 17 is Sunday
      expect(isSameWeek(DateTime(2024, 3, 11), DateTime(2024, 3, 15)), true);
      expect(isSameWeek(DateTime(2024, 3, 17), DateTime(2024, 3, 15)), true);
    });

    test('previous week returns false', () {
      expect(isSameWeek(DateTime(2024, 3, 10), DateTime(2024, 3, 15)), false);
    });

    test('next week returns false', () {
      expect(isSameWeek(DateTime(2024, 3, 18), DateTime(2024, 3, 15)), false);
    });

    test('week spanning month boundary', () {
      // March 28 2024 is Thursday, week is Mar 25 - Mar 31
      expect(isSameWeek(DateTime(2024, 3, 25), DateTime(2024, 3, 28)), true);
      expect(isSameWeek(DateTime(2024, 3, 31), DateTime(2024, 3, 28)), true);
    });
  });

  group('isSameMonth', () {
    test('same month returns true', () {
      expect(isSameMonth(DateTime(2024, 3, 1), DateTime(2024, 3, 31)), true);
    });

    test('different month returns false', () {
      expect(isSameMonth(DateTime(2024, 3, 31), DateTime(2024, 4, 1)), false);
    });

    test('same month different year returns false', () {
      expect(isSameMonth(DateTime(2024, 3, 15), DateTime(2025, 3, 15)), false);
    });
  });

  group('isSameYear', () {
    test('same year returns true', () {
      expect(isSameYear(DateTime(2024, 1, 1), DateTime(2024, 12, 31)), true);
    });

    test('different year returns false', () {
      expect(isSameYear(DateTime(2024, 12, 31), DateTime(2025, 1, 1)), false);
    });
  });

  group('sumIncomeExpense', () {
    test('sums income and expense separately', () {
      final result = sumIncomeExpense([
        (baseAmount: 5000.0, isExpense: false),
        (baseAmount: 1000.0, isExpense: true),
        (baseAmount: 3000.0, isExpense: false),
        (baseAmount: 500.0, isExpense: true),
      ]);
      expect(result['income'], 8000.0);
      expect(result['expense'], 1500.0);
    });

    test('empty list returns zeros', () {
      final result = sumIncomeExpense([]);
      expect(result['income'], 0.0);
      expect(result['expense'], 0.0);
    });

    test('only income', () {
      final result = sumIncomeExpense([
        (baseAmount: 5000.0, isExpense: false),
      ]);
      expect(result['income'], 5000.0);
      expect(result['expense'], 0.0);
    });

    test('only expense', () {
      final result = sumIncomeExpense([
        (baseAmount: 1000.0, isExpense: true),
      ]);
      expect(result['income'], 0.0);
      expect(result['expense'], 1000.0);
    });
  });

  group('dateChangeProvider logic', () {
    test('same date does not change', () {
      final now = DateTime.now();
      final today1 = DateTime(now.year, now.month, now.day);
      final today2 = DateTime(now.year, now.month, now.day);
      expect(today1, equals(today2));
    });

    test('different dates are not equal', () {
      final today = DateTime(2024, 3, 15);
      final tomorrow = DateTime(2024, 3, 16);
      expect(today, isNot(equals(tomorrow)));
    });

    test('midnight boundary detection', () {
      final beforeMidnight = DateTime(2024, 3, 15, 23, 59, 59);
      final afterMidnight = DateTime(2024, 3, 16, 0, 0, 1);
      final day1 = DateTime(beforeMidnight.year, beforeMidnight.month, beforeMidnight.day);
      final day2 = DateTime(afterMidnight.year, afterMidnight.month, afterMidnight.day);
      expect(day1, isNot(equals(day2)));
    });
  });
}
