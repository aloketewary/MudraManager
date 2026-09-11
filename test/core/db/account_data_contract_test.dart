import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:mudra_manager/features/backup/data/account_backup.dart';

void main() {
  setUp(() {
    final key = base64Encode(List<int>.generate(32, (index) => index + 1));
    FieldEncryptionService.setKeyForTesting(key);
  });

  tearDown(FieldEncryptionService.resetForTesting);

  Account account({
    required int id,
    required String name,
    String? number,
    bool active = true,
    bool primary = false,
  }) {
    return Account()
      ..id = id
      ..name = name
      ..accountType = AccountType.bank
      ..initialBalance = 100
      ..accountNumber = number
      ..isActive = active
      ..isPrimary = primary
      ..currencyCode = 'INR';
  }

  test('strict read returns detached safe copy and preserves metadata',
      () async {
    final stored = account(id: 7, name: 'Primary', number: '1234567890')
      ..accountSuffixHash = 'suffix-hash';

    final result = await AccountDataContract.resolveAccount(stored);

    expect(result.resolution.isResolved, isTrue);
    expect(result.resolution.resolvedValue, '1234567890');
    expect(result.account.accountNumber, '•••• 7890');
    expect(result.account.accountSuffixHash, 'suffix-hash');
    expect(result.account.id, stored.id);
    expect(result.account.name, stored.name);
    expect(result.account.initialBalance, stored.initialBalance);
    expect(identical(result.account, stored), isFalse);
    expect(stored.accountNumber, '1234567890');
  });

  test('safe presentation formatter masks or rejects every unsafe state', () {
    expect(
      SafeAccountPresentation.formatAccountNumber('1234567890'),
      '•••• 7890',
    );
    expect(
      SafeAccountPresentation.formatAccountNumber('•••• 7890'),
      '•••• 7890',
    );
    expect(
      SafeAccountPresentation.formatAccountNumber('ENC:secret-ciphertext'),
      '••••',
    );
    expect(SafeAccountPresentation.formatAccountNumber(null), '••••');
    expect(SafeAccountPresentation.formatAccountNumber(''), '••••');
    expect(SafeAccountPresentation.formatAccountNumber('123'), '••••');
    expect(
      SafeAccountPresentation.formatAccountNumber('**** 7890'),
      '•••• 7890',
    );
  });
  test('active/all/primary-style reads share order and safe output', () async {
    final stored = [
      account(id: 7, name: 'First', number: '1111'),
      account(id: 3, name: 'Primary', number: '2222', primary: true),
      account(id: 11, name: 'Archived', number: '3333', active: false),
    ];

    final active = await AccountDataContract.resolveAccounts(
      stored.where((item) => item.isActive),
    );
    final all = await AccountDataContract.resolveAccounts(stored);
    final primary = all
        .firstWhere((item) => item.account.isPrimary && item.account.isActive);

    expect(active.map((item) => item.account.id), [7, 3]);
    expect(all.map((item) => item.account.id), [7, 3, 11]);
    expect(primary.account.id, 3);
    expect(
      active.map((item) => item.account.accountNumber),
      ['•••• 1111', '•••• 2222'],
    );
    expect(
      all.every((item) => !item.account.accountNumber!.startsWith('ENC:')),
      isTrue,
    );
  });

  test('malformed record preserves non-sensitive fields and fails safe',
      () async {
    final stored = account(id: 9, name: 'Unavailable', number: 'ENC:bad');

    final result = await AccountDataContract.resolveAccount(stored);

    expect(result.account.id, 9);
    expect(result.account.name, 'Unavailable');
    expect(result.account.accountType, AccountType.bank);
    expect(result.account.accountNumber, '••••');
    expect(result.resolution.isUnavailable, isTrue);
    expect(result.account.accountNumber, isNot(contains('ENC:')));
  });

  test('link/count-only audited services do not inspect account number', () {
    const paths = <String>[
      'lib/core/entitlement/entitlement_service.dart',
      'lib/features/account/data/balance_history_service.dart',
      'lib/features/account/data/investment_portfolio_service.dart',
      'lib/features/account/data/reconciliation_service.dart',
      'lib/features/account/data/low_balance_alert_plugin.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains('account.accountNumber')),
        reason: '$path must remain link/count-only',
      );
      expect(
        source,
        isNot(contains('accountSuffixHash')),
        reason: '$path must not inspect suffix metadata',
      );
    }
  });

  test('startup and providers name shared contract boundary', () {
    final providers = File(
      'lib/features/account/data/account_providers.dart',
    ).readAsStringSync();
    final startup = File('lib/main.dart').readAsStringSync();
    final access = File(
      'lib/features/account/data/account_access_provider.dart',
    ).readAsStringSync();

    expect(providers, contains('AccountDataContract.safeAccounts'));
    expect(providers, contains('AccountDataContract.safeAccount'));
    expect(providers, contains('AccountDataContract.setPrimaryMetadata'));
    expect(startup, contains('FieldEncryptionService.waitForReadiness'));
    expect(startup, contains('AccountDataContract.normalizePrimaryMetadata'));
    expect(access, contains('accountsProvider.future'));
  });

  group('strict atomic account writer', () {
    late Isar isar;
    late Directory tmpDir;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('account_writer_');
      final existing = Isar.getInstance();
      if (existing != null && existing.isOpen) await existing.close();
      isar = await Isar.open([AccountSchema], directory: tmpDir.path);
    });

    tearDown(() async {
      await isar.close();
      tmpDir.deleteSync(recursive: true);
    });

    Account draft(String name, String number) {
      return Account()
        ..name = name
        ..accountType = AccountType.bank
        ..initialBalance = 0
        ..accountNumber = number;
    }

    test('writes encrypted number and suffix metadata at rest', () async {
      final result = await AccountDataContract.writeAccount(
        isar,
        draft('Bank', '1234567890'),
        accountNumber: '1234567890',
      );

      expect(result.succeeded, isTrue);
      final stored = (await isar.accounts.where().findAll()).single;
      expect(stored.accountNumber, startsWith('ENC:'));
      expect(stored.accountNumber, isNot('1234567890'));
      expect(stored.accountSuffixHash, isNotNull);
    });

    test('duplicate check resolves encrypted storage', () async {
      final first = await AccountDataContract.writeAccount(
        isar,
        draft('First', '1234567890'),
        accountNumber: '1234567890',
      );
      final second = await AccountDataContract.writeAccount(
        isar,
        draft('Second', '1234567890'),
        accountNumber: '1234567890',
      );

      expect(first.succeeded, isTrue);
      expect(second.status, AccountWriteStatus.duplicateNumber);
      expect((await isar.accounts.where().findAll()).length, 1);
    });

    test('malformed input fails before put and retry succeeds', () async {
      final account = draft('Retry', 'ENC:bad');
      final failed = await AccountDataContract.writeAccount(
        isar,
        account,
        accountNumber: 'ENC:bad',
      );

      expect(failed.succeeded, isFalse);
      expect((await isar.accounts.where().findAll()), isEmpty);

      final retried = await AccountDataContract.writeAccount(
        isar,
        account,
        accountNumber: '0000',
      );
      expect(retried.succeeded, isTrue);
      final stored = (await isar.accounts.where().findAll()).single;
      expect(stored.accountNumber, startsWith('ENC:'));
      expect(stored.accountNumber, isNot('0000'));
    });

    test('masked edit preserves encrypted storage value', () async {
      await AccountDataContract.writeAccount(
        isar,
        draft('Before', '1234567890'),
        accountNumber: '1234567890',
      );
      final storedBefore = (await isar.accounts.where().findAll()).single;
      final ciphertext = storedBefore.accountNumber;
      final safe = await AccountDataContract.safeAccount(storedBefore);
      final edit = AccountDataContract.copyAccount(safe)..name = 'After';

      final result = await AccountDataContract.writeAccount(
        isar,
        edit,
        accountNumber: safe!.accountNumber!,
      );

      expect(result.succeeded, isTrue);
      final storedAfter = await isar.accounts.get(storedBefore.id);
      expect(storedAfter!.accountNumber, ciphertext);
      expect(storedAfter.name, 'After');
    });

    test('metadata patch preserves exact encrypted field and updates flags',
        () async {
      final draft = account(
        id: Isar.autoIncrement,
        name: 'Metadata',
        number: '1234567890',
      );
      final write = await AccountDataContract.writeAccount(
        isar,
        draft,
        accountNumber: '1234567890',
      );
      expect(write.succeeded, isTrue);

      final before = (await isar.accounts.where().findAll()).single;
      final ciphertext = before.accountNumber;
      final suffixHash = before.accountSuffixHash;
      final changed = await AccountDataContract.patchStoredMetadata(
        isar,
        before.id,
        (stored) {
          stored.isActive = false;
          stored.isPrimary = true;
          stored.colorValue = 42;
        },
      );

      expect(changed, isTrue);
      final after = await isar.accounts.get(before.id);
      expect(after!.accountNumber, ciphertext);
      expect(after.accountSuffixHash, suffixHash);
      expect(after.isActive, isFalse);
      expect(after.isPrimary, isTrue);
      expect(after.colorValue, 42);
    });

    test(
        'restore preparation re-encrypts plaintext and leaves source unchanged',
        () async {
      final source = account(id: 77, name: 'Restored', number: '1234567890')
        ..isPrimary = true
        ..accountSuffixHash = null;

      final result = await AccountDataContract.prepareRestoredAccount(source);

      expect(result.succeeded, isTrue);
      expect(result.account!.accountNumber, startsWith('ENC:'));
      expect(result.account!.accountNumber, isNot('1234567890'));
      expect(result.account!.accountSuffixHash, isNotNull);
      expect(source.accountNumber, '1234567890');
      expect(source.accountSuffixHash, isNull);
      final resolved = await result.account!.resolveAccountNumberStrict();
      expect(resolved.resolvedValue, '1234567890');
    });

    test('restore preparation rejects foreign ciphertext without mutation',
        () async {
      final source = account(id: 78, name: 'Foreign', number: 'ENC:foreign');

      final result = await AccountDataContract.prepareRestoredAccount(source);

      expect(result.succeeded, isFalse);
      expect(result.errorCategory, isNotNull);
      expect(source.accountNumber, 'ENC:foreign');
      expect(source.accountSuffixHash, isNull);
    });

    test('backup adapter preserves metadata and portable account boundary',
        () async {
      final source = account(id: 79, name: 'Backup', number: '1234567890')
        ..accountType = AccountType.creditCard
        ..accountSuffixHash = null
        ..currencyCode = 'USD'
        ..statementDay = 3
        ..dueDay = 15
        ..creditLimit = 5000
        ..isPrimary = true;
      final backup = await AccountBackup.reEncrypt(source);
      final json = backup.toBackupJson();
      final restored = AccountBackup().fromBackupJson(json, {});

      expect(json['accountNumberEncoding'], 'portable-plaintext');
      expect(restored.id, source.id);
      expect(restored.name, source.name);
      expect(restored.accountType, source.accountType);
      expect(restored.currencyCode, 'USD');
      expect(restored.statementDay, 3);
      expect(restored.dueDay, 15);
      expect(restored.creditLimit, 5000);
      expect(restored.isPrimary, isTrue);
      expect(restored.accountNumber, '1234567890');
    });
  });

  test('account creation paths use shared writer and avoid direct puts', () {
    final form = File(
      'lib/features/account/presentation/screens/add_edit_account_screen.dart',
    ).readAsStringSync();
    final filter =
        File('lib/core/providers/app_filter_chip.dart').readAsStringSync();
    final onboarding = File(
      'lib/features/onboarding/presentation/screens/account_setup_screen.dart',
    ).readAsStringSync();
    final smsRoute = File(
      'lib/features/transactions/presentation/widgets/add_transaction_widgets.dart',
    ).readAsStringSync();

    expect(form, contains('AccountDataContract.writeAccount'));
    expect(filter, contains('AccountDataContract.writeAccount'));
    expect(onboarding, contains('AccountDataContract.writeAccount'));
    expect(onboarding, contains("accountNumber: '0000'"));
    expect(smsRoute, contains("'/manage-accounts/add'"));
    expect(form, isNot(contains('isar.accounts.put')));
    expect(filter, isNot(contains('isar.accounts.put')));
    expect(onboarding, isNot(contains('isar.accounts.put')));
  });
}
