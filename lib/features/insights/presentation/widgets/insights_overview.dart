import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/analytics_aggregates.dart';
import 'package:mudra_manager/features/insights/data/insights_provider.dart';
import 'package:mudra_manager/features/insights/domain/health_metrics.dart';
import 'package:mudra_manager/features/insights/domain/recommendation.dart';
import 'package:mudra_manager/features/insights/presentation/widgets/pattern_card.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

BoxDecoration _premiumPanelDecoration(
  ColorScheme color,
  AppSpacing spacing, {
  Color? accent,
}) {
  final edge = accent ?? color.primary;
  final isDark = color.brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.surfaceContainerHigh.withValues(alpha: isDark ? 0.72 : 0.92),
        color.surfaceContainerLow.withValues(alpha: isDark ? 0.92 : 1),
      ],
    ),
    borderRadius: BorderRadius.circular(spacing.radiusMedium),
    border: Border.all(color: edge.withValues(alpha: isDark ? 0.24 : 0.16)),
    boxShadow: [
      BoxShadow(
        color: edge.withValues(alpha: isDark ? 0.08 : 0.045),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: color.onSurface.withValues(alpha: 0.025),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

/// Visual narrative for the Insights screen.
///
/// The order is intentional: see money move, feel momentum, spot the biggest
/// category, understand health, then choose one next move.
class InsightsOverview extends ConsumerWidget {
  final InsightsData insights;
  final String periodKey;
  final ValueChanged<Recommendation>? onRecommendationTap;
  final VoidCallback? onPatternTap;

  const InsightsOverview({
    super.key,
    required this.insights,
    required this.periodKey,
    this.onRecommendationTap,
    this.onPatternTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final periodAggregates = ref.watch(analyticsAggregatesProvider(periodKey));
    final periodTransfers =
        ref.watch(analyticsTransferTransactionsProvider(periodKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Reveal(
          child: _MoneyFlowHero(
            insights: insights,
            periodAggregates: periodAggregates.asData?.value,
            transferTransactions: periodTransfers,
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        const _Reveal(
          delay: Duration(milliseconds: 80),
          child: _MomentumStory(),
        ),
        SizedBox(height: spacing.sectionGap),
        _Reveal(
          delay: const Duration(milliseconds: 140),
          child: _SpendingRhythm(periodKey: periodKey),
        ),
        SizedBox(height: spacing.sectionGap),
        _Reveal(
          delay: const Duration(milliseconds: 200),
          child: _HealthOrbit(metrics: insights.healthMetrics),
        ),
        if (insights.hiddenPatterns.isNotEmpty) ...[
          SizedBox(height: spacing.sectionGap),
          HiddenPatternsSection(
            patterns: insights.hiddenPatterns,
            onPatternTap: onPatternTap,
          ),
        ],
        if (insights.quickWins.isNotEmpty) ...[
          SizedBox(height: spacing.sectionGap),
          _Reveal(
            delay: const Duration(milliseconds: 300),
            child: _NextMove(
              recommendation: insights.quickWins.first,
              onTap: onRecommendationTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curve);
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _MoneyFlowHero extends StatefulWidget {
  final InsightsData insights;
  final AnalyticsAggregates? periodAggregates;
  final AsyncValue<List<Transaction>> transferTransactions;

  const _MoneyFlowHero({
    required this.insights,
    this.periodAggregates,
    required this.transferTransactions,
  });

  @override
  State<_MoneyFlowHero> createState() => _MoneyFlowHeroState();
}

class _MoneyFlowHeroState extends State<_MoneyFlowHero> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final aggregates = widget.periodAggregates ?? widget.insights.aggregates;
    final isIncome = _selectedTab == 1;
    final isTransfer = _selectedTab == 2;
    final reportBreakdown = isIncome
        ? aggregates.incomeCategoryBreakdown
        : aggregates.categoryBreakdown;
    final reportTotal =
        isIncome ? aggregates.totalIncome : aggregates.totalExpense;

    return Semantics(
      container: true,
      label:
          'Money Report. ${isTransfer ? 'Transfer' : isIncome ? 'Income' : 'Expenses'} report for the selected date range.',
      child: Container(
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: color.onSurface.withValues(alpha: 0.055),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVerticalMax,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StoryHeading(
              kicker: 'MONEY REPORT',
              title: 'Where money moved',
              icon: LucideIcons.chartNoAxesCombined,
            ),
            SizedBox(height: spacing.sectionGap),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(spacing.radiusLarge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ReportTab(
                      label: 'Expenses',
                      icon: LucideIcons.arrowUpRight,
                      selected: _selectedTab == 0,
                      onTap: () => _selectTab(0),
                    ),
                  ),
                  Expanded(
                    child: _ReportTab(
                      label: 'Income',
                      icon: LucideIcons.arrowDownLeft,
                      selected: _selectedTab == 1,
                      onTap: () => _selectTab(1),
                    ),
                  ),
                  Expanded(
                    child: _ReportTab(
                      label: 'Transfer',
                      icon: LucideIcons.arrowLeftRight,
                      selected: _selectedTab == 2,
                      onTap: () => _selectTab(2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            if (isTransfer)
              _TransferReportContent(
                transferTransactions: widget.transferTransactions,
              )
            else ...[
              Row(
                children: [
                  Text(
                    isIncome ? 'Income Report' : 'Expenses Report',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? LucideIcons.wallet : LucideIcons.pieChart,
                      size: spacing.iconSM,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 2),
              _ExpenseReportVisual(
                breakdown: reportBreakdown,
                totalExpense: reportTotal,
                color: color,
                textTheme: textTheme,
                reportLabel: isIncome ? 'Total Income' : 'Total Expenses',
                summaryLabel: isIncome ? 'All Income' : 'All Expenses',
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectTab(int tab) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = tab);
  }
}

class _ReportTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReportTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label report tab',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusLarge - 2),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.elementGapMin,
            vertical: spacing.elementGap,
          ),
          decoration: BoxDecoration(
            color: selected ? color.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(spacing.radiusLarge - 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.onSurface.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? color.onSurface : color.onSurfaceVariant,
              ),
              SizedBox(width: spacing.elementGapMin),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: selected ? color.onSurface : color.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
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

class _TransferReportContent extends StatelessWidget {
  final AsyncValue<List<Transaction>> transferTransactions;

  const _TransferReportContent({required this.transferTransactions});

  @override
  Widget build(BuildContext context) {
    return transferTransactions.when(
      data: (transfers) {
        if (transfers.isEmpty) return const _TransferReportEmpty();

        final color = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final breakdown = <String, double>{};
        for (final transfer in transfers) {
          final source =
              transfer.related.value?.account.value?.name ?? 'Source account';
          final destination =
              transfer.account.value?.name ?? 'Destination account';
          final label = '$source → $destination';
          breakdown[label] = (breakdown[label] ?? 0) + transfer.baseAmount;
        }
        final total = breakdown.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Transfer Report',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.arrowLeftRight,
                    size: context.readSpacing().iconSM,
                    color: color.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.readSpacing().elementGap * 2),
            _ExpenseReportVisual(
              breakdown: breakdown,
              totalExpense: total,
              color: color,
              textTheme: textTheme,
              reportLabel: 'Total Transfers',
              summaryLabel: 'All Transfers',
            ),
          ],
        );
      },
      loading: () => const _TransferReportLoading(),
      error: (_, __) => const _TransferReportEmpty(),
    );
  }
}

class _TransferReportLoading extends StatelessWidget {
  const _TransferReportLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 252,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TransferReportEmpty extends StatelessWidget {
  const _TransferReportEmpty();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 252,
      child: NoDataFound(
        message: 'No transaction present for selected period.',
        iconData: LucideIcons.arrowLeftRight,
      ),
    );
  }
}

class _ExpenseReportVisual extends StatefulWidget {
  final Map<String, double> breakdown;
  final double totalExpense;
  final ColorScheme color;
  final TextTheme textTheme;
  final String reportLabel;
  final String summaryLabel;

  const _ExpenseReportVisual({
    required this.breakdown,
    required this.totalExpense,
    required this.color,
    required this.textTheme,
    required this.reportLabel,
    required this.summaryLabel,
  });

  @override
  State<_ExpenseReportVisual> createState() => _ExpenseReportVisualState();
}

class _ExpenseReportVisualState extends State<_ExpenseReportVisual> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant _ExpenseReportVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breakdown != widget.breakdown ||
        oldWidget.totalExpense != widget.totalExpense) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final hasData = widget.totalExpense > 0 ||
        widget.breakdown.values.any((amount) => amount > 0);
    if (!hasData) {
      return const SizedBox(
        height: 252,
        child: NoDataFound(
          message: 'No transaction details found in selected date range.',
          iconData: LucideIcons.receiptText,
        ),
      );
    }

    final color = widget.color;
    final textTheme = widget.textTheme;
    final entries = widget.breakdown.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = entries.take(4).toList();
    final remainder = entries.skip(4).fold<double>(
          0,
          (sum, entry) => sum + entry.value,
        );
    if (remainder > 0) visible.add(MapEntry('Other', remainder));

    final values = visible.isEmpty
        ? [MapEntry(widget.summaryLabel, widget.totalExpense)]
        : visible;
    final palette = [
      ChartPalette.colors[4],
      ChartPalette.colors[0],
      ChartPalette.colors[2],
      ChartPalette.colors[3],
      ChartPalette.colors[6],
    ];
    final total = values.fold<double>(0, (sum, entry) => sum + entry.value);
    final topShare =
        total <= 0 ? 0.0 : (values.first.value / total).clamp(0.0, 1.0);
    final selected = _touchedIndex >= 0 && _touchedIndex < values.length
        ? values[_touchedIndex]
        : null;
    final selectedShare = selected == null || total <= 0
        ? 0.0
        : (selected.value / total).clamp(0.0, 1.0);
    final displayedShare = selected == null ? topShare : selectedShare;

    return Column(
      children: [
        SizedBox(
          height: 252,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 7,
                  centerSpaceRadius: 56,
                  sections: values.asMap().entries.map((entry) {
                    final isSelected = entry.key == _touchedIndex;
                    return PieChartSectionData(
                      value: entry.value.value,
                      color: palette[entry.key % palette.length],
                      radius: isSelected ? 94 : 88,
                      showTitle: false,
                    );
                  }).toList(),
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final nextIndex =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (nextIndex == _touchedIndex) return;
                      HapticFeedback.selectionClick();
                      setState(() => _touchedIndex = nextIndex);
                    },
                  ),
                ),
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
              if (selected != null)
                Align(
                  alignment: const Alignment(0.78, -0.18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.inverseSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CurrencyText(
                      amount: selected.value,
                      compact: true,
                      fixedLength: 0,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.onInverseSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 128,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: selected == null
                      ? [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.reportLabel,
                              maxLines: 1,
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CurrencyText(
                              amount: total,
                              compact: true,
                              fixedLength: 0,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ]
                      : [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              selected.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${(displayedShare * 100).toStringAsFixed(0)}%',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin / 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: CurrencyText(
                              amount: selected.value,
                              compact: true,
                              fixedLength: 0,
                              style: textTheme.labelMedium?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.elementGap * 2),
        Row(
          children: [
            Text(
              widget.summaryLabel,
              style: textTheme.titleSmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            CurrencyText(
              amount: total,
              compact: true,
              fixedLength: 0,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MomentumStory extends ConsumerWidget {
  const _MomentumStory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final forecastAsync = ref.watch(cashFlowForecastProvider);

    return forecastAsync.when(
      data: (forecast) {
        final income = _chronological(forecast.incomeHistory);
        final expense = _chronological(forecast.expenseHistory);
        final length = math.max(income.length, expense.length);
        if (length == 0) return const SizedBox.shrink();

        final incomeValues = _padValues(income, length);
        final expenseValues = _padValues(expense, length);
        final historyNet = List<double>.generate(
          length,
          (index) => incomeValues[index] - expenseValues[index],
        );
        final netValues = [
          ...historyNet,
          forecast.projectedNet,
          ...forecast.forecastMonths.map((month) => month.net),
        ];
        final maxMagnitude = netValues.fold<double>(
          1,
          (current, value) => math.max(current, value.abs()),
        );
        final minY = netValues.reduce(math.min);
        final maxY = netValues.reduce(math.max);
        final chartMinY = math.min(0.0, minY) - maxMagnitude * 0.12;
        final chartMaxY = math.max(0.0, maxY) + maxMagnitude * 0.12;
        final netColor = forecast.projectedNet >= 0
            ? FinanceColors.incomeColor(brightness)
            : FinanceColors.expenseColor(brightness);

        return Semantics(
          container: true,
          label:
              'Cash flow momentum. Expected net next month and three month outlook shown against six months of history.',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVerticalMax,
            ),
            decoration: _premiumPanelDecoration(color, spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoryHeading(
                  kicker: 'MOMENTUM',
                  title: 'Expected net next month',
                  icon: forecast.projectedNet >= 0
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
                  iconColor: netColor,
                ),
                SizedBox(height: spacing.elementGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CurrencyText(
                      amount: forecast.projectedNet,
                      showSign: true,
                      compact: true,
                      fixedLength: 0,
                      style: textTheme.headlineSmall?.copyWith(
                        color: netColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Padding(
                      padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                      child: Text(
                        'month-end projection',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.sectionGap),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (netValues.length - 1).toDouble(),
                      minY: chartMinY,
                      maxY: chartMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (chartMaxY - chartMinY) / 3,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: color.outlineVariant.withValues(alpha: 0.22),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final index = value.round();
                              if (index < 0 || index >= netValues.length) {
                                return const SizedBox.shrink();
                              }
                              final now = DateTime.now();
                              final month = index < length
                                  ? DateTime(
                                      now.year,
                                      now.month - length + index,
                                    )
                                  : DateTime(
                                      now.year,
                                      now.month + index - length,
                                    );
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(month),
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    color: index >= length
                                        ? color.primary
                                        : color.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      rangeAnnotations: RangeAnnotations(
                        verticalRangeAnnotations: [
                          VerticalRangeAnnotation(
                            x1: length.toDouble() - 0.5,
                            x2: (netValues.length - 1).toDouble(),
                            color: color.primary.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 0,
                            color: color.outlineVariant.withValues(alpha: 0.55),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        _line(
                          netValues,
                          netColor,
                          fill: true,
                          surface: color.surface,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing.elementGap),
                Row(
                  children: [
                    _LegendDot(color: netColor, label: 'net outlook'),
                    const Spacer(),
                    Text(
                      '3-mo avg',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    CurrencyText(
                      amount: forecast.avgMonthlyNet,
                      showSign: true,
                      compact: true,
                      fixedLength: 0,
                      style: textTheme.labelLarge?.copyWith(
                        color: forecast.isPositive
                            ? FinanceColors.incomeColor(brightness)
                            : FinanceColors.expenseColor(brightness),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  LineChartBarData _line(
    List<double> values,
    Color color, {
    required bool fill,
    required Color surface,
  }) {
    return LineChartBarData(
      spots: values
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: surface,
        ),
      ),
      belowBarData: BarAreaData(
        show: fill,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

class _SpendingRhythm extends ConsumerWidget {
  final String periodKey;

  const _SpendingRhythm({required this.periodKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final aggregatesAsync = ref.watch(analyticsAggregatesProvider(periodKey));

    Widget panel(Widget child) {
      return Semantics(
        container: true,
        label: 'Spending rhythm across weekdays in the selected period.',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVerticalMax,
          ),
          decoration: _premiumPanelDecoration(color, spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StoryHeading(
                kicker: 'SPENDING RHYTHM',
                title: 'When spending happens',
                icon: LucideIcons.calendarDays,
              ),
              SizedBox(height: spacing.sectionGap),
              child,
            ],
          ),
        ),
      );
    }

    return aggregatesAsync.when(
      data: (aggregates) {
        const weekdayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final entries = weekdayOrder
            .map(
              (day) => MapEntry(
                day,
                aggregates.spendingByDayOfWeek[day] ?? 0.0,
              ),
            )
            .toList();
        final total = entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value,
        );

        if (total <= 0) {
          return panel(
            const SizedBox(
              height: 168,
              child: NoDataFound(
                message: 'No spending activity found for selected period.',
                iconData: LucideIcons.calendarDays,
              ),
            ),
          );
        }

        final peak = entries.reduce(
          (current, next) => next.value > current.value ? next : current,
        );
        final maxValue = peak.value;
        final activeDays = entries.where((entry) => entry.value > 0).length;

        return panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peak spending day',
                          style: textTheme.labelMedium?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _weekdayName(peak.key),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$activeDays of 7 weekdays with spending',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CurrencyText(
                    amount: peak.value,
                    compact: true,
                    fixedLength: 0,
                    style: textTheme.titleMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.sectionGap),
              SizedBox(
                height: 168,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: entries.map((entry) {
                    final factor = (entry.value / maxValue).clamp(0.0, 1.0);
                    final isPeak = entry.key == peak.key;
                    final share = entry.value / total;

                    return Expanded(
                      child: Semantics(
                        container: true,
                        label:
                            '${_weekdayName(entry.key)}, ${(share * 100).toStringAsFixed(0)} percent of spending',
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.elementGapMin / 2,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: factor.toDouble(),
                                    widthFactor: isPeak ? 0.72 : 0.56,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isPeak
                                            ? color.primary
                                            : color.primary.withValues(
                                                alpha: 0.28,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.key,
                                style: textTheme.labelSmall?.copyWith(
                                  color: isPeak
                                      ? color.primary
                                      : color.onSurfaceVariant,
                                  fontWeight: isPeak
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(share * 100).toStringAsFixed(0)}%',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => panel(
        Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == 3 ? 0 : spacing.elementGap + 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 90 + index * 18,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => panel(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text(
            'Spending rhythm is unavailable right now.',
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _weekdayName(String shortName) {
    return switch (shortName) {
      'Mon' => 'Monday',
      'Tue' => 'Tuesday',
      'Wed' => 'Wednesday',
      'Thu' => 'Thursday',
      'Fri' => 'Friday',
      'Sat' => 'Saturday',
      'Sun' => 'Sunday',
      _ => shortName,
    };
  }
}

class _HealthOrbit extends StatelessWidget {
  final HealthMetrics metrics;

  const _HealthOrbit({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final healthColor = metrics.ratingColor(context);
    final values = [
      metrics.savingsHealth,
      metrics.incomeStability,
      metrics.emergencyFund,
      metrics.debtHealth,
      metrics.budgetAdherence,
    ];

    return Semantics(
      container: true,
      label:
          'Financial health ${metrics.overallScore.toStringAsFixed(0)} out of 100, ${metrics.rating}.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.cardHorizontal,
          vertical: spacing.cardVerticalMax,
        ),
        decoration: _premiumPanelDecoration(color, spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StoryHeading(
              kicker: 'THE BIG PICTURE',
              title: 'Financial health',
              icon: LucideIcons.activity,
            ),
            SizedBox(height: spacing.sectionGap),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final orbit = _healthOrb(
                  metrics: metrics,
                  values: values,
                  healthColor: healthColor,
                  color: color,
                  textTheme: textTheme,
                );
                final signals = _healthSignals(values, healthColor, spacing);

                if (compact) {
                  return Column(
                    children: [
                      orbit,
                      SizedBox(height: spacing.sectionGap),
                      signals,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    orbit,
                    SizedBox(width: spacing.sectionGap),
                    Expanded(child: signals),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthOrb({
    required HealthMetrics metrics,
    required List<HealthScoreBreakdown> values,
    required Color healthColor,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return SizedBox(
      width: 204,
      height: 204,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(204),
            painter: _HealthOrbitPainter(
              values: values.map((value) => value.percentage).toList(),
              color: healthColor,
              gridColor: color.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${metrics.overallScore.toStringAsFixed(0)} / 100',
                style: textTheme.headlineSmall?.copyWith(
                  color: healthColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                metrics.rating,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthSignals(
    List<HealthScoreBreakdown> values,
    Color healthColor,
    AppSpacing spacing,
  ) {
    return Column(
      children: values
          .map(
            (value) => Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap),
              child: _HealthSignal(
                metric: value,
                healthColor: healthColor,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HealthSignal extends StatelessWidget {
  final HealthScoreBreakdown metric;
  final Color healthColor;

  const _HealthSignal({required this.metric, required this.healthColor});

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final signalColor = metric.isCritical
        ? FinanceColors.expenseColor(brightness)
        : metric.isWarning
            ? FinanceColors.statusWarning
            : healthColor;
    final statusLabel = metric.isHealthy
        ? 'Healthy'
        : metric.isWarning
            ? 'Watch'
            : 'Needs attention';
    final statusIcon = metric.isHealthy
        ? LucideIcons.circleCheck
        : metric.isWarning
            ? LucideIcons.triangleAlert
            : LucideIcons.circleAlert;

    return Semantics(
      container: true,
      label:
          '${metric.label}: ${metric.score.toStringAsFixed(0)} out of 100. ${metric.description}. Status: $statusLabel.',
      child: Column(
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
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: signalColor),
                      const SizedBox(width: 3),
                      Semantics(
                        button: true,
                        label:
                            'Learn more about ${metric.label} and what to do next',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showHealthDetails(
                              context,
                              signalColor,
                              statusLabel,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              child: Text(
                                statusLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: signalColor,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
                                      decorationColor: signalColor,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${metric.score.toStringAsFixed(0)} / 100',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: signalColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.elementGapMin),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metric.percentage.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              backgroundColor: color.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(signalColor),
              semanticsLabel: metric.label,
              semanticsValue: '${metric.score.toStringAsFixed(0)} out of 100',
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthDetails(
    BuildContext context,
    Color signalColor,
    String statusLabel,
  ) {
    HapticFeedback.lightImpact();
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusIcon = metric.isHealthy
        ? LucideIcons.circleCheck
        : metric.isWarning
            ? LucideIcons.triangleAlert
            : LucideIcons.circleAlert;
    final reasonTitle =
        metric.isHealthy ? 'Why this is healthy' : 'Why this needs attention';
    Widget detailBlock({
      required IconData icon,
      required String title,
      required String body,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(icon, size: 16, color: color.primary),
          ),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: color.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(spacing.radiusMedium + 4),
            ),
            border: Border.all(
              color: signalColor.withValues(alpha: 0.22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardInner,
                spacing.elementGap,
                spacing.cardInner,
                spacing.cardInner,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: signalColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          statusIcon,
                          color: signalColor,
                          size: spacing.iconSM,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.label,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$statusLabel · ${metric.score.toStringAsFixed(0)} / 100',
                              style: textTheme.bodySmall?.copyWith(
                                color: signalColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.sectionGap),
                  Divider(color: color.outlineVariant.withValues(alpha: 0.3)),
                  SizedBox(height: spacing.sectionGap),
                  detailBlock(
                    icon: LucideIcons.search,
                    title: reasonTitle,
                    body: metric.description,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  detailBlock(
                    icon: LucideIcons.arrowRight,
                    title: 'What you can do next',
                    body: metric.tip ?? _nextStep(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _nextStep() {
    return switch (metric.label) {
      'Savings Rate' => metric.isHealthy
          ? 'Keep building this buffer and review your target as income changes.'
          : 'Work toward saving at least 20% of income when possible.',
      'Income Stability' => metric.isHealthy
          ? 'Keep a buffer for months when income varies.'
          : 'Check whether your income reliably covers spending in this period.',
      'Emergency Fund' => metric.isHealthy
          ? 'Keep building toward 3-6 months of essential expenses.'
          : 'Build toward 3-6 months of essential expenses over time.',
      'Debt Health' => metric.isHealthy
          ? 'Keep balances manageable and review interest rates periodically.'
          : 'Review high-interest balances and choose one payoff target.',
      'Budget Discipline' => metric.isHealthy
          ? 'Keep checking planned spending before adding new expenses.'
          : 'Compare planned spending with income before adding new expenses.',
      _ => metric.isHealthy
          ? 'Keep this habit going and review it as your situation changes.'
          : 'Review this area and choose one small improvement to start today.',
    };
  }
}

class _HealthOrbitPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;

  const _HealthOrbitPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.42;
    final points = <Offset>[];
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;

    for (var ring = 1; ring <= 3; ring++) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final point = _point(center, radius * ring / 3, i);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < values.length; i++) {
      final outer = _point(center, radius, i);
      canvas.drawLine(center, outer, gridPaint);
      points.add(_point(center, radius * values[i].clamp(0.0, 1.0), i));
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.20);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;
    final dataPath = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        dataPath.moveTo(points[i].dx, points[i].dy);
      } else {
        dataPath.lineTo(points[i].dx, points[i].dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fill);
    canvas.drawPath(dataPath, stroke);

    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }
  }

  Offset _point(Offset center, double radius, int index) {
    final angle = -math.pi / 2 + (math.pi * 2 * index / values.length);
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthOrbitPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor;
  }
}

class _NextMove extends StatelessWidget {
  final Recommendation recommendation;
  final ValueChanged<Recommendation>? onTap;

  const _NextMove({required this.recommendation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label:
          'Next best move: ${recommendation.title}. Opens guidance about why it matters and how to start.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: _premiumPanelDecoration(
            color,
            spacing,
            accent: recommendation.iconColor,
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showGuidance(context);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVerticalMax,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: recommendation.iconColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      recommendation.icon,
                      color: recommendation.iconColor,
                      size: spacing.iconMD,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXT MOVE',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          recommendation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: spacing.elementGapMin),
                        Text(
                          recommendation.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        if (recommendation.subtitle != null) ...[
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            recommendation.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: recommendation.iconColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'See how',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(LucideIcons.arrowRight, color: color.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGuidance(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final guidance = _guidanceFor(recommendation);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
          ),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(spacing.radiusMedium + 4),
            ),
            border: Border.all(
              color: recommendation.iconColor.withValues(alpha: 0.22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.cardHorizontal,
                spacing.elementGap,
                spacing.cardHorizontal,
                spacing.cardVertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              recommendation.iconColor.withValues(alpha: 0.13),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          recommendation.icon,
                          color: recommendation.iconColor,
                          size: spacing.iconMD,
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXT MOVE',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: spacing.elementGapMin),
                            Text(
                              recommendation.title,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: spacing.elementGapMin),
                            Text(
                              recommendation.description,
                              style: textTheme.bodyMedium?.copyWith(
                                color: color.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (recommendation.subtitle != null) ...[
                    SizedBox(height: spacing.elementGap),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      decoration: BoxDecoration(
                        color: recommendation.iconColor.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                        border: Border.all(
                          color:
                              recommendation.iconColor.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        recommendation.subtitle!,
                        style: textTheme.labelLarge?.copyWith(
                          color: recommendation.iconColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: spacing.sectionGap),
                  Divider(color: color.outlineVariant.withValues(alpha: 0.35)),
                  SizedBox(height: spacing.sectionGap),
                  _GuidanceBlock(
                    title: 'Why it matters',
                    icon: LucideIcons.lightbulb,
                    color: recommendation.iconColor,
                    body: guidance.why,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  Text(
                    'How to start',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  ...guidance.steps.asMap().entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(bottom: spacing.elementGap),
                          child: _GuidanceStep(
                            number: entry.key + 1,
                            text: entry.value,
                            color: recommendation.iconColor,
                          ),
                        ),
                      ),
                  SizedBox(height: spacing.elementGap),
                  _GuidanceBlock(
                    title: 'What success looks like',
                    icon: LucideIcons.checkCircle2,
                    color: color.primary,
                    body: guidance.outcome,
                  ),
                  if (onTap != null &&
                      recommendation.id != 'review_category') ...[
                    SizedBox(height: spacing.sectionGap),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(sheetContext).pop();
                          if (context.mounted) {
                            onTap!.call(recommendation);
                          }
                        },
                        icon: const Icon(LucideIcons.arrowUpRight),
                        label: Text(recommendation.actionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GuidanceBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String body;

  const _GuidanceBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: spacing.iconSM, color: color),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: spacing.elementGapMin),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuidanceStep extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _GuidanceStep({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final textTheme = Theme.of(context).textTheme;
    final surface = Theme.of(context).colorScheme.surfaceContainerLow;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationGuidance {
  final String why;
  final List<String> steps;
  final String outcome;

  const _RecommendationGuidance({
    required this.why,
    required this.steps,
    required this.outcome,
  });
}

_RecommendationGuidance _guidanceFor(Recommendation recommendation) {
  return switch (recommendation.id) {
    'boost_savings' => const _RecommendationGuidance(
        why:
            'A small, repeatable saving habit gives your income a job before discretionary spending begins.',
        steps: [
          'Choose an amount you can repeat every payday. Start small if your cash flow is tight.',
          'Create a dedicated budget or savings target for that amount.',
          'Check the target after your first month and increase it only when the habit feels comfortable.',
        ],
        outcome:
            'Your savings rate becomes more consistent and your next month starts with a clearer plan.',
      ),
    'reduce_spending' => const _RecommendationGuidance(
        why:
            'Your projection is ahead of income, so a small change now can prevent a larger month-end shortfall.',
        steps: [
          'Review the trend and identify the one or two categories driving the increase.',
          'Pause non-essential spending in those categories until the forecast returns below income.',
          'Set a weekly limit and review it once midweek instead of waiting for month end.',
        ],
        outcome:
            'Your projected spending moves closer to income and decisions become easier before money is spent.',
      ),
    'review_category' => const _RecommendationGuidance(
        why:
            'One category is taking a large share of spending, so it is the clearest place to look for flexibility.',
        steps: [
          'Review recent transactions in this category and separate essentials from optional purchases.',
          'Pick one recurring expense or habit to reduce for the next month.',
          'Set a category limit and compare actual spending with it each week.',
        ],
        outcome:
            'You gain a realistic category target without needing to cut every type of spending at once.',
      ),
    _ => switch (recommendation.category) {
        RecommendationCategory.savings => const _RecommendationGuidance(
            why:
                'A repeatable savings action strengthens your financial buffer over time.',
            steps: [
              'Choose a realistic amount to save regularly.',
              'Create a target and track progress after each payday.',
              'Review the amount monthly and adjust when your income changes.',
            ],
            outcome:
                'Saving becomes a visible, repeatable part of your monthly plan.',
          ),
        RecommendationCategory.budgeting => const _RecommendationGuidance(
            why:
                'A clear limit makes spending decisions easier before the budget is stretched.',
            steps: [
              'Review recent spending and find the largest controllable area.',
              'Set a limit that fits your current income.',
              'Check progress weekly and adjust early if needed.',
            ],
            outcome:
                'Your plan stays closer to income and surprises become easier to manage.',
          ),
        RecommendationCategory.subscription => const _RecommendationGuidance(
            why:
                'Recurring payments can quietly reduce the money available for current priorities.',
            steps: [
              'List active subscriptions and note the next payment date.',
              'Mark services you rarely use or can replace.',
              'Cancel or pause one service and review the total again next month.',
            ],
            outcome:
                'Your recurring commitments better match what you use and value.',
          ),
        _ => const _RecommendationGuidance(
            why:
                'A focused review turns this insight into one practical decision.',
            steps: [
              'Open the related details and confirm what is changing.',
              'Choose one small action you can complete this week.',
              'Review the result next month and keep what works.',
            ],
            outcome:
                'You move from awareness to a measurable next step without overhauling everything.',
          ),
      },
  };
}

class _StoryHeading extends StatelessWidget {
  final String kicker;
  final String title;
  final IconData icon;
  final Color? iconColor;

  const _StoryHeading({
    required this.kicker,
    required this.title,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.readSpacing();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconColor = iconColor ?? color.primary;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveIconColor.withValues(alpha: 0.20),
                effectiveIconColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            border: Border.all(
              color: effectiveIconColor.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, size: spacing.iconSM, color: effectiveIconColor),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<double> _chronological(List<double> values) => values.reversed.toList();

List<double> _padValues(List<double> values, int length) {
  if (values.length == length) return values;
  return [
    ...List<double>.filled(length - values.length, 0),
    ...values,
  ];
}

extension on BuildContext {
  AppSpacing readSpacing() =>
      ProviderScope.containerOf(this).read(spacingProvider);
}
