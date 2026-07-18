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
  int get defaultOrder => 1; // First widget - quick access is priority

  @override
  WidgetCategory get category => WidgetCategory.actions;

  @override
  WidgetSize get defaultSize => WidgetSize.medium; // 2x height for better visibility

  @override
  bool get isResizable => true; // Let user scale to full width if needed

  @override
  String get description => 'Quick access to add expenses, income, and transfers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use small height for narrow screens, medium for wider
        final isWide = constraints.maxWidth >= 400;
        return QuickActionButton(isWide: isWide);
      },
    );
  }
}
