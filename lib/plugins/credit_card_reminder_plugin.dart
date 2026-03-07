import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class CreditCardReminderPlugin extends MudraPlugin {
  static const _baseNotificationId = 5000;
  static final _plugin = FlutterLocalNotificationsPlugin();

  @override
  String get id => 'com.mudra.credit_card_reminder';

  @override
  String get name => 'Credit Card Bill Reminder';

  @override
  String get description => 'Get notified before credit card bill due dates';

  @override
  String get version => '1.0.0';

  @override
  String get iconPath => 'assets/logo/plugins/credit_card.svg';

  @override
  void onLoad() {}

  @override
  void onStart() {
    _scheduleReminders();
  }

  @override
  void onExpense(ExpenseEvent event) {
    if (event.category.toLowerCase().contains('credit') || 
        event.category.toLowerCase().contains('card')) {
      _scheduleReminders();
    }
  }

  Future<void> _scheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('credit_card_reminder_days') ?? 1;
    final billDates = prefs.getStringList('credit_card_bill_dates') ?? [];

    // Cancel only necessary notifications
    final cancelFutures = List.generate(
      billDates.length.clamp(0, 10),
      (i) => _plugin.cancel(_baseNotificationId + i),
    );
    await Future.wait(cancelFutures);

    // Schedule in parallel
    final scheduleFutures = <Future>[];
    for (int i = 0; i < billDates.length; i++) {
      final parts = billDates[i].split('|');
      if (parts.length == 2) {
        final cardName = parts[0];
        final billDay = int.tryParse(parts[1]) ?? 15;
        scheduleFutures.add(_scheduleReminderForCard(cardName, billDay, reminderDays, i));
      }
    }
    await Future.wait(scheduleFutures);
  }

  Future<void> _scheduleReminderForCard(
    String cardName,
    int billDay,
    int reminderDays,
    int index,
  ) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final currentMonth = tz.TZDateTime(tz.local, now.year, now.month, billDay, 9, 0);
      final nextMonth = tz.TZDateTime(tz.local, now.year, now.month + 1, billDay, 9, 0);
      
      final nextBillDate = currentMonth.isAfter(now) ? currentMonth : nextMonth;
      final reminderDate = nextBillDate.subtract(Duration(days: reminderDays));
      
      if (reminderDate.isAfter(now)) {
        await _plugin.zonedSchedule(
          _baseNotificationId + index,
          '💳 Credit Card Bill Reminder',
          '$cardName bill due on ${billDay}th. Pay now to avoid late fees!',
          reminderDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'credit_card_reminder_channel',
              'Credit Card Reminders',
              channelDescription: 'Reminders for credit card bill payments',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      // Silently fail - notification scheduling is non-critical
    }
  }

  @override
  Map<String, dynamic>? getConfig() {
    return {
      'ui_screen': 'CreditCardReminderSettings',
      'description': 'Manage your credit card bill reminders',
    };
  }
}