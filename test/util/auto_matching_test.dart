import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

void main() {
  group('TransactionMatchingService - matchTransaction', () {
    late List<Account> mockAccounts;
    late List<Category> mockCategories;

    setUp(() {
      mockAccounts = [
        Account.create(name: 'HDFC Bank')..accountNumber = '1234',
        Account.create(name: 'SBM Bank')..accountNumber = '1651',
      ];
      mockCategories = [
        Category.create(name: 'Grocery', categoryType: CategoryType.expense),
        Category.create(name: 'Salary', categoryType: CategoryType.income),
        Category.create(name: 'Other', categoryType: CategoryType.expense),
      ];
    });

    test('should match account with exact 4 digits', () {
      final pending = PendingTransaction()
        ..account = '1651'
        ..body = 'Some transaction on SBM'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNotNull);
      expect(result!.account.name, 'SBM Bank');
    });

    test('should match account with suffix match', () {
      final pending = PendingTransaction()
        ..account = '1234'
        ..body = 'HDFC bank alert'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNotNull);
      expect(result!.account.name, 'HDFC Bank');
    });

    test('should NOT match account if number is different', () {
      final pending = PendingTransaction()
        ..account = '9999'
        ..body = 'Unknown bank'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNull);
    });

    test('should match category by keyword in body', () {
      final pending = PendingTransaction()
        ..account = '1234'
        ..body = 'Spent Rs. 500 on Grocery shop'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNotNull);
      expect(result!.category.name, 'Grocery');
    });

    test('should match vegetable transaction to Grocery category', () {
      final pending = PendingTransaction()
        ..account = '1234'
        ..body =
            'Sent Rs.154.00\nFrom HDFC Bank A/C *7334\nTo SRI LAKSHMI VEGETABLE AND\nOn 01/02/26'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNotNull);
      expect(result!.category.name, 'Grocery');
    });

    test('should fallback to OTHER category if no match found', () {
      final pending = PendingTransaction()
        ..account = '9999'
        ..body = 'Random expense'
        ..isIncome = false;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNull);
    });

    test('should handle income matching correctly', () {
      final pending = PendingTransaction()
        ..account = '1651'
        ..body = 'Salary credited'
        ..isIncome = true;

      final result = TransactionMatchingService.matchTransaction(
        pending: pending,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(result, isNotNull);
      expect(result!.category.name, 'Salary');
    });
  });
}
