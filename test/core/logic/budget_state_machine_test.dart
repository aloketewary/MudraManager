import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/budget_state_machine.dart';

void main() {
  group('BudgetStateMachine', () {
    test('returns unset when limit is 0', () {
      expect(BudgetStateMachine.classify(500, 0), BudgetState.unset);
    });

    test('returns unset when limit is negative', () {
      expect(BudgetStateMachine.classify(500, -100), BudgetState.unset);
    });

    test('returns ok when under 80%', () {
      expect(BudgetStateMachine.classify(700, 1000), BudgetState.ok);
    });

    test('returns ok at exactly 0 spent', () {
      expect(BudgetStateMachine.classify(0, 1000), BudgetState.ok);
    });

    test('returns warn at exactly 80%', () {
      expect(BudgetStateMachine.classify(800, 1000), BudgetState.warn);
    });

    test('returns warn between 80-100%', () {
      expect(BudgetStateMachine.classify(950, 1000), BudgetState.warn);
    });

    test('returns warn at exactly 100%', () {
      expect(BudgetStateMachine.classify(1000, 1000), BudgetState.warn);
    });

    test('returns breach when over 100%', () {
      expect(BudgetStateMachine.classify(1001, 1000), BudgetState.breach);
    });

    test('returns breach at 200%', () {
      expect(BudgetStateMachine.classify(2000, 1000), BudgetState.breach);
    });
  });
}
