import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/health_metrics.dart';
import 'package:mudra_manager/shared/widgets/progress_ring.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Financial health score card with breakdown metrics.
///
/// Displays:
/// - Overall score ring with rating
/// - Component breakdown (savings, income, emergency fund, debt, budget)
/// - Actionable tips for improvement
class HealthScoreCard extends ConsumerWidget {
  final HealthMetrics healthMetrics;

  const HealthScoreCard({
    super.key,
    required this.healthMetrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: 'Financial Health',
          icon: LucideIcons.heartPulse,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        // Hero card with score
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                healthMetrics.ratingColor(context).withValues(alpha: brightness == Brightness.dark ? 0.20 : 0.12),
                color.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: healthMetrics.ratingColor(context).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: healthMetrics.ratingColor(context).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                // Score ring
                ProgressRing(
                  progress: healthMetrics.overallScore / 100,
                  color: healthMetrics.ratingColor(context),
                  size: 80,
                  strokeWidth: 8,
                  labelBuilder: (animatedValue) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          healthMetrics.overallScore.toStringAsFixed(0),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: healthMetrics.ratingColor(context),
                          ),
                        ),
                        Text(
                          '/100',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(width: spacing.sectionGap),
                // Rating and quick stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        healthMetrics.rating,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: healthMetrics.ratingColor(context),
                        ),
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Text(
                        'Your overall financial wellness score',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: spacing.elementGap),
                      // Quick breakdown chips
                      Row(
                        children: [
                          _buildMiniChip(
                            'Savings',
                            healthMetrics.savingsHealth.percentage >= 0.8,
                            color,
                            textTheme,
                            spacing,
                            context,
                          ),
                          SizedBox(width: spacing.elementGap),
                          _buildMiniChip(
                            'Budget',
                            healthMetrics.budgetAdherence.percentage >= 0.8,
                            color,
                            textTheme,
                            spacing,
                            context,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        // Detailed breakdown
        _buildBreakdownCard(context, color, textTheme, spacing),
      ],
    );
  }

  Widget _buildMiniChip(String label, bool isGood, ColorScheme color, TextTheme textTheme, AppSpacing spacing, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: isGood
            ? FinanceColors.incomeColor(Theme.of(context).brightness).withValues(alpha: 0.1)
            : color.outlineVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? LucideIcons.checkCircle : LucideIcons.info,
            size: 10,
            color: isGood
                ? FinanceColors.incomeColor(Theme.of(context).brightness)
                : color.onSurfaceVariant,
          ),
          SizedBox(width: spacing.elementGapMin),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isGood
                  ? FinanceColors.incomeColor(Theme.of(context).brightness)
                  : color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(BuildContext context, ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildBreakdownItem(
            context: context,
            icon: LucideIcons.piggyBank,
            title: healthMetrics.savingsHealth.label,
            description: healthMetrics.savingsHealth.description,
            score: healthMetrics.savingsHealth.score,
            maxScore: healthMetrics.savingsHealth.maxScore,
            tip: healthMetrics.savingsHealth.tip,
            iconColor: FinanceColors.incomeColor(Theme.of(context).brightness),
            color: color,
            textTheme: textTheme,
            spacing: spacing,
          ),
          _buildBreakdownItem(
            context: context,
            icon: LucideIcons.wallet,
            title: healthMetrics.incomeStability.label,
            description: healthMetrics.incomeStability.description,
            score: healthMetrics.incomeStability.score,
            maxScore: healthMetrics.incomeStability.maxScore,
            tip: healthMetrics.incomeStability.tip,
            iconColor: color.primary,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
          ),
          _buildBreakdownItem(
            context: context,
            icon: LucideIcons.shield,
            title: healthMetrics.emergencyFund.label,
            description: healthMetrics.emergencyFund.description,
            score: healthMetrics.emergencyFund.score,
            maxScore: healthMetrics.emergencyFund.maxScore,
            tip: healthMetrics.emergencyFund.tip,
            iconColor: FinanceColors.statusWarning,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
          ),
          _buildBreakdownItem(
            context: context,
            icon: LucideIcons.creditCard,
            title: healthMetrics.debtHealth.label,
            description: healthMetrics.debtHealth.description,
            score: healthMetrics.debtHealth.score,
            maxScore: healthMetrics.debtHealth.maxScore,
            tip: healthMetrics.debtHealth.tip,
            iconColor: FinanceColors.expenseColor(Theme.of(context).brightness),
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required double score,
    required double maxScore,
    required String? tip,
    required Color iconColor,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    bool isLast = false,
  }) {
    final percentage = maxScore > 0 ? score / maxScore : 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGapMin),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          description,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score indicator
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: percentage >= 0.8
                          ? FinanceColors.incomeColor(Theme.of(context).brightness)
                          : percentage >= 0.5
                              ? FinanceColors.statusWarning
                              : FinanceColors.expenseColor(Theme.of(context).brightness),
                    ),
                  ),
                ],
              ),
              // Progress bar
              SizedBox(height: spacing.elementGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: LinearProgressIndicator(
                  value: percentage.toDouble(),
                  minHeight: 6,
                  backgroundColor: color.outlineVariant.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 0.8
                        ? FinanceColors.incomeColor(Theme.of(context).brightness)
                        : percentage >= 0.5
                            ? FinanceColors.statusWarning
                            : FinanceColors.expenseColor(Theme.of(context).brightness),
                  ),
                ),
              ),
              // Tip
              if (tip != null)
                Padding(
                  padding: EdgeInsets.only(top: spacing.elementGapMin),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.lightbulb,
                        size: 12,
                        color: FinanceColors.statusWarning,
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        tip,
                        style: textTheme.bodySmall?.copyWith(
                          color: FinanceColors.statusWarning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}