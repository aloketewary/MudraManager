import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/insights/data/insights_provider.dart';
import 'package:mudra_manager/features/insights/domain/health_metrics.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/insights/presentation/widgets/deep_dive_analytics_section.dart';
import 'package:mudra_manager/features/insights/presentation/widgets/pattern_card.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/progress_ring.dart';

class InsightsOverview extends ConsumerWidget {
  final InsightsData insights;
  final String periodKey;
  final VoidCallback? onRecommendationTap;
  final VoidCallback? onPatternTap;

  const InsightsOverview({
    super.key,
    required this.insights,
    required this.periodKey,
    this.onRecommendationTap,
    this.onPatternTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryHero(insights: insights),
        SizedBox(height: spacing.sectionGap),
        if (insights.quickWins.isNotEmpty) ...[
          const _SectionHeader(
            label: 'Next best action',
            icon: LucideIcons.sparkles,
          ),
          SizedBox(height: spacing.elementGap),
          _PrimaryActionCard(
            recommendation: insights.quickWins.first,
            onTap: onRecommendationTap,
          ),
          SizedBox(height: spacing.sectionGap),
        ],
        const _CategoryChangesSection(),
        SizedBox(height: spacing.sectionGap),
        const _ForecastPreview(),
        SizedBox(height: spacing.sectionGap),
        _HealthOverview(healthMetrics: insights.healthMetrics),
        if (insights.hiddenPatterns.isNotEmpty) ...[
          SizedBox(height: spacing.sectionGap),
          HiddenPatternsSection(
            patterns: insights.hiddenPatterns,
            onPatternTap: onPatternTap,
          ),
        ],
        SizedBox(height: spacing.sectionGap),
        _ExploreAnalytics(
          periodKey: periodKey,
          insights: insights,
        ),
      ],
    );
  }
}

class _SummaryHero extends ConsumerWidget {
  final InsightsData insights;

  const _SummaryHero({required this.insights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final aggregates = insights.aggregates;
    final saved = aggregates.totalIncome - aggregates.totalExpense;
    final isPositive = saved >= 0;
    final heroColor = isPositive
        ? FinanceColors.incomeColor(Theme.of(context).brightness)
        : FinanceColors.expenseColor(Theme.of(context).brightness);
    final expenseChange = _percentageChange(
      aggregates.totalExpense,
      aggregates.previousFullExpense,
    );

    return Semantics(
      container: true,
      label: 'Monthly financial summary',
      child: AnimatedContainer(
        duration: spacing.animNormal,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primary.withValues(
                alpha: color.brightness == Brightness.dark ? 0.20 : 0.12,
              ),
              color.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.primary.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: color.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.walletCards,
                  size: spacing.iconSM,
                  color: color.primary,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  'This month',
                  style: textTheme.labelLarge?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'How this is calculated',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSummaryInfo(context, spacing);
                  },
                  icon: Icon(
                    LucideIcons.info,
                    size: spacing.iconSM,
                    color: color.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: BoxConstraints(
                    minWidth: spacing.touchTarget,
                    minHeight: spacing.touchTarget,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              isPositive
                  ? 'You are saving this month'
                  : 'Spending is above income',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing.elementGapMin),
            AmountGlow(
              color: heroColor,
              child: AnimatedBalance(
                value: saved,
                duration: spacing.animHero,
                compact: false,
                fixedStringLength: 0,
                style: textTheme.headlineLarge?.copyWith(
                  color: heroColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(height: spacing.elementGapMin),
            Text(
              insights.aiSummary.prediction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'Income',
                    value: aggregates.totalIncome,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    icon: LucideIcons.arrowUp,
                    iconColor: FinanceColors.incomeColor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Expenses',
                    value: aggregates.totalExpense,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    icon: LucideIcons.arrowDown,
                    iconColor: FinanceColors.expenseColor(
                      Theme.of(context).brightness,
                    ),
                    changePercent: expenseChange,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Saved',
                    value: aggregates.savingsRate,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    icon: LucideIcons.piggyBank,
                    iconColor: color.primary,
                    suffix: '%',
                    isPercent: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryInfo(BuildContext context, AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: color.surface,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.cardInner,
            spacing.elementGapMin,
            spacing.cardInner,
            spacing.cardInner,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.walletCards, size: 64, color: color.primary),
              SizedBox(height: spacing.elementGap),
              Text(
                'How this is calculated',
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.elementGap),
              Text(
                'Savings is income minus expenses recorded for the selected period. The savings rate is the amount saved as a percentage of income.',
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sectionGap),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final double value;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final IconData icon;
  final Color iconColor;
  final double? changePercent;
  final String? suffix;
  final bool isPercent;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.icon,
    required this.iconColor,
    this.changePercent,
    this.suffix,
    this.isPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.elementGap),
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: spacing.iconXS, color: iconColor),
              SizedBox(width: spacing.elementGapMin),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          if (isPercent)
            Text(
              '${value.toStringAsFixed(0)}${suffix ?? ''}',
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            )
          else
            CurrencyText(
              amount: value,
              compact: true,
              fixedLength: 0,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          if (changePercent != null)
            Text(
              '${changePercent! >= 0 ? '+' : ''}${changePercent!.toStringAsFixed(0)}%',
              style: textTheme.labelSmall?.copyWith(
                color: changePercent! > 0
                    ? FinanceColors.expenseColor(Theme.of(context).brightness)
                    : FinanceColors.incomeColor(Theme.of(context).brightness),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends ConsumerWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;

  const _PrimaryActionCard({required this.recommendation, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Recommended action: ${recommendation.title}',
      child: Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: EdgeInsets.all(spacing.cardInner),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGap),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(
                recommendation.icon,
                size: spacing.iconMD,
                color: color.primary,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    recommendation.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  FilledButton.tonal(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onTap?.call();
                    },
                    child: Text(recommendation.actionLabel),
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

class _CategoryChangesSection extends ConsumerWidget {
  const _CategoryChangesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final trendsAsync = ref.watch(categoryTrendsProvider);

    return trendsAsync.when(
      data: (trends) {
        if (trends.isEmpty) return const SizedBox.shrink();
        final rows = trends.values.toList()
          ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
        final visibleRows = rows.take(3).toList();
        final maxAmount = visibleRows.first.thisMonth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              label: 'What changed',
              icon: LucideIcons.chartNoAxesCombined,
            ),
            SizedBox(height: spacing.elementGap),
            Container(
              decoration: BoxDecoration(
                color: color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                children: visibleRows
                    .map(
                      (trend) => Padding(
                        padding: EdgeInsets.only(bottom: spacing.sectionGap),
                        child: _CategoryChangeRow(
                          trend: trend,
                          maxAmount: maxAmount,
                          color: color,
                          textTheme: textTheme,
                          spacing: spacing,
                          brightness: brightness,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CategoryChangeRow extends StatelessWidget {
  final CategoryTrend trend;
  final double maxAmount;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final Brightness brightness;

  const _CategoryChangeRow({
    required this.trend,
    required this.maxAmount,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = trend.changePercent > 0;
    final changeColor = isUp
        ? FinanceColors.expenseColor(brightness)
        : trend.changePercent < 0
            ? FinanceColors.incomeColor(brightness)
            : color.onSurfaceVariant;
    final progress =
        maxAmount == 0 ? 0.0 : (trend.thisMonth / maxAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trend.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            CurrencyText(
              amount: trend.thisMonth,
              compact: true,
              fixedLength: 0,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGapMin),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: spacing.progressNormal,
                  backgroundColor: color.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color.primary),
                ),
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: spacing.iconXS,
                  color: changeColor,
                ),
                Text(
                  '${trend.changePercent.abs().toStringAsFixed(0)}%',
                  style: textTheme.labelSmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ForecastPreview extends ConsumerWidget {
  const _ForecastPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final forecastAsync = ref.watch(cashFlowForecastProvider);

    return forecastAsync.when(
      data: (forecast) {
        final forecastColor = forecast.avgMonthlyNet >= 0
            ? FinanceColors.incomeColor(brightness)
            : FinanceColors.expenseColor(brightness);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              label: 'Looking ahead',
              icon: LucideIcons.trendingUp,
            ),
            SizedBox(height: spacing.elementGap),
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: color.surfaceContainerLow,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: forecastColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      forecast.avgMonthlyNet >= 0
                          ? LucideIcons.arrowUpRight
                          : LucideIcons.alertTriangle,
                      size: spacing.iconMD,
                      color: forecastColor,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forecast.avgMonthlyNet >= 0
                              ? 'Expected monthly savings'
                              : 'Projected monthly shortfall',
                          style: textTheme.labelMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        CurrencyText(
                          amount: forecast.avgMonthlyNet,
                          showSign: true,
                          compact: false,
                          fixedLength: 0,
                          style: textTheme.titleLarge?.copyWith(
                            color: forecastColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: spacing.iconMD,
                    color: color.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HealthOverview extends ConsumerWidget {
  final HealthMetrics healthMetrics;

  const _HealthOverview({required this.healthMetrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final healthColor = healthMetrics.ratingColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          label: 'Financial health',
          icon: LucideIcons.heartPulse,
        ),
        SizedBox(height: spacing.elementGap),
        Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border:
                Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              ProgressRing(
                progress: healthMetrics.overallScore / 100,
                color: healthColor,
                size: 64,
                strokeWidth: spacing.progressNormal,
                labelBuilder: (_) => Text(
                  healthMetrics.overallScore.toStringAsFixed(0),
                  style: textTheme.titleMedium?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthMetrics.rating,
                      style: textTheme.titleSmall?.copyWith(
                        color: healthColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      '${healthMetrics.savingsHealth.label}: ${healthMetrics.savingsHealth.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: spacing.iconMD,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreAnalytics extends StatelessWidget {
  final String periodKey;
  final InsightsData insights;

  const _ExploreAnalytics({required this.periodKey, required this.insights});

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: spacing.cardInner),
        childrenPadding: EdgeInsets.fromLTRB(
          spacing.cardInner,
          0,
          spacing.cardInner,
          spacing.cardInner,
        ),
        leading: Icon(LucideIcons.barChart3, color: color.primary),
        title: Text(
          'Explore your data',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Trends, categories, and detailed reports',
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        children: [
          DeepDiveAnalyticsSection(periodKey: periodKey),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing.elementGap),
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
          child: Icon(icon, size: spacing.iconSM, color: color.primary),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

extension on BuildContext {
  AppSpacing readSpacing() =>
      ProviderScope.containerOf(this).read(spacingProvider);
}

double? _percentageChange(double current, double? previous) {
  if (previous == null || previous <= 0) return null;
  return ((current - previous) / previous) * 100;
}
