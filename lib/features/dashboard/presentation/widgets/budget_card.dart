import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';

import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class BudgetCard extends ConsumerWidget {
  final double globalPadding;

  const BudgetCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetsWithProgressProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return budgetAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) return const SizedBox.shrink();

        final totalBudget =
            budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
        final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
        final remaining = totalBudget - totalSpent;
        final percent = totalBudget > 0
            ? (totalSpent / totalBudget * 100).clamp(0.0, 150.0)
            : 0.0;

        final daysInMonth =
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
        final daysLeft = daysInMonth - DateTime.now().day + 1;
        final dailyAllowance = daysLeft > 0 ? remaining / daysLeft : 0.0;

        Color progressColor = color.onSurfaceVariant;
        if (percent >= 100) {
          progressColor = color.error;
        } else if (percent >= 80) {
          progressColor = color.tertiary;
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: globalPadding,
            vertical: spacing.cardVertical,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: color.outlineVariant),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push(AppRoutes.budgetDashboard);
              },
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Icon(
                          LucideIcons.target,
                          color: color.onSurfaceVariant,
                          size: 18,
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!
                                .dashboard_mini_budget_text,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    ),

                    SizedBox(height: spacing.sectionGap),

                    // ── Hero: Remaining ──
                    Text(
                      formatCurrency(remaining, decimals: 0),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: percent >= 100
                            ? color.error
                            : color.onSurface,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      AppLocalizations.of(context)!.budget_remaining,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),

                    SizedBox(height: spacing.elementGap),

                    // ── Progress bar (thin, subordinate) ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            color.surfaceContainerHighest,
                        color: progressColor,
                      ),
                    ),

                    SizedBox(height: spacing.elementGap),

                    // ── Daily allowance ──
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          AppLocalizations.of(context)!
                              .budget_safeToSpend,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: spacing.elementGapMin),
                        Text(
                          formatCurrency(dailyAllowance, decimals: 0),
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
      loading: () => const BudgetCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
