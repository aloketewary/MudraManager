import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/components/currency_text.dart';

class BudgetCard extends ConsumerWidget {
  final double globalPadding;

  const BudgetCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return budgetAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) return SizedBox.shrink();
        
        final (budget, spent, _, _) = budgets.first;
        final percent = (spent / budget.amount * 100).clamp(0.0, 100.0);
        final remaining = budget.amount - spent;
        final isOverBudget = spent >= budget.amount;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/budget-dashboard');
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart, color: color.primary),
                        SizedBox(width: 8),
                        Text(
                          budget.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: percent),
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isOverBudget ? Colors.red : Color(0xFFF59E0B),
                                    ),
                                  );
                                },
                              ),
                              Text(
                                isOverBudget ? 'Over Budget' : 'Used',
                                style: textTheme.titleMedium?.copyWith(
                                  color: isOverBudget ? Colors.red : Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildMetric('Spent', spent, color, textTheme),
                              SizedBox(height: 8),
                              _buildMetric('Budget', budget.amount, color, textTheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOverBudget ? Icons.warning_amber : Icons.lightbulb_outline,
                          size: 16,
                          color: color.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isOverBudget
                                ? 'You exceeded your budget by ${(spent - budget.amount).toStringAsFixed(0)}'
                                : 'You have ${remaining.toStringAsFixed(0)} left to spend',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }

  Widget _buildMetric(String label, double value, ColorScheme color, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        CurrencyText(
          amount: value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
