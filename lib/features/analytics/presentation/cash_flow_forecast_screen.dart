import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class CashFlowForecastScreen extends ConsumerWidget {
  const CashFlowForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.analytics_cashFlowTitle),
        elevation: 0,
      ),
      body: forecastAsync.when(
        data: (forecast) => ListView(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          children: [
            _buildCurrentMonthCard(
              forecast, color, textTheme, spacing, brightness, isGuestMode, ctxt,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildTrendChart(
              forecast, color, textTheme, spacing, brightness, ctxt,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildForecastTable(
              forecast, color, textTheme, spacing, brightness, isGuestMode, ctxt,
            ),
            SizedBox(height: spacing.sectionGap),
            _buildSummaryCard(
              forecast, color, textTheme, spacing, brightness, isGuestMode, ctxt,
            ),
            SizedBox(height: spacing.sectionGap * 3),
          ],
        ),
        loading: () => const Center(child: DashboardCardSkeleton()),
        error: (_, __) => const InlineError(),
      ),
    );
  }

  Widget _buildCurrentMonthCard(
    CashFlowForecast f,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    bool isGuestMode,
    AppLocalizations ctxt,
  ) {
    final incomeColor = FinanceColors.incomeColor(brightness);
    final expenseColor = FinanceColors.expenseColor(brightness);

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
              Icon(LucideIcons.calendarDays, size: 18, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(ctxt.analytics_currentMonth,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),),
            ],),
            SizedBox(height: spacing.sectionGap),
            Row(children: [
              Expanded(child: _statColumn(
                ctxt.analytics_income,
                GuestModeUtil.applyGuestMode(f.currentMonthIncome, isGuestMode),
                incomeColor, textTheme,
              ),),
              Expanded(child: _statColumn(
                ctxt.analytics_expense,
                GuestModeUtil.applyGuestMode(f.currentMonthExpense, isGuestMode),
                expenseColor, textTheme,
              ),),
              Expanded(child: _statColumn(
                ctxt.analytics_net,
                GuestModeUtil.applyGuestMode(f.currentNet, isGuestMode),
                f.currentNet >= 0 ? incomeColor : expenseColor, textTheme,
              ),),
            ],),
            SizedBox(height: spacing.sectionGap),
            Divider(color: color.outlineVariant.withValues(alpha: 0.3)),
            SizedBox(height: spacing.elementGap),
            Row(children: [
              Text(ctxt.analytics_projected,
                  style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),),
              const Spacer(),
              CurrencyText(
                amount: GuestModeUtil.applyGuestMode(f.projectedNet, isGuestMode),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: f.projectedNet >= 0 ? incomeColor : expenseColor,
                ),
              ),
            ],),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, double amount, Color accent, TextTheme textTheme) {
    return Column(children: [
      Text(label, style: textTheme.bodySmall),
      const SizedBox(height: 4),
      CurrencyText(
        amount: amount,
        fixedLength: 0,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700, color: accent,
        ),
      ),
    ],);
  }

  Widget _buildTrendChart(
    CashFlowForecast f,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    AppLocalizations ctxt,
  ) {
    final incomeColor = FinanceColors.incomeColor(brightness);
    final expenseColor = FinanceColors.expenseColor(brightness);

    // Build spots: 6 history months + 3 forecast months
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < f.incomeHistory.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), f.incomeHistory[i]));
      expenseSpots.add(FlSpot(i.toDouble(), f.expenseHistory[i]));
    }
    for (int i = 0; i < f.forecastMonths.length; i++) {
      final x = (f.incomeHistory.length + i).toDouble();
      incomeSpots.add(FlSpot(x, f.forecastMonths[i].income));
      expenseSpots.add(FlSpot(x, f.forecastMonths[i].expense));
    }

    final allValues = [
      ...f.incomeHistory, ...f.expenseHistory,
      ...f.forecastMonths.map((m) => m.income),
      ...f.forecastMonths.map((m) => m.expense),
    ];
    final maxY = allValues.isEmpty ? 100.0 : allValues.reduce((a, b) => a > b ? a : b) * 1.15;

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
              Icon(LucideIcons.chartLine, size: 18, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(ctxt.analytics_monthlyNet,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),),
            ],),
            SizedBox(height: spacing.sectionGap),
            // Legend
            Row(children: [
              _legendDot(incomeColor, ctxt.analytics_income, textTheme),
              SizedBox(width: spacing.sectionGap),
              _legendDot(expenseColor, ctxt.analytics_expense, textTheme),
            ],),
            SizedBox(height: spacing.elementGap),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: color.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      final now = DateTime.now();
                      // History is newest-first (index 0 = most recent), chart is left-to-right
                      final monthOffset = f.incomeHistory.length - 1 - i;
                      final month = (monthOffset >= 0)
                          ? DateTime(now.year, now.month - monthOffset)
                          : DateTime(now.year, now.month + (i - f.incomeHistory.length + 1));
                      return Text(
                        DateFormat('MMM').format(month),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: i >= f.incomeHistory.length
                              ? color.primary
                              : color.onSurfaceVariant,
                        ),
                      );
                    },
                  ),),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                // Forecast zone
                rangeAnnotations: RangeAnnotations(
                  verticalRangeAnnotations: [
                    VerticalRangeAnnotation(
                      x1: f.incomeHistory.length.toDouble() - 0.5,
                      x2: (f.incomeHistory.length + f.forecastMonths.length).toDouble(),
                      color: color.primary.withValues(alpha: 0.04),
                    ),
                  ],
                ),
                lineBarsData: [
                  _buildLine(incomeSpots, incomeColor, f.incomeHistory.length),
                  _buildLine(expenseSpots, expenseColor, f.incomeHistory.length),
                ],
              ),),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color lineColor, int historyLen) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: lineColor,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: lineColor.withValues(alpha: 0.08),
      ),
      dashArray: null,
    );
  }

  Widget _legendDot(Color c, String label, TextTheme textTheme) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: textTheme.labelSmall),
    ],);
  }

  Widget _buildForecastTable(
    CashFlowForecast f,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    bool isGuestMode,
    AppLocalizations ctxt,
  ) {
    final incomeColor = FinanceColors.incomeColor(brightness);
    final expenseColor = FinanceColors.expenseColor(brightness);

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
              Icon(LucideIcons.table, size: 18, color: color.primary),
              SizedBox(width: spacing.elementGap),
              Text(ctxt.analytics_forecast3Month,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),),
            ],),
            SizedBox(height: spacing.sectionGap),
            // Header
            Row(children: [
              Expanded(flex: 3, child: Text('', style: textTheme.labelSmall)),
              Expanded(flex: 3, child: Text(ctxt.analytics_income,
                  style: textTheme.labelSmall?.copyWith(color: incomeColor), textAlign: TextAlign.end,),),
              Expanded(flex: 3, child: Text(ctxt.analytics_expense,
                  style: textTheme.labelSmall?.copyWith(color: expenseColor), textAlign: TextAlign.end,),),
              Expanded(flex: 3, child: Text(ctxt.analytics_net,
                  style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.end,),),
            ],),
            SizedBox(height: spacing.elementGap),
            ...f.forecastMonths.map((m) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: Row(children: [
                Expanded(flex: 3, child: Text(
                  DateFormat('MMM yy').format(m.month),
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),),
                Expanded(flex: 3, child: CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(m.income, isGuestMode),
                  fixedLength: 0, compact: true,
                  style: textTheme.bodySmall?.copyWith(color: incomeColor),
                  textAlign: TextAlign.end,
                ),),
                Expanded(flex: 3, child: CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(m.expense, isGuestMode),
                  fixedLength: 0, compact: true,
                  style: textTheme.bodySmall?.copyWith(color: expenseColor),
                  textAlign: TextAlign.end,
                ),),
                Expanded(flex: 3, child: CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(m.net, isGuestMode),
                  fixedLength: 0, compact: true,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: m.isPositive ? incomeColor : expenseColor,
                  ),
                  textAlign: TextAlign.end,
                ),),
              ],),
            ),),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    CashFlowForecast f,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    Brightness brightness,
    bool isGuestMode,
    AppLocalizations ctxt,
  ) {
    final netColor = f.isPositive
        ? FinanceColors.incomeColor(brightness)
        : FinanceColors.expenseColor(brightness);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: netColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: netColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(
          f.isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          color: netColor, size: 24,
        ),
        SizedBox(width: spacing.elementGap * 1.5),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctxt.analytics_avgMonthlyNet,
                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),),
            CurrencyText(
              amount: GuestModeUtil.applyGuestMode(f.avgMonthlyNet, isGuestMode),
              fixedLength: 0,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, color: netColor,
              ),
            ),
          ],
        ),),
        Icon(
          f.isPositive ? LucideIcons.circleCheck : LucideIcons.circleAlert,
          color: netColor, size: 20,
        ),
      ],),
    );
  }
}
