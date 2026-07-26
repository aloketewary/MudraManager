import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/engine/dashboard_state_provider.dart';
import 'package:mudra_manager/features/insights/data/derive_attention_items.dart';
import 'package:mudra_manager/features/insights/data/map_attention_to_alerts.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/features/dashboard/data/priority_alert_provider.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';
import 'package:mudra_manager/features/insights/domain/attention_item.dart';

/// Raw domain attention items — reusable by any consumer
/// (dashboard, notifications, widgets, etc.)
final attentionItemsProvider = Provider.autoDispose<List<AttentionItem>>((ref) {
  final state = ref.watch(dashboardStateV2Provider);
  if (state == null) return [];

  final goals = ref.watch(goalsProvider).value ?? [];

  return deriveAttentionItems(state: state, goals: goals);
});

/// UI-ready alerts derived from attention items.
/// Replaces the old `priorityAlertProvider`.
final dashboardAlertProvider = Provider.autoDispose<List<PriorityAlert>>((ref) {
  final items = ref.watch(attentionItemsProvider);
  return mapAttentionItemsToAlerts(items, l10n: Tone.appL10n);
});
