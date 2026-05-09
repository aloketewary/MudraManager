import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';

void main() {
  group('NotificationRecord Encryption Extension', () {
    test('encryptFields and decryptFields (service not initialized)', () {
      // Sentinel: Verify that if encryption is not initialized, fields remain unchanged (safe fallback)
      final record = NotificationRecord()
        ..title = 'Bank Alert'
        ..body = 'You spent Rs. 500 at Merchant'
        ..actionData = '{"id": 123}'
        ..primaryAction = 'View';

      record.encryptFields();

      expect(record.title, 'Bank Alert');
      expect(record.body, 'You spent Rs. 500 at Merchant');
      expect(record.actionData, '{"id": 123}');
      expect(record.primaryAction, 'View');

      record.decryptFields();
      expect(record.title, 'Bank Alert');
    });

    test('isEncrypted helper detects encryption prefix', () {
      // Sentinel: Ensure the prefix detection logic is consistent
      expect(FieldEncryptionService.isEncrypted('ENC:iv:data'), isTrue);
      expect(FieldEncryptionService.isEncrypted('Plain Title'), isFalse);
    });

    test('decryptFields handles non-encrypted data gracefully', () {
      // Sentinel: Verify that decrypting plain text doesn't corrupt it
      final record = NotificationRecord()
        ..title = 'Plain Title'
        ..body = 'Plain Body';

      record.decryptFields();

      expect(record.title, 'Plain Title');
      expect(record.body, 'Plain Body');
    });
  });
}
