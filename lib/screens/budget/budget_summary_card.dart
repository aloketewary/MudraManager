import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/budget_service_provider.dart'
    show BudgetWithProgress, budgetServiceProvider, budgetsWithProgressProvider;
import 'package:mudra_manager/screens/budget/add_budget_screen.dart'
    show AddBudgetScreen;
import 'package:mudra_manager/screens/budget/budget_category_mini_card.dart'
    show BudgetCategoryMiniCard;
import 'package:mudra_manager/screens/budget/budget_chart_screen.dart'
    show NestedCircularChart;
import 'package:mudra_manager/screens/budget/chart_legend.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/localization_extension.dart';

import 'package:mudra_manager/components/currency_text.dart';

class BudgetSummaryCard extends ConsumerStatefulWidget {
  final BudgetWithProgress data;

  const BudgetSummaryCard(this.data, {super.key});

  @override
  BudgetSummaryCardState createState() => BudgetSummaryCardState();
}

class BudgetSummaryCardState extends ConsumerState<BudgetSummaryCard> {
  bool _expanded = false;
  double allBoxWidthFactor = 0.4;

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final b = widget.data.budget;
    final spent = widget.data.spent;
    final total = b.amount;
    final pct = total > 0 ? (spent / total) : 0;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('dd MMM yy', ctxt.localeName);

    // Status color logic
    final statusColor =
        pct >= 1.0
            ? color.error
            : pct >= 0.8
            ? Colors.orange
            : color.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pct >= 1.0 ? Icons.warning_rounded : Icons.pie_chart_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${formatter.format(widget.data.startDate)} - ${formatter.format(widget.data.endDate)}",
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: color.onSurfaceVariant),
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
                        await ref
                            .read(budgetServiceProvider)
                            .deleteBudget(b.id);
                        ref.invalidate(budgetsWithProgressProvider);
                      }
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 20,
                                color: color.secondary,
                              ),
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
                              Text(
                                'Delete Budget',
                                style: TextStyle(color: color.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content Section
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _expanded = !_expanded);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: NestedCircularChart(
                          total: total,
                          spent: spent,
                          spentCategories: {
                            for (var cs in widget.data.categorySpendings)
                              cs.category.name: cs.spent,
                          },
                          categories: [
                            for (var cs in widget.data.categorySpendings)
                              cs.category,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctxt.budget_dashboardMiniCardBudgetTitleText
                                  .toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            CurrencyText(
                              amount: b.amount,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.onSurface,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ctxt.budget_dashboardMiniCardSpentTitleText
                                  .toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: CurrencyText(
                                    amount: spent,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                Text(
                                  "  (${ctxt.formatPercentNumber(pct)})",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const SizedBox(height: 24),
                        ChartLegend(
                          spentCategories: {
                            for (var cs in widget.data.categorySpendings)
                              cs.category.name: cs.spent,
                          },
                          categories: [
                            for (var cs in widget.data.categorySpendings)
                              cs.category,
                          ],
                          total: total,
                          spent: spent,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ctxt.budget_categoriesTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.data.categorySpendings.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              var cat = widget.data.categorySpendings[index];
                              return BudgetCategoryMiniCard(
                                category: cat.category,
                                allocated: cat.allocated,
                                spent: cat.spent,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    crossFadeState:
                        _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),

                  const SizedBox(height: 16),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
