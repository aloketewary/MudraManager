import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart'
    show BudgetWithProgress, budgetServiceProvider, budgetsWithProgressProvider;
import 'package:mudra_manager/screens/budget/add_budget_screen.dart'
    show AddBudgetScreen;
import 'package:mudra_manager/screens/budget/budget_category_mini_card.dart'
    show BudgetCategoryMiniCard;
import 'package:mudra_manager/screens/budget/budget_chart_screen.dart'
    show NestedCircularChart;

class BudgetSummaryCard extends ConsumerStatefulWidget {
  final BudgetWithProgress data;

  const BudgetSummaryCard(this.data, {super.key});

  @override
  _BudgetSummaryCardState createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends ConsumerState<BudgetSummaryCard> {
  bool _expanded = false;
  double allBoxWidthFactor = 0.4;

  @override
  Widget build(BuildContext context) {
    final b = widget.data.budget;
    final spent = widget.data.spent;
    final total = b.amount;
    final pct = total > 0 ? (spent / total) : 0;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('dd MMM yy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: _expanded ? 480 : 280,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              // Light background color
              border: Border.all(
                color: pct == 1.0 ? color.error : color.primary,
              ), // Subtle border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16,
                      child: Icon(
                        pct == 1.0
                            ? Icons.warning_amber
                            : Icons.bubble_chart_outlined,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        b.name.toUpperCase(),
                        // textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton.filled(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddBudgetScreen(
                                  existing: widget.data.budget,
                                ),
                          ),
                        );
                      },
                    ),
                    IconButton.filled(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: Text(
                                  'Delete Budget?',
                                  style: textTheme.titleLarge,
                                ),
                                content: Text(
                                  'This will remove the budget and its allocations.',
                                  style: textTheme.bodyLarge,
                                ),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      'Cancel'.toUpperCase(),
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.primary,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: color.primary,
                                    ),
                                    child: Text(
                                      'Delete'.toUpperCase(),
                                      style: textTheme.labelLarge?.copyWith(
                                        color: color.onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(budgetServiceProvider)
                              .deleteBudget(b.id);
                          ref.invalidate(budgetsWithProgressProvider);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: SizedBox(
                        height: 150,
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
                    ),
                    Expanded(
                      flex: (allBoxWidthFactor * 100).toInt(),
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Budget",
                              // textAlign: TextAlign.center,
                              style: textTheme.labelLarge?.copyWith(
                                color: color.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "₹${b.amount.toStringAsFixed(0)}",
                              // textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: color.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 35,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Spent",
                              // textAlign: TextAlign.center,
                              style: textTheme.labelLarge?.copyWith(
                                color: color.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "₹${spent.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)",
                              // textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: color.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacer(),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "${formatter.format(b.startDate)} - ${formatter.format(b.endDate)}",
                        style: textTheme.bodyLarge?.copyWith(
                          color: color.primary,
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_outlined
                          : Icons.keyboard_arrow_down_outlined,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  Divider(indent: 10, endIndent: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Categories'.toUpperCase(),
                      style: textTheme.bodyLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 150, // Adjust height as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: widget.data.categorySpendings.length,
                      itemBuilder: (BuildContext context, int index) {
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
