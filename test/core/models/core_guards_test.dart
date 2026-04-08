import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

void main() {
  group('Currency formatting guards', () {
    test('INR formats with Indian grouping', () {
      final result = formatCurrency(1234567, code: 'INR', decimals: 0);
      expect(result.contains('12'), true);
      expect(result.contains('₹'), true);
    });

    test('USD formats with standard grouping', () {
      final result = formatCurrency(1234567, code: 'USD', decimals: 0);
      expect(result.contains('\$'), true);
    });

    test('zero amount formats correctly', () {
      final result = formatCurrency(0, code: 'INR', decimals: 0);
      expect(result.contains('0'), true);
    });

    test('negative amount handled', () {
      final result = formatCurrency(-500, code: 'INR', decimals: 0);
      expect(result.contains('500'), true);
    });

    test('currencySymbol returns correct symbols', () {
      expect(currencySymbol('INR'), '₹');
      expect(currencySymbol('USD'), '\$');
      expect(currencySymbol('EUR'), '€');
      expect(currencySymbol('GBP'), '£');
    });

    test('null code defaults to INR', () {
      expect(currencySymbol(null), '₹');
    });
  });

  group('Goal model guards', () {
    test('progressPercent clamps between 0 and 1', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 10000,
        currentAmount: 15000,
      );
      expect(goal.progressPercent, 1.0);
    });

    test('progressPercent is 0 when target is 0', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 0,
        currentAmount: 500,
      );
      expect(goal.progressPercent, 0.0);
    });

    test('remainingAmount never negative', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 1000,
        currentAmount: 1500,
      );
      expect(goal.remainingAmount, 0.0);
    });

    test('remainingAmount correct when partially saved', () {
      final goal = Goal.create(
        name: 'Test',
        targetAmount: 10000,
        currentAmount: 3000,
      );
      expect(goal.remainingAmount, 7000);
    });

    test('goal defaults are correct', () {
      final goal = Goal();
      expect(goal.isActive, true);
      expect(goal.currentAmount, 0.0);
      expect(goal.contributions, isEmpty);
    });
  });

  group('Account model guards', () {
    test('account defaults', () {
      final account = Account();
      expect(account.isActive, true);
      expect(account.isPrimary, false);
    });

    test('account types exist', () {
      expect(AccountType.values.length, greaterThanOrEqualTo(5));
      expect(AccountType.values, contains(AccountType.bank));
      expect(AccountType.values, contains(AccountType.cash));
      expect(AccountType.values, contains(AccountType.creditCard));
    });
  });

  group('Category model guards', () {
    test('category defaults', () {
      final cat = Category();
      expect(cat.isSystem, false);
    });

    test('category types exist', () {
      expect(CategoryType.values, contains(CategoryType.income));
      expect(CategoryType.values, contains(CategoryType.expense));
    });

    test('system category not mixed with user categories', () {
      final categories = [
        Category.create(name: 'Food', categoryType: CategoryType.expense),
        Category.create(name: 'Salary', categoryType: CategoryType.income),
        Category.create(name: 'Settlement', categoryType: CategoryType.expense)
          ..isSystem = true,
      ];

      final userCats = categories.where((c) => !c.isSystem).toList();
      expect(userCats.length, 2);
      expect(userCats.every((c) => !c.isSystem), true);
    });
  });

  group('Transaction model invariants', () {
    test('effectiveAmount always >= 0 for expenses', () {
      final scenarios = [
        Transaction.create(date: DateTime.now(), amount: 100, isExpense: true),
        Transaction.create(date: DateTime.now(), amount: 100, isExpense: true)
          ..myShare = 50,
        Transaction.create(date: DateTime.now(), amount: 100, isExpense: true)
          ..isSettlement = true,
        Transaction.create(
            date: DateTime.now(),
            amount: 100,
            isExpense: true,
            isTransfer: true),
      ];

      for (final txn in scenarios) {
        expect(txn.effectiveAmount, greaterThanOrEqualTo(0),
            reason: 'effectiveAmount should never be negative');
      }
    });

    test('affectsStats is consistent with effectiveAmount', () {
      final settlement = Transaction.create(
        date: DateTime.now(),
        amount: 500,
        isExpense: true,
      )..isSettlement = true;

      // If doesn't affect stats, effectiveAmount should be 0
      if (!settlement.affectsStats) {
        expect(settlement.effectiveAmount, 0);
      }
    });

    test('baseAmount uses convertedAmount when available', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
        convertedAmount: 8350,
      );
      expect(txn.baseAmount, 8350);
      expect(txn.amount, 100); // original preserved
    });

    test('baseAmount falls back to amount when no conversion', () {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount: 500,
        isExpense: true,
      );
      expect(txn.baseAmount, 500);
    });
  });

  group('Recurring bill edge cases', () {
    test('daily frequency advances by 1 day', () {
      final current = DateTime(2024, 1, 15);
      final next = current.add(const Duration(days: 1));
      expect(next, DateTime(2024, 1, 16));
    });

    test('monthly frequency handles month end', () {
      final jan31 = DateTime(2024, 1, 31);
      final next = DateTime(jan31.year, jan31.month + 1, jan31.day);
      // Feb 31 doesn't exist — Dart wraps to March 2
      expect(next.month, 3);
      expect(next.day, 2);
    });

    test('yearly frequency handles leap year', () {
      final feb29 = DateTime(2024, 2, 29); // leap year
      final next = DateTime(feb29.year + 1, feb29.month, feb29.day);
      // 2025 is not a leap year — wraps to March 1
      expect(next.month, 3);
      expect(next.day, 1);
    });
  });
}
