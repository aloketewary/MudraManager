import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_notifications.g.dart';

@collection
@JsonSerializable()
class PendingNotifications {
  Id id = Isar.autoIncrement;

  final String body;
  final String sender;
  final int timestamp;
  @Index(unique: true)
  late String hash;
  int retryCount;

  @Index()
  DateTime nextRetryAt;

  @enumerated
  RetryStatus status;

  PendingNotifications({
    required this.body,
    required this.sender,
    required this.timestamp,
    required this.hash,
    this.retryCount = 0,
    required this.nextRetryAt,
    this.status = RetryStatus.pending,
  });

  void scheduleNextRetry() {
    retryCount++;
    final delaySeconds = (1 << retryCount).clamp(1, 300);
    nextRetryAt = DateTime.now().add(Duration(seconds: delaySeconds));
  }

  void markFailed() {
    status = RetryStatus.failed;
  }

  factory PendingNotifications.fromJson(Map<String, dynamic> json) =>
      _$PendingNotificationsFromJson(json);

  Map<String, dynamic> toJson() => _$PendingNotificationsToJson(this);

  factory PendingNotifications.create({
    required String body,
    required String sender,
    required int timestamp,
    required String hash,
  }) {
    return PendingNotifications(
      body: body,
      sender: sender,
      timestamp: timestamp,
      hash: hash,
      nextRetryAt: DateTime.now(),
    );
  }
}

enum RetryStatus {
  pending,
  retrying,
  failed,
}
