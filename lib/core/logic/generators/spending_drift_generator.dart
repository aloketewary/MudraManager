import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/insight.dart';
import 'package:mudra_manager/core/logic/insight_generator.dart';

/// Categories that are naturally lumpy/seasonal.
/// These produce false positives because they spike predictably.
const _excludedCategories = {
  'Travel',
  'Education',
  'Insurance',
  'Investments',
  'Rent',
  'EMI',
  'Transfer',
  'Salary',
};

/// Detects spending drift using month-to-date comparison.
///
/// Compares current month (day 1 to today) against the same
/// period (day 1 to same day) in previous months.
///
/// No projection. No forecasting. Just: "Are you spending more
/// than usual by this point in the month?"
class SpendingDriftGenerator implements InsightGenerator {
  final String? actionRoute;

  const SpendingDriftGenerator({this.actionRoute});

  @override
  String get source => 'spending_drift';

  @override
  List<Insight> generate(Facts facts) {
    // Drift needs transaction-level data — use generateFromTransactions instead
    return [];
  }

  /// Generates drift insights directly from transactions.
  /// This is a standalone pure function that doesn't depend on the Facts model
  /// because drift detection requires raw transaction history spanning 3+ months.
  static List<Insight> generateFromTransactions(
    List<Transaction> transactions, {
    String? actionRoute,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();

    // Gate: need at least half a month of signal
    if (effectiveNow.day < 15) return [];

    final currentMonthStart =
        DateTime(effectiveNow.year, effectiveNow.month, 1);
    final dayOfMonth = effectiveNow.day;

    final monthStarts = <DateTime>[];
    for (int i = 1; i <= 3; i++) {
      monthStarts
          .add(DateTime(effectiveNow.year, effectiveNow.month - i, 1));
    }

    // Build month-to-date totals per category for each month
    final currentMtd = _categoryTotals(
      transactions,
      from: currentMonthStart,
      throughDay: dayOfMonth,
    );

    final baselineMonthTotals = <Map<String, double>>[];
    for (final start in monthStarts) {
      final totals = _categoryTotals(
        transactions,
        from: start,
        throughDay: dayOfMonth,
      );
      if (totals.isNotEmpty) baselineMonthTotals.add(totals);
    }

    // Require at least 2 baseline months
    if (baselineMonthTotals.length < 2) return [];

    // Average the baseline months (same day-of-month window).
    final baselineAvg = <String, double>{};
    final allCategories = <String>{};
    for (final m in baselineMonthTotals) {
      allCategories.addAll(m.keys);
    }

    for (final cat in allCategories) {
      double sum = 0;
      for (final m in baselineMonthTotals) {
        sum += m[cat] ?? 0;
      }
      baselineAvg[cat] = sum / baselineMonthTotals.length;
    }

    // Find drifts
    final drifts = <_Drift>[];

    for (final entry in currentMtd.entries) {
      final category = entry.key;
      final currentSpend = entry.value;

      if (_excludedCategories.contains(category)) continue;

      final avg = baselineAvg[category];
      if (avg == null || avg < 200) continue;

      final increase = currentSpend - avg;
      final driftPct = increase / avg;

      // Threshold: >30% drift AND >₹1,000 absolute increase
      if (driftPct > 0.30 && increase > 1000) {
        drifts.add(
          _Drift(
            category: category,
            currentSpend: currentSpend,
            baselineAvg: avg,
            increase: increase,
            driftPct: driftPct,
          ),
        );
      }
    }

    if (drifts.isEmpty) return [];

    // Sort by absolute increase (most impactful first)
    drifts.sort((a, b) => b.increase.compareTo(a.increase));

    // Return only top 1 — avoid fatigue
    final top = drifts.first;

    return [
      Insight(
        trigger: BriefingTrigger.spendingDrift,
        source: 'spending_drift',
        magnitude: top.increase,
        confidence: _confidence(dayOfMonth),
        context: {
          'category': top.category,
          'increase': top.increase,
          'driftPercent': top.driftPct,
          'currentSpend': top.currentSpend,
          'baselineAvg': top.baselineAvg,
        },
        actionRoute: actionRoute,
      ),
    ];
  }

  /// Confidence ramps with days elapsed.
  static double _confidence(int dayOfMonth) {
    if (dayOfMonth >= 20) return 0.95;
    if (dayOfMonth >= 15) return 0.8;
    return 0.6;
  }
}

/// Sums expense amounts per category for a given month,
/// only counting transactions from day 1 through [throughDay].
Map<String, double> _categoryTotals(
  List<Transaction> transactions, {
  required DateTime from,
  required int throughDay,
}) {
  final end = DateTime(from.year, from.month, throughDay, 23, 59, 59);
  final totals = <String, double>{};

  for (final t in transactions) {
    if (!t.isExpense || t.isTransfer || t.isSettlement) continue;
    if (t.date.isBefore(from) || t.date.isAfter(end)) continue;

    final catName = t.category.value?.name;
    if (catName == null) continue;

    totals[catName] = (totals[catName] ?? 0) + t.effectiveAmount;
  }

  return totals;
}

class _Drift {
  final String category;
  final double currentSpend;
  final double baselineAvg;
  final double increase;
  final double driftPct;

  _Drift({
    required this.category,
    required this.currentSpend,
    required this.baselineAvg,
    required this.increase,
    required this.driftPct,
  });
}
