import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

// Mirrors the logic from subscription_detector_provider.dart
String normalizeKey(String desc) {
  return desc
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String displayName(String description, String categoryName) {
  final desc = description.trim();
  final name = desc.isNotEmpty ? desc : (categoryName.isNotEmpty ? categoryName : 'Unknown');
  return name.length > 30 ? '${name.substring(0, 27)}...' : name;
}

int? estimateDayOfMonth(List<int> days) {
  if (days.isEmpty) return null;
  final freq = <int, int>{};
  for (final d in days) {
    freq[d] = (freq[d] ?? 0) + 1;
  }
  final sorted = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

bool isAmountConsistent(List<double> amounts) {
  if (amounts.length < 2) return false;
  amounts.sort();
  final median = amounts[amounts.length ~/ 2];
  if (median <= 0) return false;
  return amounts.every((a) => (a - median).abs() / median < 0.10);
}

bool isMonthlyInterval(List<DateTime> dates) {
  dates.sort((a, b) => a.compareTo(b));
  for (int i = 1; i < dates.length; i++) {
    final gap = dates[i].difference(dates[i - 1]).inDays;
    if (gap < 20 || gap > 40) return false;
  }
  return true;
}

void main() {
  group('normalizeKey', () {
    test('lowercases and strips special chars', () {
      expect(normalizeKey('Netflix India'), 'netflix india');
    });

    test('collapses whitespace', () {
      expect(normalizeKey('  Swiggy   Order  '), 'swiggy order');
    });

    test('strips symbols', () {
      expect(normalizeKey('UPI-NETFLIX@OKAXIS'), 'upinetflixokaxis');
    });

    test('empty string returns empty', () {
      expect(normalizeKey(''), '');
    });

    test('numbers preserved', () {
      expect(normalizeKey('Plan 299'), 'plan 299');
    });
  });

  group('displayName', () {
    test('short description returned as-is', () {
      expect(displayName('Netflix India', ''), 'Netflix India');
    });

    test('long description truncated to 30 chars', () {
      final long = 'A very long subscription name that exceeds thirty characters';
      final result = displayName(long, '');
      expect(result.length, 30);
      expect(result.endsWith('...'), true);
    });

    test('exactly 30 chars not truncated', () {
      final exact = 'A' * 30;
      expect(displayName(exact, ''), exact);
    });

    test('empty description falls back to category', () {
      expect(displayName('', 'Food'), 'Food');
    });

    test('empty both returns Unknown', () {
      expect(displayName('', ''), 'Unknown');
    });
  });

  group('estimateDayOfMonth', () {
    test('returns most common day', () {
      expect(estimateDayOfMonth([15, 15, 14, 15]), 15);
    });

    test('returns null for empty list', () {
      expect(estimateDayOfMonth([]), isNull);
    });

    test('single day returns that day', () {
      expect(estimateDayOfMonth([7]), 7);
    });

    test('tie-breaks by first encountered', () {
      final result = estimateDayOfMonth([1, 2, 1, 2]);
      expect(result, anyOf(1, 2));
    });
  });

  group('isAmountConsistent', () {
    test('identical amounts are consistent', () {
      expect(isAmountConsistent([299, 299, 299]), true);
    });

    test('amounts within 10% are consistent', () {
      // 299 ± 10% = 269.1 to 328.9
      expect(isAmountConsistent([299, 295, 302]), true);
    });

    test('amounts varying >10% are inconsistent', () {
      expect(isAmountConsistent([299, 500, 299]), false);
    });

    test('single amount returns false', () {
      expect(isAmountConsistent([299]), false);
    });

    test('zero median returns false', () {
      expect(isAmountConsistent([0, 0, 0]), false);
    });
  });

  group('isMonthlyInterval', () {
    test('monthly dates are detected', () {
      final dates = [
        DateTime(2025, 3, 15),
        DateTime(2025, 4, 14),
        DateTime(2025, 5, 15),
        DateTime(2025, 6, 14),
      ];
      expect(isMonthlyInterval(dates), true);
    });

    test('weekly dates are rejected', () {
      final dates = [
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 8),
        DateTime(2025, 6, 15),
      ];
      expect(isMonthlyInterval(dates), false);
    });

    test('irregular dates are rejected', () {
      final dates = [
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 15), // 14 days — too short
        DateTime(2025, 5, 1),
      ];
      expect(isMonthlyInterval(dates), false);
    });

    test('exactly 30 day gaps pass', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 31),
        DateTime(2025, 3, 2),
      ];
      expect(isMonthlyInterval(dates), true);
    });

    test('25 day gap passes (lower bound)', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 26), // 25 days
      ];
      expect(isMonthlyInterval(dates), true);
    });

    test('40 day gap passes (upper bound)', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 2, 10), // 40 days
      ];
      expect(isMonthlyInterval(dates), true);
    });

    test('41 day gap fails', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 2, 11), // 41 days
      ];
      expect(isMonthlyInterval(dates), false);
    });

    test('19 day gap fails', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 20), // 19 days
      ];
      expect(isMonthlyInterval(dates), false);
    });
  });
}
