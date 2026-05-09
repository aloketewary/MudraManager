import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

final notificationRecordServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  return NotificationRecordService(isar);
});

class NotificationRecordService {
  final IsarService isarService;

  NotificationRecordService(this.isarService);

  /// Persists a new notification record to the database.
  /// Sensitive fields are encrypted before storage.
  Future<void> logNotification({
    required String title,
    required String body,
    String? type,
  }) async {
    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type
      ..priority = NotificationPriority.normal
      ..category = NotificationCategory.financial;
    record.encryptFields(); // Sentinel: Protect sensitive financial alerts in the database
    final isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.notificationRecords.put(record));
  }

  Future<void> readNotification({required NotificationRecord record}) async {
    final isar = await isarService.getInstance();
    record.isRead = !record.isRead;
    record.encryptFields();
    await isar.writeTxn(() => isar.notificationRecords.put(record));
    record.decryptFields();
  }

  Future<void> deleteNotification(NotificationRecord record) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.notificationRecords.delete(record.id));
  }

  /// Marks all unread notifications as read.
  /// Decrypts before modification and re-encrypts before saving to prevent double-encryption.
  Future<void> markAllAsRead() async {
    final isar = await isarService.getInstance();
    final unread = await isar.notificationRecords
        .where()
        .filter()
        .isReadEqualTo(false)
        .findAll()
        .withDecryption(); // Sentinel: Decrypt to avoid double-encryption on put
    await isar.writeTxn(() async {
      for (final record in unread) {
        record.isRead = true;
        record.encryptFields(); // Sentinel: Re-encrypt sensitive fields before storage
        await isar.notificationRecords.put(record);
      }
    });
  }

  Stream<List<NotificationRecord>> watchNotifications() async* {
    final isar = await isarService.getInstance();
    yield* isar.notificationRecords
        .where()
        .sortByTimestampDesc()
        .watch(
          fireImmediately: true,
        )
        .withDecryption();
  }

  Future<void> clearAllNotifications() async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.notificationRecords.clear());
  }

  Future<int> countUnreadNotification() async {
    final isar = await isarService.getInstance();
    return await isar.notificationRecords
        .where()
        .filter()
        .isReadEqualTo(false)
        .count();
  }

  Future<void> archiveNotification(NotificationRecord record) async {
    final isar = await isarService.getInstance();
    record.isArchived = true;
    record.encryptFields();
    await isar.writeTxn(() => isar.notificationRecords.put(record));
    record.decryptFields();
  }
}
