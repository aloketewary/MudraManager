import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/modern_cashflow_card.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class CashFlowWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'cash_flow';

  @override
  String get title => 'Cash Flow';

  @override
  IconData get icon => LucideIcons.wallet;

  @override
  int get defaultOrder => 3;

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  bool get isResizable => true;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  String get description =>
      'Track your income and expenses for the current month';

  @override
  bool isVisible(WidgetRef ref) {
    // Always visible
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RepaintBoundary(
      child: ModernCashFlowCard(),
    );
  }

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    context.push(AppRoutes.transactions);
  }

  @override
  Future<void> refresh(WidgetRef ref) async {
    ref.invalidate(dashboardDataProvider);
  }
}
