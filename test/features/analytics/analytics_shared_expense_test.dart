import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

void main() {
  group('Analytics with mixed transaction types', () {
    late List<Transaction> transactions;

    setUp(() {
      transactions = [
        // Regular personal expenses
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true),
        Transaction.create(date: DateTime.now(), amount: 300, isExpense: true),

        // Shared expense: owner paid ₹1200, share ₹400
        Transaction.create(date: DateTime.now(), amount: 1200, isExpense: true)
          ..myShare = 400
          ..isSharedExpense = true,

        // Shared expense: friend paid, owner's share ₹300
        Transaction.create(date: DateTime.now(), amount: 0, isExpense: true)
          ..myShare = 300
          ..isSharedExpense = true,

        // Settlement: owner paid friend ₹500
        Transaction.create(date: DateTime.now(), amount: 500, isExpense: true)
          ..isSettlement = true,

        // Settlement: friend paid owner ₹200
        Transaction.create(date: DateTime.now(), amount: 200, isExpense: false)
          ..isSettlement = true,

        // Transfer between accounts
        Transaction.create(
            date: DateTime.now(),
            amount: 10000,
            isExpense: true,
            isTransfer: true),

        // Regular income
        Transaction.create(
            date: DateTime.now(), amount: 50000, isExpense: false),
      ];
    });

    test('total spending uses effectiveAmount', () {
      final spending = transactions
          .where((t) => t.isExpense && t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      // 500 + 300 + 400 (myShare) + 300 (myShare) = 1500
      expect(spending, 1500);
    });

    test('total income excludes settlements', () {
      final income = transactions
          .where((t) => !t.isExpense && t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      // Only regular income: 50000
      // Settlement received (200) excluded
      expect(income, 50000);
    });

    test('savings rate calculation is correct', () {
      final income = transactions
          .where((t) => !t.isExpense && t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);
      final expense = transactions
          .where((t) => t.isExpense && t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      final savingsRate = ((income - expense) / income * 100);

      // (50000 - 1500) / 50000 * 100 = 97%
      expect(savingsRate, 97);
    });

    test('cash flow includes all amounts', () {
      final cashOut = transactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final cashIn = transactions
          .where((t) => !t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Cash out: 500 + 300 + 1200 + 0 + 500 + 10000 = 12500
      expect(cashOut, 12500);
      // Cash in: 200 + 50000 = 50200
      expect(cashIn, 50200);
    });

    test('transaction count for stats excludes settlements and transfers', () {
      final statsTxnCount =
          transactions.where((t) => t.affectsStats).length;

      // 4 expenses (2 regular + 2 shared) + 1 income = 5
      // Excludes: 2 settlements + 1 transfer
      expect(statsTxnCount, 5);
    });
  });

  group('Essential vs discretionary with shared expenses', () {
    test('shared expense counted at myShare for category ratio', () {
      // Simulate: ₹1200 dinner (shared, myShare ₹300) + ₹500 groceries
      final foodShare = 300.0; // myShare of shared dinner
      final groceries = 500.0;
      final totalExpense = foodShare + groceries;

      final essentialRatio = groceries / totalExpense;
      final discretionaryRatio = foodShare / totalExpense;

      expect(essentialRatio, closeTo(0.625, 0.001));
      expect(discretionaryRatio, closeTo(0.375, 0.001));
    });
  });

  group('Weekend spending with shared expenses', () {
    test('weekend ratio uses effectiveAmount', () {
      final weekdayTxn = Transaction.create(
        date: DateTime(2024, 1, 15), // Monday
        amount: 500,
        isExpense: true,
      );
      final weekendTxn = Transaction.create(
        date: DateTime(2024, 1, 13), // Saturday
        amount: 1200,
        isExpense: true,
      )
        ..myShare = 300
        ..isSharedExpense = true;

      final transactions = [weekdayTxn, weekendTxn];
      final total = transactions.fold(
          0.0, (sum, t) => sum + t.effectiveAmount);
      final weekendAmount = weekendTxn.effectiveAmount;

      final weekendRatio = weekendAmount / total;

      // 300 / (500 + 300) = 0.375
      expect(weekendRatio, closeTo(0.375, 0.001));
    });
  });

  group('Budget impact with shared expenses', () {
    test('budget tracks effectiveAmount not full amount', () {
      final budgetLimit = 5000.0;

      final expenses = [
        Transaction.create(
            date: DateTime.now(), amount: 2000, isExpense: true),
        Transaction.create(
            date: DateTime.now(), amount: 1200, isExpense: true)
          ..myShare = 400
          ..isSharedExpense = true,
        Transaction.create(
            date: DateTime.now(), amount: 800, isExpense: true),
      ];

      final spent = expenses
          .where((t) => t.affectsStats)
          .fold(0.0, (sum, t) => sum + t.effectiveAmount);

      // 2000 + 400 (myShare) + 800 = 3200
      expect(spent, 3200);
      expect(spent < budgetLimit, true);

      // If we used full amount: 2000 + 1200 + 800 = 4000 (wrong!)
      final wrongSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
      expect(wrongSpent, 4000);
    });
  });
}
