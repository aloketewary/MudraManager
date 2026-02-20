import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/export_excel_pdf.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'dart:ui' as ui;
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'Month';
  PeriodType _selectedPeriod = PeriodType.month;
  DateTime? _customStart;
  DateTime? _customEnd;
  final Set<String> _disabledCategories = {};
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationServiceProvider).track(GamificationEvent.analyticsViewed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats =
        _selectedPeriod == PeriodType.custom &&
            _customStart != null &&
            _customEnd != null
        ? ref.watch(
            customStatsProvider(
              '${_customStart!.millisecondsSinceEpoch}_${_customEnd!.millisecondsSinceEpoch}',
            ),
          )
        : ref.watch(statsProvider(_period));

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      body: stats.when(
        data: (d) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PeriodCalendarSelector(
                  selectedPeriod: _selectedPeriod,
                  customStart: _customStart,
                  customEnd: _customEnd,
                  onChanged: (period, start, end) {
                    setState(() {
                      _selectedPeriod = period;
                      _customStart = start;
                      _customEnd = end;
                      switch (period) {
                        case PeriodType.day:
                          _period = 'Today';
                          break;
                        case PeriodType.week:
                          _period = 'Week';
                          break;
                        case PeriodType.month:
                          _period = 'Month';
                          break;
                        case PeriodType.year:
                          _period = 'Year';
                          break;
                        case PeriodType.custom:
                          _period = 'Custom';
                          break;
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Income/Expense Chart Card
                _AnimatedCard(
                  delay: 0,
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
                              Icons.show_chart,
                              color: color.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ctxt.statistics_quickOverviewTitle,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        RepaintBoundary(
                          key: _chartKey,
                          child: SizedBox(
                            height: 200,
                            child: LineChart(
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
                                        final day = value.toInt() + 1;
                                        return Text(
                                          day.toString(),
                                          style: textTheme.bodySmall,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: d.incomeSpots,
                                    isCurved: true,
                                    color: color.primary,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: d.expenseSpots,
                                    isCurved: true,
                                    color: color.error,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegend('Income', color.primary, textTheme),
                            _buildLegend('Expense', color.error, textTheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Cards
                _AnimatedCard(
                  delay: 100,
                  child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Income',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: d.income),
                                builder: (context, value, child) {
                                  return CurrencyText(
                                    amount: value,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: color.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_downward,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Expense',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: d.expense),
                                builder: (context, value, child) {
                                  return CurrencyText(
                                    amount: value,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  ),
                ),

                const SizedBox(height: 12),

                _AnimatedCard(
                  delay: 200,
                  child: Consumer(
                  builder: (context, ref, child) {
                    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
                    return totalBalanceAsync.when(
                      data: (totalBalance) => Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: color.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Net Worth',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween(begin: 0.0, end: totalBalance),
                                      builder: (context, value, child) {
                                        return CurrencyText(
                                          amount: value,
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: color.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Savings Rate',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween(begin: 0.0, end: d.savingsRate),
                                      builder: (context, value, child) {
                                        return Text(
                                          '${value.toStringAsFixed(1)}%',
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: color.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Savings Rate',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${d.savingsRate.toStringAsFixed(1)}%',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: color.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Net Worth',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    CurrencyText(
                                      amount: d.income - d.expense,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: color.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: color.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Savings Rate',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${d.savingsRate.toStringAsFixed(1)}%',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  ),
                ),

                const SizedBox(height: 16),

                // Analytics Section
                _buildAnalyticsSection(),

                const SizedBox(height: 16),

                // Insights Card
                if (d.categoryData.isNotEmpty)
                  _AnimatedCard(
                    delay: 300,
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
                                Icons.lightbulb_outline,
                                color: color.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ctxt.statistics_insightsTitle,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInsightRow(
                            'Top Category',
                            (d.categoryData.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                .first
                                .key,
                            color,
                            textTheme,
                          ),
                          const SizedBox(height: 12),
                          _buildInsightRow(
                            'Avg Daily Spend',
                            '\u20b9${d.avgDailySpend.toStringAsFixed(0)}',
                            color,
                            textTheme,
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),

                const SizedBox(height: 16),

                _AnimatedCard(
                  delay: 400,
                  child: _buildCategoryTrendsCard(d),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, TextTheme textTheme) {
    return Row(
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 8),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInsightRow(
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
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    final healthAsync = ref.watch(financialHealthProvider);
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
    final spendingByDayAsync = ref.watch(spendingByDayProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Health
        _AnimatedCard(
          delay: 0,
          child: healthAsync.when(
            data: (health) {
              if (health.score == 0) return const SizedBox.shrink();
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getScoreColor(
                              health.score,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: _getScoreColor(health.score),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Health',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Comprehensive health analysis',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getScoreColor(health.score),
                                width: 8,
                              ),
                              color: _getScoreColor(
                                health.score,
                              ).withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${health.score}',
                                    style: textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(health.score),
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '/100',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(
                                health.score,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              health.rating,
                              style: textTheme.titleMedium?.copyWith(
                                color: _getScoreColor(health.score),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.savings,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Savings Rate',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${health.savingsRate.toStringAsFixed(1)}%',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.trending_down,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Expense Ratio',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${health.expenseRatio.toStringAsFixed(1)}%',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (health.insights.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Key Insights',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...health.insights.map(
                        (insight) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lightbulb,
                                  size: 14,
                                  color: color.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  insight,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.onSurface,
                                    height: 1.4,
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
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(height: 16),

        // Spending Prediction
        _AnimatedCard(
          delay: 100,
          child: predictionAsync.when(
          data: (predicted) {
            if (predicted <= 0) return const SizedBox.shrink();
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
                        Icon(Icons.trending_up, color: color.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Spending Prediction',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Next Month',
                            style: textTheme.bodyLarge?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CurrencyText(
                            amount: predicted,
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Based on last 3 months average',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(height: 16),

        // 12-Month Expense Trends
        _AnimatedCard(
          delay: 200,
          child: _build12MonthTrendsCard(),
        ),

        const SizedBox(height: 16),

        // Spending by Day
        _AnimatedCard(
          delay: 300,
          child: spendingByDayAsync.when(
          data: (byDay) {
            final maxSpending = byDay.values.reduce((a, b) => a > b ? a : b);
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
                          Icons.calendar_today,
                          color: color.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Spending by Day',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          ),
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
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCategoryTrendsCard(StatsData d) {
    final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return categoryTrendsAsync.when(
      data: (trends) {
        if (trends.isEmpty) return const SizedBox.shrink();
        final sortedTrends = trends.values.toList()
          ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));

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
                    Icon(Icons.category, color: color.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Category Trends',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...sortedTrends
                    .take(5)
                    .toList()
                    .map(
                      (trend) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trend.categoryName,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    CurrencyText(
                                      amount: trend.thisMonth,
                                      style: textTheme.titleSmall,
                                    ),
                                    if (trend.changePercent != 0) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        trend.changePercent > 0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color: trend.changePercent > 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      Text(
                                        '${trend.changePercent.abs().toStringAsFixed(0)}%',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: trend.changePercent > 0
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  (trend.thisMonth /
                                          sortedTrends.first.thisMonth)
                                      .clamp(0.0, 1.0),
                              backgroundColor: color.surfaceContainerHighest,
                              color: color.primary,
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
  }

  void showExportOptions(BuildContext context) {
    final stats =
        _selectedPeriod == PeriodType.custom &&
            _customStart != null &&
            _customEnd != null
        ? ref.read(
            customStatsProvider(
              '${_customStart!.millisecondsSinceEpoch}_${_customEnd!.millisecondsSinceEpoch}',
            ),
          )
        : ref.read(statsProvider(_period));

    stats.whenData((data) {
      final ctxt = AppLocalizations.of(context)!;
      showModalBottomSheet(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(ctxt.statistics_exportToPdfButtonText),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await _exportToPdf(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(ctxt.statistics_exportToExcelButtonText),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await exportStatsToExcelMethod(data);
              },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _exportToPdf(StatsData stats) async {
    try {
      final boundary =
          _chartKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final health = await ref.read(financialHealthProvider.future);
      final predicted = await ref.read(predictedSpendingProvider.future);
      final categoryTrends = await ref.read(categoryTrendsProvider.future);
      final spendingByDay = await ref.read(spendingByDayProvider.future);

      await exportStatsToPdf(
        context,
        stats,
        null,
        byteData.buffer.asUint8List(),
        health: health,
        predicted: predicted,
        categoryTrends: categoryTrends,
        spendingByDay: spendingByDay,
        gamificationService: ref.read(gamificationServiceProvider),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _build12MonthTrendsCard() {
    final trendsAsync = ref.watch(monthlyExpenseTrendsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return trendsAsync.when(
      data: (categoryData) {
        if (categoryData.isEmpty) return const SizedBox.shrink();

        final sortedCategories = categoryData.entries.toList()
          ..sort(
            (a, b) => b.value
                .reduce((a, b) => a + b)
                .compareTo(a.value.reduce((a, b) => a + b)),
          );

        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];

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
                    Icon(Icons.timeline, color: color.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '12-Month Expense Trends',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: LineChart(
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
                              final monthIndex = value.toInt();
                              if (monthIndex < 0 || monthIndex >= 12) {
                                return const Text('');
                              }
                              final month = DateTime(
                                now.year,
                                now.month - 11 + monthIndex,
                              );
                              return Text(
                                [
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
                                ][month.month - 1],
                                style: textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: (() {
                        final top5 = sortedCategories.take(5).toList();
                        final List<LineChartBarData> bars = [];
                        for (var i = 0; i < top5.length; i++) {
                          if (!_disabledCategories.contains(top5[i].key)) {
                            bars.add(
                              LineChartBarData(
                                spots: List.generate(
                                  12,
                                  (j) => FlSpot(j.toDouble(), top5[i].value[j]),
                                ),
                                isCurved: true,
                                color: colors[i % colors.length],
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            );
                          }
                        }
                        return bars;
                      })(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: sortedCategories
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final categoryName = entry.value.key;
                        final isDisabled = _disabledCategories.contains(
                          categoryName,
                        );
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              if (isDisabled) {
                                _disabledCategories.remove(categoryName);
                              } else {
                                _disabledCategories.add(categoryName);
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 3,
                                color: isDisabled
                                    ? Colors.grey
                                    : colors[entry.key % colors.length],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryName,
                                style: textTheme.bodySmall?.copyWith(
                                  decoration: isDisabled
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDisabled ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
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

  Future<void> exportStatsToExcelMethod(StatsData data) async {
    await exportStatsToExcel(data, ref.read(gamificationServiceProvider));
  }

  Future<void> exportStatsToPdfMethod(StatsData data) async {
    await _exportToPdf(data);
  }
}
