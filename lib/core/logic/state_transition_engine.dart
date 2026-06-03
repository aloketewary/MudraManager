import 'package:mudra_manager/core/domain/financial_states.dart';

/// Detects transitions between states.
/// Compares previous snapshot to current. Pure function.
abstract final class StateTransitionEngine {
  static StateTransition detectBudget(
    BudgetState? previous,
    BudgetState current,
  ) {
    if (previous == null || previous == current) return StateTransition.stable;
    if (current == BudgetState.breach && previous != BudgetState.breach) {
      return StateTransition.newlyViolated;
    }
    if (current.index > previous.index) return StateTransition.worsening;
    return StateTransition.improving;
  }

  static StateTransition detectBill(
    BillState? previous,
    BillState current,
  ) {
    if (previous == null || previous == current) return StateTransition.stable;
    if ((current == BillState.overdue || current == BillState.dueToday) &&
        previous != BillState.overdue &&
        previous != BillState.dueToday) {
      return StateTransition.newlyViolated;
    }
    if (current.index > previous.index) return StateTransition.worsening;
    return StateTransition.improving;
  }

  static StateTransition detectCashflow(
    CashflowState? previous,
    CashflowState current,
  ) {
    if (previous == null || previous == current) return StateTransition.stable;
    if (current == CashflowState.negative) return StateTransition.worsening;
    return StateTransition.improving;
  }
}
