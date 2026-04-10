import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

void main() {
  group('Transaction.effectiveAmount', () {
    test('regular expense returns full baseAmount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1000,
        isExpense: true,
      );
      expect(txn.effectiveAmount, 1000);
    });

    test('shared expense returns myShare when set', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;
      expect(txn.effectiveAmount, 300);
    });

    test('shared expense with myShare=0 returns 0', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 0
        ..isSharedExpense = true;
      expect(txn.effectiveAmount, 0);
    });

    test('settlement returns 0 regardless of amount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500,
        isExpense: true,
      )..isSettlement = true;
      expect(txn.effectiveAmount, 0);
    });

    test('transfer returns 0 regardless of amount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 5000,
        isExpense: true,
        isTransfer: true,
      );
      expect(txn.effectiveAmount, 0);
    });

    test('income returns full baseAmount', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 50000,
        isExpense: false,
      );
      expect(txn.effectiveAmount, 50000);
    });

    test('settlement income returns 0', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: false,
      )..isSettlement = true;
      expect(txn.effectiveAmount, 0);
    });

    test('converted amount used when available', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
        convertedAmount: 8350,
      );
      expect(txn.baseAmount, 8350);
      expect(txn.effectiveAmount, 8350);
    });

    test('myShare overrides convertedAmount for shared expense', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
        convertedAmount: 8350,
      )
        ..myShare = 2087.5
        ..isSharedExpense = true;
      expect(txn.effectiveAmount, 2087.5);
    });
  });

  group('Transaction.affectsStats', () {
    test('regular expense affects stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500,
        isExpense: true,
      );
      expect(txn.affectsStats, true);
    });

    test('regular income affects stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 50000,
        isExpense: false,
      );
      expect(txn.affectsStats, true);
    });

    test('settlement does NOT affect stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: true,
      )..isSettlement = true;
      expect(txn.affectsStats, false);
    });

    test('transfer does NOT affect stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 5000,
        isExpense: true,
        isTransfer: true,
      );
      expect(txn.affectsStats, false);
    });

    test('settlement + transfer both false', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: true,
        isTransfer: true,
      )..isSettlement = true;
      expect(txn.affectsStats, false);
    });

    test('shared expense DOES affect stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;
      expect(txn.affectsStats, true);
    });
  });

  group('Transaction defaults', () {
    test('new transaction has correct defaults', () {
      final txn = Transaction();
      expect(txn.isSharedExpense, false);
      expect(txn.isSettlement, false);
      expect(txn.myShare, null);
    });

    test('Transaction.create has correct defaults', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
      );
      expect(txn.isTransfer, false);
      expect(txn.isSharedExpense, false);
      expect(txn.isSettlement, false);
      expect(txn.myShare, null);
      expect(txn.effectiveAmount, 100);
      expect(txn.affectsStats, true);
    });
  });

  group('Split expense scenarios', () {
    test('owner paid dinner for 4 — analytics sees only myShare', () {
      // Dinner ₹1200, 4 people, owner paid
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200, // cash outflow
        isExpense: true,
      )
        ..myShare = 300 // owner's share
        ..isSharedExpense = true;

      expect(txn.amount, 1200); // wallet impact
      expect(txn.effectiveAmount, 300); // analytics impact
      expect(txn.affectsStats, true);
    });

    test('friend paid dinner — owner has no cash outflow', () {
      // Dinner ₹1200, friend paid, owner's share ₹300
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 0, // no cash left wallet
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;

      expect(txn.amount, 0); // no wallet impact
      expect(txn.effectiveAmount, 300); // but analytics counts it
      expect(txn.affectsStats, true);
    });

    test('settlement payment — affects balance not stats', () {
      // Owner pays friend ₹300
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: true,
      )
        ..isSettlement = true
        ..isSharedExpense = true;

      expect(txn.amount, 300); // wallet impact
      expect(txn.effectiveAmount, 0); // no analytics impact
      expect(txn.affectsStats, false);
    });

    test('settlement received — affects balance not stats', () {
      // Friend pays owner ₹300
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: false,
      )
        ..isSettlement = true
        ..isSharedExpense = true;

      expect(txn.amount, 300); // wallet impact
      expect(txn.effectiveAmount, 0); // no analytics impact
      expect(txn.affectsStats, false);
    });
  });

  group('Analytics aggregation simulation', () {
    test('sum of effectiveAmount excludes settlements and transfers', () {
      final transactions = [
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true),
        Transaction.create(date: DateTime.now(), amount: 1200, isExpense: true)
          ..myShare = 300
          ..isSharedExpense = true,
        Transaction.create(date: DateTime.now(), amount: 300, isExpense: true)
          ..isSettlement = true,
        Transaction.create(
            date: DateTime.now(),
            amount: 5000,
            isExpense: true,
            isTransfer: true,),
        Transaction.create(date: DateTime.now(), amount: 200, isExpense: true),
      ];

      final totalSpending = transactions
          .where((t) => t.isExpense && t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      // 500 + 300 (myShare) + 200 = 1000
      // Settlement (300) and Transfer (5000) excluded
      expect(totalSpending, 1000);
    });

    test('category breakdown uses effectiveAmount', () {
      final transactions = [
        Transaction.create(
            date: DateTime.now(), amount: 1200, isExpense: true,)
          ..myShare = 300
          ..isSharedExpense = true,
        Transaction.create(
            date: DateTime.now(), amount: 800, isExpense: true,),
      ];

      final categoryTotal = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      // 300 (myShare) + 800 = 1100, NOT 1200 + 800 = 2000
      expect(categoryTotal, 1100);
    });

    test('balance calculation uses full amount', () {
      final transactions = [
        Transaction.create(
            date: DateTime.now(), amount: 1200, isExpense: true,)
          ..myShare = 300
          ..isSharedExpense = true,
        Transaction.create(
            date: DateTime.now(), amount: 300, isExpense: true,)
          ..isSettlement = true,
        Transaction.create(
            date: DateTime.now(), amount: 50000, isExpense: false,),
      ];

      final balance = transactions.fold(0.0, (sum, t) {
        return sum + (t.isExpense ? -t.amount : t.amount);
      });

      // 50000 - 1200 - 300 = 48500
      expect(balance, 48500);
    });
  });
}
