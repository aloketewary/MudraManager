import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/widget_metrics.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/dashboard/data/widget_analytics_provider.dart';

class WidgetAnalyticsScreen extends ConsumerWidget {
  const WidgetAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final metricsAsync = ref.watch(widgetMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Analytics'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () async {
              await ref.read(widgetAnalyticsServiceProvider).resetAll();
              ref.invalidate(widgetMetricsProvider);
            },
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) => _buildBody(metrics, color, textTheme, spacing),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(
    List<WidgetMetrics> metrics,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.chartBar, size: 48, color: color.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No interactions recorded yet',
              style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Sort by impressions descending
    final sorted = [...metrics]..sort((a, b) => b.impressions.compareTo(a.impressions));

    return ListView(
      padding: EdgeInsets.all(spacing.cardHorizontal),
      children: [
        // Summary row
        _buildSummaryRow(sorted, color, textTheme, spacing),
        SizedBox(height: spacing.sectionGap),
        // Table
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.elementGap,
                ),
                color: color.primary.withValues(alpha: 0.06),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Widget', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Text('Impr', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Clicks', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('CTR', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text('Hides', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              // Rows
              ...sorted.map((m) => _buildRow(m, color, textTheme, spacing)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    List<WidgetMetrics> metrics,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final totalImpressions = metrics.fold<int>(0, (s, m) => s + m.impressions);
    final totalClicks = metrics.fold<int>(0, (s, m) => s + m.clicks);
    final totalHides = metrics.fold<int>(0, (s, m) => s + m.hides);
    final avgCtr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

    return Row(
      children: [
        _summaryChip('Impressions', '$totalImpressions', color.primary, color, textTheme),
        SizedBox(width: spacing.elementGap),
        _summaryChip('Clicks', '$totalClicks', color.tertiary, color, textTheme),
        SizedBox(width: spacing.elementGap),
        _summaryChip('Avg CTR', '${avgCtr.toStringAsFixed(1)}%', color.secondary, color, textTheme),
        SizedBox(width: spacing.elementGap),
        _summaryChip('Hides', '$totalHides', color.error, color, textTheme),
      ],
    );
  }

  Widget _summaryChip(String label, String value, Color accent, ColorScheme color, TextTheme textTheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: accent)),
            const SizedBox(height: 2),
            Text(label, style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(WidgetMetrics m, ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    final ctrColor = m.ctr > 15
        ? color.primary
        : m.ctr > 5
            ? color.tertiary
            : color.error;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.cardInner, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(m.widgetId, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${m.impressions}', style: textTheme.bodySmall, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('${m.clicks}', style: textTheme.bodySmall, textAlign: TextAlign.right)),
          Expanded(
            flex: 2,
            child: Text(
              '${m.ctr.toStringAsFixed(1)}%',
              style: textTheme.bodySmall?.copyWith(color: ctrColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(flex: 2, child: Text('${m.hides}', style: textTheme.bodySmall?.copyWith(color: m.hides > 0 ? color.error : null), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
