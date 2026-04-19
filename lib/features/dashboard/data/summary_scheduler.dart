import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryScheduler {
  static const _lastDailySummaryKey = 'last_daily_summary_date';
  static const _lastWeeklySummaryKey = 'last_weekly_summary_date';

  static Future<void> checkAndShowSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await _checkDailySummary(prefs, now);
    await _checkWeeklySummary(prefs, now);
  }

  static Future<void> _checkDailySummary(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    if (!(prefs.getBool('daily_summary_enabled') ?? false)) return;

    final lastSummary = prefs.getString(_lastDailySummaryKey);
    final today = DateTime(now.year, now.month, now.day);

    if (lastSummary == null || DateTime.parse(lastSummary).isBefore(today)) {
      await NotificationService.showDailySummary();
      await prefs.setString(_lastDailySummaryKey, today.toIso8601String());
    }
  }

  static Future<void> _checkWeeklySummary(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    if (!(prefs.getBool('weekly_summary_enabled') ?? true)) return;

    final selectedDay = prefs.getInt('weekly_summary_day') ?? DateTime.sunday;
    if (now.weekday != selectedDay) return;

    final lastSummary = prefs.getString(_lastWeeklySummaryKey);
    final today = DateTime(now.year, now.month, now.day);

    if (lastSummary == null || DateTime.parse(lastSummary).isBefore(today)) {
      await NotificationService.showWeeklySummary();
      await prefs.setString(_lastWeeklySummaryKey, today.toIso8601String());
    }
  }
}
