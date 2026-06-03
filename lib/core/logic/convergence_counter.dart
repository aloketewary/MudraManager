import 'package:mudra_manager/core/domain/financial_states.dart';

/// Counts how many constraints are simultaneously violated.
/// Pure function. No dependencies.
abstract final class ConvergenceCounter {
  static int compute({
    required BudgetState budget,
    required BillState bill,
    required CashflowState cashflow,
  }) {
    int count = 0;
    if (budget == BudgetState.breach) count++;
    if (bill == BillState.dueToday || bill == BillState.overdue) count++;
    if (cashflow == CashflowState.negative) count++;
    return count;
  }
}
