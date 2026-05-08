import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_record.g.dart';

enum NotificationPriority { low, normal, high, urgent }
enum NotificationCategory { system, financial, trip, budget }
enum NotificationSource { smart, sms, scheduled, event }

@collection
@JsonSerializable()
class NotificationRecord {
  Id id = Isar.autoIncrement;

  late String title;
  late String body;

  @Index()
  late DateTime timestamp;

  @Index()
  String? type;
  late bool isRead;
  
  // Action-oriented fields
  @enumerated
  @JsonKey(defaultValue: NotificationPriority.normal)
  late NotificationPriority priority;
  
  @enumerated
  @JsonKey(defaultValue: NotificationCategory.system)
  late NotificationCategory category;
  
  // Action metadata (JSON string)
  String? actionData; // {"type": "settle_up", "tripId": 123, "amount": 500}
  String? primaryAction; // "Settle Now", "View Details", "Split Equal"
  String? secondaryAction; // "Remind", "Ignore", "View Trip"
  
  // Related entity IDs
  int? tripId;
  int? expenseId;
  int? budgetId;
  
  bool isArchived = false;

  @enumerated
  @JsonKey(defaultValue: NotificationSource.smart)
  late NotificationSource source;

  NotificationRecord();

  factory NotificationRecord.fromJson(Map<String, dynamic> json) => _$NotificationRecordFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationRecordToJson(this);
}
