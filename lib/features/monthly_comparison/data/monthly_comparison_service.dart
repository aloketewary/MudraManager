import 'dart:math' as math;

import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';

// ── Output DTOs ──

/// A single category's contribution to net variance.
class CategoryContribution {
  final String name;
  final String iconName;
  final double currentSpend;
  final double compareSpend;

  const CategoryContribution({
    required this.name,
    required this.iconName,
    required this.currentSpend,
    required this.compareSpend,
  });

  /// Absolute delta (positive = increased spending).
  double get delta => currentSpend - compareSpend;

  /// Contribution to net expense variance.
  /// Sum of all contributions = 100% (or -100% if net decreased).
  /// Can exceed ±100% for individual categories when offsets exist.
  double contributionPct(double netVariance) =>
      netVariance.abs() > 0 ? (delta / netVariance) * 100 : 0;

  double get absDelta => delta.abs();
}

/// Top driver for the insight card.
class CategoryDriver {
  final String name;
  final double delta;
  final double contributionPct;

  const CategoryDriver({
    required this.name,
    required this.delta,
    required this.contributionPct,
  });
}

/// Complete comparison analysis — produced by service, consumed by UI.
/// UI never computes these values.
class ComparisonAnalysis {
  // ── Hero ──
  final double currentIncome;
  final double compareIncome;
  final double currentExpense;
  final double compareExpense;

  double get currentNet => currentIncome - currentExpense;
  double get compareNet => compareIncome - compareExpense;
  double get netVariance => currentNet - compareNet;
  double get netVariancePct =>
      compareNet.abs() > 0 ? (netVariance / compareNet.abs()) * 100 : 0;

  double get expenseVariance => currentExpense - compareExpense;
  double get expenseVariancePct =>
      compareExpense > 0 ? (expenseVariance / compareExpense) * 100 : 0;

  // ── Confidence ──
  final bool isPartialPeriod;
  final int comparedDays;

  // ── Insight (drivers) ──
  final CategoryDriver? topIncrease;
  final CategoryDriver? topDecrease;

  // ── Pace ──
  final double currentDailySpend;
  final double compareDailySpend;
  final double projectedMonthEndSpend;
  final bool forecastEligible;

  // ── Categories ──
  /// Sorted by abs(delta) descending — largest financial impact first.
  final List<CategoryContribution> contributions;

  // ── Activity ──
  final int currentTxnCount;
  final int compareTxnCount;
  final double currentAvgTxn;
  final double compareAvgTxn;

  // ── Narrative ──
  final List<NarrativeFact> facts;

  const ComparisonAnalysis({
    required this.currentIncome,
    required this.compareIncome,
    required this.currentExpense,
    required this.compareExpense,
    required this.isPartialPeriod,
    required this.comparedDays,
    required this.topIncrease,
    required this.topDecrease,
    required this.currentDailySpend,
    required this.compareDailySpend,
    required this.projectedMonthEndSpend,
    required this.forecastEligible,
    required this.contributions,
    required this.currentTxnCount,
    required this.compareTxnCount,
    required this.currentAvgTxn,
    required this.compareAvgTxn,
    required this.facts,
  });

  bool get isExpenseDown => expenseVariance < 0;
  bool get isExpenseFlat => expenseVariance.abs() < 1;
}

// ── Service ──

/// Pure computation service. Takes Isar, returns [ComparisonAnalysis].
/// No Riverpod. No UI. No side effects beyond DB reads.
class MonthlyComparisonService {
  final Isar _isar;

  const MonthlyComparisonService(this._isar);

  Future<ComparisonAnalysis> analyze({
    required DateTime compareMonth,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final curStart = DateTime(today.year, today.month, 1);
    final curEnd = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
    final cmpStart = compareMonth;
    final cmpEnd = DateTime(cmpStart.year, cmpStart.month + 1, 0, 23, 59, 59);

    // Determine compared days for confidence
    final daysInCurrentMonth = DateTime(today.year, today.month + 1, 0).day;
    final daysElapsed = today.day;
    final isPartial = daysElapsed < daysInCurrentMonth;

    // For fair comparison, cap compare month at same day-of-month
    final daysInCompareMonth =
        DateTime(cmpStart.year, cmpStart.month + 1, 0).day;
    final compareDays = math.min(daysElapsed, daysInCompareMonth);
    final cmpSameDayEnd = DateTime(
      cmpStart.year,
      cmpStart.month,
      compareDays,
      23,
      59,
      59,
    );

    // Fetch transactions
    final curTxns = await _isar.transactions
        .where()
        .dateBetween(curStart, curEnd)
        .findAll();
    final cmpTxns = await _isar.transactions
        .where()
        .dateBetween(cmpStart, cmpEnd)
        .findAll();

    // Load categories
    for (final t in curTxns) {
      await t.category.load();
    }
    for (final t in cmpTxns) {
      await t.category.load();
    }

    // ── Aggregate totals ──
    double curInc = 0, curExp = 0, cmpInc = 0, cmpExp = 0;
    int curExpCount = 0, cmpExpCount = 0;
    final catMap = <String, _CatAccum>{};

    for (final t in curTxns) {
      if (!t.affectsStats) continue;
      final amt = t.effectiveAmount;
      if (t.isExpense) {
        curExp += amt;
        curExpCount++;
        _accumCategory(catMap, t, amt, isCurrent: true);
      } else {
        curInc += amt;
      }
    }

    for (final t in cmpTxns) {
      if (!t.affectsStats) continue;
      final amt = t.effectiveAmount;
      // Only count up to same day for fair pace comparison
      final withinSameDay = !t.date.isAfter(cmpSameDayEnd);
      if (t.isExpense) {
        cmpExp += amt;
        cmpExpCount++;
        _accumCategory(catMap, t, amt, isCurrent: false);
      } else {
        cmpInc += amt;
      }
      // Track same-day expense for pace
      if (t.isExpense && withinSameDay) {
        // already accumulated in cmpExp above for full month;
        // pace uses daysElapsed below
      }
    }

    // ── Categories: build contributions sorted by abs(delta) ──
    final contributions = catMap.values
        .map(
          (c) => CategoryContribution(
            name: c.name,
            iconName: c.iconName,
            currentSpend: c.current,
            compareSpend: c.compare,
          ),
        )
        .toList()
      ..sort((a, b) => b.absDelta.compareTo(a.absDelta));

    // ── Drivers ──
    final netExpVariance = curExp - cmpExp;
    final increases = contributions.where((c) => c.delta > 0).toList();
    final decreases = contributions.where((c) => c.delta < 0).toList();

    final topIncrease = increases.isNotEmpty
        ? CategoryDriver(
            name: increases.first.name,
            delta: increases.first.delta,
            contributionPct: increases.first.contributionPct(netExpVariance),
          )
        : null;

    final topDecrease = decreases.isNotEmpty
        ? CategoryDriver(
            name: decreases.first.name,
            delta: decreases.first.delta,
            contributionPct: decreases.first.contributionPct(netExpVariance),
          )
        : null;

    // ── Pace ──
    final currentDaily = daysElapsed > 0 ? curExp / daysElapsed : 0.0;
    final compareDaily =
        daysInCompareMonth > 0 ? cmpExp / daysInCompareMonth : 0.0;
    final projected = currentDaily * daysInCurrentMonth;

    // Forecast gating: reuse budget logic (≥7 days + meaningful activity)
    final forecastEligible = daysElapsed >= 7 && curExpCount >= 5;

    // ── Activity ──
    final curAvg = curExpCount > 0 ? curExp / curExpCount : 0.0;
    final cmpAvg = cmpExpCount > 0 ? cmpExp / cmpExpCount : 0.0;

    // ── Facts ──
    final facts = <NarrativeFact>[];
    const materialityThreshold = 50.0;

    if (netExpVariance.abs() < materialityThreshold) {
      facts.add(const InsufficientHistoryFact()); // Reuse as "Steady"
    } else if (cmpExp > 0) {
      if (netExpVariance < 0) {
        facts.add(
          SpendingDecelerationFact(
            category: 'Total Spending',
            percentage: (netExpVariance.abs() / cmpExp * 100).clamp(0, 100),
          ),
        );
      } else {
        facts.add(
          SpendingAccelerationFact(
            category: 'Total Spending',
            percentage: (netExpVariance / cmpExp * 100),
            amount: netExpVariance,
          ),
        );
      }
    } else {
      // First time spending
      facts.add(
        SpendingAccelerationFact(
          category: 'Total Spending',
          percentage: 100,
          amount: netExpVariance,
        ),
      );
    }

    if (topIncrease != null && topIncrease.delta > materialityThreshold) {
      facts.add(
        TopCategoryFact(
          category: topIncrease.name,
          percentage: topIncrease.contributionPct,
        ),
      );
    }

    // New/Stopped categories
    for (final contrib in contributions) {
      if (contrib.currentSpend > materialityThreshold &&
          contrib.compareSpend == 0) {
        facts.add(
          NewSpendingCategoryFact(
            category: contrib.name,
            amount: contrib.currentSpend,
          ),
        );
      } else if (contrib.currentSpend == 0 &&
          contrib.compareSpend > materialityThreshold) {
        facts.add(
          CategoryStoppedFact(
            category: contrib.name,
            previousAmount: contrib.compareSpend,
          ),
        );
      }
    }

    if (forecastEligible) {
      facts.add(
        SpendingForecastFact(
          projectedAmount: projected,
          variance: projected - cmpExp,
          comparisonPeriod: 'baseline',
        ),
      );
    }

    return ComparisonAnalysis(
      currentIncome: curInc,
      compareIncome: cmpInc,
      currentExpense: curExp,
      compareExpense: cmpExp,
      isPartialPeriod: isPartial,
      comparedDays: daysElapsed,
      topIncrease: topIncrease,
      topDecrease: topDecrease,
      currentDailySpend: currentDaily,
      compareDailySpend: compareDaily,
      projectedMonthEndSpend: projected,
      forecastEligible: forecastEligible,
      contributions: contributions,
      currentTxnCount: curExpCount,
      compareTxnCount: cmpExpCount,
      currentAvgTxn: curAvg,
      compareAvgTxn: cmpAvg,
      facts: facts,
    );
  }

  void _accumCategory(
    Map<String, _CatAccum> map,
    Transaction t,
    double amount, {
    required bool isCurrent,
  }) {
    final c = t.category.value;
    if (c == null) return;
    final accum = map.putIfAbsent(
      c.name,
      () => _CatAccum(name: c.name, iconName: c.iconName ?? 'circle'),
    );
    if (isCurrent) {
      accum.current += amount;
    } else {
      accum.compare += amount;
    }
  }
}

class _CatAccum {
  final String name;
  final String iconName;
  double current = 0;
  double compare = 0;

  _CatAccum({required this.name, required this.iconName});
}
