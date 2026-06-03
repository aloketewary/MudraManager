import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/convergence_counter.dart';

void main() {
  group('ConvergenceCounter', () {
    test('returns 0 when all constraints are clear', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.clear,
          cashflow: CashflowState.positive,
        ),
        0,
      );
    });

    test('returns 1 for budget breach only', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.breach,
          bill: BillState.clear,
          cashflow: CashflowState.positive,
        ),
        1,
      );
    });

    test('returns 1 for bill dueToday only', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.dueToday,
          cashflow: CashflowState.positive,
        ),
        1,
      );
    });

    test('returns 1 for bill overdue only', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.overdue,
          cashflow: CashflowState.positive,
        ),
        1,
      );
    });

    test('returns 1 for negative cashflow only', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.clear,
          cashflow: CashflowState.negative,
        ),
        1,
      );
    });

    test('returns 3 when all constraints violated', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.breach,
          bill: BillState.overdue,
          cashflow: CashflowState.negative,
        ),
        3,
      );
    });

    test('does not count budget warn', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.warn,
          bill: BillState.clear,
          cashflow: CashflowState.positive,
        ),
        0,
      );
    });

    test('does not count bill dueSoon', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.dueSoon,
          cashflow: CashflowState.positive,
        ),
        0,
      );
    });

    test('does not count neutral cashflow', () {
      expect(
        ConvergenceCounter.compute(
          budget: BudgetState.ok,
          bill: BillState.clear,
          cashflow: CashflowState.neutral,
        ),
        0,
      );
    });
  });
}
