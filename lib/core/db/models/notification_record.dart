import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_record.g.dart';

@collection
@JsonSerializable()
class NotificationRecord {
  Id id = Isar.autoIncrement;

  late String title;
  late String body;
  late DateTime timestamp;

  // Optional: Type of notification (e.g., 'low_balance', 'budget')
  String? type;
  late bool isRead;

  NotificationRecord();

  factory NotificationRecord.fromJson(Map<String, dynamic> json) => _$NotificationRecordFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationRecordToJson(this);
}
