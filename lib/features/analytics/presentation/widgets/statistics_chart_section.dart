import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/domain/narrative_fact.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:visibility_detector/visibility_detector.dart';

class StatisticsChartSection extends ConsumerStatefulWidget {
  final String periodKey;
  const StatisticsChartSection({super.key, required this.periodKey});

  @override
  ConsumerState<StatisticsChartSection> createState() =>
      _StatisticsChartSectionState();
}

class _StatisticsChartSectionState
    extends ConsumerState<StatisticsChartSection> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stats_trends,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacing.sectionGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
          child: Column(
            children: [
              // Tab Switcher
              Padding(
                padding: EdgeInsets.all(spacing.elementGap),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        l10n.stats_12MonthTrend,
                        0,
                        color,
                        textTheme,
                        spacing,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildTabButton(
                        l10n.stats_spendingByDay,
                        1,
                        color,
                        textTheme,
                        spacing,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Content
              Padding(
                padding: EdgeInsets.all(spacing.sectionGap),
                child: _selectedTab == 0
                    ? _build12MonthChart(color, textTheme, spacing)
                    : _buildSpendingByDayChart(color, textTheme, spacing),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
        decoration: BoxDecoration(
          color: isSelected ? color.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected ? color.onPrimaryContainer : color.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _build12MonthChart(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final chartAsync = ref.watch(analyticsChartProvider(widget.periodKey));
    final l10n = AppLocalizations.of(context)!;

    return chartAsync.when(
      data: (aggregates) {
        final categoryData = aggregates.monthlyExpenseTrends;
        if (categoryData.isEmpty) {
          return SizedBox(
            height: 200,
            child: NoDataFound(
              message: BuddyMessages.noTransactions,
              iconData: LucideIcons.chartBar,
            ),
          );
        }
        final sortedCategories = categoryData.entries.toList()
          ..sort(
            (a, b) => b.value
                .reduce((a, b) => a + b)
                .compareTo(a.value.reduce((a, b) => a + b)),
          );

        // Derive narrative using facts from aggregates
        final facts = ref
                .watch(analyticsNarrativeFactsProvider(widget.periodKey))
                .value ??
            [];
        final trendFact = facts.whereType<TopCategoryFact>().firstOrNull;

        final insight = trendFact != null
            ? NarrativeMapper.map(
                trendFact,
                l10n,
                Theme.of(context).brightness,
                color,
              )
            : null;

        final chartColors = ChartPalette.colors;
        final topCats = sortedCategories.take(3).toList();

        return Column(
          children: [
            // Inline legend
            Wrap(
              spacing: spacing.elementGap,
              runSpacing: spacing.elementGapMin,
              children: topCats.asMap().entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: chartColors[entry.key % chartColors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      entry.value.key,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: spacing.elementGap),
            // Tap to expand
            GestureDetector(
              onTap: () => _showFullScreenChart(
                context,
                sortedCategories,
                chartColors,
                color,
                textTheme,
                spacing,
              ),
              child: RepaintBoundary(
                child: _ChartOnVisible(
                  height: 200,
                  zeroChild: _MonthlyTrendChart(
                    sortedCategories: sortedCategories
                        .map(
                          (e) => MapEntry(
                            e.key,
                            List<double>.filled(e.value.length, 0),
                          ),
                        )
                        .toList(),
                    maxCategories: 4,
                  ),
                  child: _MonthlyTrendChart(
                    sortedCategories: sortedCategories,
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.elementGapMin),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showFullScreenChart(
                  context,
                  sortedCategories,
                  chartColors,
                  color,
                  textTheme,
                  spacing,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.elementGap,
                    vertical: spacing.elementGapMin,
                  ),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.expand,
                        size: 12,
                        color: color.onSurfaceVariant,
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        'Expand',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (insight != null) ...[
              SizedBox(height: spacing.elementGap),
              _chartInsight(
                insight.text,
                insight.icon,
                insight.color,
                color,
                textTheme,
                spacing,
              ),
            ],
          ],
        );
      },
      loading: () => SizedBox(
        height: 200,
        child: Center(
          child: SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 200,
        child: Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Widget _buildSpendingByDayChart(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final chartAsync = ref.watch(analyticsChartProvider(widget.periodKey));
    final l10n = AppLocalizations.of(context)!;

    return chartAsync.when(
      data: (aggregates) {
        final byDay = aggregates.spendingByDayOfWeek;
        final maxSpending = byDay.values.isNotEmpty
            ? byDay.values.reduce((a, b) => a > b ? a : b)
            : 0.0;

        if (maxSpending == 0) {
          return SizedBox(
            height: 200,
            child: NoDataFound(
              message: BuddyMessages.noTransactions,
              iconData: LucideIcons.chartBar,
            ),
          );
        }

        // Derive pattern narrative
        final facts = ref
                .watch(analyticsNarrativeFactsProvider(widget.periodKey))
                .value ??
            [];
        final patternFact = facts
            .where((f) => f is WeekendPeakFact || f is WeekdayPeakFact)
            .firstOrNull;

        final insight = patternFact != null
            ? NarrativeMapper.map(
                patternFact,
                l10n,
                Theme.of(context).brightness,
                color,
              )
            : null;

        return Column(
          children: [
            _ChartOnVisible(
              height: 200,
              zeroChild: BarChart(
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
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
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
                  barGroups: List.generate(
                    7,
                    (i) => _buildBarGroup(
                      i,
                      0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
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
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  color.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
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
                    _buildBarGroup(
                      0,
                      byDay['Mon'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      1,
                      byDay['Tue'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      2,
                      byDay['Wed'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      3,
                      byDay['Thu'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      4,
                      byDay['Fri'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      5,
                      byDay['Sat'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      6,
                      byDay['Sun'] ?? 0,
                      color.primary.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
            if (insight != null) ...[
              SizedBox(height: spacing.elementGap),
              _chartInsight(
                insight.text,
                insight.icon,
                insight.color,
                color,
                textTheme,
                spacing,
              ),
            ],
          ],
        );
      },
      loading: () => SizedBox(
        height: 200,
        child: Center(
          child: SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        height: 200,
        child: Center(child: Text(BuddyMessages.genericError)),
      ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _chartInsight(
    String text,
    IconData icon,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenChart(
    BuildContext context,
    List<MapEntry<String, List<double>>> sortedCategories,
    List<Color> chartColors,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => PopScope(
        onPopInvokedWithResult: (_, __) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        },
        child: _FullScreenTrendChart(
          sortedCategories: sortedCategories,
          chartColors: chartColors,
          onClose: () {
            Navigator.pop(ctx);
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          },
        ),
      ),
    );
  }
}

class _MonthlyTrendChart extends StatefulWidget {
  final List<MapEntry<String, List<double>>> sortedCategories;
  final int maxCategories;

  const _MonthlyTrendChart({
    required this.sortedCategories,
    this.maxCategories = 3,
  });

  @override
  State<_MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<_MonthlyTrendChart>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutCubic,
    );
    _controller!.forward();
  }

  @override
  void didUpdateWidget(_MonthlyTrendChart old) {
    super.didUpdateWidget(old);
    if (old.sortedCategories != widget.sortedCategories) {
      _controller?.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = ChartPalette.colors;

    if (_animation == null) return const SizedBox(height: 200);

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation!,
        builder: (context, _) {
          final t = _animation!.value;
          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'J',
                        'F',
                        'M',
                        'A',
                        'M',
                        'J',
                        'J',
                        'A',
                        'S',
                        'O',
                        'N',
                        'D',
                      ];
                      final index = value.toInt();
                      return Text(
                        index >= 0 && index < 12 ? months[index] : '',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: widget.sortedCategories
                  .take(widget.maxCategories)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                return LineChartBarData(
                  spots: List.generate(
                    12,
                    (j) => FlSpot(
                      j.toDouble(),
                      entry.value.value[j] * t,
                    ),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.4,
                  preventCurveOverShooting: true,
                  color:
                      colors[entry.key % colors.length].withValues(alpha: 0.9),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors[entry.key % colors.length]
                            .withValues(alpha: 0.15 * t),
                        colors[entry.key % colors.length]
                            .withValues(alpha: 0.05 * t),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ChartOnVisible extends StatefulWidget {
  final double height;
  final Widget child;
  final Widget zeroChild;

  const _ChartOnVisible({
    required this.height,
    required this.child,
    required this.zeroChild,
  });

  @override
  State<_ChartOnVisible> createState() => _ChartOnVisibleState();
}

class _ChartOnVisibleState extends State<_ChartOnVisible> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: VisibilityDetector(
        key: ValueKey('chart_${widget.child.runtimeType}_${widget.hashCode}'),
        onVisibilityChanged: (info) {
          if (!_visible && info.visibleFraction > 0.2) {
            setState(() => _visible = true);
          }
        },
        child: _visible ? widget.child : widget.zeroChild,
      ),
    );
  }
}

class _FullScreenTrendChart extends ConsumerStatefulWidget {
  final List<MapEntry<String, List<double>>> sortedCategories;
  final List<Color> chartColors;
  final VoidCallback onClose;

  const _FullScreenTrendChart({
    required this.sortedCategories,
    required this.chartColors,
    required this.onClose,
  });

  @override
  ConsumerState<_FullScreenTrendChart> createState() =>
      _FullScreenTrendChartState();
}

class _FullScreenTrendChartState extends ConsumerState<_FullScreenTrendChart> {
  int? _selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final l10n = AppLocalizations.of(context)!;
    final maxCats = widget.sortedCategories.length.clamp(1, 7);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(LucideIcons.x),
          onPressed: widget.onClose,
        ),
        title: Text(
          _selectedMonthIndex != null
              ? _monthLabel(now, _selectedMonthIndex!)
              : l10n.stats_12MonthTrend,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedMonthIndex != null)
            IconButton(
              tooltip: 'Back',
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => setState(() => _selectedMonthIndex = null),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.sectionGap,
            vertical: spacing.cardVertical,
          ),
          child: Column(
            children: [
              // Legend
              Wrap(
                spacing: spacing.elementGap * 1.5,
                runSpacing: spacing.elementGap,
                children: widget.sortedCategories
                    .take(maxCats)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final catColor =
                      widget.chartColors[entry.key % widget.chartColors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        entry.value.key,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: spacing.elementGap),
              // Chart
              Expanded(
                child: _selectedMonthIndex == null
                    ? _buildMonthlyView(color, textTheme, spacing, maxCats)
                    : _buildDailyDrillDown(
                        color,
                        textTheme,
                        spacing,
                        now,
                        _selectedMonthIndex!,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyView(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    int maxCats,
  ) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots != null) {
              final spot = response!.lineBarSpots!.first;
              setState(() => _selectedMonthIndex = spot.x.toInt());
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final catName = widget.sortedCategories[spot.barIndex].key;
              return LineTooltipItem(
                '$catName\n${formatCurrency(spot.y, code: BaseCurrency.code)}',
                textTheme.labelSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final now = DateTime.now();
                final month =
                    DateTime(now.year, now.month - (11 - value.toInt()));
                return Text(
                  safeDateFormat(
                    'MMM',
                    AppLocalizations.of(context)!.localeName,
                  ).format(month),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: widget.sortedCategories
            .take(maxCats)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final c = widget.chartColors[entry.key % widget.chartColors.length];
          return LineChartBarData(
            spots: List.generate(
              12,
              (j) => FlSpot(j.toDouble(), entry.value.value[j]),
            ),
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: true,
            color: c.withValues(alpha: 0.9),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: c,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.withValues(alpha: 0.12),
                  c.withValues(alpha: 0.03),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDailyDrillDown(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    DateTime now,
    int monthIndex,
  ) {
    final month = DateTime(now.year, now.month - (11 - monthIndex));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final transactionsAsync = ref.watch(transactionProvider);
    final maxCats = widget.sortedCategories.length.clamp(1, 7);

    return FutureBuilder(
      future: transactionsAsync.getAllForDashBoard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final txns = snapshot.data!;
        final monthStart = DateTime(month.year, month.month, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

        // Build per-category daily totals
        final catDailyTotals = <int, List<double>>{};
        for (var i = 0; i < maxCats; i++) {
          catDailyTotals[i] = List<double>.filled(daysInMonth, 0);
        }
        final otherDaily = List<double>.filled(daysInMonth, 0);

        for (final t in txns) {
          if (!t.isExpense ||
              t.date.isBefore(monthStart) ||
              t.date.isAfter(monthEnd)) {
            continue;
          }
          final catName = t.category.value?.name;
          final dayIdx = t.date.day - 1;
          final catIdx = widget.sortedCategories
              .take(maxCats)
              .toList()
              .indexWhere((e) => e.key == catName);
          if (catIdx >= 0) {
            catDailyTotals[catIdx]![dayIdx] += t.baseAmount;
          } else {
            otherDaily[dayIdx] += t.baseAmount;
          }
        }

        double maxStacked = 0;
        for (var d = 0; d < daysInMonth; d++) {
          double dayTotal = otherDaily[d];
          for (var c = 0; c < maxCats; c++) {
            dayTotal += catDailyTotals[c]![d];
          }
          if (dayTotal > maxStacked) maxStacked = dayTotal;
        }
        if (maxStacked == 0) {
          return Center(
            child: Text(
              BuddyMessages.noTransactions,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
            ),
          );
        }

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxStacked * 1.15,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final segments = <String>[];
                  for (var i = rod.rodStackItems.length - 1; i >= 0; i--) {
                    final item = rod.rodStackItems[i];
                    final amount = item.toY - item.fromY;
                    if (amount <= 0) continue;
                    final name =
                        i < maxCats ? widget.sortedCategories[i].key : 'Other';
                    segments.add(
                      '$name: ${formatCurrency(amount, code: BaseCurrency.code)}',
                    );
                  }
                  return BarTooltipItem(
                    'Day ${group.x + 1}\n${segments.join("\n")}',
                    textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt() + 1;
                    if (day % 5 == 1 || day == daysInMonth) {
                      return Text(
                        '$day',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(daysInMonth, (d) {
              final stackItems = <BarChartRodStackItem>[];
              double cumulative = 0;
              for (var c = 0; c < maxCats; c++) {
                final val = catDailyTotals[c]![d];
                if (val > 0) {
                  stackItems.add(
                    BarChartRodStackItem(
                      cumulative,
                      cumulative + val,
                      widget.chartColors[c % widget.chartColors.length],
                    ),
                  );
                  cumulative += val;
                }
              }
              if (otherDaily[d] > 0) {
                stackItems.add(
                  BarChartRodStackItem(
                    cumulative,
                    cumulative + otherDaily[d],
                    const Color(0xFF9CA3AF),
                  ),
                );
                cumulative += otherDaily[d];
              }

              return BarChartGroupData(
                x: d,
                barRods: [
                  BarChartRodData(
                    toY: cumulative,
                    rodStackItems: stackItems,
                    width: daysInMonth > 28 ? 4 : 6,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              );
            }),
          ),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  String _monthLabel(DateTime now, int index) {
    final month = DateTime(now.year, now.month - (11 - index));
    return safeDateFormat('MMMM yyyy', AppLocalizations.of(context)!.localeName)
        .format(month);
  }
}
