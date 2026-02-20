import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _reminderTimeKey = 'daily_reminder_time_key';
  static const _streakReminderTimeKey = 'streak_reminder_time_key';
  static BuildContext? _context;
  static final _log = AppLog(getLogger(), 'NotificationService');

  static void setContext(BuildContext context) {
    _context = context;
  }

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );
  }

  static Future<void> requestNotificationPermission() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
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
    _log.i('Scheduling daily reminder at ${time.hour}:${time.minute}');

    await _plugin.zonedSchedule(
      0,
      '📊 Daily Summary',
      'Tap to view your spending summary and statistics',
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
      payload: 'statistics',
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    _log.i('Daily reminder scheduled successfully');
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
        payload: 'statistics',
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
          categorySpending[cat.name] =
              (categorySpending[cat.name] ?? 0) + tx.amount;
        }
      } else {
        totalIncome += tx.amount;
      }
    }

    String topCategory = 'None';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    final accounts = await isar.collection<Account>().where().findAll();
    double totalBalance = 0;
    for (final acc in accounts) {
      final txs = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(acc.id))
          .findAll();
      final balance =
          acc.initialBalance +
          txs.fold<double>(
            0,
            (sum, tx) => sum + (tx.isExpense ? -tx.amount : tx.amount),
          );
      totalBalance += balance;
    }

    final body =
        '💸 Spent: ₹${totalSpent.toStringAsFixed(0)} | '
        '💰 Income: ₹${totalIncome.toStringAsFixed(0)}\n'
        '🏆 Top: $topCategory | Balance: ₹${totalBalance.toStringAsFixed(0)}';

    await showLocalNotification(
      id: 100,
      title: '📊 Yesterday\'s Summary',
      body: body,
      payload: 'statistics',
    );
  }

  static Future<void> scheduleWeeklySummary([
    int weekday = DateTime.sunday,
  ]) async {
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
      '📅 Weekly Summary',
      'Tap to view your week\'s spending and statistics',
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
      payload: 'statistics',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showWeeklySummary() async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
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
          categorySpending[cat.name] =
              (categorySpending[cat.name] ?? 0) + tx.amount;
        }
      } else {
        totalIncome += tx.amount;
      }
    }

    String topCategory = 'None';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    final body =
        '💸 Spent: ₹${totalSpent.toStringAsFixed(0)} | '
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
    prefs.setString(_reminderTimeKey, '${time.hour}:${time.minute}');
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

  static Future<TimeOfDay?> getSavedStreakReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_streakReminderTimeKey);
    if (saved == null) return null;
    final parts = saved.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static Future<void> saveStreakReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _streakReminderTimeKey,
      '${time.hour}:${time.minute}',
    );
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
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _log.i('Showing notification: $title');
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

    await _plugin.show(id, title, body, notificationDetails, payload: payload);
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == 'statistics' && _context != null) {
      _context!.go('/statistics');
    } else if (payload == 'home' && _context != null) {
      _context!.go('/home');
    } else if (payload == 'achievements' && _context != null) {
      _context!.go('/achievements');
    }
  }

  static Future<void> scheduleMonthlyGoalReminder(String body) async {
    // ID 1 for monthly goal reminder
    await _plugin.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for the 1st of next month at 9:00 AM
    final scheduledDate = tz.TZDateTime(
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

  static Future<void> scheduleStreakReminder(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('streak_reminder_enabled') ?? true;

    if (!enabled) return;

    await _plugin.cancel(3);

    final savedTime = await getSavedStreakReminderTime();
    final time = savedTime ?? const TimeOfDay(hour: 20, minute: 0);

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
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      3,
      '🔥 Don\'t Break Your Streak!',
      'You have a $currentStreak-day streak. Check in today to keep it going!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder_channel',
          'Streak Reminders',
          channelDescription: 'Reminders to maintain your daily streak',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'home',
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelStreakReminder() async {
    await _plugin.cancel(3);
  }

  static Future<void> showAchievementUnlocked(String title, int xp) async {
    await showLocalNotification(
      id: 200,
      title: '🏆 Achievement Unlocked!',
      body: '$title (+$xp XP)',
      payload: 'achievements',
    );
    await _logToDatabase('🏆 Achievement Unlocked!', '$title (+$xp XP)', 'achievement');
  }

  static Future<void> showLevelUp(int newLevel) async {
    await showLocalNotification(
      id: 201,
      title: '🎉 Level Up!',
      body: 'Congratulations! You are now Level $newLevel',
      payload: 'achievements',
    );
    await _logToDatabase('🎉 Level Up!', 'Congratulations! You are now Level $newLevel', 'level_up');
  }

  static Future<void> showStreakMilestone(int days) async {
    await showLocalNotification(
      id: 202,
      title: '🔥 Streak Milestone!',
      body: 'Amazing! You have a $days-day streak',
      payload: 'achievements',
    );
    await _logToDatabase('🔥 Streak Milestone!', 'Amazing! You have a $days-day streak', 'streak');
  }

  static Future<void> _logToDatabase(String title, String body, String type) async {
    final isar = Isar.getInstance();
    if (isar == null) return;
    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type;
    await isar.writeTxn(() => isar.notificationRecords.put(record));
  }
}
