import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logic/attention/attention_item.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';

/// Maps domain [AttentionItem]s to UI-ready [PriorityAlert]s.
///
/// Handles:
/// - Severity assignment
/// - Localized copy
/// - Route mapping
/// - Sorting (urgent > warning > info)
/// - Capping to [maxAlerts]
///
/// This is presentation logic — it knows about routes, l10n, and display severity.
List<PriorityAlert> mapAttentionItemsToAlerts(
  List<AttentionItem> items, {
  AppLocalizations? l10n,
  int maxAlerts = 3,
}) {
  final alerts = <PriorityAlert>[];

  for (final item in items) {
    switch (item) {
      case BillDueTomorrow(:final count):
        alerts.add(PriorityAlert(
          title: l10n?.alert_actionNeeded ?? 'Action Needed',
          message: l10n?.alert_billsDueTomorrow(count) ??
              '$count bill${count > 1 ? 's' : ''} due tomorrow',
          route: AppRoutes.recurringTransactions,
          type: AlertType.urgent,
        ),);

      case BillDueSoon(:final count, :final daysUntil):
        alerts.add(PriorityAlert(
          title: l10n?.alert_upcomingBills ?? 'Upcoming Bills',
          message: l10n?.alert_billsDueInDays(count) ??
              '$count bill${count > 1 ? 's' : ''} due in $daysUntil days',
          route: AppRoutes.recurringTransactions,
          type: AlertType.warning,
        ),);

      case BudgetOverLimit(:final overCount):
        alerts.add(PriorityAlert(
          title: l10n?.alert_budgetAlert ?? 'Budget Alert',
          message: l10n?.alert_budgetsExceeded(overCount) ??
              '$overCount budget${overCount > 1 ? 's' : ''} exceeded',
          route: AppRoutes.budgetDashboard,
          type: AlertType.urgent,
        ),);

      case BudgetNearLimit(:final nearCount):
        alerts.add(PriorityAlert(
          title: l10n?.alert_budgetWarning ?? 'Budget Warning',
          message: l10n?.alert_budgetsNearLimit(nearCount) ??
              '$nearCount budget${nearCount > 1 ? 's' : ''} near limit',
          route: AppRoutes.budgetDashboard,
          type: AlertType.warning,
        ),);

      case GoalNearCompletion(:final count):
        alerts.add(PriorityAlert(
          title: l10n?.alert_goalProgress ?? 'Goal Progress',
          message: l10n?.alert_goalsAlmostComplete(count) ??
              '$count goal${count > 1 ? 's' : ''} almost complete!',
          route: AppRoutes.goalScreen,
          type: AlertType.info,
        ),);
    }
  }

  // Sort by severity: urgent > warning > info
  alerts.sort((a, b) => a.type.index.compareTo(b.type.index));
  return alerts.take(maxAlerts).toList();
}
