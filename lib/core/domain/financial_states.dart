/// Single source of truth for all financial state enums.
/// No logic. No Riverpod. No UI. No Isar.
library;

enum DataValidityLevel { insufficient, partial, valid }

enum BudgetState { unset, ok, warn, breach }

/// Urgency-ranked budget constraint states for sort order.
/// Order matches design spec: breached > imminent > approaching > near > unknown > within.
enum BudgetConstraintUrgency {
  breached,        // Over limit
  imminentBreach,  // Forecast breach <= 7 days
  approachingBreach, // Forecast breach > 7 days
  nearLimit,       // >80% used, no forecast breach
  unknown,         // Insufficient data to assess
  withinLimit,     // Healthy, no action needed
}

enum BillState { unknown, clear, upcoming, dueSoon, dueToday, overdue }

enum CashflowState { positive, neutral, negative }

enum StateTransition { stable, worsening, improving, newlyViolated, newlyDue }

enum BriefingTrigger {
  billOverdue(100),
  billDueToday(90),
  budgetBreach(80),
  spendingThresholdBreach(70),
  spendingAcceleration(70),
  spendingDrift(70),
  billDueSoon(60),
  netNegative(50),
  improvement(20);

  const BriefingTrigger(this.priority);
  final int priority;
}
