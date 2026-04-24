import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/notification_record.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'dart:convert';

import 'package:mudra_manager/features/notifications/data/smart_check.dart';
import 'package:mudra_manager/features/notifications/data/all_checks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartNotificationService {
  static final SmartNotificationService instance = SmartNotificationService._();
  static final AppLog _log = AppLog(getLogger(), 'SmartNotificationService');

  SmartNotificationService._();

  // ─── 7. WEEKLY SUMMARY (📅) ───
  // Handled by SummaryScheduler in _runAllTasks — skip here to avoid double-fire.

  /// All OS notifications route through NotificationService gateway.
  /// This method only handles in-app record persistence + dedup.
  Future<void> _emit(
    Isar isar, {
    required String type,
    required String title,
    required String body,
    required String channel,
    required String channelName,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.financial,
    String? primaryAction,
    String? secondaryAction,
    String? actionData,
    int? budgetId,
  }) async {
    // Check if already emitted today (prevents duplicate in-app records)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final existing = await isar.notificationRecords
        .filter()
        .typeEqualTo(type)
        .timestampGreaterThan(startOfDay)
        .findFirst();
    if (existing != null) return;

    // 1. Save in-app record
    final record = NotificationRecord()
      ..title = title
      ..body = body
      ..timestamp = DateTime.now()
      ..isRead = false
      ..type = type
      ..priority = priority
      ..category = category
      ..primaryAction = primaryAction
      ..secondaryAction = secondaryAction
      ..actionData = actionData
      ..budgetId = budgetId;

    await isar.writeTxn(() => isar.notificationRecords.put(record));

    // 2. Fire OS notification through the single gateway (handles throttle + dedup)
    await NotificationService.showLocalNotification(
      id: type.hashCode.abs() % 2147483647,
      title: title,
      body: body,
      dedupKey: type,
    );

    _log.i('Smart alert emitted: $type');
  }

  // ─── 1. BUDGET ALERTS (🚨 Overspending Warning) ───
  /// Collects all exceeded/warning budgets, fires ONE grouped notification.
  Future<void> checkBudgetAlerts() async {
    final isar = await IsarService().getInstance();
    final now = DateTime.now();
    final budgets =
        await isar.budgets.filter().isArchivedEqualTo(false).findAll();

    final exceeded = <String>[];
    final warnings = <String>[];

    for (final budget in budgets) {
      if (budget.recurrence == BudgetRecurrence.none &&
          budget.endDate.isBefore(now)) {
        continue;
      }

      final (start, end) = budget.getCurrentPeriodRange(now);

      double spent;
      if (budget.budgetType == BudgetType.tagWise) {
        await budget.budgetTags.load();
        final tagIds = budget.budgetTags.map((t) => t.id).toSet();
        if (tagIds.isEmpty) continue;
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        spent = 0;
        for (final t in txns) {
          await t.tags.load();
          if (t.tags.any((tag) => tagIds.contains(tag.id))) {
            spent += t.baseAmount;
          }
        }
      } else if (budget.budgetType == BudgetType.dayWise ||
          budget.budgetType == BudgetType.festival ||
          budget.budgetType == BudgetType.travel) {
        await budget.categories.load();
        final categoryIds = budget.categories.map((c) => c.id).toList();
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        if (categoryIds.isEmpty) {
          spent = txns.fold<double>(0.0, (s, t) => s + t.baseAmount);
        } else {
          for (final t in txns) {
            await t.category.load();
          }
          spent = txns
              .where((t) => t.category.value != null && categoryIds.contains(t.category.value!.id))
              .fold<double>(0.0, (s, t) => s + t.baseAmount);
        }
      } else {
        await budget.categories.load();
        final categoryIds = budget.categories.map((c) => c.id).toList();
        if (categoryIds.isEmpty) continue;
        final txns = await isar.transactions
            .filter()
            .isExpenseEqualTo(true)
            .dateBetween(start, end)
            .findAll();
        for (final t in txns) {
          await t.category.load();
        }
        spent = txns
            .where((t) => t.category.value != null && categoryIds.contains(t.category.value!.id))
            .fold<double>(0.0, (s, t) => s + t.baseAmount);
      }

      final pct = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;

      // Reset flags if spending dropped (new period started)
      if (pct < 80 && (budget.notifiedAt80 || budget.notifiedAt90 || budget.notifiedAt100)) {
        budget.notifiedAt80 = false;
        budget.notifiedAt90 = false;
        budget.notifiedAt100 = false;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }

      if (pct >= 100 && !budget.notifiedAt100) {
        exceeded.add(budget.name);
        budget.notifiedAt100 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      } else if (pct >= 80 && !budget.notifiedAt80 && !budget.notifiedAt100) {
        warnings.add(budget.name);
        budget.notifiedAt80 = true;
        await isar.writeTxn(() => isar.budgets.put(budget));
      }
    }

    // Fire ONE grouped notification instead of one per budget
    if (exceeded.isNotEmpty) {
      final n = exceeded.length;
      await _emit(
        isar,
        type: 'budget_exceeded',
        title: Tone.appL10n?.notif_budgetsOverLimitTitle(n) ?? '🚨 $n budget${n > 1 ? 's' : ''} over limit',
        body: n == 1
            ? Tone.appL10n?.notif_budgetExceededBody(exceeded.first) ?? '${exceeded.first} is over budget — time to review'
            : Tone.appL10n?.notif_budgetExceededBodyMulti(exceeded.join(', ')) ?? '${exceeded.join(', ')} are over budget',
        channel: 'budget_alerts',
        channelName: 'Budget Alerts',
        priority: NotificationPriority.urgent,
        primaryAction: 'Review Budgets',
        actionData: jsonEncode({'type': 'view_budget'}),
      );
    } else if (warnings.isNotEmpty) {
      final n = warnings.length;
      await _emit(
        isar,
        type: 'budget_warning',
        title: Tone.appL10n?.notif_budgetsGettingTightTitle(n) ?? '⚠️ $n budget${n > 1 ? 's' : ''} getting tight',
        body: n == 1
            ? Tone.appL10n?.notif_budgetWarningBody(warnings.first) ?? '${warnings.first} is nearing the limit'
            : Tone.appL10n?.notif_budgetWarningBodyMulti(warnings.join(', ')) ?? '${warnings.join(', ')} are nearing their limits',
        channel: 'budget_alerts',
        channelName: 'Budget Alerts',
        priority: NotificationPriority.high,
        primaryAction: 'View Details',
        actionData: jsonEncode({'type': 'view_budget'}),
      );
    }
  }

  // ─── 2. UPCOMING BILL REMINDERS (📅) ───
  Future<void> checkUpcomingBills() async {
    final isar = await IsarService().getInstance();
    final now = DateTime.now();
    final threeDays = now.add(const Duration(days: 3));

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
          ? bill.description!
          : bill.category.value?.name ?? 'Bill';

      await _emit(
        isar,
        type: 'bill_due_${bill.id}',
        title: Tone.appL10n?.notif_billDueTitle(name, label) ?? '📅 $name is due $label',
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
  }

  // ─── 3. BALANCE DROP PREDICTION (📉) ───
  Future<void> checkBalanceDropPrediction() async {
    final isar = await IsarService().getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all accounts with balances
    final accounts =
        await isar.accounts.filter().isActiveEqualTo(true).findAll();

    // Calculate total balance
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

    // Average daily burn rate (last 30 days)
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

    // Upcoming bills in next 30 days
    final upcomingBills = await isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .isExpenseEqualTo(true)
        .nextDueDateBetween(now, now.add(const Duration(days: 30)))
        .findAll();
    final billsTotal = upcomingBills.fold<double>(0, (s, b) => s + b.amount);

    final daysUntilZero = (totalBalance - billsTotal) / dailyBurn;

    if (daysUntilZero > 0 && daysUntilZero <= 30) {
      await _emit(
        isar,
        type: 'balance_drop_prediction',
        title: Tone.appL10n?.notif_fundsGettingLowTitle ?? '📉 Funds getting low',
        body: Tone.current.balanceDropNotif(daysUntilZero.toStringAsFixed(0)),
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

  // ─── 4. SAVINGS OPPORTUNITY (💡) ───
  Future<void> checkSavingsOpportunity() async {
    final isar = await IsarService().getInstance();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // This month's expenses by category
    final monthTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(startOfMonth.subtract(const Duration(days: 1)))
        .findAll();

    if (monthTxns.isEmpty) return;

    // Group by category
    final catSpend = <String, double>{};
    for (final t in monthTxns) {
      t.category.loadSync();
      final name = t.category.value?.name ?? 'Other';
      catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
    }

    // Last month's expenses by category for comparison
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = startOfMonth.subtract(const Duration(days: 1));
    final lastMonthTxns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(lastMonthStart, lastMonthEnd)
        .findAll();

    if (lastMonthTxns.isEmpty) return;

    final lastCatSpend = <String, double>{};
    for (final t in lastMonthTxns) {
      t.category.loadSync();
      final name = t.category.value?.name ?? 'Other';
      lastCatSpend[name] = (lastCatSpend[name] ?? 0) + t.baseAmount;
    }

    // Find category with biggest increase
    String? spikeCategory;
    double spikeAmount = 0;

    for (final entry in catSpend.entries) {
      final lastMonth = lastCatSpend[entry.key] ?? 0;
      if (lastMonth == 0) continue;

      // Prorate current month to full month for fair comparison
      final daysElapsed = now.day;
      final projected = entry.value / daysElapsed * 30;
      final increase = projected - lastMonth;

      if (increase > spikeAmount && increase > 500) {
        spikeAmount = increase;
        spikeCategory = entry.key;
      }
    }

    if (spikeCategory != null) {
      await _emit(
        isar,
        type: 'savings_opportunity',
        title: Tone.appL10n?.notif_categoryCreepingUpTitle(spikeCategory) ?? '💡 $spikeCategory is creeping up',
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

  // ─── 5. UNUSUAL SPENDING (📈 Spike) ───
  Future<void> checkUnusualSpending() async {
    final isar = await IsarService().getInstance();
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
      await _emit(
        isar,
        type: 'unusual_spending',
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

  // ─── 6. PENDING SMS ───
  Future<void> checkPendingSmsTransactions() async {
    final isar = await IsarService().getInstance();
    final pendingCount = await isar.smsActivitys
        .filter()
        .statusEqualTo(ActivityStatus.pending)
        .or()
        .statusEqualTo(ActivityStatus.needsReview)
        .or()
        .statusEqualTo(ActivityStatus.duplicate)
        .count();

    if (pendingCount > 0) {
      await _emit(
        isar,
        type: 'pending_sms',
        title: Tone.appL10n?.notif_smsFoundTitle(pendingCount) ?? '📱 $pendingCount SMS transactions found',
        body: Tone.current.pendingSmsNotif(pendingCount),
        channel: 'pending_transactions',
        channelName: 'Pending Transactions',
        primaryAction: 'Review',
        actionData: jsonEncode({'type': 'view_sms'}),
      );
    }
  }

// ─── 8. MONEY LEAK DETECTION (💧) ───
  Future<void> checkMoneyLeaks() async {
    final isar = await IsarService().getInstance();
    final now = DateTime.now();
    if (now.day < 14) return; // need half a month of data

    final startOfMonth = DateTime(now.year, now.month, 1);
    final txns = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateGreaterThan(startOfMonth.subtract(const Duration(days: 1)))
        .findAll();

    if (txns.isEmpty) return;

    final catStats = <String, ({int count, double total})>{};
    for (final t in txns) {
      t.category.loadSync();
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
    await _emit(
      isar,
      type: 'money_leak',
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

  // ─── 9. RE-ENGAGEMENT NUDGES (🔔) ───
  Future<void> checkReEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('re_engagement_enabled') ?? true)) return;

    final lastCheckInStr = prefs.getString('last_daily_check_in');
    if (lastCheckInStr == null) {
      return; // never opened — onboarding handles this
    }

    final lastCheckIn = DateTime.tryParse(lastCheckInStr);
    if (lastCheckIn == null) return;

    final daysSince = DateTime.now().difference(lastCheckIn).inDays;
    if (daysSince < 1) return;

    final isar = await IsarService().getInstance();

    // ── Day 1: Content-rich first re-open nudge ──
    if (daysSince == 1) {
      // Only fire if user has transactions (not brand new)
      final txnCount = await isar.transactions.count();
      if (txnCount == 0) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      final yTxns = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .dateBetween(yStart, yEnd)
          .findAll();
      final ySpend = yTxns.fold<double>(0, (s, t) => s + t.baseAmount);

      if (ySpend > 0) {
        await _emit(
          isar,
          type: 're_engage_day1',
          title: Tone.appL10n?.notif_yesterdaySpendTitle ?? '💰 Yesterday\'s spending',
          body: Tone.current.morningInsightSpent(
            ySpend.toStringAsFixed(0),
            '', // no avg needed for day 1
          ),
          channel: 're_engagement',
          channelName: 'Re-engagement',
          primaryAction: 'View Details',
          actionData: '{"type": "open_home"}',
        );
      }
      return;
    }

    if (daysSince >= 14) {
      // Streak loss message
      final streak =
          await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
      final lost = streak?.longestCount ?? 0;
      await _emit(
        isar,
        type: 're_engage_day14',
        title: Tone.appL10n?.notif_missYouTitle ?? '👋 We miss you',
        body: Tone.current.reEngageMissYou(lost),
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'Open App',
        actionData: '{"type": "open_home"}',
      );
    } else if (daysSince >= 7) {
      // Day 7: Weekly recap hook
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekTxns = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .dateGreaterThan(weekAgo)
          .findAll();
      final weekTotal = weekTxns.fold<double>(0, (s, t) => s + t.baseAmount);

      await _emit(
        isar,
        type: 're_engage_day7',
        title: Tone.appL10n?.notif_weeklyRecapReadyTitle ?? '📊 Your weekly recap is waiting',
        body: weekTotal > 0
            ? Tone.current.reEngageDay7Spend(_formatAmount(weekTotal.round()))
            : Tone.current.reEngageQuickNudge,
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'View Recap',
        actionData: '{"type": "view_recap"}',
      );
    } else if (daysSince >= 5) {
      // Day 5: Estimate missed spending
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

      await _emit(
        isar,
        type: 're_engage_day5',
        title: Tone.appL10n?.notif_daysUntrackedTitle(daysSince) ?? '📊 $daysSince days untracked',
        body: missed > 0
            ? Tone.current.reEngageUntracked(daysSince, _formatAmount(missed))
            : Tone.current.reEngageQuickNudge,
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'Catch Up',
        actionData: '{"type": "open_home"}',
      );
    } else if (daysSince >= 3) {
      // Day 3: Budget status hook
      final budgets = await isar.budgets
          .filter()
          .isArchivedEqualTo(false)
          .findAll();

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

      await _emit(
        isar,
        type: 're_engage_day3',
        title: Tone.appL10n?.notif_fewDaysUntrackedTitle ?? '📊 A few days untracked',
        body: body,
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: 'Open App',
        actionData: '{"type": "open_home"}',
      );
    } else {
      // Day 2: streak at risk
      final streak =
          await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();
      final currentStreak = streak?.currentCount ?? 0;

      // Content-rich: show pending SMS count if any
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

      await _emit(
        isar,
        type: 're_engage_day2',
        title: currentStreak >= 3
            ? Tone.appL10n?.notif_streakOnLineTitle(currentStreak) ?? '🔥 $currentStreak-day streak on the line!'
            : Tone.appL10n?.notif_quickActionTitle ?? '⚡ 5 seconds is all it takes',
        body: body,
        channel: 're_engagement',
        channelName: 'Re-engagement',
        primaryAction: currentStreak >= 3 ? 'Keep Streak' : 'Add Transaction',
        actionData: '{"type": "open_home"}',
      );
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  // ─── 10. MORNING MONEY MINUTE (☀️) ───
  /// Fires a personalized spending insight once per morning.
  /// Shows yesterday's spend vs daily average + top category.
  Future<void> checkMorningInsight() async {
    final now = DateTime.now();
    // Only fire between 7 AM and 11 AM
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

    // Calculate 30-day daily average (excluding yesterday)
    final thirtyDaysAgo = yStart.subtract(const Duration(days: 30));
    final pastExpenses = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .isTransferEqualTo(false)
        .dateBetween(thirtyDaysAgo, yStart.subtract(const Duration(seconds: 1)))
        .findAll();

    final pastTotal = pastExpenses.fold<double>(0, (s, t) => s + t.baseAmount);
    final dailyAvg = pastTotal / 30;

    // Need at least some history
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

    // Add top category if there was spending
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

    await _emit(
      isar,
      type: 'morning_insight',
      title: Tone.appL10n?.notif_morningInsightTitle ?? '☀️ Your morning money minute',
      body: body,
      channel: 'smart_alerts',
      channelName: 'Smart Alerts',
      primaryAction: 'View Dashboard',
      actionData: jsonEncode({'type': 'open_home'}),
    );
  }

  // ─── 11. WEEKLY RECAP NUDGE (📊) ───
  /// Fires on Sunday evening with a hook stat to drive recap screen opens.
  Future<void> checkWeeklyRecapNudge() async {
    final now = DateTime.now();
    // Only fire on Sunday, between 5 PM and 9 PM
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

    // Find top category for the hook
    final catSpend = <String, double>{};
    for (final t in weekTxns) {
      t.category.loadSync();
      final name = t.category.value?.name ?? 'Other';
      catSpend[name] = (catSpend[name] ?? 0) + t.baseAmount;
    }
    final topCat = catSpend.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topPct = (topCat.value / weekTotal * 100).toStringAsFixed(0);

    final hookStat = Tone.current.weeklyRecapHookStat(topPct, topCat.key);

    await _emit(
      isar,
      type: 'weekly_recap_nudge',
      title: Tone.appL10n?.notif_weeklyRecapNudgeTitle ?? '📊 Your weekly recap is ready',
      body: Tone.current.weeklyRecapNudge(hookStat),
      channel: 'summaries',
      channelName: 'Summaries',
      primaryAction: 'View Recap',
      actionData: jsonEncode({'type': 'view_recap'}),
    );
  }


  // ─── Extracted checks (independently testable) ───
  static final List<SmartCheck> checks = [
    MorningInsightCheck(),
    UnusualSpendingCheck(),
    PendingSmsCheck(),
    MoneyLeakCheck(),
    WeeklyRecapNudgeCheck(),
  ];

  // ─── MASTER RUN ───
  Future<void> runSmartChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final smartEnabled = prefs.getBool('smart_alerts_enabled') ?? true;
    if (!smartEnabled) {
      await checkReEngagement();
      return;
    }
    // Extracted checks
    for (final check in checks) {
      try {
        await check.run();
      } catch (e) {
        _log.e('Smart check "${check.type}" failed', e);
      }
    }
    // Inline checks (complex, to be extracted in follow-up)
    await checkUpcomingBills();
    await checkBudgetAlerts();
    await checkBalanceDropPrediction();
    await checkSavingsOpportunity();
    await checkReEngagement();
    _log.i('All smart checks completed');
  }

  /// Notify when a recurring bill is actually paid (auto-created or SMS-matched).
  /// Called from RecurringTransactionService.
  Future<void> notifyBillPaid({
    required String description,
    required double amount,
    required int billId,
    required bool wasSmsMatched,
  }) async {
    final isar = await IsarService().getInstance();
    await _emit(
      isar,
      type: 'bill_paid_$billId',
      title: wasSmsMatched
          ? Tone.appL10n?.notif_billPaidAutoTitle(description) ?? '✅ $description — auto-matched'
          : Tone.appL10n?.notif_billPaidRecordedTitle(description) ?? '✅ $description — recorded',
      body: Tone.current.billPaidNotif(
        description,
        amount.toStringAsFixed(0),
      ),
      channel: 'bill_reminders',
      channelName: 'Bill Reminders',
      priority: NotificationPriority.normal,
      primaryAction: 'View Bills',
      actionData: jsonEncode({'type': 'view_bills'}),
    );
  }

  /// Notify when budget is exceeded (called from BudgetAlertService).
  Future<void> notifyBudgetExceeded({
    required List<String> names,
    required double spent,
    required double limit,
  }) async {
    final isar = await IsarService().getInstance();
    final n = names.length;
    await _emit(
      isar,
      type: 'budget_exceeded_realtime',
      title: Tone.appL10n?.notif_budgetsOverLimitTitle(n) ?? '🚨 $n budget${n > 1 ? 's' : ''} exceeded!',
      body: n == 1
          ? Tone.appL10n?.notif_budgetExceededBody(names.first) ?? '${names.first} is over budget — time to review'
          : Tone.appL10n?.notif_budgetExceededBodyMulti(names.join(', ')) ?? '${names.join(', ')} are over budget',
      channel: 'budget_alerts',
      channelName: 'Budget Alerts',
      priority: NotificationPriority.urgent,
      primaryAction: 'Review Budgets',
      actionData: jsonEncode({'type': 'view_budget'}),
    );
  }

  /// Notify when budget is near limit (called from BudgetAlertService).
  Future<void> notifyBudgetWarning({
    required List<String> names,
    required double percentage,
  }) async {
    final isar = await IsarService().getInstance();
    final n = names.length;
    await _emit(
      isar,
      type: 'budget_warning_realtime',
      title: Tone.appL10n?.notif_budgetsGettingTightTitle(n) ?? '⚠️ $n budget${n > 1 ? 's' : ''} near limit',
      body: n == 1
          ? Tone.appL10n?.notif_budgetWarningPctBody(names.first, percentage.toStringAsFixed(0)) ?? '${names.first}: ${percentage.toStringAsFixed(0)}% used'
          : Tone.appL10n?.notif_budgetWarningBodyMulti(names.join(', ')) ?? '${names.join(', ')} are nearing their limits',
      channel: 'budget_alerts',
      channelName: 'Budget Alerts',
      priority: NotificationPriority.high,
      primaryAction: 'View Details',
      actionData: jsonEncode({'type': 'view_budget'}),
    );
  }
}
