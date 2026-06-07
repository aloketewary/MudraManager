import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/tax_estimation_service.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(gamificationServiceProvider)
          ?.track(GamificationEvent.analyticsViewed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(financialHealthProvider);
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
    final spendingByDayAsync = ref.watch(spendingByDayProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final taxAsync = ref.watch(taxEstimationProvider);

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScreenShell(
      config: ScreenShellConfig(
        title: AppLocalizations.of(context)!.title_analytics,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Health Score
            healthAsync.when(
              data: (health) => Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.heart,
                            color: color.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!
                                .analytics_financialHealthScore,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${health.score}',
                              style: textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(health.score),
                              ),
                            ),
                            Text(
                              health.rating,
                              style: textTheme.titleLarge?.copyWith(
                                color: _getScoreColor(health.score),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMetricRow(
                        AppLocalizations.of(context)!.analytics_savingsRate,
                        '${GuestModeUtil.applyGuestMode(health.savingsRate, isGuestMode).toStringAsFixed(1)}%',
                        color,
                        textTheme,
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        AppLocalizations.of(context)!.analytics_expenseRatio,
                        '${GuestModeUtil.applyGuestMode(health.expenseRatio, isGuestMode).toStringAsFixed(1)}%',
                        color,
                        textTheme,
                      ),
                      if (health.insights.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.analytics_insights,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...health.insights.map(
                          (insight) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.lightbulb,
                                  size: 20,
                                  color: color.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    insight,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 16),

            // Spending Prediction
            predictionAsync.when(
              data: (predicted) => Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.trendingUp,
                            color: color.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!
                                .analytics_spendingPrediction,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.analytics_nextMonth,
                              style: textTheme.bodyLarge?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CurrencyText(
                              amount: GuestModeUtil.applyGuestMode(
                                predicted,
                                isGuestMode,
                              ),
                              style: textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.analytics_basedOnAvg,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 16),

            // Cash Flow Forecast
            forecastAsync.when(
              data: (forecast) => GestureDetector(
                onTap: () => context.push(AppRoutes.cashFlowForecast),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Tone.current.borderRadius),
                    side: BorderSide(
                      color: color.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              color: color.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!
                                  .analytics_cashFlowForecast,
                              style: textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Current month projection
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: forecast.projectedNet >= 0
                                ? FinanceColors.incomeColor(
                                    Theme.of(context).brightness,
                                  ).withValues(alpha: 0.08)
                                : FinanceColors.expenseColor(
                                    Theme.of(context).brightness,
                                  ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              Tone.current.borderRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .analytics_thisMonthProjected,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              CurrencyText(
                                amount: GuestModeUtil.applyGuestMode(
                                  forecast.projectedNet,
                                  isGuestMode,
                                ),
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: forecast.projectedNet >= 0
                                      ? FinanceColors.incomeColor(
                                          Theme.of(context).brightness,
                                        )
                                      : FinanceColors.expenseColor(
                                          Theme.of(context).brightness,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Next 3 months
                        ...forecast.forecastMonths.map(
                          (m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM yyyy').format(m.month),
                                  style: textTheme.bodyMedium,
                                ),
                                Row(
                                  children: [
                                    CurrencyText(
                                      amount: GuestModeUtil.applyGuestMode(
                                        m.net,
                                        isGuestMode,
                                      ),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: m.isPositive
                                            ? FinanceColors.incomeColor(
                                                Theme.of(context).brightness,
                                              )
                                            : FinanceColors.expenseColor(
                                                Theme.of(context).brightness,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      m.isPositive
                                          ? LucideIcons.trendingUp
                                          : LucideIcons.trendingDown,
                                      size: 16,
                                      color: m.isPositive
                                          ? FinanceColors.incomeColor(
                                              Theme.of(context).brightness,
                                            )
                                          : FinanceColors.expenseColor(
                                              Theme.of(context).brightness,
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Summary
                        Center(
                          child: Text(
                            forecast.isPositive
                                ? AppLocalizations.of(context)!
                                    .analytics_savingOnAverage
                                : AppLocalizations.of(context)!
                                    .analytics_spendingExceedsIncome,
                            style: textTheme.bodySmall?.copyWith(
                              color: forecast.isPositive
                                  ? FinanceColors.incomeColor(
                                      Theme.of(context).brightness,
                                    )
                                  : FinanceColors.expenseColor(
                                      Theme.of(context).brightness,
                                    ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 16),

            // Tax Estimation
            taxAsync.when(
              data: (tax) =>
                  _buildTaxCard(tax, color, textTheme, isGuestMode, context),
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 16),
            // Category Trends
            categoryTrendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) return const SizedBox.shrink();
                final sortedTrends = trends.values.toList()
                  ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));

                return GestureDetector(
                  onTap: () => context.push(AppRoutes.spendingTrends),
                  child: Card(
                    elevation: 0,
                    color: color.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.layoutGrid,
                                color: color.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!
                                    .analytics_categoryTrends,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...sortedTrends.take(5).map(
                                (trend) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            trend.categoryName,
                                            style:
                                                textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              CurrencyText(
                                                amount: GuestModeUtil
                                                    .applyGuestMode(
                                                  trend.thisMonth,
                                                  isGuestMode,
                                                ),
                                                style: textTheme.titleSmall,
                                              ),
                                              if (trend.changePercent != 0) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  trend.changePercent > 0
                                                      ? LucideIcons.arrowUp
                                                      : LucideIcons.arrowDown,
                                                  size: 16,
                                                  color: trend.changePercent > 0
                                                      ? FinanceColors
                                                          .statusDanger
                                                      : FinanceColors
                                                          .statusGood,
                                                ),
                                                Text(
                                                  '${trend.changePercent.abs().toStringAsFixed(0)}%',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        trend.changePercent > 0
                                                            ? FinanceColors
                                                                .statusDanger
                                                            : FinanceColors
                                                                .statusGood,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        semanticsLabel: 'Progress',
                                        value: (trend.thisMonth /
                                                sortedTrends.first.thisMonth)
                                            .clamp(0.0, 1.0),
                                        backgroundColor:
                                            color.surfaceContainerHighest,
                                        color: color.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 16),

            // Spending by Day of Week
            spendingByDayAsync.when(
              data: (byDay) {
                final maxSpending = byDay.values.reduce(
                  (a, b) => a > b ? a : b,
                );
                if (maxSpending == 0) return const SizedBox.shrink();

                return Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              color: color.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!
                                  .analytics_spendingByDay,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxSpending * 1.2,
                              barTouchData: const BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final days = [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ];
                                      return Text(
                                        days[value.toInt()],
                                        style: textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _buildBarGroup(0, byDay['Mon']!, color.primary),
                                _buildBarGroup(1, byDay['Tue']!, color.primary),
                                _buildBarGroup(2, byDay['Wed']!, color.primary),
                                _buildBarGroup(3, byDay['Thu']!, color.primary),
                                _buildBarGroup(4, byDay['Fri']!, color.primary),
                                _buildBarGroup(5, byDay['Sat']!, color.primary),
                                _buildBarGroup(6, byDay['Sun']!, color.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const DashboardCardSkeleton(),
              error: (_, __) => const InlineError(),
            ),

            const SizedBox(height: 24),
            const AmbientBrandSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(color: color.onSurfaceVariant),
        ),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return FinanceColors.statusGood;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return FinanceColors.statusWarning;
    return FinanceColors.statusDanger;
  }

  Widget _buildTaxCard(
    TaxEstimate tax,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    BuildContext context,
  ) {
    final brightness = Theme.of(context).brightness;
    final ctxt = AppLocalizations.of(context)!;
    final taxColor =
        tax.isZeroTax ? FinanceColors.goodColor(brightness) : color.onSurface;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.taxEstimation),
      child: Card(
        elevation: 0,
        color: color.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tone.current.borderRadius),
          side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.landmark, color: color.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ctxt.tax_title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ctxt.tax_newRegime,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tax.financialYear,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      tax.isZeroTax
                          ? Text(
                              ctxt.tax_zeroTax,
                              style: textTheme.titleMedium?.copyWith(
                                color: taxColor,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : CurrencyText(
                              amount: GuestModeUtil.applyGuestMode(
                                tax.totalTax,
                                isGuestMode,
                              ),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: taxColor,
                              ),
                            ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        ctxt.tax_viewDetails,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: color.primary,
                      ),
                    ],
                  ),
                ],
              ),
              if (tax.isProjected) ...[
                const SizedBox(height: 8),
                Text(
                  ctxt.tax_projected,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
