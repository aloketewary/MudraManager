import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/dashboard/data/spending_drift_detector.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/daily_briefing_card.dart';

class AiInsight {
  final String title;
  final String message;
  final String type; // 'warning', 'tip', 'success', 'info'
  final IconType iconType;
  final DateTime generatedAt;
  final String? actionLabel;
  final String? actionRoute;
  final int priority; // higher = more urgent

  const AiInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.iconType,
    required this.generatedAt,
    this.actionLabel,
    this.actionRoute,
    this.priority = 0,
  });
}

enum IconType {
  warning,
  tip,
  success,
  info,
  budget,
  goal,
  savings,
  spending,
  sms,
}

final aiInsightProvider = Provider<List<AiInsight>>((ref) {
  final dashboardData = ref.watch(dashboardDataProvider);
  final briefing = ref.watch(dailyBriefingProvider);

  return dashboardData.maybeWhen(
    data: (data) => _generateInsights(data, briefing),
    orElse: () => [],
  );
});

List<AiInsight> _generateInsights(DashboardData data, Briefing? briefing) {
  final candidates = <AiInsight>[];
  final now = DateTime.now();

  // Determine which signal categories the Briefing already covers
  // Philosophy principle #3: "Signals must compete, not coexist."
  final briefingCovers = <String>{};
  if (briefing != null) {
    switch (briefing.signalType) {
      case BriefingSignalType.billDueToday:
      case BriefingSignalType.billDueSoon:
        briefingCovers.add('bills');
      case BriefingSignalType.budgetExceeded:
        briefingCovers.add('budget');
      case BriefingSignalType.spendingDrift:
        briefingCovers.add('drift');
      case BriefingSignalType.overspending:
        briefingCovers.add('overspending');
      case BriefingSignalType.improvement:
        briefingCovers.add('improvement');
    }
  }

  // ────────────────────────────────────────────
  // ACTIONABLE — things user must act on NOW
  // ────────────────────────────────────────────

  // (SMS pending is handled by _AutoImportBanner on dashboard — no duplicate insight needed)

  // Bills due — urgency by proximity
  if (data.recurringExpenses.isNotEmpty && !briefingCovers.contains('bills')) {
    final dueTomorrow = data.recurringExpenses
        .where(
          (r) =>
              r.nextDueDate.difference(now).inDays == 0 ||
              r.nextDueDate.difference(now).inDays == 1,
        )
        .length;
    final dueIn3Days = data.recurringExpenses.where((r) {
      final d = r.nextDueDate.difference(now).inDays;
      return d >= 0 && d <= 3;
    }).length;

    if (dueIn3Days > 0) {
      final score = dueTomorrow > 0 ? 85 : 70;
      candidates.add(
        dueTomorrow > 0
            ? AiInsight(
                title: BuddyMessages.insightBillsDueSoon,
                message: BuddyMessages.insightBillsDueMessage(dueIn3Days),
                type: 'warning',
                iconType: IconType.info,
                generatedAt: now,
                actionLabel: 'View Bills',
                actionRoute: AppRoutes.recurringTransactions,
                priority: score,
              )
            : AiInsight(
                title: BuddyMessages.insightBillsDueSoon,
                message: BuddyMessages.insightBillsDueMessage(dueIn3Days),
                type: 'info',
                iconType: IconType.info,
                generatedAt: now,
                actionLabel: 'View Bills',
                actionRoute: AppRoutes.recurringTransactions,
                priority: score,
              ),
      );
    }
  }

  // ────────────────────────────────────────────
  // ALERTS — financial health warnings
  // ────────────────────────────────────────────

  // Budget exceeded
  if (data.budgets.isNotEmpty && !briefingCovers.contains('budget')) {
    final overBudget = data.budgets.where((b) => b.spent > b.budget.amount);
    final nearLimit = data.budgets.where((b) {
      final pct = b.spent / b.budget.amount;
      return pct >= 0.8 && pct < 1.0;
    });

    if (overBudget.isNotEmpty) {
      final count = overBudget.length;
      // Exceeded is more urgent than near-limit
      candidates.add(
        AiInsight(
          title: BuddyMessages.insightOverBudget,
          message: BuddyMessages.insightOverBudgetMessage(count),
          type: 'warning',
          iconType: IconType.budget,
          generatedAt: now,
          actionLabel: 'Review Budgets',
          actionRoute: AppRoutes.budgetDashboard,
          priority: 75,
        ),
      );
    } else if (nearLimit.isNotEmpty) {
      final count = nearLimit.length;
      candidates.add(
        AiInsight(
          title: BuddyMessages.insightNearBudget,
          message: BuddyMessages.insightNearBudgetMessage(count),
          type: 'tip',
          iconType: IconType.budget,
          generatedAt: now,
          actionLabel: 'View Details',
          actionRoute: AppRoutes.budgetDashboard,
          priority: 50,
        ),
      );
    }
  }

  // Overspending this month
  if (data.totalExpense > data.totalIncome &&
      data.totalIncome > 0 &&
      !briefingCovers.contains('overspending')) {
    final deficit = data.totalExpense - data.totalIncome;
    final ratio = deficit / data.totalIncome;
    // Scale: 10% over = 60, 50%+ over = 80
    final score = 60 + (ratio.clamp(0, 0.5) * 40).toInt();
    candidates.add(
      AiInsight(
        title: BuddyMessages.insightOverspending,
        message: BuddyMessages.insightOverspendingMessage(
            deficit.toStringAsFixed(0),),
        type: 'warning',
        iconType: IconType.warning,
        generatedAt: now,
        actionLabel: 'View Budget',
        actionRoute: AppRoutes.budgetDashboard,
        priority: score,
      ),
    );
  }

  // High spending today — compare to personal baseline
  if (data.transactions.isNotEmpty && now.day > 1) {
    final today = DateTime(now.year, now.month, now.day);
    final todayExpenses = data.transactions
        .where(
          (t) =>
              t.isExpense &&
              !t.isTransfer &&
              DateTime(t.date.year, t.date.month, t.date.day) == today,
        )
        .fold<double>(0, (sum, t) => sum + t.baseAmount);

    if (todayExpenses > 0) {
      final avgDaily = data.totalExpense / now.day;
      if (todayExpenses > avgDaily * 1.5) {
        candidates.add(
          AiInsight(
            title: BuddyMessages.insightSpendingSpike,
            message: BuddyMessages.insightSpendingSpikeMessage(
              avgDaily.toStringAsFixed(0),
              todayExpenses.toStringAsFixed(0),
            ),
            type: 'warning',
            iconType: IconType.spending,
            generatedAt: now,
            priority: 55,
          ),
        );
      }
    }
  }

  // ── Weekend vs usual weekend ──
  if (data.transactions.isNotEmpty &&
      (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday)) {
    final todayDate = DateTime(now.year, now.month, now.day);

    // This weekend's spend (Sat + Sun so far)
    final weekendStart = now.weekday == DateTime.sunday
        ? todayDate.subtract(const Duration(days: 1))
        : todayDate;
    final weekendSpend = data.transactions
        .where(
          (t) =>
              t.isExpense &&
              !t.isTransfer &&
              !t.date.isBefore(weekendStart) &&
              !t.date.isAfter(now),
        )
        .fold<double>(0, (s, t) => s + t.baseAmount);

    if (weekendSpend <= 0) {
      // skip — nothing spent yet
    } else {
      // Average weekend spend (last 8 weekends = ~60 days)
      final sixtyDaysAgo = todayDate.subtract(const Duration(days: 60));
      final pastWeekendTxns = data.transactions.where(
        (t) =>
            t.isExpense &&
            !t.isTransfer &&
            t.date.isAfter(sixtyDaysAgo) &&
            t.date.isBefore(weekendStart) &&
            (t.date.weekday == DateTime.saturday ||
                t.date.weekday == DateTime.sunday),
      );
      final pastWeekendTotal =
          pastWeekendTxns.fold<double>(0, (s, t) => s + t.baseAmount);

      // Count past weekends
      int weekendCount = 0;
      var d = sixtyDaysAgo;
      while (d.isBefore(weekendStart)) {
        if (d.weekday == DateTime.saturday) weekendCount++;
        d = d.add(const Duration(days: 1));
      }

      if (weekendCount >= 2) {
        final avgWeekend = pastWeekendTotal / weekendCount;
        if (avgWeekend > 0 && weekendSpend > avgWeekend * 1.3) {
          candidates.add(
            AiInsight(
              title: BuddyMessages.insightWeekendAlert,
              message: BuddyMessages.insightWeekendAlertMessage(
                avgWeekend.toStringAsFixed(0),
                weekendSpend.toStringAsFixed(0),
              ),
              type: 'warning',
              iconType: IconType.spending,
              generatedAt: now,
              priority: 60,
            ),
          );
        }
      }
    }
  }

// ── Money Leak Detection ──
  if (data.transactions.isNotEmpty && now.day >= 14) {
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthExpenses = data.transactions
        .where(
          (t) =>
              t.isExpense &&
              !t.isTransfer &&
              t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))),
        )
        .toList();

    // Group by category: count + total
    final catStats = <String, ({int count, double total})>{};
    for (final t in monthExpenses) {
      final name = t.category.value?.name ?? 'Other';
      final prev = catStats[name] ?? (count: 0, total: 0.0);
      catStats[name] = (count: prev.count + 1, total: prev.total + t.amount);
    }

    // "Leak" = high frequency (5+/month), low avg amount (< 15% of daily avg)
    final dailyAvg = data.totalExpense / now.day;
    final leaks = catStats.entries.where((e) {
      final avgTxn = e.value.total / e.value.count;
      return e.value.count >= 5 && avgTxn < dailyAvg * 0.15;
    }).toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    if (leaks.isNotEmpty) {
      final top = leaks.first;
      candidates.add(
        AiInsight(
          title: Tone.appL10n?.insight_moneyLeakTitle ?? 'Frequent small spends',
          message: BuddyMessages.insightMoneyLeak(
            top.key,
            top.value.count,
            top.value.total.toStringAsFixed(0),
          ),
          type: 'tip',
          iconType: IconType.spending,
          generatedAt: now,
          actionLabel: 'View Stats',
          actionRoute: AppRoutes.statistics,
          priority: 45,
        ),
      );
    }
  }

  // ── Best Day to Save ──
  if (data.transactions.isNotEmpty && now.day >= 14) {
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final recentExpenses = data.transactions.where(
      (t) => t.isExpense && !t.isTransfer && t.date.isAfter(ninetyDaysAgo),
    );

    if (recentExpenses.length >= 20) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final byDay = List.filled(7, 0.0);
      final countByDay = List.filled(7, 0);

      for (final t in recentExpenses) {
        final idx = t.date.weekday - 1;
        byDay[idx] += t.baseAmount;
        countByDay[idx]++;
      }

      // Find lowest-spend day (by average)
      int bestIdx = 0;
      double bestAvg = double.infinity;
      for (int i = 0; i < 7; i++) {
        if (countByDay[i] == 0) continue;
        final avg = byDay[i] / countByDay[i];
        if (avg < bestAvg) {
          bestAvg = avg;
          bestIdx = i;
        }
      }

      // Find highest-spend day for contrast
      int worstIdx = 0;
      double worstAvg = 0;
      for (int i = 0; i < 7; i++) {
        if (countByDay[i] == 0) continue;
        final avg = byDay[i] / countByDay[i];
        if (avg > worstAvg) {
          worstAvg = avg;
          worstIdx = i;
        }
      }

      // Replace the existing "Best Day to Save" block:
      if (worstAvg > bestAvg * 1.3) {
        final potentialSaving = (worstAvg - bestAvg);
        candidates.add(
          AiInsight(
            title: Tone.appL10n?.insight_bestDayTitle(days[worstIdx]) ??
                '${days[worstIdx]}s: avg ₹${worstAvg.toStringAsFixed(0)}',
            message: BuddyMessages.insightBestDay(
              days[worstIdx],
              worstAvg.toStringAsFixed(0),
              days[bestIdx],
              bestAvg.toStringAsFixed(0),
              potentialSaving.toStringAsFixed(0),
            ),
            type: 'tip',
            iconType: IconType.savings,
            generatedAt: now,
            actionLabel: 'View Pattern',
            actionRoute: AppRoutes.statistics,
            priority: 30,
          ),
        );
      }
    }
  }

  // ────────────────────────────────────────────
  // SPENDING DRIFT — category trend detection
  // ────────────────────────────────────────────

  candidates.addAll(detectSpendingDrift(data.transactions));

  // ────────────────────────────────────────────
  // ONBOARDING — only when nothing else matters
  // ────────────────────────────────────────────

  if (data.transactions.isEmpty) {
    candidates.add(
      AiInsight(
        title: BuddyMessages.insightGetStarted,
        message: BuddyMessages.insightGetStartedMessage,
        type: 'info',
        iconType: IconType.info,
        generatedAt: now,
        actionLabel: 'Add Transaction',
        actionRoute: AppRoutes.addTransaction,
        priority: 10,
      ),
    );
  }

  // ────────────────────────────────────────────
  // SMART SELECTION — pick best 3 with diversity
  // ────────────────────────────────────────────

  return _selectTopInsights(candidates, maxCount: 3);
}

/// Picks top insights ensuring type diversity.
/// Guarantees at most 2 of the same type so the card
/// doesn't feel like a wall of red warnings.
// _selectTopInsights — remove the recursive call, return selected:
List<AiInsight> _selectTopInsights(
  List<AiInsight> candidates, {
  int maxCount = 3,
}) {
  if (candidates.length <= maxCount) return candidates..sort(_byPriority);

  candidates.sort(_byPriority);

  final selected = <AiInsight>[];
  final typeCounts = <String, int>{};

  for (final insight in candidates) {
    if (selected.length >= maxCount) break;
    final count = typeCounts[insight.type] ?? 0;
    if (count < 2) {
      selected.add(insight);
      typeCounts[insight.type] = count + 1;
    }
  }

  if (selected.length < maxCount) {
    for (final insight in candidates) {
      if (selected.length >= maxCount) break;
      if (!selected.contains(insight)) {
        selected.add(insight);
      }
    }
  }

  return selected;
}

int _byPriority(AiInsight a, AiInsight b) => b.priority.compareTo(a.priority);
