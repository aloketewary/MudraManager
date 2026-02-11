import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/service/recurring_transaction_service.dart';

class RecurringTransactionScheduler {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await scheduleRecurringCheck();
  }

  static Future<void> scheduleRecurringCheck() async {
    try {
      // Schedule daily check at 6 AM using inexact timing (doesn't require special permission)
      await _notifications.zonedSchedule(
        999,
        'Recurring Transactions',
        'Processing recurring transactions',
        _nextInstanceOf6AM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_check',
            'Recurring Check',
            channelDescription: 'Background check for recurring transactions',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Recurring transaction check scheduled successfully');
    } catch (e) {
      debugPrint('Recurring check scheduling skipped: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOf6AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 6);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> processNow() async {
    final isarService = IsarService();
    final service = RecurringTransactionService(isarService);
    await service.processRecurringTransactions();
  }
}
