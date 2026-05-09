import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';

/// Interface for all periodic smart notification checks.
///
/// Each check is independently testable and runs in isolation.
/// Wire new checks into [SmartNotificationService.checks].
abstract class SmartCheck {
  final IsarService isarService;

  SmartCheck(this.isarService);

  /// Unique type string for dedup (one per day per type).
  String get type;

  /// Run the check and emit notification if conditions are met.
  Future<void> run();
}

/// Shared helper for emitting smart notifications.
/// All [SmartCheck] implementations route through this.
class SmartNotificationEmitter {
  static final _log = AppLog(getLogger(), 'SmartNotificationEmitter');

  static Future<void> emit(
    Isar isar, {
    required String type,
    required String title,
    required String body,
    required String channel,
    required String channelName,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.financial,
    String? primaryAction,
    String? actionData,
  }) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final existing = await isar.notificationRecords
        .filter()
        .typeEqualTo(type)
        .timestampGreaterThan(startOfDay)
        .findFirst();
    if (existing != null) return;

    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type
      ..priority = priority
      ..category = category
      ..primaryAction = primaryAction
      ..actionData = actionData;

    record.encryptFields(); // Sentinel: Encrypt smart check result before persisting
    await isar.writeTxn(() => isar.notificationRecords.put(record));

    // Extract route from actionData JSON for tap navigation
    String? payload;
    if (actionData != null) {
      try {
        final data = jsonDecode(actionData) as Map<String, dynamic>;
        payload = data['type'] as String?;
      } catch (_) {}
    }

    await NotificationService.showLocalNotification(
      id: type.hashCode.abs() % 2147483647,
      title: title,
      body: body,
      payload: payload,
      dedupKey: type,
    );

    _log.i('Smart alert emitted: $type');
  }
}
