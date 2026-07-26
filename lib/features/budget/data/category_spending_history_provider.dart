import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

/// Spending history for a single category — powers budget templates.
class CategorySpendingHistory {
  final double lastMonthSpent;
  final double threeMonthAverage;
  final double thisMonthSoFar;
  final int daysWithData;

  const CategorySpendingHistory({
    required this.lastMonthSpent,
    required this.threeMonthAverage,
    required this.thisMonthSoFar,
    required this.daysWithData,
  });

  bool get hasHistory => daysWithData >= 7;

  /// Conservative: ~85% of 3-month avg (rounded to nearest 500)
  double get conservativeLimit =>
      _roundTo500((threeMonthAverage * 0.85).clamp(0, double.infinity));

  /// Recommended: last month (rounded to nearest 500)
  double get recommendedLimit => _roundTo500(lastMonthSpent);

  /// Flexible: ~120% of 3-month avg (rounded to nearest 500)
  double get flexibleLimit =>
      _roundTo500((threeMonthAverage * 1.2).clamp(0, double.infinity));

  double _roundTo500(double v) => (v / 500).round() * 500.0;
}

/// Fetches spending history for a category (by ID).
/// Includes subcategory spending if the category is a parent.
final categorySpendingHistoryProvider = FutureProvider.autoDispose
    .family<CategorySpendingHistory, int>((ref, categoryId) async {
  final isar = await ref.read(isarServiceProvider).getInstance();
  final now = DateTime.now();

  // Date ranges
  final thisMonthStart = DateTime(now.year, now.month);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
  final threeMonthsAgo = DateTime(now.year, now.month - 3);

  // Get category + its children (for parent categories)
  final category = await isar.categorys.get(categoryId);
  final childIds = <int>[categoryId];
  if (category != null) {
    final children = await isar.categorys
        .filter()
        .parentCategory((q) => q.idEqualTo(categoryId))
        .findAll();
    childIds.addAll(children.map((c) => c.id));
  }

  // Query all expenses for these categories in last 3 months
  final expenses = await isar.transactions
      .filter()
      .isExpenseEqualTo(true)
      .isTransferEqualTo(false)
      .isSettlementEqualTo(false)
      .dateGreaterThan(threeMonthsAgo)
      .findAll();

  // Load categories for filtering
  for (final t in expenses) {
    await t.category.load();
  }

  final relevant = expenses.where(
    (t) => t.category.value != null && childIds.contains(t.category.value!.id),
  );

  // Compute per-period
  double lastMonth = 0;
  double thisMonth = 0;
  double threeMonthTotal = 0;
  int monthsWithSpending = 0;
  final monthSet = <String>{};

  for (final t in relevant) {
    final d = t.date;
    final amt = t.baseAmount;
    threeMonthTotal += amt;
    monthSet.add('${d.year}-${d.month}');

    if (d.isAfter(lastMonthStart) &&
        d.isBefore(lastMonthEnd.add(const Duration(seconds: 1)))) {
      lastMonth += amt;
    }
    if (d.isAfter(thisMonthStart) || d.isAtSameMomentAs(thisMonthStart)) {
      thisMonth += amt;
    }
  }

  // Guard: monthSet can be empty when there's no spending history at all —
  // don't force a minimum of 1, or hasHistory/daysWithData will falsely
  // report enough data when there's actually zero transactions.
  final monthsCounted = monthSet.length;
  monthsWithSpending = monthsCounted.clamp(0, 3);
  final threeMonthAvg =
      monthsWithSpending > 0 ? threeMonthTotal / monthsWithSpending : 0.0;

  return CategorySpendingHistory(
    lastMonthSpent: lastMonth,
    threeMonthAverage: threeMonthAvg,
    thisMonthSoFar: thisMonth,
    daysWithData: monthsWithSpending * 30,
  );
});
