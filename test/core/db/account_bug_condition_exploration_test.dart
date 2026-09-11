import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

/// Property 1 exploration tests for the account crypto/data visibility gap.
///
/// These tests intentionally run against unfixed code. A failure is a
/// baseline counterexample, not a reason to weaken the assertion or change
/// production code. Failure messages contain only account ID and category.
void main() {
  final fieldEncryptionSource =
      File('lib/core/db/field_encryption_service.dart').readAsStringSync();
  final accountExtensionSource =
      File('lib/core/db/extensions/field_encryption_ext.dart')
          .readAsStringSync();
  final accountProvidersSource =
      File('lib/features/account/data/account_providers.dart')
          .readAsStringSync();
  final matchingSource =
      File('lib/features/transactions/data/transaction_matching_service.dart')
          .readAsStringSync();

  group('Property 1 — account crypto boundary exploration', () {
    test('malformed and wrong-key values fail closed', () async {
      const cases = <String>[
        'malformed-encoding',
        'foreign-key-value',
      ];

      for (final category in cases) {
        // Synthetic ENC markers exercise strict account failure
        // classification; no real ciphertext or account number is included.
        final unresolved = await FieldEncryptionService.decryptStrict(
          'ENC:$category',
        );
        expect(unresolved.isFailure, isTrue);
        expect(unresolved.plaintext, isNull);
      }
    });

    test('encryption failure never becomes plaintext persistence', () {
      const candidate = 'redacted-account-input';
      try {
        final stored = FieldEncryptionService.encryptStrict(candidate);
        expect(stored, startsWith('ENC:'));
      } on FieldEncryptionException catch (error) {
        expect(error.category, isNotEmpty);
      }
    });

    test('account extension uses strict preparation before persistence', () async {
      const candidate = 'redacted-account-input';
      final account = Account()
        ..id = 42
        ..name = 'Exploration account'
        ..accountType = AccountType.bank
        ..accountNumber = candidate;

      final preparation = await account.prepareStrictWrite();
      if (preparation.succeeded) {
        expect(preparation.encryptedAccountNumber, startsWith('ENC:'));
        expect(preparation.accountSuffixHash, isNotEmpty);
      } else {
        expect(preparation.errorCategory, isNotEmpty);
      }
      expect(account.accountNumber, candidate);
    });

    test('ciphertext matching uses suffix metadata or strict resolution', () {
      final account = Account()
        ..id = 43
        ..name = 'Exploration bank'
        ..accountType = AccountType.bank
        ..accountNumber = 'ENC:unavailable-account-value'
        ..accountSuffixHash = sha256.convert(utf8.encode('1234')).toString();
      final category = Category.create(
        name: 'Exploration expense',
        categoryType: CategoryType.expense,
      );

      final result = TransactionMatchingService.matchTransaction(
        pending: const _PendingStub(
          account: '1234',
          amount: 10,
          body: 'exploration body',
          isIncome: false,
        ),
        accounts: [account],
        categories: [category],
      );

      if (result == null || result.account.id != account.id) {
        fail(_counterexample('43', 'suffix-match-uses-raw-ciphertext'));
      }
    });
  });

  group('Property 1 — repository contract bypass exploration', () {
    test('strict decrypt contract rejects raw ciphertext fallback', () {
      final strictDecryptSource = _sourceSection(
        fieldEncryptionSource,
        'static Future<StrictDecryptResult> decryptStrict',
        '/// Strict encrypt for account writes.',
      );
      _expectSourceAbsent(
        strictDecryptSource,
        'return ciphertext',
        'crypto-raw-ciphertext-fallback',
      );
      _expectSourceAbsent(
        strictDecryptSource,
        'return ciphertext;',
        'crypto-raw-ciphertext-fallback',
      );
    });

    test('account writes do not use fallback or readiness no-op', () {
      _expectSourceContains(
        accountExtensionSource,
        'prepareStrictWrite',
        'account-encrypt-contract-missing',
      );
      _expectSourceContains(
        accountExtensionSource,
        'FieldEncryptionService.encryptStrict',
        'account-encrypt-strict-missing',
      );
      _expectSourceAbsent(
        accountExtensionSource,
        'encryptOrFallback',
        'account-encrypt-fallback',
      );
    });

    test('all provider reads share account contract and preserve storage', () {
      _expectSourceContains(
        accountProvidersSource,
        'safeAccounts',
        'provider-contract-missing',
      );
      _expectSourceContains(
        accountProvidersSource,
        'safeAccount',
        'provider-contract-missing',
      );
      _expectSourceAbsent(
        accountProvidersSource,
        'await isar.accounts.put(acc)',
        'metadata-reputes-decrypted-model',
      );
      _expectSourceContains(
        accountProvidersSource,
        'primaryAccountProvider',
        'provider-parity-missing',
      );
    });

    test('matching never compares raw accountNumber text', () {
      _expectSourceContains(
        matchingSource,
        'accountSuffixHash',
        'matching-suffix-hash-missing',
      );
      _expectSourceAbsent(
        matchingSource,
        'dbAccNo.endsWith(pendingAccTrimmed)',
        'matching-raw-ciphertext-compare',
      );
      _expectSourceAbsent(
        matchingSource,
        'Looking for account ending with:',
        'matching-secret-bearing-diagnostic',
      );
    });
  });

  group('Property 1 — write, migration, restore, and output surfaces', () {
    final sourceExpectations = <String, List<String>>{
      'lib/features/account/presentation/screens/add_edit_account_screen.dart':
          [
        'AccountDataContract.writeAccount',
      ],
      'lib/core/providers/app_filter_chip.dart': [
        'AccountDataContract.writeAccount',
      ],
      'lib/features/onboarding/presentation/screens/account_setup_screen.dart':
          [
        'AccountDataContract.writeAccount',
      ],
      'lib/core/db/account_encryption_migration.dart': [
        'prepareStrictWrite',
      ],
      'lib/core/db/account_suffix_hash_migration.dart': [
        'resolveAccountNumberStrict',
      ],
      'lib/features/backup/data/account_backup.dart': [
        'accountSuffixHash',
        'reEncrypt',
      ],
    };

    for (final entry in sourceExpectations.entries) {
      test('${entry.key} uses account contract', () {
        final source = File(entry.key).readAsStringSync();
        for (final required in entry.value) {
          _expectSourceContains(source, required, 'bypass-${entry.key}');
        }
      });
    }

    final outputSurfaces = <String>[
      'lib/features/dashboard/presentation/providers/dashboard_data_provider.dart',
      'lib/features/dashboard/presentation/widgets/swipeable_account_card.dart',
      'lib/features/dashboard/presentation/widgets/dashboard_account_card.dart',
      'lib/features/dashboard/presentation/widgets/dashboard_animated_card.dart',
      'lib/features/dashboard/presentation/screens/command_center_screen.dart',
      'lib/features/account/presentation/screens/manage_account_screen.dart',
      'lib/shared/widgets/account_selector.dart',
      'lib/shared/widgets/account_selector_bottom_sheet.dart',
      'lib/shared/widgets/account_display_card.dart',
      'lib/features/transactions/presentation/widgets/add_transaction_widgets.dart',
      'lib/features/transactions/presentation/widgets/quick_add_transaction_sheet.dart',
      'lib/features/transactions/presentation/screens/transfer_screen_new.dart',
      'lib/features/transactions/presentation/screens/add_recurring_transaction_screen.dart',
      'lib/features/transactions/presentation/widgets/sms_activity_card.dart',
      'lib/features/import_export/presentation/screens/import_preview_screen.dart',
      'lib/features/profile/presentation/screens/profile_screen.dart',
      'lib/features/marketplace/screens/plugin_groups_screen.dart',
      'lib/core/services/widget_service.dart',
    ];

    test('all listed output surfaces use safe account presentation', () {
      final unsafe = <String>[];
      for (final path in outputSurfaces) {
        final source = File(path).readAsStringSync();
        final hasSafeBoundary = source.contains('safeAccount') ||
            source.contains('maskedAccount') ||
            source.contains('formatAccount') ||
            source.contains('safeDisplay') ||
            source.contains('AccountDataContract') ||
            source.contains('accountsProvider') ||
            source.contains('linkProjections') ||
            source.contains('AccountCard') ||
            !source.contains('accountNumber');
        if (!hasSafeBoundary) unsafe.add(path);
      }
      if (unsafe.isNotEmpty) {
        fail(_counterexample('account-output-set', 'unsafe-output-surface'));
      }
    });

    test('diagnostics expose only account ID and redacted category', () {
      _expectSourceAbsent(
        fieldEncryptionSource,
        "_log.w('Decrypt failed, returning raw value', e)",
        'diagnostic-secret-bearing-error',
      );
      _expectSourceAbsent(
        matchingSource,
        'pendingAccTrimmed',
        'diagnostic-secret-bearing-match-log',
      );
      _expectSourceAbsent(
        matchingSource,
        r"_log.i('Account matched: ${acc.name}')",
        'diagnostic-account-name-leak',
      );
    });
  });
}

String _sourceSection(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  if (startIndex < 0 || endIndex < 0) return '';
  return source.substring(startIndex, endIndex);
}

String _counterexample(String accountId, String category) =>
    'counterexample accountId=$accountId errorCategory=$category';

void _expectSourceContains(String source, String fragment, String category) {
  if (!source.contains(fragment)) {
    fail(_counterexample('source-contract', category));
  }
}

void _expectSourceAbsent(String source, String fragment, String category) {
  if (source.contains(fragment)) {
    fail(_counterexample('source-contract', category));
  }
}

class _PendingStub implements PendingTransactionData {
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

  const _PendingStub({
    required this.account,
    required this.amount,
    required this.body,
    required this.isIncome,
  }) : fromBank = null;
}
