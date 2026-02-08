import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/notification_record.dart'
    show GetNotificationRecordCollection, NotificationRecord, NotificationRecordQueryFilter, NotificationRecordQuerySortBy;
import 'package:mudra_manager/providers/isar_provider.dart';

final notificationRecordServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  return NotificationRecordService(isar);
});

class NotificationRecordService {
  final IsarService isarService;

  NotificationRecordService(this.isarService);

  Future<void> logNotification({
    required String title,
    required String body,
    String? type,
  }) async {
    final record =
        NotificationRecord()
          ..title = title
          ..body = body
          ..timestamp = DateTime.now()
          ..isRead = false
          ..type = type;
    var isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.notificationRecords.put(record));
  }

  Future<void> readNotification({
    required NotificationRecord record
  }) async {
    var isar = await isarService.getInstance();
    record.isRead = !record.isRead;
    await isar.writeTxn(() => isar.notificationRecords.put(record));
  }

  Stream<List<NotificationRecord>> watchNotifications() async* {
    var isar = await isarService.getInstance();
    yield* isar.notificationRecords.where().sortByTimestampDesc().watch(
      fireImmediately: true,
    );
  }

  Future<void> clearAllNotifications() async {
    var isar = await isarService.getInstance();
    await isar.writeTxn(() => isar.notificationRecords.clear());
  }

  Future<int> countUnreadNotification() async {
    var isar = await isarService.getInstance();
    return await isar.notificationRecords.where().filter().isReadEqualTo(false).count();
  }
}
