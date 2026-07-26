import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
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
        TypeSectionHeader(
          label: l10n.stats_insights,
          icon: LucideIcons.sparkles,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),

        // 1. Forecast hero — glanceable, chart-backed prediction.
        Consumer(
          builder: (context, ref, child) {
            final predictionAsync = ref.watch(predictedSpendingProvider);
            return predictionAsync.when(
              data: (predicted) {
                if (predicted <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: _ForecastCard(
                    predicted: predicted,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    label: l10n.stats_nextMonthForecast,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const InlineError(),
            );
          },
        ),

        // 2. Narrative facts — accent-bar cards, colour = meaning.
        narrativeFactsAsync.when(
          data: (facts) {
            if (facts.isEmpty) return const SizedBox.shrink();
            return Column(
              children: facts.map((fact) {
                final presentation =
                    NarrativeMapper.map(fact, l10n, brightness, color);
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.elementGap),
                  child: _InsightCard(
                    presentation: presentation,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const InlineError(),
        ),

        // 3. Category trends — sparkline rows inside one glass card.
        Consumer(
          builder: (context, ref, child) {
            final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
            return categoryTrendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) return const SizedBox.shrink();
                final sortedTrends = trends.values.toList()
                  ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
                final maxAmount = sortedTrends.first.thisMonth;

                return Container(
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  padding: EdgeInsets.all(spacing.cardInner),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.layoutGrid,
                            size: 16,
                            color: color.primary,
                          ),
                          SizedBox(width: spacing.elementGap),
                          Text(
                            l10n.stats_categoryTrends,
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sectionGap),
                      ...sortedTrends.take(5).toList().asMap().entries.map(
                        (entry) {
                          final isLast =
                              entry.key == sortedTrends.take(5).length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : spacing.sectionGap,
                            ),
                            child: _CategoryTrendRow(
                              trend: entry.value,
                              maxAmount: maxAmount,
                              color: color,
                              textTheme: textTheme,
                              spacing: spacing,
                              brightness: brightness,
                              anomalyLabel: l10n.analytics_anomaly,
                            ),
                          );
                        },
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
      ],
    );
  }
}

/// Forecast hero — dominant number, tinted container, no borrowed chart.
class _ForecastCard extends StatelessWidget {
  final double predicted;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final String label;

  const _ForecastCard({
    required this.predicted,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: 0.10),
            color.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.primary.withValues(alpha: 0.18)),
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.sparkles, color: color.primary, size: 20),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                SizedBox(height: spacing.elementGapUltraMin),
                CurrencyText(
                  amount: predicted,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color.onSurface,
                  ),
                  compact: false,
                  fixedLength: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Narrative insight card — left accent bar carries the semantic color,
/// so the eye can scan severity/type before reading the sentence.
class _InsightCard extends StatelessWidget {
  final NarrativePresentation presentation;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _InsightCard({
    required this.presentation,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: presentation.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: presentation.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          spacing.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        presentation.icon,
                        color: presentation.color,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: spacing.elementGapMin),
                        child: Text(
                          presentation.text,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category trend row — name + anomaly badge, sparkline, amount + delta pill.
/// Mirrors the visual language of the standalone Spending Trends screen so
/// the two surfaces read as the same product.
class _CategoryTrendRow extends StatelessWidget {
  final CategoryTrend trend;
  final double maxAmount;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final Brightness brightness;
  final String anomalyLabel;

  const _CategoryTrendRow({
    required this.trend,
    required this.maxAmount,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.brightness,
    required this.anomalyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = trend.changePercent > 0;
    final isDown = trend.changePercent < 0;
    final changeColor = isUp
        ? FinanceColors.expenseColor(brightness)
        : isDown
            ? FinanceColors.incomeColor(brightness)
            : color.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trend.categoryName,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (trend.isAnomaly)
                    Padding(
                      padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FinanceColors.statusDanger
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.triangleAlert,
                              size: 10,
                              color: FinanceColors.statusDanger,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              anomalyLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: FinanceColors.statusDanger,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trend.monthlyHistory.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
                child: SizedBox(
                  width: 56,
                  height: 22,
                  child: _Sparkline(
                    history: trend.monthlyHistory,
                    color: changeColor,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CurrencyText(
                  amount: trend.thisMonth,
                  fixedLength: 0,
                  compact: true,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (trend.changePercent != 0)
                  Padding(
                    padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                          size: 11,
                          color: changeColor,
                        ),
                        Text(
                          '${trend.changePercent.abs().toStringAsFixed(0)}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        _AnimatedMetricBar(
          progress: maxAmount == 0
              ? 0
              : (trend.thisMonth / maxAmount).clamp(0.0, 1.0),
          barColor: color.primary,
          bgColor: color.surfaceContainerHighest,
        ),
      ],
    );
  }
}

/// Minimal 6-month sparkline — no axes, just shape. History is newest-first;
/// reversed so it reads left-to-right chronologically like the rest of the UI.
class _Sparkline extends StatelessWidget {
  final List<double> history;
  final Color color;

  const _Sparkline({required this.history, required this.color});

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();
    final maxVal = reversed.fold<double>(0, (m, v) => v > m ? v : m);
    if (maxVal == 0) return const SizedBox.shrink();

    final spots = reversed
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        maxY: maxVal * 1.15,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color.withValues(alpha: 0.8),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
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
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            semanticsLabel: 'Progress',
            value: _anim.value * widget.progress,
            minHeight: 6,
            backgroundColor: widget.bgColor,
            valueColor: AlwaysStoppedAnimation(widget.barColor),
          ),
        ),
      ),
    );
  }
}
