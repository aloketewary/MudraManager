import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class WeeklyRecapNudgeCheck extends SmartCheck {
  @override
  String get type => 'weekly_recap_nudge';

  @override
  Future<void> run() async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;
    if (now.hour < 17 || now.hour >= 21) return;

    final isar = await IsarService().getInstance();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final weekTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(startOfWeek, now)
        .findAll();

    if (weekTxns.isEmpty) return;

    final weekTotal = weekTxns.fold<double>(0, (s, t) => s + t.baseAmount);

    final catSpend = <String, double>{};
    for (final t in weekTxns) {
      t.category.loadSync();
      final name = t.category.value?.name ?? 'Other';
      catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
    }
    final topCat = catSpend.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topPct = (topCat.value / weekTotal * 100).toStringAsFixed(0);

    final hookStat = Tone.current.weeklyRecapHookStat(topPct, topCat.key);

    await SmartNotificationEmitter.emit(
      isar,
      type: type,
      title: Tone.appL10n?.notif_weeklyRecapNudgeTitle ?? '📊 Your weekly recap is ready',
      body: Tone.current.weeklyRecapNudge(hookStat),
      channel: 'summaries',
      channelName: 'Summaries',
      primaryAction: 'View Recap',
      actionData: jsonEncode({'type': 'view_recap'}),
    );
  }
}
