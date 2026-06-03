import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/advanced_analytics_service.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class SpendingTrendsScreen extends ConsumerWidget {
  const SpendingTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final trendsAsync = ref.watch(categoryTrendsProvider);
    final risingAsync = ref.watch(risingCategoriesProvider);
    final anomalyAsync = ref.watch(anomalyCategoriesProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.analytics_spendingTrendsTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: trendsAsync.when(
        data: (trends) {
          if (trends.isEmpty) {
            return Center(child: Text(ctxt.analytics_noTrendData));
          }

          final sorted = trends.values.toList()
            ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // Anomalies
              anomalyAsync.maybeWhen(
                data: (anomalies) => anomalies.isNotEmpty
                    ? _buildSection(
                        ctxt.analytics_anomalyCategories,
                        LucideIcons.triangleAlert,
                        FinanceColors.statusDanger,
                        anomalies, color, textTheme, spacing, isGuestMode, ctxt,
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // Rising
              risingAsync.maybeWhen(
                data: (rising) => rising.isNotEmpty
                    ? _buildSection(
                        ctxt.analytics_risingCategories,
                        LucideIcons.trendingUp,
                        FinanceColors.statusWarning,
                        rising, color, textTheme, spacing, isGuestMode, ctxt,
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // All categories
              _buildAllCategories(
                sorted, color, textTheme, spacing, isGuestMode, ctxt,
              ),
              SizedBox(height: spacing.sectionGap * 3),
            ],
          );
        },
        loading: () => const Center(child: DashboardCardSkeleton()),
        error: (_, __) => const InlineError(),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color accent,
    List<CategoryTrend> items,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isGuestMode,
    AppLocalizations ctxt,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: accent),
                SizedBox(width: spacing.elementGap),
                Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],),
              SizedBox(height: spacing.sectionGap),
              ...items.map((t) => _buildTrendRow(t, color, textTheme, spacing, isGuestMode, ctxt: ctxt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendRow(
    CategoryTrend trend,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isGuestMode, {
    AppLocalizations? ctxt,
  }) {
    final changeColor = trend.changePercent > 0
        ? FinanceColors.statusDanger
        : trend.changePercent < 0
            ? FinanceColors.statusGood
            : color.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trend.categoryName,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),),
                  if (trend.isAnomaly)
                    Container(
                      margin: EdgeInsets.only(top: spacing.elementGapUltraMin),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: FinanceColors.statusDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('⚠ Anomaly',
                          style: textTheme.labelSmall?.copyWith(
                            color: FinanceColors.statusDanger, fontSize: 10,
                          ),),
                    ),
                ],
              ),
            ),
            // Sparkline
            SizedBox(
              width: 60,
              height: 24,
              child: _buildSparkline(trend.monthlyHistory, color),
            ),
            SizedBox(width: spacing.elementGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(trend.thisMonth, isGuestMode),
                  fixedLength: 0, compact: true,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (trend.changePercent != 0)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      trend.changePercent > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                      size: 12, color: changeColor,
                    ),
                    Text(
                      '${trend.changePercent.abs().toStringAsFixed(0)}%',
                      style: textTheme.labelSmall?.copyWith(color: changeColor),
                    ),
                  ],),
              ],
            ),
          ],),
          // Predicted next month
          if (trend.predictedNextMonth > 0)
            Padding(
              padding: EdgeInsets.only(top: spacing.elementGapMin),
              child: Row(children: [
                Icon(LucideIcons.sparkles, size: 12, color: color.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                if (ctxt != null)
                  Text(
                    ctxt.analytics_predictedNextMonth,
                    style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
                  ),
                const SizedBox(width: 4),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(trend.predictedNextMonth, isGuestMode),
                  fixedLength: 0, compact: true,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.primary, fontWeight: FontWeight.w600,
                  ),
                ),
              ],),
            ),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> history, ColorScheme color) {
    if (history.isEmpty) return const SizedBox.shrink();
    // history is newest-first, reverse for left-to-right
    final reversed = history.reversed.toList();
    final maxVal = reversed.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    final spots = reversed
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(LineChartData(
      maxY: maxVal * 1.1,
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
          color: color.primary.withValues(alpha: 0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.primary.withValues(alpha: 0.06),
          ),
        ),
      ],
    ),);
  }

  Widget _buildAllCategories(
    List<CategoryTrend> sorted,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isGuestMode,
    AppLocalizations ctxt,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LucideIcons.layers, size: 18, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(ctxt.analytics_allCategories,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),),
            ],),
            SizedBox(height: spacing.sectionGap),
            ...sorted.map((t) => _buildTrendRow(t, color, textTheme, spacing, isGuestMode, ctxt: ctxt)),
          ],
        ),
      ),
    );
  }
}
