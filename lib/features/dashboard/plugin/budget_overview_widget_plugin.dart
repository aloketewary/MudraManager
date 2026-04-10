import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/budget_overview_card.dart';

class BudgetOverviewWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'budget_overview';

  @override
  String get title => 'Budget Overview';

  @override
  IconData get icon => LucideIcons.chartPie;

  @override
  int get defaultOrder => 3;

  @override
  WidgetCategory get category => WidgetCategory.finance;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  String get description => 'Quick glance at budget health and spending status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RepaintBoundary(child: BudgetOverviewCard());
  }

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    context.push(AppRoutes.budgetDashboard);
  }

  @override
  Future<void> refresh(WidgetRef ref) async {
    ref.invalidate(budgetsWithProgressProvider);
  }
}
