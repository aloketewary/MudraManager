import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';

void main() {
  group('Account credit card fields', () {
    test('new account has null credit card fields by default', () {
      final account = Account();
      expect(account.statementDay, isNull);
      expect(account.dueDay, isNull);
      expect(account.creditLimit, isNull);
    });

    test('credit card fields can be set', () {
      final account = Account()
        ..name = 'HDFC Regalia'
        ..accountType = AccountType.creditCard
        ..initialBalance = -5000
        ..statementDay = 15
        ..dueDay = 5
        ..creditLimit = 200000;

      expect(account.statementDay, 15);
      expect(account.dueDay, 5);
      expect(account.creditLimit, 200000);
      expect(account.accountType, AccountType.creditCard);
    });

    test('non-credit-card account ignores credit card fields', () {
      final account = Account()
        ..name = 'SBI Savings'
        ..accountType = AccountType.bank
        ..initialBalance = 50000;

      expect(account.statementDay, isNull);
      expect(account.dueDay, isNull);
      expect(account.creditLimit, isNull);
    });

    test('credit card fields can be cleared', () {
      final account = Account()
        ..statementDay = 15
        ..dueDay = 5
        ..creditLimit = 200000;

      account
        ..statementDay = null
        ..dueDay = null
        ..creditLimit = null;

      expect(account.statementDay, isNull);
      expect(account.dueDay, isNull);
      expect(account.creditLimit, isNull);
    });

    test('dueDay accepts valid range 1-31', () {
      final account = Account();
      for (int day = 1; day <= 31; day++) {
        account.dueDay = day;
        expect(account.dueDay, day);
      }
    });

    test('statementDay accepts valid range 1-31', () {
      final account = Account();
      for (int day = 1; day <= 31; day++) {
        account.statementDay = day;
        expect(account.statementDay, day);
      }
    });
  });

  group('AccountType enum', () {
    test('includes creditCard type', () {
      expect(AccountType.values, contains(AccountType.creditCard));
    });

    test('has all expected types', () {
      expect(AccountType.values.length, 6);
      expect(AccountType.values, containsAll([
        AccountType.bank,
        AccountType.cash,
        AccountType.creditCard,
        AccountType.eWallet,
        AccountType.investment,
        AccountType.other,
      ]),);
    });
  });
}
