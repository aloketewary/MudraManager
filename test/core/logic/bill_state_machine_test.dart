import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/domain/financial_states.dart';
import 'package:mudra_manager/core/logic/bill_state_machine.dart';

void main() {
  final today = DateTime(2025, 6, 15);

  group('BillStateMachine', () {
    test('returns unknown when scan not done', () {
      final due = today.add(const Duration(days: 1));
      expect(
        BillStateMachine.classify(due, today, scanDone: false),
        BillState.unknown,
      );
    });

    test('returns overdue when due date is in the past', () {
      final due = today.subtract(const Duration(days: 3));
      expect(
        BillStateMachine.classify(due, today, scanDone: true),
        BillState.overdue,
      );
    });

    test('returns dueToday when due date is today', () {
      expect(
        BillStateMachine.classify(today, today, scanDone: true),
        BillState.dueToday,
      );
    });

    test('returns dueSoon when due in 1 day', () {
      final due = today.add(const Duration(days: 1));
      expect(
        BillStateMachine.classify(due, today, scanDone: true),
        BillState.dueSoon,
      );
    });

    test('returns dueSoon when due in 2 days', () {
      final due = today.add(const Duration(days: 2));
      expect(
        BillStateMachine.classify(due, today, scanDone: true),
        BillState.dueSoon,
      );
    });

    test('returns upcoming when due in 3-7 days', () {
      final due = today.add(const Duration(days: 5));
      expect(
        BillStateMachine.classify(due, today, scanDone: true),
        BillState.upcoming,
      );
    });

    test('returns clear when due in 8+ days', () {
      final due = today.add(const Duration(days: 10));
      expect(
        BillStateMachine.classify(due, today, scanDone: true),
        BillState.clear,
      );
    });
  });
}
