import 'package:mudra_manager/core/domain/budget_constraint_snapshot.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/metrics.dart';

/// Input for snapshot computation. Caller assembles this from DB/providers.
class BudgetConstraintInput {
  final int budgetId;
  final String budgetName;
  final double budgetAmount;
  final double totalSpent;
  final double spentInLast7Days;
  final int daysPassed;
  final int daysLeft;
  final int totalDays;

  const BudgetConstraintInput({
    required this.budgetId,
    required this.budgetName,
    required this.budgetAmount,
    required this.totalSpent,
    required this.spentInLast7Days,
    required this.daysPassed,
    required this.daysLeft,
    required this.totalDays,
  });
}

/// Classifies budget state and produces constraint snapshots.
/// Pure functions. No side effects. No dependencies.
abstract final class BudgetStateMachine {
  /// Legacy classification (kept for Dashboard V2 compatibility).
  static BudgetState classify(double spent, double limit) {
    if (limit <= 0) return BudgetState.unset;
    final ratio = Metrics.budgetRatio(spent, limit);
    if (ratio > 1.0) return BudgetState.breach;
    if (ratio >= 0.8) return BudgetState.warn;
    return BudgetState.ok;
  }

  /// Produces a full constraint snapshot from raw inputs.
  static BudgetConstraintSnapshot computeSnapshot(BudgetConstraintInput input) {
    final remaining = input.budgetAmount - input.totalSpent;
    final isBreached = input.totalSpent > input.budgetAmount;
    final state = classify(input.totalSpent, input.budgetAmount);

    // Pace: rolling 7-day average, fallback to lifetime if < 7 days
    final currentDailySpend = input.daysPassed >= 7
        ? input.spentInLast7Days / 7
        : (input.daysPassed > 0 ? input.totalSpent / input.daysPassed : 0.0);

    // Allowed pace (stable, period-wide reference)
    final allowedDailySpend = input.totalDays > 0
        ? input.budgetAmount / input.totalDays
        : 0.0;

    // Remaining daily allowance (actionable for detail screen)
    final remainingDailyAllowance = input.daysLeft > 0 && remaining > 0
        ? remaining / input.daysLeft
        : 0.0;

    // Gap
    final dailyGap = currentDailySpend - allowedDailySpend;

    // Forecast breach (gated)
    final bool isForecastVisible;
    final int? daysUntilLimit;

    if (input.daysPassed >= 7 &&
        input.totalSpent >= input.budgetAmount * 0.20 &&
        currentDailySpend > 0 &&
        !isBreached) {
      final computed = remaining / currentDailySpend;
      if (computed < input.daysLeft) {
        isForecastVisible = true;
        daysUntilLimit = computed.ceil();
      } else {
        isForecastVisible = false;
        daysUntilLimit = null;
      }
    } else {
      isForecastVisible = false;
      daysUntilLimit = null;
    }

    // Urgency classification
    final urgency = _classifyUrgency(
      isBreached: isBreached,
      isForecastVisible: isForecastVisible,
      daysUntilLimit: daysUntilLimit,
      percentage: input.budgetAmount > 0
          ? input.totalSpent / input.budgetAmount
          : 0.0,
      isUnknown: input.daysPassed < 1 && input.totalSpent == 0,
    );

    // Recovery signal
    final recoverySignal = _computeRecovery(
      isBreached: isBreached,
      dailyGap: dailyGap,
      remainingDailyAllowance: remainingDailyAllowance,
      currentDailySpend: currentDailySpend,
      urgency: urgency,
    );

    return BudgetConstraintSnapshot(
      budgetId: input.budgetId,
      budgetName: input.budgetName,
      remaining: remaining,
      spent: input.totalSpent,
      limit: input.budgetAmount,
      currentDailySpend: currentDailySpend,
      allowedDailySpend: allowedDailySpend,
      remainingDailyAllowance: remainingDailyAllowance,
      dailyGap: dailyGap,
      daysUntilLimit: daysUntilLimit,
      isForecastVisible: isForecastVisible,
      recoverySignal: recoverySignal,
      daysLeft: input.daysLeft,
      daysPassed: input.daysPassed,
      totalDays: input.totalDays,
      urgency: urgency,
      state: state,
    );
  }

  static BudgetConstraintUrgency _classifyUrgency({
    required bool isBreached,
    required bool isForecastVisible,
    required int? daysUntilLimit,
    required double percentage,
    required bool isUnknown,
  }) {
    if (isBreached) return BudgetConstraintUrgency.breached;
    if (isForecastVisible && daysUntilLimit != null) {
      if (daysUntilLimit <= 7) return BudgetConstraintUrgency.imminentBreach;
      return BudgetConstraintUrgency.approachingBreach;
    }
    if (percentage >= 0.8) return BudgetConstraintUrgency.nearLimit;
    if (isUnknown) return BudgetConstraintUrgency.unknown;
    return BudgetConstraintUrgency.withinLimit;
  }

  static String? _computeRecovery({
    required bool isBreached,
    required double dailyGap,
    required double remainingDailyAllowance,
    required double currentDailySpend,
    required BudgetConstraintUrgency urgency,
  }) {
    if (urgency == BudgetConstraintUrgency.unknown) return null;
    if (isBreached) {
      // Over limit: show reduction needed
      return dailyGap > 0 ? '−${dailyGap.toStringAsFixed(0)}/day' : null;
    }
    if (dailyGap > 0 && remainingDailyAllowance > 0) {
      // Exceeding: show target daily spend
      return '≤${remainingDailyAllowance.toStringAsFixed(0)}/day';
    }
    return null;
  }
}
