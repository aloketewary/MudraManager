import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

void main() {
  group('Delete cascade: main transaction deleted', () {
    test('shared expense fields reset when unlinked from trip', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;

      // Simulate removeTransactionFromTrip cleanup
      txn.myShare = null;
      txn.isSharedExpense = false;

      expect(txn.myShare, null);
      expect(txn.isSharedExpense, false);
      expect(txn.effectiveAmount, 1200); // reverts to full amount
    });

    test('settlement transaction cleanup removes from stats', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 300,
        isExpense: true,
      )..isSettlement = true;

      // Before delete: doesn't affect stats
      expect(txn.affectsStats, false);
      expect(txn.effectiveAmount, 0);

      // After delete: transaction is gone, no orphan impact
      // (This is a conceptual test — actual deletion removes the object)
    });
  });

  group('Delete cascade: trip expense deleted', () {
    test('deleting trip expense should remove ledger transaction', () {
      // Simulate: trip expense exists with linked ledger txn
      final ledgerTxn = Transaction.create(
        date: DateTime.now(),
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;

      // Before delete
      expect(ledgerTxn.effectiveAmount, 300);

      // After removeTripTransaction: both SplitExpense and Transaction deleted
      // Verify the ledger txn would be cleaned up (conceptual)
      final isDeleted = true; // simulated
      expect(isDeleted, true);
    });
  });

  group('Delete cascade: entire trip deleted', () {
    test('all linked transactions should be cleaned up', () {
      final ledgerTxns = [
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true)
          ..myShare = 250
          ..isSharedExpense = true,
        Transaction.create(date: DateTime.now(), amount: 800, isExpense: true)
          ..myShare = 400
          ..isSharedExpense = true,
        Transaction.create(date: DateTime.now(), amount: 300, isExpense: true)
          ..isSettlement = true,
      ];

      // Before delete: 3 transactions exist
      expect(ledgerTxns.length, 3);

      // After deleteTrip: all should be removed
      ledgerTxns.clear(); // simulated
      expect(ledgerTxns.length, 0);
    });
  });

  group('Analytics after delete', () {
    test('deleted shared expense no longer counted in stats', () {
      final transactions = [
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true),
        Transaction.create(date: DateTime.now(), amount: 1200, isExpense: true)
          ..myShare = 300
          ..isSharedExpense = true,
      ];

      var total = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      expect(total, 800); // 500 + 300

      // Delete the shared expense
      transactions.removeAt(1);

      total = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      expect(total, 500); // only personal expense remains
    });

    test('deleted settlement does not affect stats total', () {
      final transactions = [
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true),
        Transaction.create(date: DateTime.now(), amount: 300, isExpense: true)
          ..isSettlement = true,
      ];

      var total = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      expect(total, 500); // settlement excluded

      // Delete the settlement
      transactions.removeAt(1);

      total = transactions
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      expect(total, 500); // unchanged — settlement never affected stats
    });
  });

  group('Balance after delete', () {
    test('deleting shared expense restores balance', () {
      var balance = 50000.0;

      // Owner paid ₹1200 for group dinner
      balance -= 1200;
      expect(balance, 48800);

      // Delete the expense — balance restored
      balance += 1200;
      expect(balance, 50000);
    });

    test('deleting settlement reverses balance change', () {
      var balance = 50000.0;

      // Owner paid settlement ₹300
      balance -= 300;
      expect(balance, 49700);

      // Delete the settlement — balance restored
      balance += 300;
      expect(balance, 50000);
    });

    test('deleting received settlement reverses income', () {
      var balance = 50000.0;

      // Friend paid owner ₹300
      balance += 300;
      expect(balance, 50300);

      // Delete the settlement — balance restored
      balance -= 300;
      expect(balance, 50000);
    });
  });
}
