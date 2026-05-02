import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class UnusualSpendingCheck extends SmartCheck {
  UnusualSpendingCheck(super.isarService);

  @override
  String get type => 'unusual_spending';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(today, now)
        .findAll();

    final todaySpend = todayTxns.fold<double>(0, (s, t) => s + t.baseAmount);
    if (todaySpend <= 0) return;

    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    final pastTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(thirtyDaysAgo, today.subtract(const Duration(days: 1)))
        .findAll();

    if (pastTxns.isEmpty) return;

    final avgDaily = pastTxns.fold<double>(0, (s, t) => s + t.baseAmount) / 30;

    if (todaySpend > avgDaily * 2) {
      await SmartNotificationEmitter.emit(
        isar,
        type: type,
        title: Tone.appL10n?.notif_bigDayTitle ?? '📈 Whoa, big day',
        body: Tone.current.unusualSpendingNotif(
          todaySpend.toStringAsFixed(0),
          (todaySpend / avgDaily).toStringAsFixed(1),
        ),
        channel: 'smart_alerts',
        channelName: 'Smart Alerts',
        priority: NotificationPriority.high,
      );
    }
  }
}
