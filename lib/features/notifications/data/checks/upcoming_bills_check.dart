import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class UpcomingBillsCheck extends SmartCheck {
  UpcomingBillsCheck(super.isarService);

  @override
  String get type => 'upcoming_bills';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final threeDays = now.add(const Duration(days: 3));

    // ── Recurring bills ──
    final bills = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .isExpenseEqualTo(true)
        .nextDueDateBetween(now, threeDays)
        .findAll();

    for (final bill in bills) {
      await bill.category.load();
      final days = bill.nextDueDate.difference(now).inDays;
      final label = days == 0
          ? 'today'
          : days == 1
              ? 'tomorrow'
              : 'in $days days';

      final name = bill.description?.isNotEmpty == true
          ? FieldEncryptionService.safeDisplay(
              bill.description, bill.category.value?.name ?? 'Bill',)
          : bill.category.value?.name ?? 'Bill';

      await SmartNotificationEmitter.emit(
        isar,
        type: 'bill_due_${bill.id}',
        title: Tone.appL10n?.notif_billDueTitle(name, label) ??
            '📅 $name is due $label',
        body: Tone.current.billDueNotif(
          name,
          bill.amount.toStringAsFixed(0),
          label,
        ),
        channel: 'bill_reminders',
        channelName: 'Bill Reminders',
        priority:
            days <= 1 ? NotificationPriority.high : NotificationPriority.normal,
        primaryAction: 'View Bills',
        actionData: jsonEncode({'type': 'view_bills'}),
      );
    }

    // ── Credit card due dates ──
    final cards = await isar.accounts
        .filter()
        .accountTypeEqualTo(AccountType.creditCard)
        .isActiveEqualTo(true)
        .findAll();

    for (final card in cards) {
      if (card.dueDay == null) continue;
      var dueDate = DateTime(now.year, now.month, card.dueDay!);
      if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
        dueDate = DateTime(now.year, now.month + 1, card.dueDay!);
      }
      final days =
          dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days > 3) continue;

      final label =
          days == 0 ? 'today' : days == 1 ? 'tomorrow' : 'in $days days';
      await SmartNotificationEmitter.emit(
        isar,
        type: 'cc_due_${card.id}',
        title: Tone.appL10n?.notif_billDueTitle(card.name, label) ??
            '\u{1F4B3} ${card.name} due $label',
        body: Tone.current.billDueNotif(card.name, '', label),
        channel: 'bill_reminders',
        channelName: 'Bill Reminders',
        priority:
            days <= 1 ? NotificationPriority.high : NotificationPriority.normal,
        primaryAction: 'View',
        actionData: jsonEncode({'type': 'view_accounts'}),
      );
    }
  }
}
