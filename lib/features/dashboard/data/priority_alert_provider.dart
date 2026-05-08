import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/date_change_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

class PriorityAlert {
  final String title;
  final String message;
  final String route;
  final AlertType type;

  PriorityAlert({
    required this.title,
    required this.message,
    required this.route,
    required this.type,
  });
}

enum AlertType {
  urgent, // Red/Orange - immediate action needed
  warning, // Yellow - attention needed
  info, // Blue - informational
}

/// Returns up to 3 priority alerts, ordered by severity (urgent first).
final priorityAlertProvider =
    FutureProvider.autoDispose<List<PriorityAlert>>((ref) async {
  ref.watch(transactionChangeProvider);
  ref.watch(dateChangeProvider);
  final isar = ref.watch(isarServiceProvider);
  final db = await isar.getInstance();
  final alerts = <PriorityAlert>[];

  // ── Bills due in next 2 days ──
  final now = DateTime.now();
  final twoDaysLater = now.add(const Duration(days: 2));

  final upcomingBills = await db.recurringTransactions
      .where()
      .filter()
      .isActiveEqualTo(true)
      .and()
      .nextDueDateBetween(now, twoDaysLater)
      .findAll();

  if (upcomingBills.isNotEmpty) {
    final tomorrow = now.add(const Duration(days: 1));
    final billsDueTomorrow = upcomingBills
        .where(
          (b) =>
              b.nextDueDate.year == tomorrow.year &&
              b.nextDueDate.month == tomorrow.month &&
              b.nextDueDate.day == tomorrow.day,
        )
        .length;

    if (billsDueTomorrow > 0) {
      alerts.add(PriorityAlert(
        title: Tone.appL10n?.alert_actionNeeded ?? 'Action Needed',
        message: Tone.appL10n?.alert_billsDueTomorrow(billsDueTomorrow) ??
            '$billsDueTomorrow bill${billsDueTomorrow > 1 ? 's' : ''} due tomorrow',
        route: AppRoutes.recurringTransactions,
        type: AlertType.urgent,
      ),);
    } else {
      alerts.add(PriorityAlert(
        title: Tone.appL10n?.alert_upcomingBills ?? 'Upcoming Bills',
        message: Tone.appL10n?.alert_billsDueInDays(upcomingBills.length) ??
            '${upcomingBills.length} bill${upcomingBills.length > 1 ? 's' : ''} due in 2 days',
        route: AppRoutes.recurringTransactions,
        type: AlertType.warning,
      ),);
    }
  }

  // ── Budget overruns ──
  final budgetsAsync = await ref.watch(budgetsWithProgressProvider.future);
  final overBudget =
      budgetsAsync.where((b) => b.spent > b.budget.amount).toList();

  if (overBudget.isNotEmpty) {
    alerts.add(PriorityAlert(
      title: Tone.appL10n?.alert_budgetAlert ?? 'Budget Alert',
      message: Tone.appL10n?.alert_budgetsExceeded(overBudget.length) ??
          '${overBudget.length} budget${overBudget.length > 1 ? 's' : ''} exceeded',
      route: AppRoutes.budgetDashboard,
      type: AlertType.urgent,
    ),);
  }

  // ── Budgets near limit (>90%) ──
  final nearLimit = budgetsAsync.where((b) {
    final percent = (b.spent / b.budget.amount * 100);
    return percent >= 90 && percent < 100;
  }).toList();

  if (nearLimit.isNotEmpty) {
    alerts.add(PriorityAlert(
      title: Tone.appL10n?.alert_budgetWarning ?? 'Budget Warning',
      message: Tone.appL10n?.alert_budgetsNearLimit(nearLimit.length) ??
          '${nearLimit.length} budget${nearLimit.length > 1 ? 's' : ''} near limit',
      route: AppRoutes.budgetDashboard,
      type: AlertType.warning,
    ),);
  }

  // ── Goals near completion (>80%) ──
  final goalsAsync = await ref.watch(goalsProvider.future);
  final nearCompletion = goalsAsync
      .where(
        (g) => g.isActive && g.progressPercent >= 80 && g.progressPercent < 100,
      )
      .toList();

  if (nearCompletion.isNotEmpty) {
    alerts.add(PriorityAlert(
      title: Tone.appL10n?.alert_goalProgress ?? 'Goal Progress',
      message: Tone.appL10n?.alert_goalsAlmostComplete(nearCompletion.length) ??
          '${nearCompletion.length} goal${nearCompletion.length > 1 ? 's' : ''} almost complete!',
      route: AppRoutes.goalScreen,
      type: AlertType.info,
    ),);
  }

  // Sort by severity: urgent > warning > info, cap at 3
  alerts.sort((a, b) => a.type.index.compareTo(b.type.index));
  return alerts.take(3).toList();
});
