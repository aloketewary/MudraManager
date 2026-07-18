import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/goal_card.dart';

class GoalsWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'goals_progress';

  @override
  String get title => 'Savings Goals';

  @override
  IconData get icon => LucideIcons.flag;

  @override
  int get defaultOrder => 5; // Sixth

  @override
  WidgetCategory get category => WidgetCategory.finance;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  String get description => 'Track your savings goals and progress';

  @override
  bool get fullModeOnly => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RepaintBoundary(child: GoalCard());
  }
}
