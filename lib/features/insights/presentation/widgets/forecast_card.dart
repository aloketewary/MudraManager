import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
import 'package:fl_chart/fl_chart.dart';

/// Forecast card showing cash flow predictions and upcoming trends.
///
/// Displays:
/// - Monthly savings projection
/// - Upcoming recurring expenses
/// - Risk alerts (if any)
/// - Goal completion estimates
class ForecastCard extends ConsumerWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final predictedSpendingAsync = ref.watch(predictedSpendingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeSectionHeader(
          label: 'Predictions',
          icon: LucideIcons.trendingUp,
          accentColor: color.primary,
        ),
        SizedBox(height: spacing.sectionGap),
        forecastAsync.when(
          data: (forecast) {
            final predicted = predictedSpendingAsync.value ?? forecast.projectedMonthExpense;

            return Column(
              children: [
                // Main forecast card
                _buildMainForecastCard(
                  context,
                  forecast,
                  predicted,
                  color,
                  textTheme,
                  spacing,
                  brightness,
                ),
                SizedBox(height: spacing.sectionGap),
                // Forecast chart
                _buildForecastChart(context, forecast, color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
                // Risk alerts
                if (forecast.avgMonthlyNet < 0)
                  _buildRiskAlert(context, forecast, color, textTheme, spacing, l10n),
              ],
            );
          },
          loading: () => _buildLoadingSkeleton(spacing, color),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMainForecastCard(
    BuildContext context,
    CashFlowForecast forecast,
    double predictedSpending,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
  ) {
    final isPositive = forecast.avgMonthlyNet >= 0;
    final forecastColor = isPositive
        ? FinanceColors.incomeColor(brightness)
        : FinanceColors.expenseColor(brightness);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            forecastColor.withValues(alpha: brightness == Brightness.dark ? 0.20 : 0.12),
            color.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: forecastColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: forecastColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                  size: 16,
                  color: forecastColor,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  'Monthly Outlook',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: forecastColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurrencyText(
                      amount: forecast.avgMonthlyNet,
                      showSign: true,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: forecastColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Expected monthly savings',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Mini stats
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: color.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.arrowDown,
                            size: 12,
                            color: FinanceColors.expenseColor(brightness),
                          ),
                          SizedBox(width: spacing.elementGapMin),
                          CurrencyText(
                            amount: forecast.projectedMonthExpense,
                            compact: true,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.arrowUp,
                            size: 12,
                            color: FinanceColors.incomeColor(brightness),
                          ),
                          SizedBox(width: spacing.elementGapMin),
                          CurrencyText(
                            amount: forecast.projectedMonthIncome,
                            compact: true,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart(
    BuildContext context,
    CashFlowForecast forecast,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < forecast.forecastMonths.length; i++) {
      final net = forecast.forecastMonths[i].net;
      spots.add(FlSpot(i.toDouble(), net));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(spacing.cardInner),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: false,
          ),
          titlesData: FlTitlesData(
            show: false,
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 2,
          minY: minY - 500,
          maxY: maxY + 500,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 6,
                  color: color.primary,
                  strokeWidth: 2,
                  strokeColor: color.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.primary.withValues(alpha: 0.2),
                    color.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAlert(
    BuildContext context,
    CashFlowForecast forecast,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: FinanceColors.expenseColor(Theme.of(context).brightness).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: FinanceColors.expenseColor(Theme.of(context).brightness).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            size: spacing.iconMD,
            color: FinanceColors.expenseColor(Theme.of(context).brightness),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              'Cash flow warning: Projected to spend more than income',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: FinanceColors.expenseColor(Theme.of(context).brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(AppSpacing spacing, ColorScheme color) {
    return Column(
      children: [
        SkeletonLoader(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        SizedBox(height: spacing.sectionGap),
        SkeletonLoader(
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
      ],
    );
  }
}