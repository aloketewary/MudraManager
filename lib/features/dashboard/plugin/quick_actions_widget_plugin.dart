import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/dashboard_action_button.dart';

class QuickActionsWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'quick_actions';

  @override
  String get title => 'Quick Actions';

  @override
  IconData get icon => LucideIcons.pointer;

  @override
  int get defaultOrder => 2;

  @override
  WidgetCategory get category => WidgetCategory.actions;

  @override
  WidgetSize get defaultSize => WidgetSize.small;

  @override
  String get description => 'Quick access to add expenses and transfers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const QuickActionButton();
  }
}
