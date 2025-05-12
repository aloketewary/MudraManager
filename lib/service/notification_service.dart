import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _reminderTimeKey = 'daily_reminder_time_key';

  static Future<void> initialize() async {
    // Time zone setup
    tz.initializeTimeZones();
    String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
    if (timeZoneName == 'Asia/Calcutta') {
      timeZoneName = 'Asia/Kolkata';
    }

    // This handles unknown or unsupported timezones gracefully
    final location = tz.getLocation(
      tz.timeZoneDatabase.locations.containsKey(timeZoneName)
          ? timeZoneName
          : 'UTC',
    );
    tz.setLocalLocation(location);

    await requestNotificationPermission();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initializationSettings);
  }

  static Future<void> requestNotificationPermission() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    // Cancel any existing notification with the same ID
    await _plugin.cancel(0);

    // Save the selected time to storage (e.g., SharedPreferences)
    await _saveReminderTime(time);

    // Schedule the new notification
    final scheduledDate = _nextInstanceOfTime(time);
    // _plugin.resolvePlatformSpecificImplementation();
    if (kDebugMode) {
      print(scheduledDate);
    }

    await _plugin.zonedSchedule(
      0,
      'Daily Expense Reminder',
      'Don\'t forget to track your expenses today!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Daily reminder to track expenses',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> _saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_reminderTimeKey, "${time.hour}:${time.minute}");
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(0);
  }

  static Future<TimeOfDay?> getSavedReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_reminderTimeKey);
    if (saved == null) return null;
    final parts = saved.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mudra_channel_id',
      'Mudra Manager Notifications',
      channelDescription: 'Notifications for budget & account alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails);
  }
}
