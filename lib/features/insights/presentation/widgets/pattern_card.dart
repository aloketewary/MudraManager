import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/spending_pattern.dart';

BoxDecoration _patternsPanelDecoration(
  ColorScheme color,
  AppSpacing spacing,
) {
  final accent = color.tertiary;
  final isDark = color.brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.surfaceContainerHigh.withValues(alpha: isDark ? 0.72 : 0.92),
        color.surfaceContainerLow.withValues(alpha: isDark ? 0.92 : 1),
      ],
    ),
    borderRadius: BorderRadius.circular(spacing.radiusMedium),
    border: Border.all(color: accent.withValues(alpha: isDark ? 0.24 : 0.16)),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.08 : 0.045),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: color.onSurface.withValues(alpha: 0.025),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

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

    return Semantics(
      button: onTap != null,
      label:
          '${presentation.title}. ${presentation.description}. ${presentation.insight}.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: presentation.color.withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: color.onSurface.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!.call();
                  },
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontalMin,
                vertical: spacing.cardVertical,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          presentation.color.withValues(alpha: 0.20),
                          presentation.color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                      border: Border.all(
                        color: presentation.color.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      presentation.icon,
                      size: spacing.iconMD,
                      color: presentation.color,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
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
                            fontWeight: FontWeight.w800,
                            color: color.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          presentation.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          presentation.insight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: presentation.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    SizedBox(width: spacing.elementGapMin),
                    Icon(
                      LucideIcons.chevronRight,
                      size: spacing.iconSM,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
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
          description:
              '${p.weekendPercentage.toStringAsFixed(0)}% of spending on weekends',
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
          insight:
              '${p.monthOverMonthGrowth.toStringAsFixed(0)}% vs last month',
          color: color.primary,
        ),
      final CategoryChangePattern p => SpendingPatternPresentation(
          icon: LucideIcons.chartBar,
          title: 'Category Changes',
          description:
              '${p.newCategories.length + p.increasedCategories.length} significant changes',
          insight:
              '${p.increasedCategories.firstOrNull?.categoryName ?? "None"} up',
          color: FinanceColors.statusWarning,
        ),
      final SalaryWeekPattern p => SpendingPatternPresentation(
          icon: LucideIcons.dollarSign,
          title: 'Salary Week Behavior',
          description: 'Spending patterns around payday',
          insight:
              '${p.salaryWeekMultiplier.toStringAsFixed(1)}x vs other weeks',
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

/// Section for hidden patterns with horizontal scroll.
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
    final textTheme = Theme.of(context).textTheme;

    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label: 'Hidden Patterns. ${patterns.length} spending patterns detected.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVertical,
        ),
        decoration: _patternsPanelDecoration(color, spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PatternHeading(
              color: color,
              textTheme: textTheme,
              spacing: spacing,
            ),
            SizedBox(height: spacing.sectionGap),
            SizedBox(
              height: 144,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: patterns.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: spacing.elementGap),
                itemBuilder: (context, index) => SizedBox(
                  width: 286,
                  child: PatternCard(
                    pattern: patterns[index],
                    onTap: onPatternTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternHeading extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _PatternHeading({
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color.tertiary;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.20),
                accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Icon(
            LucideIcons.eyeOff,
            size: spacing.iconSM,
            color: accent,
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIDDEN PATTERNS',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Spending signals worth noticing',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
