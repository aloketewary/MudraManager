import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

void main() {
  // FieldEncryptionService is NOT initialized in test env → isReady = false
  // All encrypt/decrypt calls pass through unchanged. This tests that behavior.

  group('SmsActivity encryption (passthrough)', () {
    test('encryptFields is no-op when not ready', () {
      final activity = SmsActivity()
        ..body = 'HDFC: Rs 5000 debited from A/c XX1234'
        ..merchant = 'Swiggy'
        ..sender = 'HDFCBK'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..amount = 5000;

      activity.encryptFields();

      expect(activity.body, equals('HDFC: Rs 5000 debited from A/c XX1234'));
      expect(activity.merchant, equals('Swiggy'));
    });

    test('decryptFields is no-op when not ready', () {
      final activity = SmsActivity()
        ..body = 'ENC:fakeiv:fakedata'
        ..merchant = 'ENC:fakeiv:fakemerchant'
        ..sender = 'HDFCBK'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..amount = 5000;

      activity.decryptFields();

      // Not ready → returns as-is (including ENC: prefix)
      expect(activity.body, equals('ENC:fakeiv:fakedata'));
      expect(activity.merchant, equals('ENC:fakeiv:fakemerchant'));
    });

    test('encryptFields handles null merchant', () {
      final activity = SmsActivity()
        ..body = 'test body'
        ..sender = 'TEST'
        ..date = DateTime.now()
        ..createdAt = DateTime.now()
        ..amount = 100;

      activity.encryptFields();
      expect(activity.merchant, isNull);
    });
  });

  group('Transaction encryption (passthrough)', () {
    test('encryptFields is no-op when not ready', () {
      final txn = Transaction()
        ..amount = 500
        ..isExpense = true
        ..date = DateTime.now()
        ..description = 'Coffee at Starbucks';

      txn.encryptFields();

      expect(txn.description, equals('Coffee at Starbucks'));
    });

    test('decryptFields is no-op when not ready', () {
      final txn = Transaction()
        ..amount = 500
        ..isExpense = true
        ..date = DateTime.now()
        ..description = 'ENC:fakeiv:fakedata';

      txn.decryptFields();

      expect(txn.description, equals('ENC:fakeiv:fakedata'));
    });

    test('encryptFields handles null description', () {
      final txn = Transaction()
        ..amount = 500
        ..isExpense = true
        ..date = DateTime.now();

      txn.encryptFields();
      expect(txn.description, isNull);
    });
  });

  group('RecurringBill encryption (passthrough)', () {
    test('encryptFields is no-op when not ready', () {
      final bill = RecurringBill()
        ..name = 'Rent'
        ..description = 'Monthly apartment rent'
        ..amount = 15000
        ..dueDate = DateTime.now()
        ..frequency = BillFrequency.monthly
        ..isActive = true;

      bill.encryptFields();

      expect(bill.name, equals('Rent'));
      expect(bill.description, equals('Monthly apartment rent'));
    });

    test('decryptFields is no-op when not ready', () {
      final bill = RecurringBill()
        ..name = 'ENC:fakeiv:fakename'
        ..description = 'ENC:fakeiv:fakedesc'
        ..amount = 15000
        ..dueDate = DateTime.now()
        ..frequency = BillFrequency.monthly
        ..isActive = true;

      bill.decryptFields();

      expect(bill.name, equals('ENC:fakeiv:fakename'));
      expect(bill.description, equals('ENC:fakeiv:fakedesc'));
    });

    test('encryptFields handles null description', () {
      final bill = RecurringBill()
        ..name = 'Rent'
        ..amount = 15000
        ..dueDate = DateTime.now()
        ..frequency = BillFrequency.monthly
        ..isActive = true;

      bill.encryptFields();
      expect(bill.description, isNull);
    });
  });

  group('Encryption readiness guard', () {
    test('FieldEncryptionService.isReady is false in test env', () {
      expect(FieldEncryptionService.isReady, isFalse);
    });

    test('encrypt throws and decrypt is identity when not ready', () {
      const input = 'sensitive data 12345';
      expect(
        () => FieldEncryptionService.encrypt(input),
        throwsA(isA<StateError>()),
      );
      expect(FieldEncryptionService.decrypt(input), equals(input));
    });
  });

  group('Strict AccountEncryption boundary', () {
    const key = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

    setUp(() {
      FieldEncryptionService.setKeyForTesting(key);
    });

    tearDown(FieldEncryptionService.resetForTesting);

    test('prepares encrypted value and full suffix hash without mutation',
        () async {
      final account = Account()..accountNumber = '1234567890';

      final preparation = await account.prepareStrictWrite();

      expect(preparation.succeeded, isTrue);
      expect(preparation.encryptedAccountNumber, startsWith('ENC:'));
      expect(preparation.encryptedAccountNumber, isNot('1234567890'));
      expect(
        preparation.accountSuffixHash,
        sha256.convert(utf8.encode('7890')).toString(),
      );
      expect(account.accountNumber, '1234567890');
      expect(account.accountSuffixHash, isNull);
    });

    test('valid encrypted input is not double-encrypted', () async {
      final account = Account()..accountNumber = '1234567890';
      final first = await account.prepareStrictWrite();
      account.accountNumber = first.encryptedAccountNumber;

      final second = await account.prepareStrictWrite();

      expect(second.succeeded, isTrue);
      expect(second.encryptedAccountNumber, first.encryptedAccountNumber);
      expect(second.accountSuffixHash, first.accountSuffixHash);
    });

    test('strict resolution gives safe display and redacted failure', () async {
      final valid = Account()..accountNumber = '1234567890';
      final prep = await valid.prepareStrictWrite();
      valid.accountNumber = prep.encryptedAccountNumber;

      final resolved = await valid.resolveAccountNumberStrict();
      expect(resolved.status, AccountNumberResolutionStatus.decrypted);
      expect(resolved.display, '•••• 7890');
      expect(resolved.resolvedValue, '1234567890');

      final malformed = Account()..accountNumber = 'ENC:not-valid';
      final unavailable = await malformed.resolveAccountNumberStrict();
      expect(unavailable.status, AccountNumberResolutionStatus.malformed);
      expect(unavailable.display, '••••');
      expect(unavailable.resolvedValue, isNull);
      expect(unavailable.errorCategory, 'malformed_ciphertext');
    });

    test('short and empty values classify safely and clear hash', () async {
      final short = Account()..accountNumber = '12';
      final shortResult = await short.resolveAccountNumberStrict();
      expect(shortResult.status, AccountNumberResolutionStatus.shortValue);
      expect(shortResult.display, '••••');

      final empty = Account()
        ..accountNumber = ''
        ..accountSuffixHash = 'stale';
      final prep = await empty.prepareStrictWrite();
      expect(prep.succeeded, isTrue);
      expect(prep.encryptedAccountNumber, isNull);
      expect(prep.accountSuffixHash, isNull);
    });

    test('matches full and legacy 16-character suffix hashes', () {
      final full = Account()
        ..accountSuffixHash = sha256.convert(utf8.encode('7890')).toString();
      final legacy = Account()
        ..accountSuffixHash =
            sha256.convert(utf8.encode('7890')).toString().substring(0, 16);

      expect(full.matchesSuffix('7890'), isTrue);
      expect(legacy.matchesSuffix('7890'), isTrue);
      expect(full.matchesSuffix('0000'), isFalse);
    });
  });
}
