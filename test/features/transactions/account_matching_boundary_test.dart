import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

void main() {
  Account account({
    required int id,
    required String? number,
    String? suffixHash,
    AccountType type = AccountType.bank,
    String name = 'Bank',
  }) {
    return Account()
      ..id = id
      ..name = name
      ..accountType = type
      ..initialBalance = 0
      ..accountNumber = number
      ..accountSuffixHash = suffixHash;
  }

  final category = Category.create(
    name: 'Expense',
    categoryType: CategoryType.expense,
  );

  test('hash matching accepts full SMS token and legacy 16-char hash', () {
    // Validates: Requirements 1.6, 1.13, 2.5, 2.12, 2.14, 3.6.
    final fullHash = accountSuffixHashFor('1234');
    final legacyHash = accountSuffixHashFor('5678').substring(0, 16);
    final fullHashAccount = account(
      id: 1,
      number: 'ENC:opaque',
      suffixHash: fullHash,
    );
    final legacyHashAccount = account(
      id: 2,
      number: '•••• 5678',
      suffixHash: legacyHash,
    );

    expect(
      AccountMatchingBoundary.matches(fullHashAccount, 'XXXX1234'),
      isTrue,
    );
    expect(
      AccountMatchingBoundary.matches(legacyHashAccount, '5678'),
      isTrue,
    );
  });

  test('safe provider account matches by preserved hash, not masked text', () {
    // Validates: Requirements 2.3, 2.10, 2.12, 2.16.
    final safe = account(
      id: 3,
      number: '•••• 9876',
      suffixHash: accountSuffixHashFor('9876'),
    );

    expect(AccountMatchingBoundary.matches(safe, 'A/C XXXX9876'), isTrue);
    expect(safe.accountNumber, '•••• 9876');
  });

  test('ciphertext without suffix metadata fails closed', () {
    // Validates: Requirements 2.2, 2.12, 2.16, 2.17.
    final foreign = account(id: 4, number: 'ENC:foreign-key-ciphertext');

    expect(AccountMatchingBoundary.matches(foreign, '1234'), isFalse);
    expect(
      TransactionMatchingService.matchTransaction(
        pending: _Pending(account: '1234'),
        accounts: [foreign],
        categories: [category],
      ),
      isNull,
    );
  });

  test('legacy plaintext fallback stays inside matching boundary', () {
    // Validates: Requirements 2.12, 2.14, 3.6.
    final legacy = account(id: 5, number: '0000001234');

    expect(AccountMatchingBoundary.matches(legacy, '1234'), isTrue);
    expect(
      TransactionMatchingService.matchTransaction(
        pending: _Pending(account: '1234'),
        accounts: [legacy],
        categories: [category],
      )?.account.id,
      5,
    );
  });

  test('duplicate suffix precedence and bank fallback remain stable', () {
    // Validates: Requirements 2.12, 3.6.
    final first = account(
      id: 6,
      number: 'ENC:first',
      suffixHash: accountSuffixHashFor('2222'),
    );
    final second = account(
      id: 7,
      number: 'ENC:second',
      suffixHash: accountSuffixHashFor('2222'),
    );
    final match = TransactionMatchingService.matchTransaction(
      pending: _Pending(account: '2222'),
      accounts: [first, second],
      categories: [category],
    );
    expect(match?.account.id, 6);

    final card = account(
      id: 8,
      number: 'ENC:opaque',
      type: AccountType.creditCard,
      name: 'Acme Bank Card',
    );
    final fallback = TransactionMatchingService.matchTransaction(
      pending: _Pending(account: 'unavailable', fromBank: 'Acme Bank'),
      accounts: [card],
      categories: [category],
    );
    expect(fallback?.account.id, 8);
  });

  test('suffix hash generator hashes only final four characters', () {
    // Validates: Requirements 2.12, 3.6, 3.8.
    for (final token in ['1234', 'X1234', 'A/C XXXX1234']) {
      final expected = sha256.convert(utf8.encode('1234')).toString();
      final candidate = account(
        id: 9,
        number: 'ENC:opaque',
        suffixHash: expected,
      );
      expect(AccountMatchingBoundary.matches(candidate, token), isTrue);
    }
  });

  test('task 4.6 flows use matching boundary or link-only account access', () {
    // Validates: Requirements 1.6, 1.13, 1.15, 2.5, 2.10, 2.12, 2.13, 2.14, 2.16, 3.6, 3.8.
    final requiredFragments = <String, List<String>>{
      'lib/features/transactions/data/transaction_matching_service.dart': [
        'AccountMatchingBoundary',
        'accountSuffixHash'
      ],
      'lib/features/transactions/presentation/providers/smart_defaults_provider.dart':
          ['AccountDataContract.safeAccount'],
      'lib/features/transactions/data/pending_transaction_prodiver.dart': [
        'AccountDataContract.safeAccounts',
        'TransactionMatchingService'
      ],
      'lib/features/transactions/presentation/screens/add_edit_transaction_screen.dart':
          ['AccountMatchingBoundary', 'AccountDataContract.safeAccount'],
      'lib/shared/widgets/account_selector.dart': ['AccountMatchingBoundary'],
      'lib/features/sms/data/sms_activity_service.dart': [
        'AccountMatchingBoundary'
      ],
      'lib/features/sms/presentation/screens/sms_activity_screen.dart': [
        'AccountMatchingBoundary',
        'SafeAccountPresentation',
      ],
      'lib/features/transactions/presentation/widgets/sms_activity_card.dart': [
        'AccountMatchingBoundary',
        'SafeAccountPresentation',
      ],
    };

    for (final entry in requiredFragments.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final fragment in entry.value) {
        expect(source, contains(fragment), reason: entry.key);
      }
    }

    for (final path in [
      'lib/features/transactions/presentation/screens/transfer_screen_new.dart',
      'lib/features/transactions/presentation/screens/add_recurring_transaction_screen.dart',
      'lib/features/transactions/presentation/screens/transaction_list_screen.dart',
      'lib/features/transactions/presentation/screens/bill_control_center_screen.dart',
      'lib/features/transactions/data/recurring_transaction_service.dart',
      'lib/features/transactions/data/bulk_transaction_service.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('accountNumber')), reason: path);
    }
  });
}

class _Pending implements PendingTransactionData {
  @override
  final String? account;

  @override
  final double? amount = 10;

  @override
  final bool? isIncome = false;

  @override
  final String body = 'test purchase';

  @override
  final String? fromBank;

  const _Pending({required this.account, this.fromBank});
}
