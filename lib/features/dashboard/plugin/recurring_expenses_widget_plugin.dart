import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/widgets/dashboard_widget_plugin.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/recurring_expenses_card.dart';

class RecurringExpensesWidgetPlugin extends DashboardWidgetPlugin {
  @override
  String get id => 'recurring_expenses';

  @override
  String get title => 'Bill Control Center';

  @override
  IconData get icon => LucideIcons.repeat;

  @override
  int get defaultOrder => 7; // Eighth

  @override
  WidgetCategory get category => WidgetCategory.finance;

  @override
  WidgetSize get defaultSize => WidgetSize.small;

  @override
  String get description => 'Upcoming bills and recurring expenses';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RepaintBoundary(child: RecurringExpensesCard());
  }

  @override
  void onTap(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> refresh(WidgetRef ref) async {
    ref.invalidate(dashboardRecurringExpensesProvider);
  }
}
