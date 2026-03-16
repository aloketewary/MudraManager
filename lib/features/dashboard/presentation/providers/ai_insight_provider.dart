import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';

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

final _smsPendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  // Re-fetch when sms activities change
  ref.watch(smsActivityProvider);
  return await SmsActivityService.instance.getPendingCount();
});

final aiInsightProvider = Provider<List<AiInsight>>((ref) {
  final dashboardData = ref.watch(dashboardDataProvider);
  final smsPendingCount = ref.watch(_smsPendingCountProvider).valueOrNull ?? 0;

  return dashboardData.maybeWhen(
    data: (data) => _generateInsights(data, smsPendingCount),
    orElse: () => [],
  );
});

List<AiInsight> _generateInsights(DashboardData data, int smsPendingCount) {
  final candidates = <AiInsight>[];
  final now = DateTime.now();

  // ────────────────────────────────────────────
  // ACTIONABLE — things user must act on NOW
  // ────────────────────────────────────────────

  // Pending SMS — scales with count (user inaction piles up)
  if (smsPendingCount > 0) {
    // 90 base + up to 10 bonus for volume
    final score = 90 + (smsPendingCount.clamp(0, 10));
    candidates.add(
      AiInsight(
        title: 'SMS Transactions Pending',
        message:
            '$smsPendingCount transaction${smsPendingCount > 1 ? 's' : ''} '
            'need${smsPendingCount == 1 ? 's' : ''} your approval',
        type: 'warning',
        iconType: IconType.sms,
        generatedAt: now,
        actionLabel: 'Review',
        actionRoute: '/sms-activity',
        priority: score,
      ),
    );
  }

  // Bills due — urgency by proximity
  if (data.recurringExpenses.isNotEmpty) {
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
      // Due tomorrow = 85, due in 2-3 days = 70
      final score = dueTomorrow > 0 ? 85 : 70;
      candidates.add(
        AiInsight(
          title: dueTomorrow > 0 ? 'Bills Due Tomorrow' : 'Bills Due Soon',
          message: '$dueIn3Days bill${dueIn3Days > 1 ? 's' : ''} due '
              '${dueTomorrow > 0 ? 'by tomorrow' : 'in the next 3 days'}',
          type: dueTomorrow > 0 ? 'warning' : 'info',
          iconType: IconType.info,
          generatedAt: now,
          actionLabel: 'View Bills',
          actionRoute: '/recurring-transactions',
          priority: score,
        ),
      );
    }
  }

  // ────────────────────────────────────────────
  // ALERTS — financial health warnings
  // ────────────────────────────────────────────

  // Budget exceeded
  if (data.budgets.isNotEmpty) {
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
          title: 'Budget Exceeded',
          message: '$count budget${count > 1 ? 's' : ''} exceeded this month',
          type: 'warning',
          iconType: IconType.budget,
          generatedAt: now,
          actionLabel: 'Review Budgets',
          actionRoute: '/budget-dashboard',
          priority: 75,
        ),
      );
    } else if (nearLimit.isNotEmpty) {
      final count = nearLimit.length;
      candidates.add(
        AiInsight(
          title: 'Budget Nearing Limit',
          message: '$count budget${count > 1 ? 's are' : ' is'} past 80%',
          type: 'tip',
          iconType: IconType.budget,
          generatedAt: now,
          actionLabel: 'View Details',
          actionRoute: '/budget-dashboard',
          priority: 50,
        ),
      );
    }
  }

  // Overspending this month
  if (data.totalExpense > data.totalIncome && data.totalIncome > 0) {
    final deficit = data.totalExpense - data.totalIncome;
    final ratio = deficit / data.totalIncome;
    // Scale: 10% over = 60, 50%+ over = 80
    final score = 60 + (ratio.clamp(0, 0.5) * 40).toInt();
    candidates.add(
      AiInsight(
        title: 'Spending Alert',
        message:
            'You\'ve spent ₹${deficit.toStringAsFixed(0)} more than income',
        type: 'warning',
        iconType: IconType.warning,
        generatedAt: now,
        actionLabel: 'View Budget',
        actionRoute: '/budget-dashboard',
        priority: score,
      ),
    );
  }

  // High spending today (spike detection)
  if (data.transactions.isNotEmpty && now.day > 1) {
    final today = DateTime(now.year, now.month, now.day);
    final todayExpenses = data.transactions
        .where(
          (t) =>
              t.isExpense &&
              DateTime(t.date.year, t.date.month, t.date.day) == today,
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (todayExpenses > 0) {
      final avgDaily = data.totalExpense / now.day;
      if (todayExpenses > avgDaily * 2) {
        candidates.add(
          AiInsight(
            title: 'High Spending Today',
            message:
                '₹${todayExpenses.toStringAsFixed(0)} spent today — above your daily average',
            type: 'warning',
            iconType: IconType.spending,
            generatedAt: now,
            priority: 55,
          ),
        );
      }
    }
  }

  // ────────────────────────────────────────────
  // POSITIVE — celebrate wins (lower priority)
  // ────────────────────────────────────────────

  // Good savings
  if (data.totalIncome > data.totalExpense && data.totalIncome > 0) {
    final savings = data.totalIncome - data.totalExpense;
    final rate = (savings / data.totalIncome * 100).toInt();
    // Higher savings rate = slightly higher priority, but still low
    final score = 20 + (rate.clamp(0, 50) ~/ 5);
    candidates.add(
      AiInsight(
        title: rate >= 30 ? 'Excellent Savings!' : 'Great Job!',
        message: 'Saved ₹${savings.toStringAsFixed(0)} ($rate%) this month',
        type: 'success',
        iconType: IconType.success,
        generatedAt: now,
        actionLabel: 'Add to Goal',
        actionRoute: '/goal-screen',
        priority: score,
      ),
    );
  }

  // Goals near completion
  if (data.goals.isNotEmpty) {
    final active = data.goals.where((g) => g.isActive);
    final nearDone = active.where((g) => g.progressPercent >= 0.8).length;
    if (nearDone > 0) {
      candidates.add(
        AiInsight(
          title: 'Almost There!',
          message:
              '$nearDone goal${nearDone > 1 ? 's are' : ' is'} 80%+ complete',
          type: 'success',
          iconType: IconType.goal,
          generatedAt: now,
          actionLabel: 'View Goals',
          actionRoute: '/goal-screen',
          priority: 30,
        ),
      );
    }
  }

  // ────────────────────────────────────────────
  // ONBOARDING — only when nothing else matters
  // ────────────────────────────────────────────

  if (data.transactions.isEmpty) {
    candidates.add(
      AiInsight(
        title: 'Get Started',
        message: 'Add your first transaction to start tracking',
        type: 'info',
        iconType: IconType.info,
        generatedAt: now,
        actionLabel: 'Add Transaction',
        actionRoute: '/add-transaction',
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
