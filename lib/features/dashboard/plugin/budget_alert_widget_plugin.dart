import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/shared/widgets/budget_alert_banner.dart';

class BudgetAlertWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'budget_alert';

  @override
  String get title => 'Budget Alert';

  @override
  IconData get icon => LucideIcons.triangleAlert;

  @override
  int get defaultOrder => 0; // Always at top

  @override
  WidgetCategory get category => WidgetCategory.contextual;

  @override
  bool get canBeDisabled => false; // Always show when triggered

  @override
  bool isVisible(WidgetRef ref) {
    // Only show when there are budget alerts
    final alerts = ref.watch(budgetAlertsProvider);
    return alerts.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(budgetAlertsProvider);

    return BudgetAlertBanner(
      alerts: alerts,
      onDismiss: () {
        ref.read(budgetAlertsProvider.notifier).dismissAlert(alerts.first);
      },
    );
  }
}
