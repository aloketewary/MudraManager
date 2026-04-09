import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class RecentTransactionsWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'recent_transactions';

  @override
  String get title => 'Recent Transactions';

  @override
  IconData get icon => LucideIcons.receipt;

  @override
  int get defaultOrder => 6;

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  bool get isResizable => true;

  @override
  WidgetSize get defaultSize => WidgetSize.large;

  @override
  String get description => 'View your latest transactions at a glance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RepaintBoundary(
      child: RecentTransactionsCard(),
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
