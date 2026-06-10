import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/engine/dashboard_state_provider.dart';
import 'package:mudra_manager/core/logic/attention/attention_item.dart';
import 'package:mudra_manager/core/logic/attention/derive_attention_items.dart';
import 'package:mudra_manager/core/logic/attention/map_attention_to_alerts.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/features/dashboard/data/background_health_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/permission_provider.dart';
import 'package:mudra_manager/features/sms/presentation/screens/sms_activity_screen.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/features/profile/data/help_guide_provider.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

/// Raw domain attention items — reusable by any consumer
/// (dashboard, notifications, widgets, etc.)
final attentionItemsProvider = Provider.autoDispose<List<AttentionItem>>((ref) {
  final state = ref.watch(dashboardStateV2Provider);
  if (state == null) return [];

  final goals = ref.watch(goalsProvider).value ?? [];
  final isBackgroundUnhealthy =
      ref.watch(backgroundTaskUnhealthyProvider).value ?? false;
  final smsPendingCount = ref.watch(pendingCountProvider).value ?? 0;
  final isSmsPermissionGranted =
      ref.watch(smsPermissionGrantedProvider).value ?? false;
  final isSmsImportEnabled = SharedPrefsUtil.instance.getSmsImportEnabled();
  final isSmsBannerDismissed = SharedPrefsUtil.instance.getSmsbannerDismiss();
  final hasSeenHelpGuide = ref.watch(hasSeenHelpGuideProvider);

  return deriveAttentionItems(
    state: state,
    goals: goals,
    isBackgroundUnhealthy: isBackgroundUnhealthy,
    smsPendingCount: smsPendingCount,
    isSmsPermissionGranted: isSmsPermissionGranted,
    isSmsImportEnabled: isSmsImportEnabled,
    isSmsBannerDismissed: isSmsBannerDismissed,
    hasSeenHelpGuide: hasSeenHelpGuide,
  );
});

/// UI-ready alerts derived from attention items.
/// Replaces the old `priorityAlertProvider`.
final dashboardAlertProvider = Provider.autoDispose<List<PriorityAlert>>((ref) {
  final items = ref.watch(attentionItemsProvider);
  return mapAttentionItemsToAlerts(items, l10n: Tone.appL10n);
});
