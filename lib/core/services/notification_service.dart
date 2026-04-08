import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
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
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.cancel(0);
    await _saveReminderTime(time);

    final scheduledDate = _nextInstanceOfTime(time);
    _log.i('Scheduling daily reminder at ${time.hour}:${time.minute}');

    await _plugin.zonedSchedule(
      0,
      '📊 Your day in numbers',
      'Here\'s how yesterday went — take a quick look',
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
        title: '📊 Quiet day yesterday',
        body: Tone.current.dailySummaryEmpty,
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
        totalSpent += tx.baseAmount;
        final cat = tx.category.value;
        if (cat != null) {
          categorySpending[cat.name] =
              (categorySpending[cat.name] ?? 0) + tx.baseAmount;
        }
      } else {
        totalIncome += tx.baseAmount;
      }
    }

    String topCategory = 'None';
    if (categorySpending.isNotEmpty) {
      topCategory = categorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    final accounts = await isar.collection<Account>().where().findAll();
    for (final acc in accounts) {
      await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(acc.id))
          .findAll();
    }

    await showLocalNotification(
      id: 100,
      title: '📊 Here\'s yesterday',
      body: Tone.current.dailySummaryNotif(
        totalSpent.toStringAsFixed(0),
        totalIncome.toStringAsFixed(0),
        topCategory,
      ),
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
      '📅 Your week wrapped up',
      'Let\'s see how the week went — tap to check',
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
    // This week: Mon–now
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = now;

    // Last week: same span
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfWeek;

    final thisWeekTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(startOfWeek, endOfWeek)
        .findAll();

    final lastWeekTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(startOfLastWeek, endOfLastWeek)
        .findAll();

    final thisWeekTotal = thisWeekTxns.fold<double>(0, (s, t) => s + t.baseAmount);
    final lastWeekTotal = lastWeekTxns.fold<double>(0, (s, t) => s + t.baseAmount);

    if (thisWeekTotal <= 0) {
      await showLocalNotification(
        id: 101,
        title: '📅 Week in review',
        body: 'Zero expenses this week — that\'s impressive 💪',
        payload: 'statistics',
      );
      await _logToDatabase(
        '📅 Weekly Summary',
        'No expenses this week — great discipline! 💪',
        'weekly_summary',
      );
      return;
    }

    // Top category
    final catSpend = <String, double>{};
    for (final t in thisWeekTxns) {
      await t.category.load();
      final name = t.category.value?.name ?? 'Other';
      catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
    }
    final topEntry =
        catSpend.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topPct = (topEntry.value / thisWeekTotal * 100).toStringAsFixed(0);

    // Week-over-week
    String trend;
    if (lastWeekTotal <= 0) {
      trend = 'Your first full week!';
    } else {
      final change = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100);
      if (change > 0) {
        trend = 'Up ${change.toStringAsFixed(0)}% from last week';
      } else {
        trend =
            'Down ${change.abs().toStringAsFixed(0)}% from last week — nice!';
      }
    }

    final body = 'You spent ${formatCurrency(thisWeekTotal, code: BaseCurrency.code, decimals: 0)}\n'
        '$topPct% on ${topEntry.key}\n'
        '$trend';
    await showLocalNotification(
      id: 101,
      title: '📅 Your week in review',
      body: body,
      payload: 'statistics',
    );
    await _logToDatabase('📅 Your week in review', body, 'weekly_summary');
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

  // ── Throttle: max N OS notifications per day ──
  static const _maxDailyPush = 5;
  static const _pushCountKey = 'notif_push_count';
  static const _pushDateKey = 'notif_push_date';
  static final _sentToday = <String>{}; // in-memory dedup for current session

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? dedupKey,
  }) async {
    // Dedup: if a dedupKey is provided, skip if already sent today
    if (dedupKey != null) {
      if (_sentToday.contains(dedupKey)) return;
      final prefs = await SharedPreferences.getInstance();
      final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      final stored = prefs.getString('dedup_$dedupKey');
      if (stored == today) return;
      await prefs.setString('dedup_$dedupKey', today);
      _sentToday.add(dedupKey);
    }

    // Throttle: cap total OS pushes per day
    final prefs = await SharedPreferences.getInstance();
    final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    if (prefs.getString(_pushDateKey) != today) {
      await prefs.setInt(_pushCountKey, 0);
      await prefs.setString(_pushDateKey, today);
      _sentToday.clear();
    }
    final count = prefs.getInt(_pushCountKey) ?? 0;
    if (count >= _maxDailyPush) {
      _log.i('Daily push cap reached, skipping: $title');
      return;
    }
    await prefs.setInt(_pushCountKey, count + 1);

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
      _context!.go(AppRoutes.statistics);
    } else if (payload == 'home' && _context != null) {
      _context!.go(AppRoutes.home);
    } else if (payload == 'achievements' && _context != null) {
      _context!.go(AppRoutes.achievements);
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
      '🔥 $currentStreak days and counting!',
      Tone.current.streakAtRisk(currentStreak),
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
      title: '🏆 Nice one!',
      body: '$title — that\'s +$xp XP for you',
      payload: 'achievements',
    );
    await _logToDatabase(
      '🏆 Nice one!',
      '$title — that\'s +$xp XP for you',
      'achievement',
    );
  }

  static Future<void> showLevelUp(int newLevel) async {
    await showLocalNotification(
      id: 201,
      title: '🎉 Level $newLevel!',
      body: 'You just leveled up — keep going!',
      payload: 'achievements',
    );
    await _logToDatabase(
      '🎉 Level Up!',
      'Congratulations! You are now Level $newLevel',
      'level_up',
    );
  }

  static Future<void> showStreakMilestone(int days) async {
    await showLocalNotification(
      id: 202,
      title: '🔥 $days days straight!',
      body: 'That\'s dedication — your streak is on fire',
      payload: 'achievements',
    );
    await _logToDatabase(
      '🔥 Streak Milestone!',
      'Amazing! You have a $days-day streak',
      'streak',
    );
  }

  static Future<void> _logToDatabase(
    String title,
    String body,
    String type,
  ) async {
    final isar = Isar.getInstance();
    if (isar == null) return;
    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type
      ..priority = NotificationPriority.normal
      ..category = NotificationCategory.system;
    await isar.writeTxn(() => isar.notificationRecords.put(record));
  }
}
