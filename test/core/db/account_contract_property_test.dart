import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/account_encryption_migration.dart';
import 'package:mudra_manager/core/db/account_suffix_hash_migration.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/account/data/account_data_contract.dart';
import 'package:mudra_manager/features/backup/data/account_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 4.9 deterministic contract properties.
///
/// No property package is present in this project. [SeededGenerator] provides
/// fixed seeds, bounded generation, and failure messages containing only the
/// seed/category (never account values or ciphertext).
void main() {
  const key = 'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=';
  const foreignKey = 'AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI=';

  setUp(() {
    FieldEncryptionService.setKeyForTesting(key);
  });

  tearDown(FieldEncryptionService.resetForTesting);

  /// **Validates: Requirements 2.1, 2.2, 2.17**
  test('generated value/readiness states resolve safe or unavailable only',
      () async {
    final values = await _generatedValueStates(key, foreignKey);

    for (final value in values) {
      final account = _account(value.seed, value.stored);
      final result = await AccountDataContract.resolveAccount(account);
      _assert(
        !result.account.accountNumber!.contains('ENC:'),
        value.seed,
        '${value.label}-ciphertext-output',
      );
      _assert(
        result.account.accountNumber != value.plaintext,
        value.seed,
        '${value.label}-full-secret-output',
      );
      _assert(
        result.account.accountNumber == '••••' ||
            result.account.accountNumber!.startsWith('•••• '),
        value.seed,
        '${value.label}-unsafe-display',
      );
      _assert(
        result.resolution.status == value.status,
        value.seed,
        '${value.label}-status-mismatch',
      );
    }

    // Pending readiness must fail closed synchronously. This also records the
    // reproducible pending state without depending on platform key storage.
    FieldEncryptionService.resetForTesting();
    final pending = FieldEncryptionService.decryptStrictReady('ENC:pending');
    _assert(
      pending.status == StrictDecryptStatus.unavailable &&
          pending.plaintext == null,
      0x50454e44,
      'pending-readiness-fail-closed',
    );
    final pendingRestore = await AccountDataContract.prepareRestoredAccount(
      _account(0x50454e45, 'legacy-number'),
    );
    _assert(
      !pendingRestore.succeeded && pendingRestore.errorCategory != null,
      0x50454e45,
      'pending-restore-fail-closed',
    );
    FieldEncryptionService.setKeyForTesting(key);
    final failed = FieldEncryptionService.decryptStrictReady('ENC:foreign');
    _assert(
      failed.status == StrictDecryptStatus.malformed &&
          failed.plaintext == null,
      0x4641494c,
      'malformed-failed-state-fail-closed',
    );
  });

  /// **Validates: Requirements 2.3, 2.16**
  test('generated collections preserve order/metadata across read paths',
      () async {
    final values = await _generatedValueStates(key, foreignKey);
    final stored = [
      for (var index = 0; index < 18; index++)
        _account(
          0x1000 + index,
          values[index % values.length].stored,
          active: index.isEven,
          primary: index == 2,
          balance: index * 111.5,
        ),
    ];

    final all = await AccountDataContract.resolveAccounts(stored);
    final active = await AccountDataContract.resolveAccounts(
      stored.where((account) => account.isActive),
    );
    final direct = await AccountDataContract.resolveAccount(stored[2]);
    final primary = all.firstWhere((item) => item.account.isPrimary);

    _assert(
      all.map((item) => item.account.id).toList().toString() ==
          stored.map((account) => account.id).toList().toString(),
      0x52454144,
      'all-order-preserved',
    );
    _assert(
      active.map((item) => item.account.id).toList().toString() ==
          stored
              .where((account) => account.isActive)
              .map((account) => account.id)
              .toList()
              .toString(),
      0x52454144,
      'active-order-preserved',
    );
    _assert(
      primary.account.id == direct.account.id,
      0x52454144,
      'primary-direct-parity',
    );

    for (final result in [...all, ...active, direct]) {
      _assert(
        !result.account.accountNumber!.contains('ENC:'),
        result.account.id,
        'provider-path-ciphertext-output',
      );
      _assert(
        result.account.name.startsWith('Account '),
        result.account.id,
        'provider-path-metadata-loss',
      );
    }
  });

  /// **Validates: Requirements 2.3, 2.13, 2.16, 3.1, 3.9**
  test('safe collection/direct readers return detached parity projections',
      () async {
    final values = await _generatedValueStates(key, foreignKey);
    final stored = [
      for (var index = 0; index < values.length; index++)
        _account(0x1100 + index, values[index].stored),
    ];

    final resolved = await AccountDataContract.resolveAccounts(stored);
    final safeCollection = await AccountDataContract.safeAccounts(stored);

    _assert(
      resolved.length == safeCollection.length,
      0x491301,
      'safe-collection-count-changed',
    );
    for (var index = 0; index < stored.length; index++) {
      final direct = await AccountDataContract.safeAccount(stored[index]);
      final expected = resolved[index].account;
      _assert(
        direct?.id == expected.id &&
            direct?.accountNumber == expected.accountNumber &&
            safeCollection[index].accountNumber == expected.accountNumber,
        0x491302 + index,
        'direct-collection-parity',
      );
      _assert(
        !safeCollection[index].accountNumber!.contains('ENC:') &&
            safeCollection[index].accountNumber != values[index].plaintext,
        0x491302 + index,
        'safe-reader-secret-leak',
      );
      _assert(
        !identical(direct, stored[index]) &&
            !identical(safeCollection[index], stored[index]),
        0x491302 + index,
        'safe-reader-shared-storage-model',
      );
    }
  });

  group('generated strict writes and atomic outcomes', () {
    late Isar isar;
    late Directory directory;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('account_contract_');
      final existing = Isar.getInstance();
      if (existing != null && existing.isOpen) await existing.close();
      isar = await Isar.open([AccountSchema], directory: directory.path);
    });

    tearDown(() async {
      await isar.close();
      directory.deleteSync(recursive: true);
    });

    /// **Validates: Requirements 2.6, 2.12, 2.17**
    test('generated plaintext/suffix/hash/duplicate writes encrypt at rest',
        () async {
      final generator = SeededGenerator(0x4901);
      final written = <Account>[];

      for (var index = 0; index < 10; index++) {
        final suffix = generator.nextInt(9000) + 1000;
        final number = '${generator.nextInt(900000) + 100000}$suffix';
        final draft = _account(0x2000 + index, null)
          ..id = Isar.autoIncrement
          ..name = 'Generated $index';
        final result = await AccountDataContract.writeAccount(
          isar,
          draft,
          accountNumber: number,
        );
        _assert(result.succeeded, 0x2000 + index, 'write-failed');
        written.add((await isar.accounts.where().findAll()).last);

        final stored = written.last;
        _assert(
          stored.accountNumber?.startsWith('ENC:') == true,
          0x2000 + index,
          'plaintext-at-rest',
        );
        _assert(
          stored.accountNumber != number,
          0x2000 + index,
          'plaintext-equals-storage',
        );
        _assert(
          stored.accountSuffixHash == accountSuffixHashFor(number),
          0x2000 + index,
          'suffix-hash-mismatch',
        );

        final duplicate = await AccountDataContract.writeAccount(
          isar,
          _account(0x3000 + index, null)
            ..id = Isar.autoIncrement
            ..name = 'Duplicate $index',
          accountNumber: number,
        );
        _assert(
          duplicate.status == AccountWriteStatus.duplicateNumber,
          0x2000 + index,
          'duplicate-number-not-detected',
        );
      }
    });

    /// **Validates: Requirements 2.6, 2.7, 2.17**
    test('failed write/metadata patch leaves encrypted storage unchanged',
        () async {
      final draft = _account(0x4001, 'legacy')
        ..id = Isar.autoIncrement
        ..name = 'Atomic baseline';
      final write = await AccountDataContract.writeAccount(
        isar,
        draft,
        accountNumber: '55556666',
      );
      _assert(write.succeeded, 0x4001, 'atomic-baseline-write');
      final before = (await isar.accounts.where().findAll()).single;
      final ciphertext = before.accountNumber;
      final hash = before.accountSuffixHash;

      final failed = await AccountDataContract.writeAccount(
        isar,
        AccountDataContract.copyAccount(before)..name = 'Retry name',
        accountNumber: 'ENC:malformed',
      );
      _assert(!failed.succeeded, 0x4002, 'malformed-write-accepted');
      final afterFailure = await isar.accounts.get(before.id);
      _assert(
        afterFailure?.accountNumber == ciphertext,
        0x4002,
        'failed-write-mutated-ciphertext',
      );
      _assert(
        afterFailure?.accountSuffixHash == hash,
        0x4002,
        'failed-write-mutated-hash',
      );

      final changed = await AccountDataContract.patchStoredMetadata(
        isar,
        before.id,
        (stored) {
          stored.isPrimary = true;
          stored.colorValue = 91;
        },
      );
      _assert(changed, 0x4003, 'metadata-patch-failed');
      final afterMetadata = await isar.accounts.get(before.id);
      _assert(
        afterMetadata?.accountNumber == ciphertext,
        0x4003,
        'metadata-replaced-ciphertext',
      );
      _assert(
        afterMetadata?.accountSuffixHash == hash,
        0x4003,
        'metadata-replaced-hash',
      );
      _assert(
        afterMetadata?.isPrimary == true && afterMetadata?.colorValue == 91,
        0x4003,
        'metadata-fields-not-preserved',
      );
    });
  });

  /// **Validates: Requirements 2.7, 2.8, 2.17**
  test('migration/restore generated success and failure outcomes are atomic',
      () async {
    final values = await _generatedValueStates(key, foreignKey);
    final legacy = _account(
      0x5001,
      values.firstWhere((value) => value.label == 'legacy-plaintext').stored,
    )..accountSuffixHash = null;
    final malformed = _account(0x5002, 'ENC:malformed')
      ..accountSuffixHash = null;
    final originalMalformed = malformed.accountNumber;

    final restored = await AccountDataContract.prepareRestoredAccount(legacy);
    _assert(restored.succeeded, 0x5001, 'restore-legacy-failed');
    _assert(
      restored.account?.accountNumber?.startsWith('ENC:') == true,
      0x5001,
      'restore-not-encrypted',
    );
    _assert(
      legacy.accountNumber ==
          values
              .firstWhere((value) => value.label == 'legacy-plaintext')
              .stored,
      0x5001,
      'restore-mutated-source',
    );

    final failedRestore =
        await AccountDataContract.prepareRestoredAccount(malformed);
    _assert(!failedRestore.succeeded, 0x5002, 'foreign-restore-accepted');
    _assert(
      malformed.accountNumber == originalMalformed,
      0x5002,
      'failed-restore-mutated-source',
    );

    SharedPreferences.setMockInitialValues({});
    final directory = Directory.systemTemp.createTempSync('account_migration_');
    final existing = Isar.getInstance();
    if (existing != null && existing.isOpen) await existing.close();
    final isar = await Isar.open([AccountSchema], directory: directory.path);
    try {
      await isar.writeTxn(() async {
        await isar.accounts.put(legacy);
        await isar.accounts.put(malformed);
      });
      await AccountEncryptionMigration.run(isar);
      final migratedLegacy = await isar.accounts.get(legacy.id);
      final migratedMalformed = await isar.accounts.get(malformed.id);
      _assert(
        migratedLegacy?.accountNumber?.startsWith('ENC:') == true,
        0x5003,
        'legacy-migration-not-encrypted',
      );
      _assert(
        migratedMalformed?.accountNumber == originalMalformed,
        0x5003,
        'failed-migration-mutated-record',
      );

      final valid = _account(0x5004, migratedLegacy!.accountNumber)
        ..accountSuffixHash = accountSuffixHashFor(
          values
              .firstWhere((value) => value.label == 'legacy-plaintext')
              .plaintext!,
        ).substring(0, 16);
      final suffixMalformed = _account(0x5005, 'ENC:foreign')
        ..accountSuffixHash = '0123456789abcdef';
      await isar.writeTxn(() async {
        await isar.accounts.put(valid);
        await isar.accounts.put(suffixMalformed);
      });
      await AccountSuffixHashMigration.run(isar);
      final upgraded = await isar.accounts.get(valid.id);
      final untouched = await isar.accounts.get(suffixMalformed.id);
      _assert(
        upgraded?.accountSuffixHash?.length == 64,
        0x5004,
        'suffix-migration-not-upgraded',
      );
      _assert(
        untouched?.accountSuffixHash == '0123456789abcdef',
        0x5005,
        'failed-suffix-migration-mutated-record',
      );
    } finally {
      await isar.close();
      directory.deleteSync(recursive: true);
    }
  });

  /// **Validates: Requirements 2.8, 2.13, 2.16, 2.17, 3.7, 3.10**
  test('generated backup boundary re-encrypts valid values and rejects foreign',
      () async {
    final values = await _generatedValueStates(key, foreignKey);
    final valid = values.where(
      (value) =>
          value.label == 'legacy-plaintext' ||
          value.label == 'valid-encrypted' ||
          value.label == 'already-encrypted',
    );

    for (final value in valid) {
      final source = _account(0x5100 + value.seed, value.stored);
      final backup = await AccountBackup.reEncrypt(source);
      final json = backup.toBackupJson();
      _assert(
        json['accountNumberEncoding'] == 'portable-plaintext',
        value.seed,
        'backup-encoding-not-portable',
      );
      final restored = backup.fromBackupJson(json, {});
      final prepared = await AccountDataContract.prepareRestoredAccount(
        restored,
      );
      _assert(
        prepared.succeeded &&
            prepared.account?.accountNumber?.startsWith('ENC:') == true,
        value.seed,
        'backup-restore-not-reencrypted',
      );
      _assert(
        source.accountNumber == value.stored,
        value.seed,
        'backup-mutated-source',
      );
    }

    final foreign = _account(
      0x51ff,
      values.firstWhere((value) => value.label == 'foreign').stored,
    );
    var rejected = false;
    try {
      await AccountBackup.reEncrypt(foreign);
    } on AccountBackupException {
      rejected = true;
    }
    _assert(rejected, 0x51ff, 'foreign-backup-accepted');
    _assert(
      foreign.accountNumber ==
          values.firstWhere((value) => value.label == 'foreign').stored,
      0x51ff,
      'foreign-backup-mutated-source',
    );
  });

  /// **Validates: Requirements 2.10, 2.12, 2.13**
  test('generated matching never uses ciphertext and keeps hash variants', () {
    final generator = SeededGenerator(0x4902);
    for (var index = 0; index < 16; index++) {
      final suffix = '${generator.nextInt(9000) + 1000}';
      final full = _account(0x6000 + index, 'ENC:opaque')
        ..accountSuffixHash = accountSuffixHashFor(suffix);
      final legacy = _account(0x7000 + index, 'ENC:opaque')
        ..accountSuffixHash = accountSuffixHashFor(suffix).substring(0, 16);
      _assert(full.matchesSuffix(suffix), 0x6000 + index, 'full-hash-no-match');
      _assert(
        legacy.matchesSuffix('BANK$suffix'),
        0x7000 + index,
        'legacy-hash-no-match',
      );
      _assert(
        !full.matchesSuffix('0000'),
        0x6000 + index,
        'wrong-suffix-match',
      );
      _assert(
        full.accountNumber == 'ENC:opaque',
        0x6000 + index,
        'matching-mutated-storage',
      );
    }
  });

  /// **Validates: Requirements 2.2, 2.10, 2.16**
  test('all display/notification/widget/semantics modes share safe output',
      () async {
    final values = await _generatedValueStates(key, foreignKey);
    const modes = <String>[
      'carousel',
      'stack',
      'bento',
      'animated',
      'command-center',
      'selector',
      'bottom-sheet',
      'notification',
      'widget',
      'semantics',
    ];

    for (final value in values) {
      final account = _account(value.seed, value.stored);
      final resolved = await AccountDataContract.resolveAccount(account);
      final expected = SafeAccountPresentation.formatAccountNumber(
        resolved.account.accountNumber,
      );
      for (final mode in modes) {
        final text = AccountDataContract.safeOutputText(
          '$mode ${resolved.account.accountNumber}',
        );
        final payload = AccountDataContract.safeOutputPayload({
          'mode': mode,
          'label': resolved.account.accountNumber,
          'semantics': text,
        });
        _assert(text.contains(expected), value.seed, '$mode-safe-text');
        _assert(
          payload.toString().contains(expected),
          value.seed,
          '$mode-safe-payload',
        );
        _assert(!text.contains('ENC:'), value.seed, '$mode-ciphertext-text');
        _assert(
          !payload.toString().contains('ENC:'),
          value.seed,
          '$mode-ciphertext-payload',
        );
        _assert(
          value.plaintext == null || !text.contains(value.plaintext!),
          value.seed,
          '$mode-full-secret-text',
        );
        _assert(
          value.plaintext == null ||
              !payload.toString().contains(value.plaintext!),
          value.seed,
          '$mode-full-secret-payload',
        );
      }
    }
  });

  /// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10**
  test(
      'generated non-buggy balances/transactions/currency/privacy/order persist',
      () async {
    final generator = SeededGenerator(0x4903);
    final accounts = [
      for (var index = 0; index < 12; index++)
        _account(
          0x8000 + index,
          null,
          balance: generator.nextInt(50000).toDouble(),
          currency: index.isEven ? 'INR' : 'USD',
          active: index % 3 != 0,
        ),
    ];
    final beforeLinks = accounts.map(AccountLinkProjection.fromStored).toList();
    final resolved = await AccountDataContract.resolveAccounts(accounts);
    final afterLinks = resolved
        .map((result) => AccountLinkProjection.fromStored(result.account))
        .toList();

    for (var index = 0; index < beforeLinks.length; index++) {
      final before = beforeLinks[index];
      final after = afterLinks[index];
      _assert(
        before.id == after.id && before.accountType == after.accountType,
        0x8000 + index,
        'link-metadata-changed',
      );
      _assert(
        before.initialBalance == after.initialBalance &&
            before.currencyCode == after.currencyCode &&
            before.isActive == after.isActive,
        0x8000 + index,
        'balance-currency-changed',
      );
    }

    final amount = generator.nextInt(9000).toDouble() + 100;
    final transaction = Transaction.create(
      date: DateTime(2026, 1, 1),
      amount: amount,
      isExpense: true,
      currencyCode: 'USD',
      convertedAmount: amount * 83.5,
    );
    final effective = transaction.effectiveAmount;
    final currency = formatCurrency(transaction.baseAmount, code: 'INR');
    final guest = GuestModeUtil.applyGuestMode(amount, true);
    _assert(
      transaction.effectiveAmount == effective,
      0x8001,
      'transaction-aggregation-changed',
    );
    _assert(
      formatCurrency(transaction.baseAmount, code: 'INR') == currency,
      0x8001,
      'currency-conversion-changed',
    );
    _assert(guest >= 100 && guest <= 5099, 0x8001, 'guest-privacy-changed');
    _assert(
      resolved.map((result) => result.account.id).toList().toString() ==
          accounts.map((account) => account.id).toList().toString(),
      0x8002,
      'account-order-changed',
    );
  });

  test('contract source invariants retain all high-risk guards', () {
    final paths = <String, List<String>>{
      'lib/core/db/account_encryption_migration.dart': [
        'AccountDataContract.copyAccount',
        'resolveAccountNumberStrict',
        'redactedFailure',
      ],
      'lib/core/db/account_suffix_hash_migration.dart': [
        'AccountDataContract.copyAccount',
        'resolveAccountNumberStrict',
        'redactedFailure',
      ],
      'lib/features/account/data/account_data_contract.dart': [
        'waitForReadiness',
        'patchStoredMetadata',
        'prepareRestoredAccount',
        'safeOutputPayload',
      ],
    };
    for (final entry in paths.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final marker in entry.value) {
        _assert(
          source.contains(marker),
          0x4904,
          'missing-${entry.key}-$marker',
        );
      }
    }
  });
}

class SeededGenerator {
  int _state;

  SeededGenerator(this._state);

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

class _ValueState {
  final int seed;
  final String label;
  final String? stored;
  final String? plaintext;
  final AccountNumberResolutionStatus status;

  const _ValueState({
    required this.seed,
    required this.label,
    required this.stored,
    required this.plaintext,
    required this.status,
  });
}

Future<List<_ValueState>> _generatedValueStates(
  String key,
  String foreignKey,
) async {
  final generator = SeededGenerator(0x4900);
  final validPlaintext =
      '${generator.nextInt(900000) + 100000}${generator.nextInt(9000) + 1000}';
  final validAccount = Account()..accountNumber = validPlaintext;
  final encrypted =
      (await validAccount.prepareStrictWrite()).encryptedAccountNumber!;

  FieldEncryptionService.setKeyForTesting(foreignKey);
  final foreignAccount = Account()..accountNumber = validPlaintext;
  final foreign =
      (await foreignAccount.prepareStrictWrite()).encryptedAccountNumber!;
  FieldEncryptionService.setKeyForTesting(key);

  return [
    const _ValueState(
      seed: 0x490001,
      label: 'null',
      stored: null,
      plaintext: null,
      status: AccountNumberResolutionStatus.nullOrEmpty,
    ),
    const _ValueState(
      seed: 0x490002,
      label: 'empty',
      stored: '',
      plaintext: null,
      status: AccountNumberResolutionStatus.nullOrEmpty,
    ),
    const _ValueState(
      seed: 0x490003,
      label: 'short',
      stored: '12',
      plaintext: '12',
      status: AccountNumberResolutionStatus.shortValue,
    ),
    const _ValueState(
      seed: 0x490004,
      label: 'malformed',
      stored: 'ENC:malformed',
      plaintext: null,
      status: AccountNumberResolutionStatus.malformed,
    ),
    _ValueState(
      seed: 0x490005,
      label: 'foreign',
      stored: foreign,
      plaintext: null,
      status: AccountNumberResolutionStatus.keyMismatch,
    ),
    _ValueState(
      seed: 0x490006,
      label: 'legacy-plaintext',
      stored: validPlaintext,
      plaintext: validPlaintext,
      status: AccountNumberResolutionStatus.legacyPlaintext,
    ),
    _ValueState(
      seed: 0x490007,
      label: 'valid-encrypted',
      stored: encrypted,
      plaintext: validPlaintext,
      status: AccountNumberResolutionStatus.decrypted,
    ),
    _ValueState(
      seed: 0x490008,
      label: 'already-encrypted',
      stored: encrypted,
      plaintext: validPlaintext,
      status: AccountNumberResolutionStatus.decrypted,
    ),
  ];
}

Account _account(
  int id,
  String? number, {
  bool active = true,
  bool primary = false,
  double balance = 0,
  String? currency = 'INR',
}) {
  return Account()
    ..id = id
    ..name = 'Account $id'
    ..accountType = AccountType.bank
    ..initialBalance = balance
    ..currencyCode = currency
    ..isActive = active
    ..isPrimary = primary
    ..accountNumber = number;
}

void _assert(bool condition, int seed, String category) {
  if (!condition) {
    fail('counterexample seed=$seed errorCategory=$category');
  }
}
