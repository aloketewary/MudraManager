import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/financial_health_card.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';
import 'package:mudra_manager/features/transactions/data/tag_analytics_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'Month';
  PeriodType _selectedPeriod = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final stats = _selectedPeriod == PeriodType.custom &&
            _customStart != null &&
            _customEnd != null
        ? ref.watch(
            customStatsProvider(
              '${_customStart!.millisecondsSinceEpoch}_${_customEnd!.millisecondsSinceEpoch}',
            ),
          )
        : ref.watch(statsProvider(_period));
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sticky Period Selector — always visible
          SliverAppBar(
            pinned: true,
            backgroundColor: color.surface,
            elevation: 0,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              child: PeriodCalendarSelector(
                selectedPeriod: _selectedPeriod,
                customStart: _customStart,
                customEnd: _customEnd,
                spacing: spacing,
                onChanged: (period, start, end) {
                  setState(() {
                    _selectedPeriod = period;
                    _customStart = start;
                    _customEnd = end;
                    _period = period == PeriodType.day
                        ? AppLocalizations.of(context)!.stats_today
                        : period == PeriodType.week
                            ? AppLocalizations.of(context)!.stats_week
                            : period == PeriodType.month
                                ? AppLocalizations.of(context)!.stats_month
                                : period == PeriodType.year
                                    ? AppLocalizations.of(context)!.stats_year
                                    : AppLocalizations.of(context)!
                                        .stats_custom;
                  });
                },
              ),
            ),
          ),
          // Content — loading/data/error
          ...stats.when(
            data: (d) {
              final hasData =
                  d.income > 0 || d.expense > 0 || d.categoryData.isNotEmpty;
              if (!hasData) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(color, textTheme),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ZONE 1: THE PULSE (4-Card Grid)
                      _buildPulseZone(
                        d,
                        color,
                        textTheme,
                        isGuestMode,
                        spacing,
                      ),
                      SizedBox(height: spacing.sectionGap),

                      // ZONE 2: THE NARRATIVE (Tabbed Charts)
                      _buildNarrativeZone(d, color, textTheme, spacing),
                      SizedBox(height: spacing.sectionGap),

                      // ZONE 3: THE INTELLIGENCE (Insights & Actions)
                      _buildIntelligenceZone(
                        d,
                        color,
                        textTheme,
                        isGuestMode,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),

                      // TAG SPENDING BREAKDOWN
                      _buildTagSpendingZone(color, textTheme, spacing),
                      SizedBox(height: spacing.elementGap),

                      // ZONE 4: FINANCIAL HEALTH
                      const FinancialHealthCard(
                        globalPadding: 0,
                      ),
                      SizedBox(height: spacing.elementGap),

                      // ZONE 5: SPENDING PERSONALITY
                      const SpendingPersonalityCard(
                        globalPadding: 0,
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: AmbientBrandSection()),
              ];
            },
            loading: () => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Column(
                    children: [
                      SkeletonLoader(
                        width: double.infinity,
                        height: 80,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                      SizedBox(height: spacing.sectionGap),
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonLoader(
                              width: double.infinity,
                              height: 120,
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                            ),
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: SkeletonLoader(
                              width: double.infinity,
                              height: 120,
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.elementGap),
                      SkeletonLoader(
                        width: double.infinity,
                        height: 120,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                      SizedBox(height: spacing.sectionGap * 2),
                      SkeletonLoader(
                        width: double.infinity,
                        height: 300,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            error: (_, __) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(BuddyMessages.genericError)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme color, TextTheme textTheme) {
    return NoDataFound(
      message: BuddyMessages.noTransactions,
      iconData: LucideIcons.chartBar,
    );
  }

  // ZONE 1: THE PULSE - Instant health check
  Widget _buildPulseZone(
    StatsData d,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.stats_overview,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacing.sectionGap),
        Row(
          children: [
            Expanded(
              child: _buildPulseCard(
                AppLocalizations.of(context)!.stats_income,
                d.income,
                color.primary,
                LucideIcons.arrowUp,
                d.incomeSpots,
                color,
                textTheme,
                isGuestMode,
                spacing,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _buildPulseCard(
                AppLocalizations.of(context)!.stats_expense,
                d.expense,
                color.error,
                LucideIcons.arrowDown,
                d.expenseSpots,
                color,
                textTheme,
                isGuestMode,
                spacing,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        _NetWorthCard(
          isGuestMode: isGuestMode,
          savingsRate: d.savingsRate,
          savingsSpots: d.savingsSpots,
          spacing: spacing,
        ),
      ],
    );
  }

  Widget _buildPulseCard(
    String label,
    double value,
    Color cardColor,
    IconData icon,
    List<FlSpot> sparkline,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing, {
    bool isPercentage = false,
  }) {
    return _PulseCard(
      label: label,
      value: value,
      cardColor: cardColor,
      icon: icon,
      sparkline: sparkline,
      isGuestMode: isGuestMode,
      isPercentage: isPercentage,
      spacing: spacing,
    );
  }

  // ZONE 2: THE NARRATIVE - Interactive Charts
  Widget _buildNarrativeZone(
    StatsData d,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.stats_trends,
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
                        AppLocalizations.of(context)!.stats_12MonthTrend,
                        0,
                        color,
                        textTheme,
                        spacing,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _buildTabButton(
                        AppLocalizations.of(context)!.stats_spendingByDay,
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
                    ? _build12MonthChart(color, textTheme)
                    : _buildSpendingByDayChart(color, textTheme),
              ),
            ],
          ),
        ),
      ],
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

  Widget _build12MonthChart(ColorScheme color, TextTheme textTheme) {
    final trendsAsync = ref.watch(monthlyExpenseTrendsProvider);
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    return trendsAsync.when(
      data: (categoryData) {
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

        // Compute insight
        final topCat = sortedCategories.first;
        final topTotal = topCat.value.reduce((a, b) => a + b);
        final thisMonth = topCat.value.last;
        final lastMonth = topCat.value.length >= 2
            ? topCat.value[topCat.value.length - 2]
            : 0.0;
        final allTotals =
            sortedCategories.map((e) => e.value.reduce((a, b) => a + b));
        final grandTotal = allTotals.fold(0.0, (a, b) => a + b);
        final topPercent = grandTotal > 0
            ? (topTotal / grandTotal * 100).toStringAsFixed(0)
            : '0';

        String insight;
        IconData insightIcon;
        Color insightColor;
        if (thisMonth > lastMonth * 1.3 && lastMonth > 0) {
          insight = ctxt.stats_trendUp(topCat.key, topPercent);
          insightIcon = LucideIcons.trendingUp;
          insightColor =
              FinanceColors.expenseColor(Theme.of(context).brightness);
        } else if (thisMonth < lastMonth * 0.7 && lastMonth > 0) {
          insight = ctxt.stats_trendDown(topCat.key);
          insightIcon = LucideIcons.trendingDown;
          insightColor =
              FinanceColors.incomeColor(Theme.of(context).brightness);
        } else {
          insight = ctxt.stats_topCategory(topCat.key, topPercent);
          insightIcon = LucideIcons.sparkles;
          insightColor = color.primary;
        }

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
                        color: chartColors[entry.key],
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
                        .map((e) => MapEntry(
                            e.key, List<double>.filled(e.value.length, 0),),)
                        .toList(),
                    maxCategories: 4,
                  ),
                  child: _MonthlyTrendChart(sortedCategories: sortedCategories),
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
                        color: color.outlineVariant.withValues(alpha: 0.3),),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.expand,
                          size: 12, color: color.onSurfaceVariant,),
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
            SizedBox(height: spacing.elementGap),
            _chartInsight(
              insight,
              insightIcon,
              insightColor,
              color,
              textTheme,
              spacing,
            ),
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

  Widget _buildSpendingByDayChart(ColorScheme color, TextTheme textTheme) {
    final spendingByDayAsync = ref.watch(spendingByDayProvider);
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    return spendingByDayAsync.when(
      data: (byDay) {
        final maxSpending = byDay.values.reduce((a, b) => a > b ? a : b);
        if (maxSpending == 0) {
          return SizedBox(
            height: 200,
            child: NoDataFound(
              message: BuddyMessages.noTransactions,
              iconData: LucideIcons.chartBar,
            ),
          );
        }

        // Compute insight
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final peakDay =
            days.reduce((a, b) => (byDay[a] ?? 0) > (byDay[b] ?? 0) ? a : b);
        final quietDay =
            days.reduce((a, b) => (byDay[a] ?? 0) < (byDay[b] ?? 0) ? a : b);
        final weekdayTotal = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
            .fold(0.0, (s, d) => s + (byDay[d] ?? 0));
        final weekendTotal =
            ['Sat', 'Sun'].fold(0.0, (s, d) => s + (byDay[d] ?? 0));
        final weekendAvg = weekendTotal / 2;
        final weekdayAvg = weekdayTotal / 5;

        String insight;
        IconData insightIcon;
        Color insightColor;
        if (weekendAvg > weekdayAvg * 1.5) {
          insight = ctxt.stats_weekendPeak(peakDay);
          insightIcon = LucideIcons.calendarRange;
          insightColor =
              FinanceColors.expenseColor(Theme.of(context).brightness);
        } else if (weekdayAvg > weekendAvg * 1.5) {
          insight = ctxt.stats_weekdayPeak(peakDay);
          insightIcon = LucideIcons.briefcase;
          insightColor = FinanceColors.statusWarning;
        } else {
          insight = ctxt.stats_peakAndQuiet(peakDay, quietDay);
          insightIcon = LucideIcons.chartBar;
          insightColor = color.primary;
        }

        return Column(
          children: [
            _ChartOnVisible(
              height: 200,
              zeroChild: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpending * 1.2,
                  barTouchData: BarTouchData(enabled: false),
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
                  barTouchData: BarTouchData(enabled: false),
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
                      byDay['Mon']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      1,
                      byDay['Tue']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      2,
                      byDay['Wed']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      3,
                      byDay['Thu']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      4,
                      byDay['Fri']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      5,
                      byDay['Sat']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                    _buildBarGroup(
                      6,
                      byDay['Sun']!,
                      color.primary.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
            SizedBox(height: spacing.elementGap),
            _chartInsight(
              insight,
              insightIcon,
              insightColor,
              color,
              textTheme,
              spacing,
            ),
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

  // ZONE 3: THE INTELLIGENCE - Actionable Insights
  Widget _buildIntelligenceZone(
    StatsData d,
    ColorScheme color,
    TextTheme textTheme,
    bool isGuestMode,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.stats_insights,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacing.sectionGap),
        // Spending Prediction Banner
        Consumer(
          builder: (context, ref, child) {
            final predictionAsync = ref.watch(predictedSpendingProvider);
            return predictionAsync.when(
              data: (predicted) {
                if (predicted <= 0) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.primaryContainer,
                        color.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.trendingUp,
                          color: color.primary, size: 32,),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .stats_nextMonthForecast,
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
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),

        // Insights Nudges
        if (d.categoryData.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  AppLocalizations.of(context)!.stats_topSpending,
                  (d.categoryData.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .first
                      .key,
                  LucideIcons.trendingUp,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _buildInsightCard(
                  'Daily Average',
                  formatCurrency(
                    d.avgDailySpend,
                    code: BaseCurrency.code,
                    decimals: 0,
                  ),
                  LucideIcons.calendar,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
        ],

        // Category Trends (Top 5)
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
                          AppLocalizations.of(context)!.stats_categoryTrends,
                          style: textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ...sortedTrends.take(5).map(
                              (trend) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
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
                                              const SizedBox(width: 8),
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
                                                          spacing.radiusMedium,),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      trend.changePercent > 0
                                                          ? LucideIcons.arrowUp
                                                          : Icons
                                                              .arrow_downward,
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
                                    const SizedBox(height: 8),
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
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagSpendingZone(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final tagSpendingAsync = ref.watch(tagSpendingProvider(_period));
        return tagSpendingAsync.when(
          data: (tagSpendings) {
            if (tagSpendings.isEmpty) return const SizedBox.shrink();
            final maxAmount = tagSpendings.first.amount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.stats_spendingByTag,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                Card(
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
                      children: tagSpendings.take(8).map((ts) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.tag,
                                        size: 16,
                                        color: color.tertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ts.tag.name,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CurrencyText(
                                        amount: ts.amount,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${ts.count} txn',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      (ts.amount / maxAmount).clamp(0.0, 1.0),
                                  backgroundColor:
                                      color.surfaceContainerHighest,
                                  color: color.tertiary,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildInsightCard(
    String label,
    String value,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(top: spacing.elementGap),
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
            Icon(icon, color: color.primary, size: 24),
            SizedBox(height: spacing.elementGap),
            Text(
              label,
              style:
                  textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              value,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class _NetWorthCard extends ConsumerWidget {
  final bool isGuestMode;
  final double savingsRate;
  final List<FlSpot> savingsSpots;
  final AppSpacing spacing;

  const _NetWorthCard({
    required this.isGuestMode,
    required this.savingsRate,
    required this.savingsSpots,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);

    return totalBalanceAsync.when(
      data: (totalBalance) {
        final netWorthSpots = historyAsync.maybeWhen(
          data: (history) => history
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
              .toList(),
          orElse: () => <FlSpot>[],
        );

        return Row(
          children: [
            Expanded(
              child: _PulseCard(
                label: AppLocalizations.of(context)!.stats_netWorth,
                value: totalBalance,
                cardColor: color.primary,
                icon: LucideIcons.wallet,
                sparkline: netWorthSpots,
                isGuestMode: isGuestMode,
                spacing: spacing,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _PulseCard(
                label: AppLocalizations.of(context)!.stats_savings,
                value: savingsRate,
                cardColor: color.tertiary,
                icon: LucideIcons.piggyBank,
                sparkline: savingsSpots,
                isGuestMode: isGuestMode,
                isPercentage: true,
                spacing: spacing,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final String label;
  final double value;
  final Color cardColor;
  final IconData icon;
  final List<FlSpot> sparkline;
  final bool isGuestMode;
  final bool isPercentage;
  final AppSpacing spacing;

  const _PulseCard({
    required this.label,
    required this.value,
    required this.cardColor,
    required this.icon,
    required this.sparkline,
    required this.isGuestMode,
    this.isPercentage = false,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (sparkline.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 70,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sparkline,
                            isCurved: true,
                            color: cardColor.withValues(alpha: 0.4),
                            barWidth: 0,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cardColor.withValues(alpha: 0.05),
                                  cardColor.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: cardColor, size: 20),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                isPercentage
                    ? Text(
                        '${value.toStringAsFixed(1)}%',
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      )
                    : CurrencyText(
                        amount:
                            GuestModeUtil.applyGuestMode(value, isGuestMode),
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                if (sparkline.isNotEmpty) const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Health score ring that animates only when visible.
class _AnimatedScoreRing extends StatefulWidget {
  final double score;
  final Color scoreColor;
  final TextTheme textTheme;

  const _AnimatedScoreRing({
    required this.score,
    required this.scoreColor,
    required this.textTheme,
  });

  @override
  State<_AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<_AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      key: ValueKey('score_ring_${widget.score}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final value = _anim.value * widget.score;
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: widget.scoreColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(widget.scoreColor),
                ),
              ),
              Text(
                '${(value * 100).toInt()}',
                style: widget.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: widget.scoreColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Metric bar that animates only when visible.
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
          value: _anim.value * widget.progress,
          minHeight: 8,
          backgroundColor: widget.bgColor,
          valueColor: AlwaysStoppedAnimation(widget.barColor),
        ),
      ),
    );
  }
}

/// Defers chart data until visible, then animates from zero → real values
/// using fl_chart's built-in swap animation.
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
    final ctxt = AppLocalizations.of(context)!;
    final maxCats = widget.sortedCategories.length.clamp(1, 7);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: widget.onClose,
        ),
        title: Text(
          _selectedMonthIndex != null
              ? _monthLabel(now, _selectedMonthIndex!)
              : ctxt.stats_12MonthTrend,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedMonthIndex != null)
            IconButton(
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
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final now = DateTime.now();
                final month =
                    DateTime(now.year, now.month - (11 - value.toInt()));
                return Text(
                  safeDateFormat('MMM', AppLocalizations.of(context)!.localeName).format(month),
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
    widget.sortedCategories.take(maxCats).map((e) => e.key).toSet();

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
        // catIndex -> day -> amount
        final catDailyTotals = <int, List<double>>{};
        for (var i = 0; i < maxCats; i++) {
          catDailyTotals[i] = List<double>.filled(daysInMonth, 0);
        }
        // "Other" bucket for categories not in top N
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

        // Compute max stacked height
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
                        '$name: ${formatCurrency(amount, code: BaseCurrency.code)}',);
                  }
                  return BarTooltipItem(
                    'Day ${group.x + 1}\n${segments.join('\n')}',
                    textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              // Build stacked rod
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
              // Other
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
    return safeDateFormat('MMMM yyyy', AppLocalizations.of(context)!.localeName).format(month);
  }
}
