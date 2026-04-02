import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/budget_summary_card.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/overspend_warning_widget.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

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
          color: Theme.of(context).colorScheme.surface,
          child: budgetsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return NoDataFound(
                  message: BuddyMessages.noBudgets,
                  iconData: Icons.pie_chart_outline,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const OverspendWarningWidget();
                  }
                  return BudgetSummaryCard(list[index - 1]);
                },
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 80),
              itemCount: 3,
              itemBuilder: (context, index) => const TransactionCardSkeleton(),
            ),
            error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.addBudget);
        },
        icon: const Icon(Icons.add),
        label: Text(ctxt.budget_dashboardAddBudgetText),
      ),
    );
  }
}
