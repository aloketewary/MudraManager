import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'dart:convert';

class CreditCardReminderPlugin extends MudraPlugin {
  static const _baseNotificationId = 5000;
  static const _maxCards = 10;

  @override
  String get id => 'com.mudra.credit_card_reminder';

  @override
  String get name => 'Credit Card Bill Reminder';

  @override
  String get version => '1.0.0';

  @override
  void onLoad() {}

  @override
  void onStart() {
    _scheduleReminders();
  }

  @override
  void onStop() {
    _cancelAllReminders();
  }

  @override
  Future<void> dispose() async {
    await _cancelAllReminders();
  }

  @override
  void onExpense(ExpenseEvent event) {
    final cat = event.category.toLowerCase();
    if (cat.contains('credit') || cat.contains('card')) {
      _scheduleReminders();
    }
  }

  Future<void> _cancelAllReminders() async {
    for (int i = 0; i < _maxCards; i++) {
      await api.cancelNotification(_baseNotificationId + i);
    }
  }

  Future<void> _scheduleReminders() async {
    final daysStr = await api.getStorage('reminder_days');
    final reminderDays = int.tryParse(daysStr ?? '') ?? 1;

    final cardsJson = await api.getStorage('bill_dates');
    final List<dynamic> cards = cardsJson != null ? json.decode(cardsJson) : [];

    await _cancelAllReminders();

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardName = card['name'] as String? ?? '';
      final billDay = card['day'] as int? ?? 15;
      await _scheduleForCard(cardName, billDay, reminderDays, i);
    }
  }

  Future<void> _scheduleForCard(
    String cardName,
    int billDay,
    int reminderDays,
    int index,
  ) async {
    try {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, billDay, 9);
      final nextMonth = DateTime(now.year, now.month + 1, billDay, 9);

      final nextBillDate = thisMonth.isAfter(now) ? thisMonth : nextMonth;
      final reminderDate = nextBillDate.subtract(Duration(days: reminderDays));

      if (reminderDate.isAfter(now)) {
        await api.scheduleNotification(
          '💳 $cardName bill due on ${billDay}th. Pay now to avoid late fees!',
          reminderDate,
          id: _baseNotificationId + index,
        );
      }
    } catch (_) {}
  }

  @override
  Set<PluginPermission> get permissions => {
        PluginPermission.notifications,
        PluginPermission.storage,
      };
}
