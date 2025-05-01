import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budgets Details',
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: budgetsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return NoDataFound(
              message: "No Budgets Defined, Add one!",
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBudgetScreen(),
                ),
              ),
            },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }
}
