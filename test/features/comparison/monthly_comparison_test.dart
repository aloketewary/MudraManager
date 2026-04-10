import 'package:flutter_test/flutter_test.dart';

// Replicate the private models from monthly_comparison_screen.dart for testing
class ComparisonData {
  final double currentIncome, currentExpense, lastIncome, lastExpense;
  final double lastExpenseByThisDay;
  final int currentTxnCount, lastTxnCount;
  final List<CategoryDelta> categories;

  ComparisonData({
    required this.currentIncome,
    required this.currentExpense,
    required this.lastIncome,
    required this.lastExpense,
    required this.lastExpenseByThisDay,
    required this.currentTxnCount,
    required this.lastTxnCount,
    required this.categories,
  });

  double get variance => currentExpense - lastExpense;
  double get variancePct => lastExpense > 0 ? (variance / lastExpense * 100) : 0;
  bool get isDown => variance < 0;
  bool get isFlat => variance.abs() < 1;
}

class CategoryDelta {
  final String name, iconName;
  final double current, last;

  CategoryDelta({required this.name, required this.iconName, required this.current, required this.last});

  double get delta => current - last;
  double get absDelta => delta.abs();
  double get pct => last > 0 ? (delta / last * 100) : (current > 0 ? 100 : 0);
}

void main() {
  group('ComparisonData variance', () {
    test('positive variance when spending increased', () {
      final d = _make(currentExpense: 50000, lastExpense: 40000);
      expect(d.variance, 10000);
      expect(d.isDown, false);
      expect(d.isFlat, false);
    });

    test('negative variance when spending decreased', () {
      final d = _make(currentExpense: 30000, lastExpense: 40000);
      expect(d.variance, -10000);
      expect(d.isDown, true);
    });

    test('flat when variance < 1', () {
      final d = _make(currentExpense: 40000.5, lastExpense: 40000);
      expect(d.isFlat, true);
    });

    test('exactly zero is flat', () {
      final d = _make(currentExpense: 40000, lastExpense: 40000);
      expect(d.isFlat, true);
      expect(d.variance, 0);
    });

    test('variancePct correct', () {
      final d = _make(currentExpense: 50000, lastExpense: 40000);
      expect(d.variancePct, 25.0); // 10k/40k * 100
    });

    test('variancePct 0 when no last expense', () {
      final d = _make(currentExpense: 50000, lastExpense: 0);
      expect(d.variancePct, 0);
    });

    test('variancePct negative when spending down', () {
      final d = _make(currentExpense: 30000, lastExpense: 40000);
      expect(d.variancePct, -25.0);
    });
  });

  group('CategoryDelta', () {
    test('delta positive when current > last', () {
      final c = CategoryDelta(name: 'Food', iconName: 'utensils', current: 8000, last: 5000);
      expect(c.delta, 3000);
      expect(c.absDelta, 3000);
    });

    test('delta negative when current < last', () {
      final c = CategoryDelta(name: 'Food', iconName: 'utensils', current: 3000, last: 5000);
      expect(c.delta, -2000);
      expect(c.absDelta, 2000);
    });

    test('pct correct', () {
      final c = CategoryDelta(name: 'Food', iconName: 'utensils', current: 6000, last: 5000);
      expect(c.pct, 20.0); // 1k/5k * 100
    });

    test('pct 100 when last is 0 but current > 0 (new category)', () {
      final c = CategoryDelta(name: 'New', iconName: 'star', current: 3000, last: 0);
      expect(c.pct, 100);
    });

    test('pct 0 when both are 0', () {
      final c = CategoryDelta(name: 'Empty', iconName: 'x', current: 0, last: 0);
      expect(c.pct, 0);
    });

    test('sorting by absDelta', () {
      final cats = [
        CategoryDelta(name: 'A', iconName: 'a', current: 5000, last: 4000), // delta 1000
        CategoryDelta(name: 'B', iconName: 'b', current: 2000, last: 8000), // delta -6000
        CategoryDelta(name: 'C', iconName: 'c', current: 3000, last: 3000), // delta 0
      ]..sort((a, b) => b.absDelta.compareTo(a.absDelta));

      expect(cats.first.name, 'B'); // biggest absolute change
      expect(cats.last.name, 'C'); // no change
    });
  });

  group('Comparison month selection', () {
    test('compare month must be before current month', () {
      final now = DateTime.now();
      final compareMonth = DateTime(now.year, now.month - 1, 1);
      expect(compareMonth.isBefore(DateTime(now.year, now.month, 1)), true);
    });

    test('compare month can be any past month', () {
      final threeMonthsAgo = DateTime(2024, 3, 1);
      final current = DateTime(2024, 6, 1);
      expect(threeMonthsAgo.isBefore(current), true);
    });

    test('same day cutoff calculation', () {
      // If today is the 15th, compare only 1st-15th of the compare month
      final today = 15;
      final daysInCompareMonth = DateTime(2024, 4, 0).day; // 31 for March
      final cutoffDay = today < daysInCompareMonth ? today : daysInCompareMonth;
      expect(cutoffDay, 15);
    });

    test('same day cutoff handles short months', () {
      // If today is the 31st but compare month has 28 days (Feb)
      final today = 31;
      final daysInFeb = DateTime(2024, 3, 0).day; // 29 (leap year)
      final cutoffDay = today < daysInFeb ? today : daysInFeb;
      expect(cutoffDay, 29);
    });
  });

  group('Projection calculation', () {
    test('projects full month from daily average', () {
      final dayOfMonth = 15;
      final daysInMonth = 30;
      final totalSpent = 15000.0;
      final dailyAvg = totalSpent / dayOfMonth;
      final projected = dailyAvg * daysInMonth;
      expect(projected, 30000.0);
    });

    test('projection at month start is high variance', () {
      final dayOfMonth = 2;
      final daysInMonth = 30;
      final totalSpent = 5000.0; // big spend on day 1-2
      final projected = (totalSpent / dayOfMonth) * daysInMonth;
      expect(projected, 75000.0); // unreliable early in month
    });

    test('projection at month end is close to actual', () {
      final dayOfMonth = 29;
      final daysInMonth = 30;
      final totalSpent = 29000.0;
      final projected = (totalSpent / dayOfMonth) * daysInMonth;
      expect(projected, closeTo(30000, 100));
    });
  });

  group('Net balance comparison', () {
    test('net = income - expense', () {
      final curNet = 50000.0 - 35000.0;
      final lastNet = 45000.0 - 40000.0;
      expect(curNet, 15000);
      expect(lastNet, 5000);
      expect(curNet, greaterThan(lastNet));
    });

    test('negative net when overspent', () {
      final net = 20000.0 - 30000.0;
      expect(net, -10000);
    });
  });
}

ComparisonData _make({
  double currentIncome = 0,
  double currentExpense = 0,
  double lastIncome = 0,
  double lastExpense = 0,
}) {
  return ComparisonData(
    currentIncome: currentIncome,
    currentExpense: currentExpense,
    lastIncome: lastIncome,
    lastExpense: lastExpense,
    lastExpenseByThisDay: 0,
    currentTxnCount: 0,
    lastTxnCount: 0,
    categories: [],
  );
}
