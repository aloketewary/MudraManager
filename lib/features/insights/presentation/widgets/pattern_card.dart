import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/spending_pattern.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Card displaying hidden spending patterns discovered from transaction analysis.
///
/// Shows patterns like weekend spending, late-night purchases, subscription growth, etc.
class PatternCard extends ConsumerWidget {
  final SpendingPattern pattern;
  final VoidCallback? onTap;

  const PatternCard({
    super.key,
    required this.pattern,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    final presentation = _getPresentation(pattern, l10n, brightness, color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          width: 280,
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      presentation.color.withValues(alpha: 0.2),
                      presentation.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  presentation.icon,
                  size: spacing.iconMD,
                  color: presentation.color,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              // Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: presentation.color,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      presentation.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    // Insight pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 24),
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.elementGap,
                          vertical: spacing.elementGapMin / 2,
                        ),
                        decoration: BoxDecoration(
                          color: presentation.color.withValues(alpha: 0.1),
                          border: Border.all(color: presentation.color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          presentation.insight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: presentation.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SpendingPatternPresentation _getPresentation(
    SpendingPattern pattern,
    AppLocalizations l10n,
    Brightness brightness,
    ColorScheme color,
  ) {
    return switch (pattern) {
      final WeekendSpendingPattern p => SpendingPatternPresentation(
          icon: LucideIcons.calendarRange,
          title: l10n.stats_weekendPeak(p.peakDay),
          description: '${p.weekendPercentage.toStringAsFixed(0)}% of spending on weekends',
          insight: '${p.peakDay} is your biggest spend day',
          color: FinanceColors.expenseColor(brightness),
        ),
      final LateNightPattern p => SpendingPatternPresentation(
          icon: LucideIcons.moon,
          title: 'Late Night Spending',
          description: '${p.lateNightTransactionCount} late-night transactions',
          insight: '${p.percentageOfTotal.toStringAsFixed(1)}% of total',
          color: FinanceColors.statusWarning,
        ),
      final SubscriptionGrowthPattern p => SpendingPatternPresentation(
          icon: LucideIcons.refreshCw,
          title: 'Subscription Growth',
          description: '${p.activeSubscriptionCount} active subscriptions',
          insight: '${p.monthOverMonthGrowth.toStringAsFixed(0)}% vs last month',
          color: color.primary,
        ),
      final CategoryChangePattern p => SpendingPatternPresentation(
          icon: LucideIcons.chartBar,
          title: 'Category Changes',
          description: '${p.newCategories.length + p.increasedCategories.length} significant changes',
          insight: '${p.increasedCategories.firstOrNull?.categoryName ?? "None"} up',
          color: FinanceColors.statusWarning,
        ),
      final SalaryWeekPattern p => SpendingPatternPresentation(
          icon: LucideIcons.dollarSign,
          title: 'Salary Week Behavior',
          description: 'Spending patterns around payday',
          insight: '${p.salaryWeekMultiplier.toStringAsFixed(1)}x vs other weeks',
          color: FinanceColors.incomeColor(brightness),
        ),
      final SeasonalPattern p => SpendingPatternPresentation(
          icon: LucideIcons.calendar,
          title: p.seasonName,
          description: 'Seasonal spending pattern detected',
          insight: '${p.seasonalMultiplier.toStringAsFixed(1)}x baseline',
          color: FinanceColors.expenseColor(brightness),
        ),
    };
  }
}

/// Section for hidden patterns with horizontal scroll
class HiddenPatternsSection extends ConsumerWidget {
  final List<SpendingPattern> patterns;
  final VoidCallback? onPatternTap;

  const HiddenPatternsSection({
    super.key,
    required this.patterns,
    this.onPatternTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: 'Hidden Patterns',
          icon: LucideIcons.eyeOff,
          accentColor: color.tertiary,
        ),
        SizedBox(height: spacing.sectionGap),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: patterns.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing.elementGap),
            itemBuilder: (context, index) => PatternCard(
              pattern: patterns[index],
              onTap: onPatternTap,
            ),
          ),
        ),
      ],
    );
  }
}