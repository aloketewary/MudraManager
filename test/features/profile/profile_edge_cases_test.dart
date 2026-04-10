import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_display_extension.dart';
import 'package:mudra_manager/features/profile/data/help_item.dart';

void main() {
  group('AccountDisplayExtension', () {
    Account makeAccount(AccountType type) {
      return Account()..accountType = type;
    }

    test('credit card shows Outstanding', () {
      expect(makeAccount(AccountType.creditCard).getBalanceLabel(), 'Outstanding');
    });

    test('bank shows Balance', () {
      expect(makeAccount(AccountType.bank).getBalanceLabel(), 'Balance');
    });

    test('cash shows Cash', () {
      expect(makeAccount(AccountType.cash).getBalanceLabel(), 'Cash');
    });

    test('investment shows Value', () {
      expect(makeAccount(AccountType.investment).getBalanceLabel(), 'Value');
    });

    test('eWallet shows Balance', () {
      expect(makeAccount(AccountType.eWallet).getBalanceLabel(), 'Balance');
    });

    test('credit card healthy when balance <= 0', () {
      final cc = makeAccount(AccountType.creditCard);
      expect(cc.isBalanceHealthy(0), true);
      expect(cc.isBalanceHealthy(-100), true);
      expect(cc.isBalanceHealthy(500), false);
    });

    test('bank healthy when balance >= 0', () {
      final bank = makeAccount(AccountType.bank);
      expect(bank.isBalanceHealthy(1000), true);
      expect(bank.isBalanceHealthy(0), true);
      expect(bank.isBalanceHealthy(-100), false);
    });

    test('cash healthy when balance >= 0', () {
      final cash = makeAccount(AccountType.cash);
      expect(cash.isBalanceHealthy(500), true);
      expect(cash.isBalanceHealthy(-1), false);
    });
  });

  group('HelpItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'sms_import',
        'title': 'SMS Import',
        'icon': 'message',
        'shortDescription': 'Auto-import transactions',
        'description': 'Full description here',
        'steps': ['Step 1', 'Step 2'],
        'tips': ['Tip 1'],
      };

      final item = HelpItem.fromJson(json);
      expect(item.id, 'sms_import');
      expect(item.title, 'SMS Import');
      expect(item.icon, 'message');
      expect(item.shortDescription, 'Auto-import transactions');
      expect(item.description, 'Full description here');
      expect(item.steps, ['Step 1', 'Step 2']);
      expect(item.tips, ['Tip 1']);
    });

    test('fromJson handles empty lists', () {
      final json = {
        'id': 'test',
        'title': 'Test',
        'icon': 'help',
        'shortDescription': 'Short',
        'description': 'Desc',
        'steps': <String>[],
        'tips': <String>[],
      };

      final item = HelpItem.fromJson(json);
      expect(item.steps, isEmpty);
      expect(item.tips, isEmpty);
    });
  });
}
