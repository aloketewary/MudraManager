import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/goal.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_progress_bar.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_section_header.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_surface.dart';
import 'package:mudra_manager/shared/widgets/progress_ring.dart';

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final goals = ref.watch(dashboardGoalsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    final activeGoals = goals
        .where((goal) => goal.isActive && goal.progressPercent < 1.0)
        .toList();
    if (activeGoals.isEmpty) return const SizedBox.shrink();

    // Dashboard surfaces show one decision at a time. Use the goal with the
    // most progress as the featured goal and keep the full list in GoalScreen.
    activeGoals.sort(
      (a, b) => b.progressPercent.compareTo(a.progressPercent),
    );
    final goal = activeGoals.first;
    final goalColor =
        goal.colorValue == null ? color.primary : Color(goal.colorValue!);
    final progress = goal.progressPercent.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();
    final cardRadius = spacing.borderRadiusLarge;

    return FinanceSurface(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontalMin,
        vertical: spacing.cardVerticalMin,
      ),
      padding: EdgeInsets.all(spacing.cardHorizontal),
      borderRadius: cardRadius,
      border: BorderSide(color: goalColor.withValues(alpha: 0.0)),
      accent: goalColor,
      semanticLabel: '${goal.name}, $percent%',
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(AppRoutes.goalDetails, extra: {'goal': goal});
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            title: ctxt.title_goals,
            trailingLabel: ctxt.dashboard_viewAllLabel,
            icon: LucideIcons.flag,
            accent: goalColor,
            onTrailingTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.goalScreen);
            },
          ),
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.all(spacing.cardInner * 0.75),
            decoration: BoxDecoration(
              color: color.surfaceContainerHigh,
              borderRadius: spacing.borderRadiusMedium,
              border: Border.all(
                color: goalColor.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGoalIcon(goal, goalColor, spacing),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          CurrencyText(
                            amount: goal.remainingAmount,
                            currencyCode: goal.currencyCode,
                            fixedLength: 0,
                            compact: false,
                            suffixText: ctxt.goal_suffixLeft,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    ProgressRing(
                      progress: progress,
                      color: goalColor,
                      size: spacing.sectionGap * 2.5,
                      insetPadding: spacing.cardVerticalMin,
                      labelBuilder: (value) => Text(
                        '${(value * 100).toInt()}%',
                        style: textTheme.titleMedium?.copyWith(
                          color: goalColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap),
                Row(
                  children: [
                    Text(
                      ctxt.goal_suffixSaved,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    CurrencyText(
                      amount: goal.currentAmount,
                      currencyCode: goal.currencyCode,
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    CurrencyText(
                      amount: goal.targetAmount,
                      currencyCode: goal.currencyCode,
                      fixedLength: 0,
                      compact: true,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: textTheme.labelMedium?.copyWith(
                        color: goalColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGapMin),
                FinanceProgressBar(
                  value: progress,
                  fillColor: goalColor,
                  trackColor: color.surfaceContainerHighest,
                  stripeColor: goalColor.withValues(alpha: 0.22),
                  height: spacing.progressNormal,
                  semanticLabel: '${goal.name} progress',
                ),
              ],
            ),
          ),
          if (activeGoals.length > 1) ...[
            SizedBox(height: spacing.elementGap),
            Text(
              ctxt.goal_goalsInProgress(activeGoals.length),
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalIcon(Goal goal, Color goalColor, AppSpacing spacing) {
    return Container(
      width: spacing.touchTargetSmall,
      height: spacing.touchTargetSmall,
      decoration: BoxDecoration(
        color: goalColor.withValues(alpha: 0.12),
        borderRadius: spacing.borderRadiusMedium,
      ),
      alignment: Alignment.center,
      child: Icon(
        IconHelper.getIconData(goal.iconName),
        color: goalColor,
        size: spacing.iconMD,
      ),
    );
  }
}
