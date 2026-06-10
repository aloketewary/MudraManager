import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:visibility_detector/visibility_detector.dart';

class StatisticsInsightsSection extends ConsumerWidget {
  final String periodKey;

  const StatisticsInsightsSection({
    super.key,
    required this.periodKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    final narrativeFactsAsync =
        ref.watch(analyticsNarrativeFactsProvider(periodKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stats_insights,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacing.sectionGap),

        // 1. Prediction Banner (Remains high-level)
        Consumer(
          builder: (context, ref, child) {
            final predictionAsync = ref.watch(predictedSpendingProvider);
            return predictionAsync.when(
              data: (predicted) {
                if (predicted <= 0) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                        color: color.outlineVariant.withValues(alpha: 0.5),),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        color: color.primary,
                        size: 32,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.stats_nextMonthForecast,
                              style: textTheme.labelLarge?.copyWith(
                                color: color.onPrimaryContainer,
                              ),
                            ),
                            SizedBox(height: spacing.elementGap),
                            CurrencyText(
                              amount: predicted,
                              style: textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              compact: false,
                              fixedLength: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const InlineError(),
            );
          },
        ),

        // 2. Narrative Facts via Mapper
        narrativeFactsAsync.when(
          data: (facts) {
            if (facts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: spacing.elementGap),
              child: Column(
                children: facts.map((fact) {
                  final presentation =
                      NarrativeMapper.map(fact, l10n, brightness, color);
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.only(bottom: spacing.elementGap),
                    color: color.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      side: BorderSide(
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing.cardInner),
                      child: Row(
                        children: [
                          Icon(
                            presentation.icon,
                            color: presentation.color,
                            size: 24,
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: Text(
                              presentation.text,
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const InlineError(),
        ),

        // 3. Category Trends
        Consumer(
          builder: (context, ref, child) {
            final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
            return categoryTrendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) return const SizedBox.shrink();
                final sortedTrends = trends.values.toList()
                  ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(),
                  color: color.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    side: BorderSide(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.cardInner),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.stats_categoryTrends,
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: spacing.sectionGap),
                        ...sortedTrends.take(5).map(
                              (trend) => Padding(
                                padding:
                                    EdgeInsets.only(bottom: spacing.elementGap),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          trend.categoryName,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            CurrencyText(
                                              amount: trend.thisMonth,
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (trend.changePercent != 0) ...[
                                              SizedBox(
                                                width: spacing.elementGap,
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (trend.changePercent >
                                                              0
                                                          ? color.error
                                                          : color.primary)
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    spacing.radiusMedium,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      trend.changePercent > 0
                                                          ? LucideIcons.arrowUp
                                                          : LucideIcons
                                                              .arrowDown,
                                                      size: 12,
                                                      color:
                                                          trend.changePercent >
                                                                  0
                                                              ? color.error
                                                              : color.primary,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${trend.changePercent.abs().toStringAsFixed(0)}%',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                        color:
                                                            trend.changePercent >
                                                                    0
                                                                ? color.error
                                                                : color.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing.elementGap),
                                    _AnimatedMetricBar(
                                      progress: (trend.thisMonth /
                                              sortedTrends.first.thisMonth)
                                          .clamp(0.0, 1.0),
                                      barColor: color.primary,
                                      bgColor: color.surfaceContainerHighest,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const InlineError(),
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedMetricBar extends StatefulWidget {
  final double progress;
  final Color barColor;
  final Color bgColor;

  const _AnimatedMetricBar({
    required this.progress,
    required this.barColor,
    required this.bgColor,
  });

  @override
  State<_AnimatedMetricBar> createState() => _AnimatedMetricBarState();
}

class _AnimatedMetricBarState extends State<_AnimatedMetricBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('metric_${widget.progress}_${widget.barColor.toARGB32()}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => LinearProgressIndicator(
          semanticsLabel: 'Progress',
          value: _anim.value * widget.progress,
          minHeight: 8,
          backgroundColor: widget.bgColor,
          valueColor: AlwaysStoppedAnimation(widget.barColor),
        ),
      ),
    );
  }
}
