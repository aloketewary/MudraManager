/// Single source of truth for all financial state enums.
/// No logic. No Riverpod. No UI. No Isar.
library;

enum DataValidityLevel { insufficient, partial, valid }

enum BudgetState { unset, ok, warn, breach }

enum BillState { unknown, clear, upcoming, dueSoon, dueToday, overdue }

enum CashflowState { positive, neutral, negative }

enum StateTransition { stable, worsening, improving, newlyViolated, newlyDue }

enum BriefingTrigger {
  billOverdue(100),
  billDueToday(90),
  budgetBreach(80),
  spendingDrift(70),
  billDueSoon(60),
  netNegative(50),
  improvement(20);

  const BriefingTrigger(this.priority);
  final int priority;
}
