import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/screens/budget/add_budget_screen.dart';
import 'package:mudra_manager/screens/budget/budget_summary_card.dart'
    show BudgetSummaryCard;
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;

class BudgetDashboard extends ConsumerStatefulWidget {
  const BudgetDashboard({super.key});

  @override
  ConsumerState<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends ConsumerState<BudgetDashboard> {
  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ctxt.budget_dashboardPageTitle,
          style: textTheme.titleLarge,
        ),
      ),
      body: Hero(
        tag: 'budgetExpandHero',
        child: Material(
          child: budgetsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return NoDataFound(
                  message: ctxt.budget_dashboardNotFoundText,
                  iconData: Icons.pie_chart_outline,
                );
              }
              return ListView(
                children: list.map((data) => BudgetSummaryCard(data)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-budget');
            },
        icon: const Icon(Icons.add),
        label: Text(ctxt.budget_dashboardAddBudgetText),
      ),
    );
  }
}
