import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/statistics/data/financial_attention_layer.dart' as stats_attention;

/// Convert BudgetAlert to AttentionItem for unified attention banner display
class AttentionMapper {
  static List<stats_attention.AttentionItem> mapBudgetAlerts(List<BudgetAlert> alerts) {
    return alerts.map((alert) {
      final isOverLimit = alert.threshold == 100;
      return stats_attention.AttentionItem(
        id: 'budget_${alert.budget.id}',
        type: isOverLimit ? stats_attention.AttentionType.critical : stats_attention.AttentionType.warning,
        title: alert.percentage >= 100
            ? '${alert.budget.name} exceeded budget'
            : '${alert.budget.name} nearly reached limit',
        message: isOverLimit
            ? 'Spent ${alert.percentage.toInt()}% of ${alert.budget.amount.toStringAsFixed(0)} budget'
            : '${alert.percentage.toInt()}% of ${alert.budget.amount.toStringAsFixed(0)} budget used',
        priority: alert.percentage / 100 * (isOverLimit ? 2.0 : 1.5),
        actionLabel: 'Review Budget',
        actionRoute: '/budgets/${alert.budget.id}',
      );
    }).toList();
  }

  static List<stats_attention.AttentionItem> mapSmsPendingAlerts(int pendingCount) {
    if (pendingCount <= 0) return [];
    return [
      stats_attention.AttentionItem(
        id: 'sms_pending_$pendingCount',
        type: stats_attention.AttentionType.info,
        title: '$pendingCount pending review',
        message: 'SMS transactions ready for review',
        priority: 1.0,
        actionLabel: 'Review',
        actionRoute: '/sms-activity',
      ),
    ];
  }
}
