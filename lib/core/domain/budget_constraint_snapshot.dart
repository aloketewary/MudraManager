
import 'financial_states.dart';
import 'budget_period_snapshot.dart';

/// Pure data model representing a budget's constraint state at a point in time.
/// Produced by BudgetStateMachine. Consumed by UI templates.
/// UI never computes these values — it only renders them.
class BudgetConstraintSnapshot {
  final int budgetId;
  final String budgetName;

  // Core constraint numbers
  final double remaining;
  final double spent;
  final double limit;

  // Pace (rolling 7-day or fallback)
  final double currentDailySpend;
  final double allowedDailySpend;
  final double remainingDailyAllowance;

  // Gap: positive = exceeding, negative = within
  final double dailyGap;

  // Forecast breach (null when gated out)
  final int? daysUntilLimit;
  final bool isForecastVisible;

  // Recovery signal
  final String? recoverySignal;

  // Period context
  final int daysLeft;
  final int daysPassed;
  final int totalDays;

  // Canonical period source shared with dashboard/progress/history.
  final BudgetPeriodSnapshot? budgetSnapshot;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  // Classification
  final BudgetConstraintUrgency urgency;
  final BudgetState state;

  const BudgetConstraintSnapshot({
    required this.budgetId,
    required this.budgetName,
    required this.remaining,
    required this.spent,
    required this.limit,
    required this.currentDailySpend,
    required this.allowedDailySpend,
    required this.remainingDailyAllowance,
    required this.dailyGap,
    required this.daysUntilLimit,
    required this.isForecastVisible,
    required this.recoverySignal,
    required this.daysLeft,
    required this.daysPassed,
    required this.totalDays,
    this.budgetSnapshot,
    this.periodStart,
    this.periodEnd,
    required this.urgency,
    required this.state,
  });

  bool get isBreached => spent > limit;
  bool get isUnknown => urgency == BudgetConstraintUrgency.unknown;
  double get percentage => limit > 0 ? spent / limit : 0;
}
