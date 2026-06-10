import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/logic/attention/dashboard_alert_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';

/// Single highest-priority attention item for the dashboard, mapped to ScreenAlert.
final dashboardAttentionProvider = Provider.autoDispose<ScreenAlert?>((ref) {
  final alerts = ref.watch(dashboardAlertProvider);
  if (alerts.isEmpty) return null;

  // dashboardAlertProvider is already sorted by severity: urgent > warning > info
  final top = alerts.first;

  return ScreenAlert(
    title: top.title,
    message: top.message,
    level: switch (top.type.name) {
      'urgent' => ScreenAlertLevel.urgent,
      'warning' => ScreenAlertLevel.warning,
      _ => ScreenAlertLevel.info,
    },
    actionRoute: top.route,
  );
});
