import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _reminderTimeKey = 'daily_reminder_time_key';

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
    if (timeZoneName == 'Asia/Calcutta') {
      timeZoneName = 'Asia/Kolkata';
    }

    final location = tz.getLocation(
      tz.timeZoneDatabase.locations.containsKey(timeZoneName)
          ? timeZoneName
          : 'UTC',
    );
    tz.setLocalLocation(location);

    await requestNotificationPermission();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
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
    await _plugin.cancel(0);
    await _saveReminderTime(time);

    final scheduledDate = _nextInstanceOfTime(time);
    if (kDebugMode) {
      print(scheduledDate);
    }

    await _plugin.zonedSchedule(
      0,
      'Daily Expense Summary',
      'Tap to view your spending summary',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Daily reminder to track expenses',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showDailySummary() async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final transactions = await isar.transactions
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findAll();

    if (transactions.isEmpty) {
      await showLocalNotification(
        id: 100,
        title: '📊 Yesterday\'s Summary',
        body: 'No transactions recorded yesterday',
      );
      return;
    }

    double totalSpent = 0;
    double totalIncome = 0;
    final categorySpending = <String, double>{};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      
      if (tx.isExpense) {
        totalSpent += tx.amount;
        final cat = tx.category.value;
        if (cat != null) {
          categorySpending[cat.name] = (categorySpending[cat.name] ?? 0) + tx.amount;
        }
      } else {
        totalIncome += tx.amount;
      }
    }

    String topCategory = 'None';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final accounts = await isar.collection<Account>().where().findAll();
    double totalBalance = 0;
    for (final acc in accounts) {
      final txs = await isar.transactions.filter().account((q) => q.idEqualTo(acc.id)).findAll();
      final balance = acc.initialBalance + txs.fold<double>(0, (sum, tx) => sum + (tx.isExpense ? -tx.amount : tx.amount));
      totalBalance += balance;
    }

    final body = '💸 Spent: ₹${totalSpent.toStringAsFixed(0)} | '
        '💰 Income: ₹${totalIncome.toStringAsFixed(0)}\n'
        '🏆 Top: $topCategory | Balance: ₹${totalBalance.toStringAsFixed(0)}';

    await showLocalNotification(
      id: 100,
      title: '📊 Yesterday\'s Summary',
      body: body,
    );
  }

  static Future<void> scheduleWeeklySummary([int weekday = DateTime.sunday]) async {
    await _plugin.cancel(2);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      2,
      'Weekly Summary',
      'Tap to view your week',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary_channel',
          'Weekly Summary',
          channelDescription: 'Weekly spending summary',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showWeeklySummary() async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));

    final transactions = await isar.transactions
        .filter()
        .dateBetween(startDate, endDate)
        .findAll();

    if (transactions.isEmpty) {
      await showLocalNotification(
        id: 101,
        title: '📅 Weekly Summary',
        body: 'No transactions this week',
      );
      return;
    }

    double totalSpent = 0;
    double totalIncome = 0;
    final categorySpending = <String, double>{};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      
      if (tx.isExpense) {
        totalSpent += tx.amount;
        final cat = tx.category.value;
        if (cat != null) {
          categorySpending[cat.name] = (categorySpending[cat.name] ?? 0) + tx.amount;
        }
      } else {
        totalIncome += tx.amount;
      }
    }

    String topCategory = 'None';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final body = '💸 Spent: ₹${totalSpent.toStringAsFixed(0)} | '
        '💰 Income: ₹${totalIncome.toStringAsFixed(0)}\n'
        '🏆 Top Category: $topCategory | ${transactions.length} transactions';

    await showLocalNotification(
      id: 101,
      title: '📅 This Week\'s Summary',
      body: body,
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

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> scheduleMonthlyGoalReminder(String body) async {
    // ID 1 for monthly goal reminder
    await _plugin.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for the 1st of next month at 9:00 AM
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month + 1,
      1,
      9,
      0,
    );

    await _plugin.zonedSchedule(
      1,
      'Monthly Goal Status',
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminder_channel',
          'Goal Reminders',
          channelDescription: 'Monthly reminders for your goals',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
