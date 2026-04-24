import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';

class MorningInsightCheck extends SmartCheck {
  @override
  String get type => 'morning_insight';

  @override
  Future<void> run() async {
    final now = DateTime.now();
    if (now.hour < 7 || now.hour >= 11) return;

    final isar = await IsarService().getInstance();
    final yesterday = now.subtract(const Duration(days: 1));
    final yStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

    final yesterdayTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(yStart, yEnd)
        .findAll();

    final yesterdaySpend = yesterdayTxns.fold<double>(0, (s, t) => s + t.baseAmount);

    final thirtyDaysAgo = yStart.subtract(const Duration(days: 30));
    final pastExpenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(thirtyDaysAgo, yStart.subtract(const Duration(seconds: 1)))
        .findAll();

    final pastTotal = pastExpenses.fold<double>(0, (s, t) => s + t.baseAmount);
    final dailyAvg = pastTotal / 30;

    if (pastExpenses.isEmpty && yesterdayTxns.isEmpty) return;

    String body;
    if (yesterdaySpend <= 0) {
      body = Tone.current.morningInsightZeroSpend;
    } else if (dailyAvg > 0 && yesterdaySpend < dailyAvg) {
      final saved = (dailyAvg - yesterdaySpend).toStringAsFixed(0);
      body = Tone.current.morningInsightUnderAvg(
        yesterdaySpend.toStringAsFixed(0),
        saved,
      );
    } else {
      body = Tone.current.morningInsightSpent(
        yesterdaySpend.toStringAsFixed(0),
        dailyAvg.toStringAsFixed(0),
      );
    }

    if (yesterdayTxns.isNotEmpty) {
      final catSpend = <String, double>{};
      for (final t in yesterdayTxns) {
        t.category.loadSync();
        final name = t.category.value?.name ?? 'Other';
        catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
      }
      if (catSpend.isNotEmpty) {
        final top = catSpend.entries.reduce((a, b) => a.value > b.value ? a : b);
        body += '\n${Tone.current.morningInsightTopCategory(top.key, top.value.toStringAsFixed(0))}';
      }
    }

    await SmartNotificationEmitter.emit(
      isar,
      type: type,
      title: Tone.appL10n?.notif_morningInsightTitle ?? '☀️ Your morning money minute',
      body: body,
      channel: 'smart_alerts',
      channelName: 'Smart Alerts',
      primaryAction: 'View Dashboard',
      actionData: jsonEncode({'type': 'open_home'}),
    );
  }
}
