import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/presentation/widgets/statistics_chart_section.dart';
import 'package:mudra_manager/features/analytics/presentation/widgets/statistics_metrics_section.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';

/// Deep Dive Analytics section for detailed exploration.
///
/// Provides access to:
/// - Expense trends chart
/// - Category breakdown
/// - Merchant analysis
/// - Monthly comparison
/// - Year-over-year comparison
/// - Calendar heatmap views
class DeepDiveAnalyticsSection extends ConsumerWidget {
  final String periodKey;

  const DeepDiveAnalyticsSection({
    super.key,
    required this.periodKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: l10n.insights_deepDive,
          icon: LucideIcons.barChart3,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        // Chart section
        StatisticsChartSection(periodKey: periodKey),
        SizedBox(height: spacing.sectionGap),
        // Metrics section
        StatisticsMetricsSection(periodKey: periodKey),
        SizedBox(height: spacing.sectionGap),
        // View all analytics link
        _buildViewAllLink(context, color, textTheme, spacing, l10n),
      ],
    );
  }

  Widget _buildViewAllLink(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Navigate to full analytics screen
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: spacing.iconSM,
                  color: color.primary,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  l10n.insights_viewAllAnalytics,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for when no analytics data is available
class DeepDiveEmptyState extends ConsumerWidget {
  const DeepDiveEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      child: Column(
        children: [
          Icon(
            LucideIcons.barChart3,
            size: spacing.iconXL,
            color: color.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: spacing.elementGap),
          Text(
            l10n.insights_noDataYet,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Text(
            l10n.insights_addTransactionsPrompt,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}