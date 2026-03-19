import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/services/card_interaction_tracker.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_registry.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';

/// Computes a smart relevance score for each widget.
/// Higher score = should appear higher on dashboard.
final smartWidgetScoresProvider = Provider<Map<String, double>>((ref) {
  final data = ref.watch(dashboardDataProvider).valueOrNull;
  if (data == null) return {};

  final tapCounts = CardInteractionTracker.getAllTapCounts();
  final now = DateTime.now();
  final scores = <String, double>{};

  for (final widget in DashboardWidgetRegistry.widgets) {
    double score = 0;

    // ── 1. USAGE SIGNAL (40% weight) ──
    // More taps = user cares about this card
    final taps = tapCounts[widget.id] ?? 0;
    // Normalize: 10+ taps/month = max score
    score += (taps / 10).clamp(0, 1) * 40;

    // ── 2. URGENCY SIGNAL (40% weight) ──
    // Does this card have something the user needs to see RIGHT NOW?
    score += _urgencyScore(widget.id, data, now) * 40;

    // ── 3. FRESHNESS SIGNAL (20% weight) ──
    // Does this card have new/changed data since last view?
    score += _freshnessScore(widget.id, data, now) * 20;

    scores[widget.id] = score;
  }

  return scores;
});

/// 0.0 to 1.0 — how urgent is this card right now?
double _urgencyScore(String widgetId, DashboardData data, DateTime now) {
  switch (widgetId) {
    case 'ai_insight':
      // Always high if insights exist (they're pre-filtered for relevance)
      return 1.0;

    case 'budget_overview':
      if (data.budgets.isEmpty) return 0;
      final worstBudget = data.budgets
          .map((b) => b.budget.amount > 0 ? b.spent / b.budget.amount : 0.0)
          .reduce((a, b) => a > b ? a : b);
      // Over 80% = urgent, over 100% = critical
      if (worstBudget >= 1.0) return 1.0;
      if (worstBudget >= 0.8) return 0.7;
      return 0.2;

    case 'recurring_expenses':
      // Bills due in next 3 days = urgent
      final dueSoon = data.recurringExpenses
          .where((r) => r.nextDueDate.difference(now).inDays <= 3)
          .length;
      if (dueSoon > 0) return 0.9;
      return 0.1;

    case 'goals_progress':
      if (data.goals.isEmpty) return 0;
      // Goals near completion = motivating, boost them
      final nearDone = data.goals
          .where((g) => g.isActive && g.progressPercent >= 0.8)
          .length;
      if (nearDone > 0) return 0.7;
      return 0.2;

    case 'accounts':
      // Always somewhat important
      return 0.5;

    case 'cash_flow':
      // More urgent if spending > income
      if (data.totalIncome > 0 && data.totalExpense > data.totalIncome) {
        return 0.8;
      }
      return 0.3;

    case 'recent_transactions':
      // Check if there are transactions today
      final today = DateTime(now.year, now.month, now.day);
      final todayCount = data.transactions
          .where(
            (t) => DateTime(t.date.year, t.date.month, t.date.day) == today,
          )
          .length;
      if (todayCount > 0) return 0.4;
      return 0.1;

    default:
      return 0.2;
  }
}

/// 0.0 to 1.0 — does this card have fresh data?
double _freshnessScore(String widgetId, DashboardData data, DateTime now) {
  switch (widgetId) {
    case 'recent_transactions':
      if (data.transactions.isEmpty) return 0;
      final latest = data.transactions
          .map((t) => t.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final hoursAgo = now.difference(latest).inHours;
      if (hoursAgo < 1) return 1.0;
      if (hoursAgo < 6) return 0.7;
      if (hoursAgo < 24) return 0.4;
      return 0.1;

    case 'accounts':
      // Accounts always have "fresh" balance data
      return 0.5;

    case 'budget_overview':
      // Mid-month budgets are more relevant than start-of-month
      final dayProgress = now.day / 30;
      return dayProgress.clamp(0.2, 1.0);

    default:
      return 0.3;
  }
}
