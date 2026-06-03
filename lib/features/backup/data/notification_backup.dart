import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/features/backup/data/backable_model.dart';

class NotificationRecordBackup implements BackupAdapter<NotificationRecord> {
  final int id;
  final String title;
  final String body;
  final String timestamp;
  final String? type;
  final bool isRead;

  NotificationRecordBackup.fromNotificationRecord(NotificationRecord record)
    : id = record.id,
      title = record.title,
      body = record.body,
      timestamp = record.timestamp.toIso8601String(),
      type = record.type,
      isRead = record.isRead;

  NotificationRecordBackup()
    : id = 0,
      title = '',
      body = '',
      timestamp = '',
      type = '',
      isRead = false;

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp,
    'type': type,
    'isRead': isRead,
  };

  @override
  NotificationRecord fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    final record = NotificationRecord()
      ..id = json['id']
      ..title = json['title']
      ..body = json['body']
      ..timestamp = DateTime.parse(json['timestamp'])
      ..type = json['type'] as String?
      ..isRead = json['isRead'] as bool
      ..source = NotificationSource.smart;

    return record;
  }
}
