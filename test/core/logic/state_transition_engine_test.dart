import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/state_transition_engine.dart';

void main() {
  group('StateTransitionEngine.detectBudget', () {
    test('stable when previous is null', () {
      expect(
        StateTransitionEngine.detectBudget(null, BudgetState.breach),
        StateTransition.stable,
      );
    });

    test('stable when unchanged', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.ok, BudgetState.ok),
        StateTransition.stable,
      );
    });

    test('newlyViolated when entering breach', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.warn, BudgetState.breach),
        StateTransition.newlyViolated,
      );
    });

    test('newlyViolated from ok to breach', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.ok, BudgetState.breach),
        StateTransition.newlyViolated,
      );
    });

    test('worsening from ok to warn', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.ok, BudgetState.warn),
        StateTransition.worsening,
      );
    });

    test('improving from breach to warn', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.breach, BudgetState.warn),
        StateTransition.improving,
      );
    });

    test('improving from warn to ok', () {
      expect(
        StateTransitionEngine.detectBudget(BudgetState.warn, BudgetState.ok),
        StateTransition.improving,
      );
    });
  });

  group('StateTransitionEngine.detectBill', () {
    test('stable when previous is null', () {
      expect(
        StateTransitionEngine.detectBill(null, BillState.overdue),
        StateTransition.stable,
      );
    });

    test('stable when unchanged', () {
      expect(
        StateTransitionEngine.detectBill(BillState.clear, BillState.clear),
        StateTransition.stable,
      );
    });

    test('newlyViolated entering dueToday from clear', () {
      expect(
        StateTransitionEngine.detectBill(BillState.clear, BillState.dueToday),
        StateTransition.newlyViolated,
      );
    });

    test('newlyViolated entering overdue from dueSoon', () {
      expect(
        StateTransitionEngine.detectBill(BillState.dueSoon, BillState.overdue),
        StateTransition.newlyViolated,
      );
    });

    test('worsening from clear to upcoming', () {
      expect(
        StateTransitionEngine.detectBill(BillState.clear, BillState.upcoming),
        StateTransition.worsening,
      );
    });

    test('improving from overdue to clear', () {
      expect(
        StateTransitionEngine.detectBill(BillState.overdue, BillState.clear),
        StateTransition.improving,
      );
    });
  });

  group('StateTransitionEngine.detectCashflow', () {
    test('stable when previous is null', () {
      expect(
        StateTransitionEngine.detectCashflow(null, CashflowState.negative),
        StateTransition.stable,
      );
    });

    test('stable when unchanged', () {
      expect(
        StateTransitionEngine.detectCashflow(
          CashflowState.positive,
          CashflowState.positive,
        ),
        StateTransition.stable,
      );
    });

    test('worsening when going negative', () {
      expect(
        StateTransitionEngine.detectCashflow(
          CashflowState.positive,
          CashflowState.negative,
        ),
        StateTransition.worsening,
      );
    });

    test('improving when going positive', () {
      expect(
        StateTransitionEngine.detectCashflow(
          CashflowState.negative,
          CashflowState.positive,
        ),
        StateTransition.improving,
      );
    });
  });
}
