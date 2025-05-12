import 'package:isar/isar.dart';

part 'notification_record.g.dart';

@collection
class NotificationRecord {
  Id id = Isar.autoIncrement;

  late String title;
  late String body;
  late DateTime timestamp;

  // Optional: Type of notification (e.g., 'low_balance', 'budget')
  String? type;
  late bool isRead;
}
