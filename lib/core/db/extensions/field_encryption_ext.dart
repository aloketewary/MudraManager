import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

/// Encrypt sensitive fields before writing to Isar.
extension SmsActivityEncryption on SmsActivity {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.encrypt(body);
    merchant = FieldEncryptionService.encryptNullable(merchant);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.decrypt(body);
    merchant = FieldEncryptionService.decryptNullable(merchant);
  }
}

extension TransactionEncryption on Transaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension AccountEncryption on Account {
  // Account.accountNumber is NOT encrypted because it's used for
  // real-time SMS last-4-digit matching in the auto-approval pipeline.
  // Encrypting it would break: acNum.endsWith(activity.account!)
  void encryptFields() {}
  void decryptFields() {}
}

extension NotificationRecordEncryption on NotificationRecord {
  /// Encrypts sensitive notification fields before storage.
  /// Protects user's financial privacy in case of database exposure.
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    title = FieldEncryptionService.encrypt(title);
    body = FieldEncryptionService.encrypt(body);
    actionData = FieldEncryptionService.encryptNullable(actionData);
    primaryAction = FieldEncryptionService.encryptNullable(primaryAction);
    secondaryAction = FieldEncryptionService.encryptNullable(secondaryAction);
  }

  /// Decrypts notification fields for UI display.
  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    title = FieldEncryptionService.decrypt(title);
    body = FieldEncryptionService.decrypt(body);
    actionData = FieldEncryptionService.decryptNullable(actionData);
    primaryAction = FieldEncryptionService.decryptNullable(primaryAction);
    secondaryAction = FieldEncryptionService.decryptNullable(secondaryAction);
  }
}

/// Decrypt a list of SmsActivity after Isar read.
extension SmsActivityListDecryption on Future<List<SmsActivity>> {
  Future<List<SmsActivity>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension NotificationRecordListDecryption on Future<List<NotificationRecord>> {
  Future<List<NotificationRecord>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension NotificationRecordStreamDecryption
    on Stream<List<NotificationRecord>> {
  Stream<List<NotificationRecord>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}
