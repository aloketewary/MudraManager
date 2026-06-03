import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/domain/metrics.dart';

/// Classifies budget state from spent/limit values.
/// Pure function. No side effects. No dependencies.
abstract final class BudgetStateMachine {
  static BudgetState classify(double spent, double limit) {
    if (limit <= 0) return BudgetState.unset;
    final ratio = Metrics.budgetRatio(spent, limit);
    if (ratio > 1.0) return BudgetState.breach;
    if (ratio >= 0.8) return BudgetState.warn;
    return BudgetState.ok;
  }
}
