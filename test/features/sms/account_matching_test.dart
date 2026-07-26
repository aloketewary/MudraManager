import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

void main() {
  group('Account suffix matching', () {
    /// Simulates the endsWith matching used in TransactionMatchingService,
    /// _matchSmsAccount, and _checkAccount.
    bool accountMatches(String? dbAccountNumber, String smsAccountSuffix) {
      final dbAccNo = dbAccountNumber?.trim();
      return dbAccNo != null && dbAccNo.endsWith(smsAccountSuffix.trim());
    }

    test('full account number matches last 4 digits', () {
      expect(accountMatches('123456786988', '6988'), isTrue);
    });

    test('masked account number matches last 4 digits', () {
      expect(accountMatches('XXXX6988', '6988'), isTrue);
    });

    test('exact 4-digit match works', () {
      expect(accountMatches('6988', '6988'), isTrue);
    });

    test('non-matching suffix returns false', () {
      expect(accountMatches('123456781234', '6988'), isFalse);
    });

    test('null db account returns false', () {
      expect(accountMatches(null, '6988'), isFalse);
    });

    test('whitespace is trimmed', () {
      expect(accountMatches('XXXX6988 ', ' 6988'), isTrue);
    });

    test('empty sms account matches everything (edge case)', () {
      // endsWith('') is always true — callers should guard against empty
      expect(accountMatches('XXXX6988', ''), isTrue);
    });
  });

  group('TransactionMatchingService account matching', () {
    late List<Account> accounts;
    late List<db_category.Category> categories;

    setUp(() {
      final account = Account()
        ..name = 'HDFC Savings'
        ..accountNumber = 'XXXX6988'
        ..accountType = AccountType.bank
        ..isActive = true;

      final category = db_category.Category()
        ..name = 'Others'
        ..categoryType = db_category.CategoryType.expense
        ..keywords = ['others'];

      accounts = [account];
      categories = [category];
    });

    test('matches account by last 4 digits from SMS', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _FakePending(
          account: '6988',
          isIncome: false,
          body: 'Rs.500 debited from A/c XX6988',
          amount: 500.0,
        ),
        accounts: accounts,
        categories: categories,
      );

      expect(result, isNotNull);
      expect(result!.account.name, 'HDFC Savings');
    });

    test('does not match when suffix differs', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _FakePending(
          account: '1234',
          isIncome: false,
          body: 'Rs.500 debited from A/c XX1234',
          amount: 500.0,
        ),
        accounts: accounts,
        categories: categories,
      );

      expect(result, isNull);
    });

    test('returns null when account is empty', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _FakePending(
          account: '',
          isIncome: false,
          body: 'Rs.500 debited',
          amount: 500.0,
        ),
        accounts: accounts,
        categories: categories,
      );

      expect(result, isNull);
    });

    test('returns null when account is null', () {
      final result = TransactionMatchingService.matchTransaction(
        pending: _FakePending(
          account: null,
          isIncome: false,
          body: 'Rs.500 debited',
          amount: 500.0,
        ),
        accounts: accounts,
        categories: categories,
      );

      expect(result, isNull);
    });

    test('matches credit card by bank name fallback', () {
      final ccAccount = Account()
        ..name = 'HDFC Credit Card'
        ..accountNumber = null
        ..accountType = AccountType.creditCard
        ..isActive = true;

      final result = TransactionMatchingService.matchTransaction(
        pending: _FakePending(
          account: '9999',
          isIncome: false,
          body: 'Rs.500 charged on HDFC card',
          amount: 500.0,
          fromBank: 'HDFC',
        ),
        accounts: [ccAccount],
        categories: categories,
      );

      expect(result, isNotNull);
      expect(result!.account.name, 'HDFC Credit Card');
    });
  });
}

/// Fake pending transaction adapter for testing
class _FakePending implements PendingTransactionData {
  @override
  final String? account;
  @override
  final bool? isIncome;
  @override
  final String body;
  @override
  final double? amount;
  @override
  final String? fromBank;
  final String? toAccount;

  _FakePending({
    this.account,
    this.isIncome,
    required this.body,
    this.amount,
    this.fromBank,
  }) : toAccount = null;
  

}
