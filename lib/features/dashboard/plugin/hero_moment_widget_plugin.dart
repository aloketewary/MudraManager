import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/hero_moment_card.dart';

class HeroMomentWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'hero_moment';

  @override
  String get title => 'Daily Snapshot';

  @override
  IconData get icon => Icons.auto_awesome;

  @override
  int get defaultOrder => 0;

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  WidgetSize get defaultSize => WidgetSize.small;

  @override
  bool get canBeDisabled => true;

  @override
  String get description => 'Your most important financial insight right now';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HeroMomentCard();
  }
}
