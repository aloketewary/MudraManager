import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/domain/budget_period_snapshot.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

/// Period-aware aggregate used by budget overview surfaces.
///
/// Each current snapshot contributes its own remaining amount divided by its
/// own remaining days. This keeps mixed recurrence periods meaningful without
/// pretending they share one calendar month.
class BudgetOverviewAggregate {
  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;
  final double dailyAllowance;
  final double progress;
  final bool hasUsableLimit;
  final bool isCompatibleMonthly;

  const BudgetOverviewAggregate({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.dailyAllowance,
    required this.progress,
    required this.hasUsableLimit,
    required this.isCompatibleMonthly,
  });

  factory BudgetOverviewAggregate.fromSnapshots(
    Iterable<BudgetPeriodSnapshot> budgets,
  ) {
    final entries = budgets.toList(growable: false);
    if (entries.isEmpty) {
      return const BudgetOverviewAggregate(
        totalLimit: 0,
        totalSpent: 0,
        totalRemaining: 0,
        dailyAllowance: 0,
        progress: 0,
        hasUsableLimit: false,
        isCompatibleMonthly: false,
      );
    }

    var totalLimit = 0.0;
    var totalSpent = 0.0;
    var totalRemaining = 0.0;
    var dailyAllowance = 0.0;

    for (final snapshot in entries) {
      totalLimit += _finiteOrZero(snapshot.limit);
      totalSpent += _finiteOrZero(snapshot.spent);
      totalRemaining += _finiteOrZero(snapshot.remaining);

      final remaining = snapshot.remaining;
      if (!remaining.isFinite || remaining <= 0) continue;

      final evaluationDay = DateArithmetic.startOfDay(snapshot.evaluationDate);
      final periodStart = DateArithmetic.startOfDay(snapshot.periodStart);
      final periodEnd = DateArithmetic.startOfDay(snapshot.periodEnd);
      final firstRemainingDay =
          evaluationDay.isBefore(periodStart) ? periodStart : evaluationDay;
      final daysLeft = periodEnd.difference(firstRemainingDay).inDays + 1;
      if (daysLeft > 0) {
        dailyAllowance += remaining / daysLeft;
      }
    }

    final hasUsableLimit = totalLimit.isFinite && totalLimit > 0;
    final progress = hasUsableLimit
        ? (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final first = entries.first;
    final isCompatibleMonthly = entries.every((snapshot) {
      return snapshot.recurrence == BudgetRecurrence.monthly &&
          snapshot.periodStart == first.periodStart &&
          snapshot.periodEnd == first.periodEnd;
    });

    return BudgetOverviewAggregate(
      totalLimit: _finiteOrZero(totalLimit),
      totalSpent: _finiteOrZero(totalSpent),
      totalRemaining: _finiteOrZero(totalRemaining),
      dailyAllowance: _finiteOrZero(dailyAllowance),
      progress: progress.isFinite ? progress : 0.0,
      hasUsableLimit: hasUsableLimit,
      isCompatibleMonthly: isCompatibleMonthly,
    );
  }

  double get percent => progress * 100;

  static double _finiteOrZero(double value) => value.isFinite ? value : 0.0;
}
