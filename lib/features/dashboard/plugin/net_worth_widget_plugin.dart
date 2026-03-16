import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/net_worth_card.dart';

class NetWorthWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'net_worth';

  @override
  String get title => 'Net Worth';

  @override
  IconData get icon => Icons.account_balance;

  @override
  int get defaultOrder => 4;

  @override
  WidgetCategory get category => WidgetCategory.finance;

  @override
  WidgetSize get defaultSize => WidgetSize.medium;

  @override
  String get description => 'Track your total net worth with historical trends';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NetWorthCard(globalPadding: 0);
  }

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    // Navigation is handled inside NetWorthCard
  }
}
