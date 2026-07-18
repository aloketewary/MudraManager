import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class BudgetOverviewCard extends ConsumerWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final budgets = ref.watch(dashboardBudgetsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (budgets.isEmpty) return const SizedBox.shrink();

    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    final remaining = totalBudget - totalSpent;
    final percent = (totalSpent / totalBudget * 100).clamp(0.0, 100.0);

    final daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final daysLeft = daysInMonth - DateTime.now().day + 1;
    final dailySafe = daysLeft > 0 ? remaining / daysLeft : 0;

    Color progressColor = color.tertiary;
    if (percent >= 100) {
      progressColor = color.error;
    } else if (percent >= 90) {
      progressColor = color.error;
    } else if (percent >= 80) {
      progressColor = FinanceColors.statusWarning;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.budgetDashboard);
          },
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                ProgressRing(
                  progress: percent / 100,
                  color: progressColor,
                  size: spacing.sectionGap * 2.5,
                  insetPadding: spacing.cardVerticalMin,
                  labelBuilder: (value) => Text(
                    '${(value * 100).toInt()}%',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: progressColor,
                    ),
                  ),
                ),
                SizedBox(width: spacing.sectionGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Budget',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.elementGap),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: color.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0.0, end: percent / 100),
                            builder: (context, value, child) {
                              return FractionallySizedBox(
                                widthFactor: value,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        progressColor,
                                        progressColor.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Remaining',
                              remaining,
                              LucideIcons.wallet,
                              progressColor,
                              color,
                              textTheme,
                              spacing,
                            ),
                          ),
                          SizedBox(width: spacing.radiusMedium),
                          Expanded(
                            child: _buildMetricItem(
                              'Per Day',
                              dailySafe.toDouble(),
                              LucideIcons.calendar,
                              color.primary,
                              color,
                              textTheme,
                              spacing,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: color.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    double value,
    IconData icon,
    Color itemColor,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, color: itemColor, size: 16),
        SizedBox(width: spacing.elementGapMin + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              CurrencyText(
                amount: value,
                fixedLength: 0,
                showSign: true,
                showPositiveSign: false,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
