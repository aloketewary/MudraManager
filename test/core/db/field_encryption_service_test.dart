import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';

void main() {
  group('FieldEncryptionService (not initialized)', () {
    test('isReady is false before initialize', () {
      expect(FieldEncryptionService.isReady, isFalse);
    });

    test('encrypt throws when not ready', () {
      const plain = 'sensitive bank SMS body';
      expect(
        () => FieldEncryptionService.encrypt(plain),
        throwsA(isA<StateError>()),
      );
    });

    test('decrypt returns original when not ready', () {
      const cipher = 'ENC:abc:def';
      expect(FieldEncryptionService.decrypt(cipher), equals(cipher));
    });

    test('encryptNullable returns null for null', () {
      expect(FieldEncryptionService.encryptNullable(null), isNull);
    });

    test('decryptNullable returns null for null', () {
      expect(FieldEncryptionService.decryptNullable(null), isNull);
    });

    test('encrypt returns empty string unchanged', () {
      expect(FieldEncryptionService.encrypt(''), equals(''));
    });

    test('isEncrypted detects ENC: prefix', () {
      expect(FieldEncryptionService.isEncrypted('ENC:iv:data'), isTrue);
      expect(FieldEncryptionService.isEncrypted('plain text'), isFalse);
      expect(FieldEncryptionService.isEncrypted(null), isFalse);
      expect(FieldEncryptionService.isEncrypted(''), isFalse);
      expect(FieldEncryptionService.isEncrypted('ENC:'), isTrue);
    });

    test('encryptNullable throws when not ready', () {
      expect(
        () => FieldEncryptionService.encryptNullable('hello'),
        throwsA(isA<StateError>()),
      );
    });

    test('decryptNullable passes through non-null when not ready', () {
      expect(FieldEncryptionService.decryptNullable('hello'), equals('hello'));
    });
  });

  group('FieldEncryptionService prefix format', () {
    test('ENC: prefix is exactly 4 chars', () {
      expect('ENC:'.length, equals(4));
    });

    test('isEncrypted requires ENC: at start', () {
      expect(FieldEncryptionService.isEncrypted('xENC:data'), isFalse);
      expect(FieldEncryptionService.isEncrypted(' ENC:data'), isFalse);
    });
  });
}
