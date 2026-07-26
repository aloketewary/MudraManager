import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

class _TestPending implements PendingTransactionData {
  @override
  final String? account;
  @override
  final double? amount;
  @override
  final bool? isIncome;
  @override
  final String body;
  @override
  final String? fromBank;
  
  final String toAccount;

  _TestPending({
    this.account,
    this.amount,
    this.isIncome,
    required this.body,
    this.fromBank,
    required this.toAccount,
  });
}

void main() {
  late Account testAccount;
  late db_category.Category foodCategory;
  late db_category.Category othersCategory;

  setUp(() {
    testAccount = Account()
      ..name = 'HDFC Savings'
      ..accountNumber = 'XXXX6988'
      ..accountType = AccountType.bank
      ..isActive = true;

    foodCategory = db_category.Category()
      ..name = 'Food'
      ..categoryType = db_category.CategoryType.expense
      ..keywords = ['swiggy', 'zomato', 'food'];

    othersCategory = db_category.Category()
      ..name = 'Others'
      ..categoryType = db_category.CategoryType.expense
      ..keywords = ['others'];
  });

  group('TransactionMatchingService preMatchedCategory', () {
    test('uses preMatchedCategory when provided', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _TestPending(
          account: '6988',
          isIncome: false,
          body: 'Rs.500 debited from A/c XX6988',
          amount: 500.0,
          toAccount: '',
        ),
        accounts: [testAccount],
        categories: [foodCategory, othersCategory],
        preMatchedCategory: foodCategory,
      );

      expect(result, isNotNull);
      expect(result!.category.name, 'Food');
    });

    test('falls back to matcher when preMatchedCategory is null', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _TestPending(
          account: '6988',
          isIncome: false,
          body: 'Rs.500 debited from A/c XX6988',
          amount: 500.0,
          fromBank: '',
          toAccount: '',
        ),
        accounts: [testAccount],
        categories: [foodCategory, othersCategory],
        preMatchedCategory: null,
      );

      expect(result, isNotNull);
      // Without preMatchedCategory, matcher runs and picks a category
      expect(result!.category, isNotNull);
    });

    test('preMatchedCategory overrides what matcher would pick', () {
      // Body contains "swiggy" which would match Food,
      // but we force Others via preMatchedCategory
      final result = TransactionMatchingService.matchTransaction(
        pending: _TestPending(
          account: '6988',
          isIncome: false,
          body: 'Rs.500 debited at Swiggy from A/c XX6988',
          amount: 500.0,
          toAccount: '',
        ),
        accounts: [testAccount],
        categories: [foodCategory, othersCategory],
        preMatchedCategory: othersCategory,
      );

      expect(result, isNotNull);
      expect(result!.category.name, 'Others');
    });

    test('still returns null if no account match even with preMatchedCategory', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _TestPending(
          account: '9999',
          isIncome: false,
          body: 'Rs.500 debited',
          amount: 500.0,
          toAccount: '',
        ),
        accounts: [testAccount],
        categories: [foodCategory, othersCategory],
        preMatchedCategory: foodCategory,
      );

      expect(result, isNull);
    });
  });
}
