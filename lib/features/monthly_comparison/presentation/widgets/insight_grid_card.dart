import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class InsightGridCard extends ConsumerWidget {
  final String topCategory;
  final double topCategoryAmount;
  final double topCategoryPercent;
  final double avgDailySpend;
  final Color topCategoryColor;

  const InsightGridCard({
    super.key,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategoryPercent,
    required this.avgDailySpend,
    required this.topCategoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);

    return Row(
      children: [
        Expanded(child: _buildTopCategoryCard(context, spacing)),
        SizedBox(width: spacing.elementGap),
        Expanded(child: _buildAvgDailyCard(context, spacing)),
      ],
    );
  }

  Widget _buildTopCategoryCard(BuildContext context, AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      height: 140,
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: topCategoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: spacing.elementGap / 2),
              Text(
                ctxt.statistics_topCategory,
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdaptiveText(
                topCategory,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: topCategoryColor,
                ),
                maxLines: 1,
              ),
              SizedBox(height: spacing.elementGap / 3),
              CurrencyText(
                amount: topCategoryAmount,
                style: textTheme.titleMedium?.copyWith(
                  color: topCategoryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ],
          ),
          Text(
            ctxt.statistics_percentOfExpenses(
              topCategoryPercent.toStringAsFixed(0),
            ),
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvgDailyCard(BuildContext context, AppSpacing spacing) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      height: 140,
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: color.primary,
              ),
              SizedBox(width: spacing.elementGap / 2),
              Text(
                ctxt.statistics_dailyAverage,
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurrencyText(
                amount: avgDailySpend,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
                maxLines: 1,
              ),
              SizedBox(height: spacing.elementGap / 3),
              Text(
                ctxt.statistics_perDay,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              color: color.primary,
            ),
          ),
        ],
      ),
    );
  }
}
