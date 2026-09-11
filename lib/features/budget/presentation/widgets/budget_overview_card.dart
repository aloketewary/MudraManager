import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/providers/budget_refresh_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/budget/domain/budget_overview_aggregate.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_section_header.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_surface.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class BudgetOverviewCard extends ConsumerWidget {
  const BudgetOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final dashboard = ref.watch(dashboardDataProvider);
    final refresh = ref.watch(budgetRefreshProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    // Never reuse prior dashboard values while shared refresh is loading or
    // failed. Non-budget dashboard cards keep their own rendering contract.
    if (dashboard.isLoading || dashboard.hasError) {
      return const SizedBox.shrink();
    }
    final data = dashboard.value;
    if (data == null ||
        data.budgetGeneration != refresh.generation ||
        data.budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final aggregate = BudgetOverviewAggregate.fromSnapshots(
      data.budgets.map((budget) => budget.snapshot),
    );
    final percent = aggregate.percent;
    final title = aggregate.isCompatibleMonthly
        ? 'Monthly Budget'
        : ctxt.budget_dashboardMiniCardBudgetTitleText;

    Color progressColor = color.tertiary;
    if (percent >= 100) {
      progressColor = color.error;
    } else if (percent >= 90) {
      progressColor = color.error;
    } else if (percent >= 80) {
      progressColor = FinanceColors.statusWarning;
    }

    return FinanceSurface(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontalMin,
        vertical: spacing.cardVerticalMin,
      ),
      padding: EdgeInsets.all(spacing.cardHorizontal),
      borderRadius: spacing.borderRadiusLarge,
      border: BorderSide(color: progressColor.withValues(alpha: 0.0)),
      accent: progressColor,
      semanticLabel: '$title, ${percent.toInt()}%',
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.budgetDashboard);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            title: ctxt.title_budgets,
            trailingLabel: ctxt.dashboard_viewAllLabel,
            icon: LucideIcons.chartPie,
            accent: progressColor,
            onTrailingTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.budgetDashboard);
            },
          ),
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.all(spacing.cardInner * 0.75),
            decoration: BoxDecoration(
              color: color.surfaceContainerHigh,
              borderRadius: spacing.borderRadiusMedium,
              border: Border.all(
                color: progressColor.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: spacing.touchTargetSmall,
                      height: spacing.touchTargetSmall,
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.12),
                        borderRadius: spacing.borderRadiusMedium,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.wallet,
                        color: progressColor,
                        size: spacing.iconMD,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            'Remaining',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          AmountGlow(
                            color: progressColor,
                            child: AnimatedBalance(
                              value: aggregate.totalRemaining,
                              fixedStringLength: 0,
                              compact: false,
                              duration: const Duration(milliseconds: 700),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: color.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    ProgressRing(
                      progress: aggregate.progress,
                      color: progressColor,
                      size: spacing.sectionGap * 2.5,
                      insetPadding: spacing.cardVerticalMin,
                      labelBuilder: (value) => Text(
                        '${(value * 100).toInt()}%',
                        style: textTheme.titleSmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
                FinanceProgressBar(
                  value: aggregate.progress,
                  fillColor: progressColor,
                  trackColor: color.surfaceContainerHighest,
                  stripeColor: progressColor.withValues(alpha: 0.22),
                  height: spacing.progressNormal,
                  semanticLabel: '$title progress',
                ),
                SizedBox(height: spacing.elementGap),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        ctxt.budget_dashboardMiniCardSpentTitleText,
                        aggregate.totalSpent,
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
                        aggregate.dailyAllowance,
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
        ],
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
        Icon(icon, color: itemColor, size: spacing.iconSM),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
