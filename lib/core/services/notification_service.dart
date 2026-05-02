import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _reminderTimeKey = 'daily_reminder_time_key';
  static const _streakReminderTimeKey = 'streak_reminder_time_key';
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final _log = AppLog(getLogger(), 'NotificationService');
  static SharedPreferences? _prefsCache;

  /// Set the navigator key for notification tap routing.
  /// Call this once from your root MaterialApp/GoRouter.
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// @deprecated Use setNavigatorKey instead.
  static void setContext(BuildContext context) {
    // Kept for backward compatibility — callers should migrate to setNavigatorKey
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
      settings: initializationSettings,
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
    await _plugin.cancel(id: 0);
    await _saveReminderTime(time);

    final scheduledDate = _nextInstanceOfTime(time);
    _log.i('Scheduling daily reminder at ${time.hour}:${time.minute}');

    await _plugin.zonedSchedule(


      id: 0,


      title: Tone.appL10n?.notif_dailyReminderTitle ?? '📊 Your day in numbers',


      body: Tone.appL10n?.notif_dailyReminderBody ?? 'Here\'s how yesterday went — take a quick look',


      scheduledDate: scheduledDate,


      notificationDetails: const NotificationDetails(
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
        title: Tone.appL10n?.notif_quietDayTitle ?? '📊 Quiet day yesterday',
        body: BuddyMessages.dailySummaryEmpty,
        payload: 'statistics',
        dedupKey: 'daily_summary',
        bypassThrottle: true,
      );
      return;
    }

    double totalSpent = 0;
    double totalIncome = 0;
    final categorySpending = <String, double>{};

    // Batch-load categories once before the loop
    for (final tx in transactions) {
      tx.category.loadSync();
    }

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

    await showLocalNotification(
      id: 100,
      title: Tone.appL10n?.notif_heresYesterdayTitle ?? '📊 Here\'s yesterday',
      body: Tone.current.dailySummaryNotif(
        totalSpent.toStringAsFixed(0),
        totalIncome.toStringAsFixed(0),
        topCategory,
      ),
      payload: 'statistics',
      dedupKey: 'daily_summary',
      bypassThrottle: true,
    );
  }

  static Future<void> scheduleWeeklySummary([
    int weekday = DateTime.sunday,
  ]) async {
    await _plugin.cancel(id: 2);

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


      id: 2,


      title: Tone.appL10n?.notif_weeklyReminderTitle ?? '📅 Your week wrapped up',


      body: Tone.appL10n?.notif_weeklyReminderBody ?? 'Let\'s see how the week went — tap to check',


      scheduledDate: scheduledDate,


      notificationDetails: const NotificationDetails(
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
      final zeroBody = Tone.appL10n?.notif_weeklyZeroBody ?? 'Zero expenses this week — that\'s impressive 💪';
      await showLocalNotification(
        id: 101,
        title: Tone.appL10n?.notif_weekInReviewTitle ?? '📅 Week in review',
        body: zeroBody,
        payload: 'statistics',
        dedupKey: 'weekly_summary',
        bypassThrottle: true,
      );
      await _logToDatabase(
        Tone.appL10n?.notif_weekInReviewTitle ?? '📅 Weekly Summary',
        zeroBody,
        'weekly_summary',
      );
      return;
    }

    // Top category — batch-load once
    for (final t in thisWeekTxns) {
      t.category.loadSync();
    }
    final catSpend = <String, double>{};
    for (final t in thisWeekTxns) {
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
      title: Tone.appL10n?.notif_yourWeekInReviewTitle ?? '📅 Your week in review',
      body: body,
      payload: 'statistics',
      dedupKey: 'weekly_summary',
      bypassThrottle: true,
    );
    await _logToDatabase(Tone.appL10n?.notif_yourWeekInReviewTitle ?? '📅 Your week in review', body, 'weekly_summary');
  }

  static Future<void> _saveReminderTime(TimeOfDay time) async {
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
    prefs.setString(_reminderTimeKey, '${time.hour}:${time.minute}');
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(id: 0);
  }

  static Future<TimeOfDay?> getSavedReminderTime() async {
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
    final saved = prefs.getString(_reminderTimeKey);
    if (saved == null) return null;
    final parts = saved.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<TimeOfDay?> getSavedStreakReminderTime() async {
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
    final saved = prefs.getString(_streakReminderTimeKey);
    if (saved == null) return null;
    final parts = saved.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> saveStreakReminderTime(TimeOfDay time) async {
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
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

  // ── Throttle: max N smart-alert OS notifications per day ──
  static const _maxDailySmartPush = 12;
  static const _pushCountKey = 'notif_push_count';
  static const _pushDateKey = 'notif_push_date';
  static const _contentHashKey = 'notif_content_hashes';
  static const _contentHashDateKey = 'notif_content_hash_date';

  /// Generate a short content hash from title+body for dedup.
  static String _contentHash(String title, String body) {
    final bytes = utf8.encode('$title|$body');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// Show an OS notification.
  /// [dedupKey] — if set, only one notification per key per day.
  /// [bypassThrottle] — if true, skip the daily cap (for scheduled summaries, streaks, achievements).
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? dedupKey,
    bool bypassThrottle = false,
  }) async {
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    // ── Clean up stale dedup keys from previous days ──
    final allKeys = prefs.getKeys();
    // Only run cleanup once per day
    if (prefs.getString(_pushDateKey) != today) {
      for (final key in allKeys) {
        if (key.startsWith('dedup_')) {
          final val = prefs.getString(key);
          if (val != null && val != today) {
            await prefs.remove(key);
          }
        }
      }
    }

    // ── Content-hash dedup: same title+body never fires twice in a day ──
    // Skip for bypassThrottle — SMS per-txn notifications are unique events
    if (!bypassThrottle) {
      if (prefs.getString(_contentHashDateKey) != today) {
        await prefs.setStringList(_contentHashKey, []);
        await prefs.setString(_contentHashDateKey, today);
      }
      final hash = _contentHash(title, body);
      final seenHashes = prefs.getStringList(_contentHashKey) ?? [];
      if (seenHashes.contains(hash)) {
        _log.i('Content-hash dedup, skipping: $title');
        return;
      }
      seenHashes.add(hash);
      if (seenHashes.length > 500) seenHashes.removeRange(0, seenHashes.length - 500);
      await prefs.setStringList(_contentHashKey, seenHashes);
    }

    // Dedup: if a dedupKey is provided, skip if already sent today
    if (dedupKey != null) {
      final stored = prefs.getString('dedup_$dedupKey');
      if (stored == today) {
        _log.i('Dedup key already sent today, skipping: $dedupKey');
        return;
      }
      await prefs.setString('dedup_$dedupKey', today);
    }

    // Throttle: cap smart-alert pushes per day (scheduled notifications bypass)
    if (!bypassThrottle) {
      if (prefs.getString(_pushDateKey) != today) {
        await prefs.setInt(_pushCountKey, 0);
        await prefs.setString(_pushDateKey, today);
      }
      final count = prefs.getInt(_pushCountKey) ?? 0;
      if (count >= _maxDailySmartPush) {
        _log.i('Daily push cap reached, skipping: $title');
        return;
      }
      await prefs.setInt(_pushCountKey, count + 1);
    }

    _log.i('Showing notification: $title');

    // Route to appropriate Android channel based on dedupKey prefix
    final channelId = _resolveChannel(dedupKey, payload);
    final androidDetails = AndroidNotificationDetails(
      channelId.$1,
      channelId.$2,
      channelDescription: channelId.$3,
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id: id, title: title, body: body, notificationDetails: notificationDetails, payload: payload);
  }

  /// Resolve Android notification channel based on notification type.
  static (String id, String name, String desc) _resolveChannel(
    String? dedupKey,
    String? payload,
  ) {
    if (dedupKey != null) {
      if (dedupKey.startsWith('sms_')) {
        return ('sms_transactions', 'SMS Transactions', 'Auto-imported SMS transaction alerts');
      }
      if (dedupKey.startsWith('budget_')) {
        return ('budget_alerts', 'Budget Alerts', 'Budget limit warnings and exceeded alerts');
      }
      if (dedupKey.startsWith('bill_')) {
        return ('bill_reminders', 'Bill Reminders', 'Upcoming bill payment reminders');
      }
      if (dedupKey == 'daily_summary' || dedupKey == 'weekly_summary') {
        return ('summaries', 'Summaries', 'Daily and weekly spending summaries');
      }
    }
    if (payload == 'achievements') {
      return ('gamification', 'Achievements & Streaks', 'Achievement unlocks, level-ups, and streak milestones');
    }
    return ('mudra_channel_id', 'Mudra Manager', 'General notifications');
  }

  static void _handleNotificationTap(String? payload) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    switch (payload) {
      case 'statistics':
        GoRouter.of(context).go(AppRoutes.statistics);
      case 'home':
        GoRouter.of(context).go(AppRoutes.home);
      case 'achievements':
        GoRouter.of(context).go(AppRoutes.achievements);
      case 'sms_activity':
        GoRouter.of(context).go(AppRoutes.smsActivity);
      case 'view_budget':
        GoRouter.of(context).go(AppRoutes.budgetDashboard);
      case 'view_bills':
        GoRouter.of(context).go(AppRoutes.recurringTransactions);
      case 'view_accounts':
        GoRouter.of(context).go(AppRoutes.manageAccounts);
      case 'view_sms':
        GoRouter.of(context).go(AppRoutes.smsActivity);
      case 'view_recap':
        GoRouter.of(context).go(AppRoutes.monthlyRecap);
      case 'view_statistics':
        GoRouter.of(context).go(AppRoutes.statistics);
      case 'open_home':
        GoRouter.of(context).go(AppRoutes.home);
    }
  }

  static Future<void> scheduleMonthlyGoalReminder(String body) async {
    // ID 1 for monthly goal reminder
    await _plugin.cancel(id: 1);

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


      id: 1,


      title: Tone.appL10n?.notif_goalStatusTitle ?? 'Monthly Goal Status',


      body: body,


      scheduledDate: scheduledDate,


      notificationDetails: const NotificationDetails(
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
    final prefs = _prefsCache ??= await SharedPreferences.getInstance();
    final enabled = prefs.getBool('streak_reminder_enabled') ?? true;

    if (!enabled) return;

    await _plugin.cancel(id: 3);

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


      id: 3,


      title: Tone.appL10n?.notif_streakCountingTitle(currentStreak) ?? '🔥 $currentStreak days and counting!',


      body: Tone.current.streakAtRisk(currentStreak),


      scheduledDate: scheduledDate,


      notificationDetails: const NotificationDetails(
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
    await _plugin.cancel(id: 3);
  }

  static Future<void> showAchievementUnlocked(String title, int xp) async {
    final body = Tone.appL10n?.notif_achievementBody(title, xp) ?? '$title — that\'s +$xp XP for you';
    await showLocalNotification(
      id: DateTime.now().microsecondsSinceEpoch % 100000000,
      title: Tone.appL10n?.notif_niceOneTitle ?? '🏆 Nice one!',
      body: body,
      payload: 'achievements',
      bypassThrottle: true,
    );
    await _logToDatabase(
      Tone.appL10n?.notif_niceOneTitle ?? '🏆 Nice one!',
      body,
      'achievement',
    );
  }

  static Future<void> showLevelUp(int newLevel) async {
    final body = Tone.appL10n?.notif_levelUpBody ?? 'You just leveled up — keep going!';
    final title = Tone.appL10n?.notif_levelUpTitle(newLevel) ?? '🎉 Level $newLevel!';
    await showLocalNotification(
      id: DateTime.now().microsecondsSinceEpoch % 100000000,
      title: title,
      body: body,
      payload: 'achievements',
      bypassThrottle: true,
    );
    await _logToDatabase(title, body, 'level_up');
  }

  static Future<void> showStreakMilestone(int days) async {
    final body = Tone.appL10n?.notif_streakMilestoneBody ?? 'That\'s dedication — your streak is on fire';
    final title = Tone.appL10n?.notif_streakDaysTitle(days) ?? '🔥 $days days straight!';
    await showLocalNotification(
      id: DateTime.now().microsecondsSinceEpoch % 100000000,
      title: title,
      body: body,
      payload: 'achievements',
      bypassThrottle: true,
    );
    await _logToDatabase(title, body, 'streak');
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
