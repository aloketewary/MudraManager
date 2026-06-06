import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/transactions/domain/transfer_merge_validator.dart';

void main() {
  group('validateTransferMerge', () {
    test('valid pair: same amount, one expense one income, within 24h', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, true);
      expect(result.expense, expense);
      expect(result.income, income);
    });

    test('valid: order does not matter (income first, expense second)', () {
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: false,
      );
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: true,
      );

      final result = validateTransferMerge(income, expense);
      expect(result.valid, true);
      expect(result.expense, expense);
      expect(result.income, income);
    });

    test('valid: amounts within 1% tolerance', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 4960, // 0.8% difference
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, true);
    });

    test('invalid: both are expenses', () {
      final a = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final b = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: true,
      );

      final result = validateTransferMerge(a, b);
      expect(result.valid, false);
      expect(result.error, contains('one expense and one income'));
    });

    test('invalid: both are income', () {
      final a = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: false,
      );
      final b = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = validateTransferMerge(a, b);
      expect(result.valid, false);
      expect(result.error, contains('one expense and one income'));
    });

    test('invalid: amounts differ by more than 1%', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 4900, // 2% difference
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, false);
      expect(result.error, contains('amounts'));
    });

    test('invalid: more than 24 hours apart', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 16, 11, 0), // 25 hours later
        amount: 5000,
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, false);
      expect(result.error, contains('24 hours'));
    });

    test('valid: exactly 24 hours apart', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 16, 10, 0), // exactly 24h
        amount: 5000,
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, true);
    });

    test('invalid: one is already a transfer', () {
      final expense = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 0),
        amount: 5000,
        isExpense: true,
        isTransfer: true,
      );
      final income = Transaction.create(
        date: DateTime(2025, 6, 15, 10, 30),
        amount: 5000,
        isExpense: false,
      );

      final result = validateTransferMerge(expense, income);
      expect(result.valid, false);
      expect(result.error, contains('already a transfer'));
    });
  });
}
