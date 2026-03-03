import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditCardReminderPlugin extends MudraPlugin {
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
    // Check if expense is from credit card account
    if (event.category.toLowerCase().contains('credit') || 
        event.category.toLowerCase().contains('card')) {
      _scheduleReminders();
    }
  }

  Future<void> _scheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('credit_card_reminder_days') ?? 1;
    final billDates = prefs.getStringList('credit_card_bill_dates') ?? [];

    for (final dateStr in billDates) {
      final parts = dateStr.split('|'); // Format: "CardName|15" (15th of month)
      if (parts.length == 2) {
        final cardName = parts[0];
        final billDay = int.tryParse(parts[1]) ?? 15;
        
        await _scheduleReminderForCard(cardName, billDay, reminderDays);
      }
    }
  }

  Future<void> _scheduleReminderForCard(String cardName, int billDay, int reminderDays) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, billDay);
    final nextMonth = DateTime(now.year, now.month + 1, billDay);
    
    // Determine next bill date
    final nextBillDate = currentMonth.isAfter(now) ? currentMonth : nextMonth;
    final reminderDate = nextBillDate.subtract(Duration(days: reminderDays));
    
    // Only schedule if reminder date is in future
    if (reminderDate.isAfter(now)) {
      await NotificationService.showLocalNotification(
        id: cardName.hashCode,
        title: '💳 Credit Card Bill Reminder',
        body: '$cardName bill due on ${billDay}th. Pay now to avoid late fees!',
      );
    }
  }

  @override
  Map<String, dynamic>? getConfig() {
    return {
      'reminder_days': {
        'type': 'number',
        'label': 'Remind me before (days)',
        'default': 1,
        'min': 1,
        'max': 7,
      },
      'bill_dates': {
        'type': 'list',
        'label': 'Credit Card Bill Dates',
        'default': [],
        'item_format': 'Card Name|Bill Day (1-31)',
      },
    };
  }
}