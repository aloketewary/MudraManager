import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/health_strip.dart';

class HealthStripWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'health_strip';

  @override
  String get title => 'Health Strip';

  @override
  IconData get icon => LucideIcons.activity;

  @override
  int get defaultOrder => 0; // First widget

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  WidgetSize get defaultSize => WidgetSize.small;

  @override
  bool get canBeDisabled => true;

  @override
  String get description =>
      'Quick orientation — shows which financial domains need attention';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HealthStrip();
  }
}
