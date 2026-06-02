import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/daily_briefing_card.dart';

class DailyBriefingWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'daily_briefing';

  @override
  String get title => 'Daily Briefing';

  @override
  IconData get icon => LucideIcons.newspaper;

  @override
  int get defaultOrder => -1; // Always first

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  bool get canBeDisabled => true;

  @override
  String get description => 'Your daily financial briefing — what changed, what needs attention, what to do';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DailyBriefingCard();
  }

  @override
  Future<void> refresh(WidgetRef ref) async {
    ref.invalidate(dashboardDataProvider);
  }
}
