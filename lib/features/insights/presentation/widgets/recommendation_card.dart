import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Actionable recommendation card with clear CTA.
///
/// Used for Quick Wins and Personalized Recommendations sections.
/// Displays: icon, title, description, potential savings, and action button.
class RecommendationCard extends ConsumerWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.onSurface.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
            child: Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.elementGap),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              recommendation.iconColor.withValues(alpha: 0.15),
                              recommendation.iconColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          recommendation.icon,
                          size: spacing.iconMD,
                          color: recommendation.iconColor,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (recommendation.subtitle != null)
                              Text(
                                recommendation.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Priority indicator
                      _buildPriorityChip(context, color, textTheme, spacing),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap),
                  // Description
                  Text(
                    recommendation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  // Potential savings
                  if (recommendation.potentialSavings != null &&
                      recommendation.potentialSavings! > 0)
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: spacing.elementGap),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.piggyBank,
                              size: 12,
                              color: FinanceColors.incomeColor(
                                Theme.of(context).brightness,
                              ),
                            ),
                            SizedBox(width: spacing.elementGapMin),
                            Text(
                              'Potential savings: ',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            CurrencyText(
                              amount: recommendation.potentialSavings!,
                              compact: true,
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: FinanceColors.incomeColor(
                                  Theme.of(context).brightness,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onTap?.call();
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: spacing.elementGap,
                        ),
                      ),
                      child: Text(recommendation.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final (label, chipColor) = switch (recommendation.priority) {
      RecommendationPriority.high => ('Urgent', color.error),
      RecommendationPriority.medium => ('Important', FinanceColors.statusWarning),
      RecommendationPriority.low => ('Nice to have', color.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGapMin,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: chipColor,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Compact version for horizontal scrolling lists
class RecommendationChip extends ConsumerWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationChip({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap,
          vertical: spacing.elementGap,
        ),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recommendation.icon,
              size: 14,
              color: recommendation.iconColor,
            ),
            SizedBox(width: spacing.elementGapMin),
            Text(
              recommendation.title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}