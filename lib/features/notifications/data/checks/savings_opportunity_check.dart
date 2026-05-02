import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class SavingsOpportunityCheck extends SmartCheck {
  SavingsOpportunityCheck(super.isarService);

  @override
  String get type => 'savings_opportunity';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(startOfMonth.subtract(const Duration(days: 1)))
        .findAll();

    if (monthTxns.isEmpty) return;

    for (final t in monthTxns) {
      t.category.loadSync();
    }

    final catSpend = <String, double>{};
    for (final t in monthTxns) {
      final name = t.category.value?.name ?? 'Other';
      catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
    }

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = startOfMonth.subtract(const Duration(days: 1));
    final lastMonthTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(lastMonthStart, lastMonthEnd)
        .findAll();

    if (lastMonthTxns.isEmpty) return;

    for (final t in lastMonthTxns) {
      t.category.loadSync();
    }

    final lastCatSpend = <String, double>{};
    for (final t in lastMonthTxns) {
      final name = t.category.value?.name ?? 'Other';
      lastCatSpend[name] = (lastCatSpend[name] ?? 0) + t.baseAmount;
    }

    String? spikeCategory;
    double spikeAmount = 0;

    for (final entry in catSpend.entries) {
      final lastMonth = lastCatSpend[entry.key] ?? 0;
      if (lastMonth == 0) continue;

      final daysElapsed = now.day;
      final projected = entry.value / daysElapsed * 30;
      final increase = projected - lastMonth;

      if (increase > spikeAmount && increase > 500) {
        spikeAmount = increase;
        spikeCategory = entry.key;
      }
    }

    if (spikeCategory != null) {
      await SmartNotificationEmitter.emit(
        isar,
        type: type,
        title: Tone.appL10n?.notif_categoryCreepingUpTitle(spikeCategory) ??
            '💡 $spikeCategory is creeping up',
        body: Tone.current.savingsOpportunityNotif(
          spikeCategory,
          spikeAmount.toStringAsFixed(0),
        ),
        channel: 'smart_alerts',
        channelName: 'Smart Alerts',
        primaryAction: 'View Spending',
        actionData: jsonEncode({'type': 'view_budget'}),
      );
    }
  }
}
