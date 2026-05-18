import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/recurring_bill.dart';

/// Encrypt sensitive fields before writing to Isar.
///
/// NOTE: FieldEncryptionService internally checks if a string is already encrypted
/// (via 'ENC:' prefix), making it safe to call these methods on mixed data
/// during migration or double-save scenarios.
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

extension PendingTransactionEncryption on PendingTransaction {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.encrypt(body);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    body = FieldEncryptionService.decrypt(body);
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

extension RecurringBillEncryption on RecurringBill {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encrypt(name);
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decrypt(name);
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension RecurringTransactionEncryption on RecurringTransaction {
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

extension UserProfileEncryption on UserProfile {
  /// Encrypts personal identifiable information (PII) before storage.
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.encryptNullable(name);
    email = FieldEncryptionService.encryptNullable(email);
    phone = FieldEncryptionService.encryptNullable(phone);
  }

  /// Decrypts user PII for UI display.
  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    name = FieldEncryptionService.decryptNullable(name);
    email = FieldEncryptionService.decryptNullable(email);
    phone = FieldEncryptionService.decryptNullable(phone);
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

extension RecurringBillListDecryption on Future<List<RecurringBill>> {
  Future<List<RecurringBill>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension PendingTransactionListDecryption
    on Future<List<PendingTransaction?>> {
  Future<List<PendingTransaction?>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item?.decryptFields();
    }
    return list;
  }
}

extension GoalEncryption on Goal {
  void encryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.encryptNullable(description);
  }

  void decryptFields() {
    if (!FieldEncryptionService.isReady) return;
    description = FieldEncryptionService.decryptNullable(description);
  }
}

extension GoalListDecryption on Future<List<Goal>> {
  Future<List<Goal>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension RecurringTransactionListDecryption
    on Future<List<RecurringTransaction>> {
  Future<List<RecurringTransaction>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}

extension TransactionListDecryption on Future<List<Transaction>> {
  Future<List<Transaction>> withDecryption() async {
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

extension GoalStreamDecryption on Stream<List<Goal>> {
  Stream<List<Goal>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension TransactionStreamDecryption on Stream<List<Transaction>> {
  Stream<List<Transaction>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension RecurringTransactionStreamDecryption
    on Stream<List<RecurringTransaction>> {
  Stream<List<RecurringTransaction>> withDecryption() {
    return map((list) {
      for (final item in list) {
        item.decryptFields();
      }
      return list;
    });
  }
}

extension UserProfileDecryption on Future<UserProfile?> {
  Future<UserProfile?> withDecryption() async {
    final profile = await this;
    profile?.decryptFields();
    return profile;
  }
}

extension UserProfileListDecryption on Future<List<UserProfile>> {
  Future<List<UserProfile>> withDecryption() async {
    final list = await this;
    for (final item in list) {
      item.decryptFields();
    }
    return list;
  }
}
