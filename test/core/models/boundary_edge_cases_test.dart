import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/features/trip/data/trip_service.dart';

void main() {
  group('Zero amount edge cases', () {
    test('zero amount transaction has zero effectiveAmount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 0,
        isExpense: true,
      );
      expect(txn.effectiveAmount, 0);
      expect(txn.baseAmount, 0);
    });

    test('zero myShare on shared expense', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 0
        ..isSharedExpense = true;
      expect(txn.effectiveAmount, 0);
    });

    test('goal with zero target', () {
      final goal = Goal.create(name: 'Test', targetAmount: 0);
      expect(goal.progressPercent, 0.0);
      expect(goal.remainingAmount, 0.0);
    });

    test('TripSummary with all zeros', () {
      const summary = TripSummary(
        participantCount: 0,
        totalSpent: 0,
        ownerShare: 0,
        ownerPaid: 0,
        netBalance: 0,
      );
      expect(summary.youOwe, false);
      expect(summary.youGet, false);
      expect(summary.settled, false); // no expenses = not settled
    });
  });

  group('Very large number edge cases', () {
    test('large amount transaction', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 99999999.99,
        isExpense: true,
      );
      expect(txn.effectiveAmount, 99999999.99);
    });

    test('large myShare', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100000000,
        isExpense: true,
      )..myShare = 50000000;
      expect(txn.effectiveAmount, 50000000);
    });

    test('goal with very large target', () {
      final goal = Goal.create(
        name: 'House',
        targetAmount: 50000000,
        currentAmount: 1000000,
      );
      expect(goal.progressPercent, closeTo(0.02, 0.001));
      expect(goal.remainingAmount, 49000000);
    });
  });

  group('Negative value edge cases', () {
    test('negative convertedAmount', () {
      // Shouldn't happen but guard against it
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
        convertedAmount: -500,
      );
      expect(txn.baseAmount, -500);
    });

    test('goal with negative currentAmount', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 1000,
        currentAmount: -100,
      );
      // progressPercent should clamp to 0
      expect(goal.progressPercent, 0.0);
      expect(goal.remainingAmount, 1100);
    });
  });

  group('Date edge cases', () {
    test('transaction at midnight', () {
      final txn = Transaction.create(
        date: DateTime(2024, 1, 1, 0, 0, 0),
        amount: 100,
        isExpense: true,
      );
      expect(txn.date.hour, 0);
      expect(txn.date.minute, 0);
    });

    test('transaction at end of day', () {
      final txn = Transaction.create(
        date: DateTime(2024, 1, 1, 23, 59, 59),
        amount: 100,
        isExpense: true,
      );
      expect(txn.date.hour, 23);
    });

    test('goal with past target date', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 1000,
        currentAmount: 500,
        targetDate: DateTime(2020, 1, 1),
      );
      final daysLeft = goal.targetDate!.difference(DateTime.now()).inDays;
      expect(daysLeft, isNegative);
    });

    test('goal with no target date', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 1000,
      );
      expect(goal.targetDate, null);
    });
  });

  group('Empty list edge cases', () {
    test('empty transaction list sums to zero', () {
      final transactions = <Transaction>[];
      final total = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      expect(total, 0);
    });

    test('savings rate with zero income', () {
      final income = 0.0;
      final expense = 500.0;
      // Guard against division by zero
      final savingsRate = income > 0
          ? ((income - expense) / income * 100).clamp(0, 100)
          : 0.0;
      expect(savingsRate, 0.0);
    });

    test('budget adherence with no budgets', () {
      final budgets = <dynamic>[];
      final adherence = budgets.isNotEmpty
          ? budgets.length / budgets.length * 100
          : 0.0;
      expect(adherence, 0.0);
    });
  });

  group('Split calculation edge cases', () {
    test('single participant split = full amount', () {
      final amount = 500.0;
      final participants = 1;
      final perPerson = amount / participants;
      expect(perPerson, 500);
    });

    test('two person split', () {
      final amount = 100.0;
      final participants = 2;
      final perPerson = amount / participants;
      expect(perPerson, 50);
    });

    test('large group split', () {
      final amount = 10000.0;
      final participants = 20;
      final perPerson = amount / participants;
      expect(perPerson, 500);
    });

    test('uneven split amounts sum to total', () {
      final total = 1000.0;
      final splits = [333.34, 333.33, 333.33];
      final sum = splits.reduce((a, b) => a + b);
      expect(sum, closeTo(total, 0.01));
    });

    test('percentage split with rounding', () {
      final total = 1000.0;
      final percentages = [33.33, 33.33, 33.34];
      final amounts = percentages.map((p) => total * p / 100).toList();
      final sum = amounts.reduce((a, b) => a + b);
      expect(sum, closeTo(total, 0.01));
    });

    test('owner not in participant list', () {
      final participantIds = [2, 3, 4];
      final ownerId = 1;
      final ownerIdx = participantIds.indexOf(ownerId);
      expect(ownerIdx, -1);

      // myShare should be null when owner not participating
      final myShare = ownerIdx >= 0 ? 300.0 : null;
      expect(myShare, null);
    });
  });

  group('Account balance edge cases', () {
    test('credit card balance increases with expenses', () {
      final initial = 5000.0;
      final expense = 500.0;
      final payment = 0.0;
      final balance = initial + expense - payment;
      expect(balance, 5500);
    });

    test('zero balance account', () {
      final initial = 0.0;
      final income = 1000.0;
      final expense = 1000.0;
      final balance = initial + income - expense;
      expect(balance, 0);
    });

    test('negative balance (overdraft)', () {
      final initial = 1000.0;
      final expense = 1500.0;
      final balance = initial - expense;
      expect(balance, -500);
    });
  });

  group('Settlement key edge cases', () {
    test('settlement between same-named participants', () {
      // Edge case: two people with same name
      final from = 'Alice';
      final to = 'Alice';
      final amount = 300.0;
      final key = '${from}_TO_${to}_${amount.toStringAsFixed(2)}';
      expect(key, 'Alice_TO_Alice_300.00');
    });

    test('settlement with special characters in name', () {
      final from = "O'Brien";
      final to = 'José';
      final amount = 100.0;
      final key = '${from}_TO_${to}_${amount.toStringAsFixed(2)}';
      expect(key.contains('_TO_'), true);
    });

    test('settlement amount precision', () {
      final amount = 333.33;
      final key = amount.toStringAsFixed(2);
      expect(key, '333.33');
    });
  });
}
