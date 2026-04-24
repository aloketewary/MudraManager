import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Single source of truth for computing how much has been spent
/// against a budget in a given date range.
///
/// Used by: BudgetService, GamificationService, SmartNotificationService.
class BudgetSpentCalculator {
  BudgetSpentCalculator._();

  /// Calculate total spent for [budget] between [start] and [end].
  ///
  /// Handles all budget types: categoryWise, tagWise, dayWise, festival, travel.
  static Future<double> calculate(
    Isar isar,
    Budget budget,
    DateTime start,
    DateTime end,
  ) async {
    final txns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .dateBetween(start, end)
        .findAll();

    if (budget.budgetType == BudgetType.tagWise) {
      return _calculateTagWise(budget, txns);
    }

    if (budget.budgetType == BudgetType.dayWise ||
        budget.budgetType == BudgetType.festival ||
        budget.budgetType == BudgetType.travel) {
      return _calculatePeriodWise(budget, txns);
    }

    return _calculateCategoryWise(budget, txns);
  }

  static Future<double> _calculateTagWise(
    Budget budget,
    List<Transaction> txns,
  ) async {
    await budget.budgetTags.load();
    final tagIds = budget.budgetTags.map((t) => t.id).toSet();
    if (tagIds.isEmpty) return 0;

    double spent = 0;
    for (final t in txns) {
      await t.tags.load();
      if (t.tags.any((tag) => tagIds.contains(tag.id))) {
        spent += t.baseAmount;
      }
    }
    return spent;
  }

  static Future<double> _calculatePeriodWise(
    Budget budget,
    List<Transaction> txns,
  ) async {
    await budget.categories.load();
    final categoryIds = budget.categories.map((c) => c.id).toList();

    if (categoryIds.isEmpty) {
      return txns.fold<double>(0.0, (sum, t) => sum + t.baseAmount);
    }

    for (final t in txns) {
      await t.category.load();
    }
    return txns
        .where((t) =>
            t.category.value != null &&
            categoryIds.contains(t.category.value!.id),)
        .fold<double>(0.0, (sum, t) => sum + t.baseAmount);
  }

  static Future<double> _calculateCategoryWise(
    Budget budget,
    List<Transaction> txns,
  ) async {
    await budget.categories.load();
    final categoryIds = budget.categories.map((c) => c.id).toList();
    if (categoryIds.isEmpty) return 0;

    for (final t in txns) {
      await t.category.load();
    }
    return txns
        .where((t) =>
            t.category.value != null &&
            categoryIds.contains(t.category.value!.id),)
        .fold<double>(0.0, (sum, t) => sum + t.baseAmount);
  }
}
