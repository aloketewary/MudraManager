import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/gamification/domain/achievement.dart';
import 'package:mudra_manager/features/notifications/data/smart_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReEngagementCheck extends SmartCheck {
  ReEngagementCheck(super.isarService);

  @override
  String get type => 're_engagement';

  @override
  Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('re_engagement_enabled') ?? true)) return;

    final lastCheckInStr = prefs.getString('last_daily_check_in');
    if (lastCheckInStr == null) return;

    final lastCheckIn = DateTime.tryParse(lastCheckInStr);
    if (lastCheckIn == null) return;

    final daysSince = DateTime.now().difference(lastCheckIn).inDays;
    if (daysSince < 1) return;

    final isar = await isarService.getInstance();

    if (daysSince == 1) {
      await _day1(isar);
    } else if (daysSince == 2) {
      await _day2(isar);
    } else if (daysSince >= 3 && daysSince < 5) {
      await _day3(isar);
    } else if (daysSince >= 5 && daysSince < 7) {
      await _day5(isar, daysSince);
    } else if (daysSince >= 7 && daysSince < 14) {
      await _day7(isar);
    } else if (daysSince >= 14) {
      await _day14(isar);
    }
  }

  Future<void> _day1(Isar isar) async {
    // Priority 1: Streak at risk
    final streak =
        await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
    final currentStreak = streak?.currentCount ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final lastCheckInStr = prefs.getString('last_daily_check_in');
    final lastCheckIn = lastCheckInStr != null ? DateTime.tryParse(lastCheckInStr) : null;
    final now = DateTime.now();
    final alreadyCheckedInToday = lastCheckIn != null &&
        lastCheckIn.year == now.year &&
        lastCheckIn.month == now.month &&
        lastCheckIn.day == now.day;

    if (currentStreak >= 1 && !alreadyCheckedInToday) {
      await SmartNotificationEmitter.emit(
        isar,
        type: 're_engage_streak_risk',
        title: Tone.appL10n?.notif_streakOnLineTitle(currentStreak) ??
            '🔥 $currentStreak-day streak on the line!',
        body: Tone.current.streakAtRisk(currentStreak),
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'Keep Streak',
        actionData: '{"type": "open_home"}',
      );
      return;
    }

    final txnCount = await isar.transactions.count();
    if (txnCount == 0) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final yEnd = DateTime(
        yesterday.year, yesterday.month, yesterday.day, 23, 59, 59,);
    final yTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(yStart, yEnd)
        .findAll();
    final ySpend = yTxns.fold<double>(0, (s, t) => s + t.baseAmount);

    if (ySpend > 0) {
      await SmartNotificationEmitter.emit(
        isar,
        type: 're_engage_day1',
        title: Tone.appL10n?.notif_yesterdaySpendTitle ??
            '💰 Yesterday\'s spending',
        body: Tone.current.morningInsightSpent(
          ySpend.toStringAsFixed(0),
          '',
        ),
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'View Details',
        actionData: '{"type": "open_home"}',
      );
    }
  }

  Future<void> _day2(Isar isar) async {
    final streak =
        await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
    final currentStreak = streak?.currentCount ?? 0;

    final pendingCount = await isar.smsActivitys
        .filter()
        .statusEqualTo(ActivityStatus.pending)
        .or()
        .statusEqualTo(ActivityStatus.needsReview)
        .count();

    String body;
    if (currentStreak >= 3) {
      body = Tone.current.streakAtRisk(currentStreak);
    } else if (pendingCount > 0) {
      body = Tone.current.reEngageDay2Sms(pendingCount);
    } else {
      body = Tone.current.reEngageQuickNudge;
    }

    await SmartNotificationEmitter.emit(
      isar,
      type: 're_engage_day2',
      title: currentStreak >= 3
          ? Tone.appL10n?.notif_streakOnLineTitle(currentStreak) ??
              '🔥 $currentStreak-day streak on the line!'
          : Tone.appL10n?.notif_quickActionTitle ??
              '⚡ 5 seconds is all it takes',
      body: body,
      channel: 're_engagement',
      channelName: 'Re-engagement',
      primaryAction: currentStreak >= 3 ? 'Keep Streak' : 'Add Transaction',
      actionData: '{"type": "open_home"}',
    );
  }

  Future<void> _day3(Isar isar) async {
    final budgets =
        await isar.budgets.filter().isArchivedEqualTo(false).findAll();

    String body;
    if (budgets.isNotEmpty) {
      body = Tone.current.reEngageDay3Budgets(budgets.length);
    } else {
      final streak =
          await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
      final lostStreak = streak?.longestCount ?? 0;
      if (lostStreak >= 3) {
        body = Tone.current.streakLost(lostStreak);
      } else {
        body = Tone.current.reEngageQuickNudge;
      }
    }

    await SmartNotificationEmitter.emit(
      isar,
      type: 're_engage_day3',
      title: Tone.appL10n?.notif_fewDaysUntrackedTitle ??
          '📊 A few days untracked',
      body: body,
      channel: 're_engagement',
      channelName: 'Re-engagement',
      primaryAction: 'Open App',
      actionData: '{"type": "open_home"}',
    );
  }

  Future<void> _day5(Isar isar, int daysSince) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentExpenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(thirtyDaysAgo)
        .amountProperty()
        .sum();
    final dailyAvg = recentExpenses / 30;
    final missed = (dailyAvg * daysSince).round();

    await SmartNotificationEmitter.emit(
      isar,
      type: 're_engage_day5',
      title: Tone.appL10n?.notif_daysUntrackedTitle(daysSince) ??
          '📊 $daysSince days untracked',
      body: missed > 0
          ? Tone.current.reEngageUntracked(daysSince, _formatAmount(missed))
          : Tone.current.reEngageQuickNudge,
      channel: 're_engagement',
      channelName: 'Re-engagement',
      primaryAction: 'Catch Up',
      actionData: '{"type": "open_home"}',
    );
  }

  Future<void> _day7(Isar isar) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(weekAgo)
        .findAll();
    final weekTotal = weekTxns.fold<double>(0, (s, t) => s + t.baseAmount);

    await SmartNotificationEmitter.emit(
      isar,
      type: 're_engage_day7',
      title: Tone.appL10n?.notif_weeklyRecapReadyTitle ??
          '📊 Your weekly recap is waiting',
      body: weekTotal > 0
          ? Tone.current.reEngageDay7Spend(_formatAmount(weekTotal.round()))
          : Tone.current.reEngageQuickNudge,
      channel: 're_engagement',
      channelName: 'Re-engagement',
      primaryAction: 'View Recap',
      actionData: '{"type": "view_recap"}',
    );
  }

  Future<void> _day14(Isar isar) async {
    final streak =
        await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
    final lost = streak?.longestCount ?? 0;
    await SmartNotificationEmitter.emit(
      isar,
      type: 're_engage_day14',
      title: Tone.appL10n?.notif_missYouTitle ?? '👋 We miss you',
      body: Tone.current.reEngageMissYou(lost),
      channel: 're_engagement',
      channelName: 'Re-engagement',
      primaryAction: 'Open App',
      actionData: '{"type": "open_home"}',
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}
