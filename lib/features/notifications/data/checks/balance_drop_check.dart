import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class BalanceDropCheck extends SmartCheck {
  BalanceDropCheck(super.isarService);

  @override
  String get type => 'balance_drop_prediction';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final accounts =
        await isar.accounts.filter().isActiveEqualTo(true).findAll();

    double totalBalance = 0;
    for (final acc in accounts) {
      final txns = await isar.transactions
          .filter()
          .account((q) => q.idEqualTo(acc.id))
          .findAll();
      final income = txns
          .where((t) => !t.isExpense && !t.isTransfer)
          .fold<double>(0, (s, t) => s + t.baseAmount);
      final expense = txns
          .where((t) => t.isExpense && !t.isTransfer)
          .fold<double>(0, (s, t) => s + t.baseAmount);
      totalBalance += acc.initialBalance + income - expense;
    }

    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    final recentExpenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(thirtyDaysAgo)
        .findAll();

    final totalRecentExpense =
        recentExpenses.fold<double>(0, (s, t) => s + t.baseAmount);
    final dailyBurn = totalRecentExpense / 30;

    if (dailyBurn <= 0 || totalBalance <= 0) return;

    final upcomingBills = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .isExpenseEqualTo(true)
        .nextDueDateBetween(now, now.add(const Duration(days: 30)))
        .findAll();
    final billsTotal = upcomingBills.fold<double>(0, (s, b) => s + b.amount);

    final daysUntilZero = (totalBalance - billsTotal) / dailyBurn;

    if (daysUntilZero > 0 && daysUntilZero <= 30) {
      await SmartNotificationEmitter.emit(
        isar,
        type: type,
        title: Tone.appL10n?.notif_fundsGettingLowTitle ??
            '📉 Funds getting low',
        body: Tone.current
            .balanceDropNotif(daysUntilZero.toStringAsFixed(0)),
        channel: 'smart_alerts',
        channelName: 'Smart Alerts',
        priority: daysUntilZero <= 7
            ? NotificationPriority.urgent
            : NotificationPriority.high,
        primaryAction: 'View Accounts',
        actionData: jsonEncode({'type': 'view_accounts'}),
      );
    }
  }
}
