
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

/// Spending for one category in a canonical budget-period snapshot.
class CategorySpending {
  final Category category;
  final double allocated;
  final double spent;

  CategorySpending({
    required this.category,
    required this.allocated,
    required this.spent,
  });
}

/// Explicit outcome for a completed or current budget occurrence.
enum BudgetPeriodStatus { met, exceeded }

/// Immutable, lossless view of one budget occurrence.
///
/// All consumers that show period-sensitive budget data should use this model
/// or an adapter derived from it. [periodStart] and [periodEnd] are inclusive
/// local-day bounds suitable for the same transaction query.
class BudgetPeriodSnapshot {
  final Budget budget;
  final int budgetId;
  final String budgetName;
  final BudgetType budgetType;
  final BudgetRecurrence recurrence;
  final bool isArchived;
  final DateTime evaluationDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double limit;
  final double spent;
  final double remaining;
  final double percentage;
  final BudgetPeriodStatus status;
  final List<CategorySpending> categorySpendings;

  BudgetPeriodSnapshot({
    required this.budget,
    required this.evaluationDate,
    required this.periodStart,
    required this.periodEnd,
    required this.limit,
    required this.spent,
    this.categorySpendings = const [],
  })  : budgetId = budget.id,
        budgetName = budget.name,
        budgetType = budget.budgetType,
        recurrence = budget.recurrence,
        isArchived = budget.isArchived,
        remaining = limit - spent,
        percentage = _safePercentage(spent, limit),
        status = spent <= limit
            ? BudgetPeriodStatus.met
            : BudgetPeriodStatus.exceeded;

  /// Stable occurrence identity prevents current/history duplicates.
  String get occurrenceKey =>
      '$budgetId:${periodStart.toIso8601String()}:${periodEnd.toIso8601String()}';

  bool get isCurrent =>
      !evaluationDate.isBefore(periodStart) &&
      !evaluationDate.isAfter(periodEnd);

  factory BudgetPeriodSnapshot.fromBudget({
    required Budget budget,
    required DateTime evaluationDate,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double spent,
    List<CategorySpending> categorySpendings = const [],
  }) {
    final normalizedEvaluation = DateArithmetic.startOfDay(evaluationDate);
    final normalizedStart = DateArithmetic.startOfDay(periodStart);
    final normalizedEnd = DateArithmetic.endOfDay(periodEnd);
    return BudgetPeriodSnapshot(
      budget: budget,
      evaluationDate: normalizedEvaluation,
      periodStart: normalizedStart,
      periodEnd: normalizedEnd,
      limit: budget.amount,
      spent: spent,
      categorySpendings: List.unmodifiable(categorySpendings),
    );
  }

  static double _safePercentage(double spent, double limit) {
    if (!spent.isFinite || !limit.isFinite || limit <= 0) return 0;
    return (spent / limit).clamp(0.0, 1.0).toDouble();
  }
}
