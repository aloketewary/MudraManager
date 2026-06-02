import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/memory/data/financial_snapshot.dart';
import 'package:mudra_manager/features/memory/data/insight_exposure.dart';

/// Detects categories with sustained directional spending change over 3+ months.
/// Ranks by financial impact (not percentage).
/// Applies 7-day cooldown per category.
/// Assigns stable A/B variant via hash(userId + categoryId).
class SpendingDriftDetector {
  final Isar _isar;
  final String _userId;

  SpendingDriftDetector(this._isar, this._userId);

  Future<List<DriftInsight>> detect({int maxResults = 2}) async {
    final now = DateTime.now();

    // Load last 4 months of snapshots
    final snapshots = <FinancialSnapshot>[];
    for (int i = 0; i < 4; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final snap = await _isar.financialSnapshots
          .filter()
          .monthEqualTo(month)
          .findFirst();
      if (snap != null) snapshots.add(snap);
    }

    if (snapshots.length < 3) return [];

    // Chronological order (oldest first)
    snapshots.sort((a, b) => a.month.compareTo(b.month));

    // All category IDs across all months
    final allCatIds = <int>{};
    for (final s in snapshots) {
      allCatIds.addAll(s.categoryIds);
    }

    // 7-day cooldown: skip categories shown recently
    final cooldownCutoff = now.subtract(const Duration(days: 7));
    final recentExposures = await _isar.insightExposures
        .filter()
        .insightTypeEqualTo('spending_drift')
        .displayedAtIsNotNull()
        .displayedAtGreaterThan(cooldownCutoff)
        .findAll();
    final cooledDownCatIds = recentExposures
        .where((e) => e.categoryId != null)
        .map((e) => e.categoryId!)
        .toSet();

    final drifts = <DriftInsight>[];

    for (final catId in allCatIds) {
      if (cooledDownCatIds.contains(catId)) continue;

      final amounts = snapshots.map((s) => s.amountForCategory(catId)).toList();

      // Need 3+ non-zero months
      if (amounts.where((a) => a > 0).length < 3) continue;

      final first = amounts.first;
      final last = amounts.last;
      if (first == 0) continue;

      final percentChange = (last - first) / first * 100;

      // Only report > 20% sustained change
      if (percentChange.abs() < 20) continue;
      if (!_isConsistentDirection(amounts)) continue;

      final cat = await _isar.categorys.get(catId);
      final name = cat?.name ?? 'Unknown';
      final variant = _assignVariant(catId);
      final snapshotMonth =
          snapshots.last.month.toIso8601String().substring(0, 7);

      drifts.add(DriftInsight(
        categoryId: catId,
        categoryName: name,
        monthlyAmounts: amounts,
        percentChange: percentChange,
        isRising: percentChange > 0,
        months: snapshots.length,
        variant: variant,
        fingerprint: 'drift:$snapshotMonth:$catId:$variant',
      ),);
    }

    // Rank by FINANCIAL IMPACT (yearly savings if reverted), not percentage
    drifts.sort((a, b) => b.yearlySavingsIfReverted
        .abs()
        .compareTo(a.yearlySavingsIfReverted.abs()),);

    return drifts.take(maxResults).toList();
  }

  /// Stable variant assignment: hash(userId + categoryId) % 2.
  /// Same user always sees same framing for same category.
  /// Prevents category-type contamination.
  String _assignVariant(int categoryId) {
    final input = '$_userId:$categoryId';
    final hash = md5.convert(utf8.encode(input)).toString();
    final lastChar = hash.codeUnitAt(hash.length - 1);
    return lastChar.isEven ? 'trend' : 'consequence';
  }

  /// Returns true if amounts move consistently in one direction.
  /// Allows one "flat" month (within 10% threshold) but no reversals.
  bool _isConsistentDirection(List<double> amounts) {
    if (amounts.length < 3) return false;
    int ups = 0, downs = 0;
    for (int i = 1; i < amounts.length; i++) {
      final change = amounts[i] - amounts[i - 1];
      final threshold = amounts[i - 1] * 0.1;
      if (change > threshold) ups++;
      if (change < -threshold) downs++;
    }
    return ups >= amounts.length - 2 || downs >= amounts.length - 2;
  }
}

/// A detected spending drift for a single category.
class DriftInsight {
  final int categoryId;
  final String categoryName;
  final List<double> monthlyAmounts;
  final double percentChange;
  final bool isRising;
  final int months;
  final String variant;
  final String fingerprint;

  const DriftInsight({
    required this.categoryId,
    required this.categoryName,
    required this.monthlyAmounts,
    required this.percentChange,
    required this.isRising,
    required this.months,
    required this.variant,
    required this.fingerprint,
  });

  double get monthlyDelta => monthlyAmounts.last - monthlyAmounts.first;
  double get yearlySavingsIfReverted => isRising ? monthlyDelta * 12 : 0;

  /// A/B headline: trend framing vs consequence framing.
  String get headline {
    if (variant == 'consequence' && isRising) {
      return 'Cutting $categoryName to its old level saves ₹${yearlySavingsIfReverted.toStringAsFixed(0)}/year';
    }
    final dir = isRising ? '↑' : '↓';
    return '$categoryName $dir ${percentChange.abs().toStringAsFixed(0)}% over $months months';
  }

  /// A/B narrative: consequence creates tension, trend informs.
  String get narrative {
    if (variant == 'consequence' && isRising) {
      return '$categoryName was ₹${monthlyAmounts.first.toStringAsFixed(0)}/month, '
          'now ₹${monthlyAmounts.last.toStringAsFixed(0)}. '
          'That ₹${monthlyDelta.toStringAsFixed(0)}/month gap adds up.';
    }
    return '$categoryName went from ₹${monthlyAmounts.first.toStringAsFixed(0)} '
        'to ₹${monthlyAmounts.last.toStringAsFixed(0)} over $months months.';
  }
}
