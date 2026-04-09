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
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';
import 'package:mudra_manager/features/transactions/data/tag_analytics_provider.dart';
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
      body: stats.when(
        data: (d) {
          final hasData =
              d.income > 0 || d.expense > 0 || d.categoryData.isNotEmpty;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(statsProvider(_period));
              ref.invalidate(customStatsProvider);
              ref.invalidate(monthlyExpenseTrendsProvider);
              ref.invalidate(spendingByDayProvider);
              ref.invalidate(categoryTrendsProvider);
              ref.invalidate(financialHealthProvider);
              ref.invalidate(predictedSpendingProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Sticky Period Selector
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
                                          : AppLocalizations.of(context)!.stats_custom;
                        });
                      },
                    ),
                  ),
                ),
                if (!hasData)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(color, textTheme),
                  )
                else
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
              ],
            ),
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          child: Column(
            children: [
              SkeletonLoader(
                width: double.infinity,
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SkeletonLoader(
                      width: double.infinity,
                      height: 120,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SkeletonLoader(
                      width: double.infinity,
                      height: 120,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SkeletonLoader(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 32),
              SkeletonLoader(
                width: double.infinity,
                height: 300,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
        error: (_, __) =>
            const Center(child: Text('Unable to load statistics')),
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
                Icons.arrow_upward,
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
                Icons.arrow_downward,
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
                        '12-Month Trend',
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
    return trendsAsync.when(
      data: (categoryData) {
        if (categoryData.isEmpty) {
          return SizedBox(
            height: 200,
            child: NoDataFound(message: BuddyMessages.noTransactions, iconData: LucideIcons.chartBar),
          );
        }
        final sortedCategories = categoryData.entries.toList()
          ..sort(
            (a, b) => b.value
                .reduce((a, b) => a + b)
                .compareTo(a.value.reduce((a, b) => a + b)),
          );

        return RepaintBoundary(
          child: _ChartOnVisible(
            height: 200,
            child: _MonthlyTrendChart(sortedCategories: sortedCategories),
            zeroChild: _MonthlyTrendChart(
              sortedCategories: sortedCategories
                  .map((e) => MapEntry(
                        e.key,
                        List<double>.filled(e.value.length, 0),
                      ))
                  .toList(),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        height: 200,
        child: Center(
          child: SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
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
    return spendingByDayAsync.when(
      data: (byDay) {
        final maxSpending = byDay.values.reduce((a, b) => a > b ? a : b);
        if (maxSpending == 0) {
          return SizedBox(
            height: 200,
            child: NoDataFound(message: BuddyMessages.noTransactions, iconData: LucideIcons.chartBar),
          );
        }

        return _ChartOnVisible(
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
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      return Text(
                        days[value.toInt()],
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) => _buildBarGroup(i, 0, color.primary.withValues(alpha: 0.9))),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutCubic,
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
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        );
      },
      loading: () => SizedBox(
        height: 200,
        child: Center(
          child: SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(12),
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
                      Icon(Icons.trending_up, color: color.primary, size: 32),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.stats_nextMonthForecast,
                              style: textTheme.labelLarge?.copyWith(
                                color: color.onPrimaryContainer,
                              ),
                            ),
                            SizedBox(height: spacing.elementGap),
                            CurrencyText(
                              amount: predicted,
                              style: textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                  Icons.trending_up,
                  color,
                  textTheme,
                  spacing,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: _buildInsightCard(
                  'Daily Average',
                  formatCurrency(d.avgDailySpend, code: BaseCurrency.code, decimals: 0),
                  Icons.calendar_today,
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
                          'Category Trends',
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
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      trend.changePercent > 0
                                                          ? Icons.arrow_upward
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
                  'Spending by Tag',
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
                                        Icons.label_rounded,
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
                                  value: (ts.amount / maxAmount)
                                      .clamp(0.0, 1.0),
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

class _MonthlyTrendChart extends StatelessWidget {
  final List<MapEntry<String, List<double>>> sortedCategories;

  const _MonthlyTrendChart({required this.sortedCategories});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = [
      color.primary,
      color.secondary,
      color.tertiary,
      color.error,
      color.primaryContainer,
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
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
          lineBarsData:
              sortedCategories.take(3).toList().asMap().entries.map((entry) {
            return LineChartBarData(
              spots: List.generate(
                12,
                (j) => FlSpot(j.toDouble(), entry.value.value[j]),
              ),
              isCurved: true,
              curveSmoothness: 0.4,
              preventCurveOverShooting: true,
              color: colors[entry.key].withValues(alpha: 0.9),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors[entry.key].withValues(alpha: 0.15),
                    colors[entry.key].withValues(alpha: 0.05),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
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
                label: 'Net Worth',
                value: totalBalance,
                cardColor: color.primary,
                icon: Icons.account_balance_wallet,
                sparkline: netWorthSpots,
                isGuestMode: isGuestMode,
                spacing: spacing,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _PulseCard(
                label: 'Savings',
                value: savingsRate,
                cardColor: color.tertiary,
                icon: Icons.savings,
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
                  backgroundColor:
                      widget.scoreColor.withValues(alpha: 0.15),
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
