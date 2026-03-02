import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/presentation/screens/budget_chart_screen.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/budget_category_mini_card.dart';
import 'package:mudra_manager/features/budget/presentation/widgets/chart_legend.dart';
import 'package:mudra_manager/features/budget/data/overspend_prediction_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class BudgetDetailsScreen extends ConsumerWidget {
  final BudgetWithProgress data;

  const BudgetDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final predictions = ref.watch(overspendPredictionsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final b = data.budget;
    final spent = data.spent;
    final total = b.amount;
    final displaySpent = GuestModeUtil.applyGuestMode(spent, isGuestMode);
    final displayTotal = GuestModeUtil.applyGuestMode(total, isGuestMode);
    final pct = displayTotal > 0 ? (displaySpent / displayTotal) : 0;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('dd MMM yy', ctxt.localeName);

    final statusColor = pct >= 1.0
        ? color.error
        : pct >= 0.8
        ? Colors.orange
        : color.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(b.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/add-budget', extra: {'budget': b});
              } else if (value == 'delete') {
                final confirm = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: ctxt.budget_buttonDeleteTitleText,
                  message: ctxt.budget_buttonDeleteBodyText,
                  cancelText: ctxt.budget_buttonCancelActionText,
                  deleteText: ctxt.budget_buttonDeleteActionText,
                );
                if (confirm == true) {
                  await ref.read(budgetServiceProvider).deleteBudget(b.id);
                  ref.invalidate(budgetsWithProgressProvider);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: color.secondary),
                    const SizedBox(width: 12),
                    const Text('Edit Budget'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: color.error),
                    const SizedBox(width: 12),
                    Text('Delete Budget', style: TextStyle(color: color.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withValues(alpha: 0.1), color.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      pct >= 1.0
                          ? Icons.warning_rounded
                          : Icons.pie_chart_rounded,
                      color: statusColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${formatter.format(data.startDate)} - ${formatter.format(data.endDate)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              ctxt.budget_dashboardMiniCardBudgetTitleText
                                  .toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CurrencyText(
                              amount: displayTotal,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.onSurface,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: color.outlineVariant,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              ctxt.budget_dashboardMiniCardSpentTitleText
                                  .toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CurrencyText(
                              amount: displaySpent,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctxt.formatPercentNumber(pct),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  predictions.when(
                    data: (predList) {
                      final pred = predList.firstWhere(
                        (p) => p.budgetId == b.id,
                      );
                      if (pred != null && pred.willOverspend) {
                        return Card(
                          color: color.errorContainer,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_rounded,
                                        color: color.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pred.warningMessage,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: color.onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daily Avg: ₹${pred.dailyAverage.toStringAsFixed(0)}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onErrorContainer,
                                      ),
                                    ),
                                    Text(
                                      'Projected: ₹${pred.projectedTotal.toStringAsFixed(0)}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: NestedCircularChart(
                              total: displayTotal,
                              spent: displaySpent,
                              spentCategories: {
                                for (var cs in data.categorySpendings)
                                  cs.category.name: GuestModeUtil.applyGuestMode(cs.spent, isGuestMode),
                              },
                              categories: [
                                for (var cs in data.categorySpendings)
                                  cs.category,
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ChartLegend(
                            spentCategories: {
                              for (var cs in data.categorySpendings)
                                cs.category.name: GuestModeUtil.applyGuestMode(cs.spent, isGuestMode),
                            },
                            categories: [
                              for (var cs in data.categorySpendings)
                                cs.category,
                            ],
                            total: displayTotal,
                            spent: displaySpent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    ctxt.budget_categoriesTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: data.categorySpendings.length,
                    itemBuilder: (context, index) {
                      final cat = data.categorySpendings[index];
                      return BudgetCategoryMiniCard(
                        category: cat.category,
                        allocated: GuestModeUtil.applyGuestMode(cat.allocated, isGuestMode),
                        spent: GuestModeUtil.applyGuestMode(cat.spent, isGuestMode),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
