import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/swipeable_account_card.dart';

class AccountsWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'accounts';

  @override
  String get title => 'Account Balances';

  @override
  IconData get icon => LucideIcons.wallet;

  @override
  int get defaultOrder => 1; // Second

  @override
  WidgetCategory get category => WidgetCategory.essential;

  @override
  WidgetSize get defaultSize => WidgetSize.large;

  @override
  String get description =>
      'View all your account balances and total net worth';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AnimatedSwipeableAccountCards();
  }
}
