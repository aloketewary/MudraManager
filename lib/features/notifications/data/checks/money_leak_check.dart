import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class MoneyLeakCheck extends SmartCheck {
  MoneyLeakCheck(super.isarService);

  @override
  String get type => 'money_leak';

  @override
  Future<void> run() async {
    final isar = await isarService.getInstance();
    final now = DateTime.now();
    if (now.day < 14) return;

    final startOfMonth = DateTime(now.year, now.month, 1);
    final txns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(startOfMonth.subtract(const Duration(days: 1)))
        .findAll();

    if (txns.isEmpty) return;

    // Batch-load categories once before aggregation
    for (final t in txns) {
      t.category.loadSync();
    }

    final catStats = <String, ({int count, double total})>{};
    for (final t in txns) {
      final name = t.category.value?.name ?? 'Other';
      final prev = catStats[name] ?? (count: 0, total: 0.0);
      catStats[name] = (count: prev.count + 1, total: prev.total + t.baseAmount);
    }

    final totalExpense = txns.fold<double>(0, (s, t) => s + t.baseAmount);
    final dailyAvg = totalExpense / now.day;

    final leaks = catStats.entries.where((e) {
      final avgTxn = e.value.total / e.value.count;
      return e.value.count >= 5 && avgTxn < dailyAvg * 0.15;
    }).toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    if (leaks.isEmpty) return;

    final top = leaks.first;
    await SmartNotificationEmitter.emit(
      isar,
      type: type,
      title: Tone.appL10n?.notif_smallSpendsTitle ?? '💧 Small spends adding up',
      body: Tone.current.moneyLeakNotif(
        top.key,
        top.value.count,
        top.value.total.toStringAsFixed(0),
      ),
      channel: 'smart_alerts',
      channelName: 'Smart Alerts',
      primaryAction: 'View Stats',
      actionData: jsonEncode({'type': 'view_statistics'}),
    );
  }
}
