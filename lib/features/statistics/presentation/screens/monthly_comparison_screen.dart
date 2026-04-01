import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/shared/widgets/widgets.dart';

class MonthlyComparisonScreen extends ConsumerStatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  ConsumerState<MonthlyComparisonScreen> createState() =>
      _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState
    extends ConsumerState<MonthlyComparisonScreen> {
  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isar = ref.watch(isarServiceProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final currentMonthName = DateFormat('MMMM').format(now);
    final lastMonthName = DateFormat('MMMM').format(lastMonthStart);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getComparisonData(
          isar,
          currentMonthStart,
          currentMonthEnd,
          lastMonthStart,
          lastMonthEnd,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CustomScrollView(
              slivers: [
                const SliverAppBar(
                  title: Text('Monthly Comparison'),
                  pinned: true,
                ),
                SliverPadding(
                  padding: EdgeInsets.all(spacing.sectionGap),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildComparisonCardSkeleton(context, spacing),
                      SizedBox(height: spacing.elementGap),
                      _buildComparisonCardSkeleton(context, spacing),
                      SizedBox(height: spacing.elementGap),
                      _buildComparisonCardSkeleton(context, spacing),
                    ]),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final rawCurrentIncome = data['currentIncome']! as double;
          final rawCurrentExpense = data['currentExpense']! as double;
          final rawLastIncome = data['lastIncome']! as double;
          final rawLastExpense = data['lastExpense']! as double;
          final categoryData =
              data['categoryComparison'] as List<Map<String, dynamic>>;

          final currentIncome =
              GuestModeUtil.applyGuestMode(rawCurrentIncome, isGuestMode);
          final currentExpense =
              GuestModeUtil.applyGuestMode(rawCurrentExpense, isGuestMode);
          final lastIncome =
              GuestModeUtil.applyGuestMode(rawLastIncome, isGuestMode);
          final lastExpense =
              GuestModeUtil.applyGuestMode(rawLastExpense, isGuestMode);

          final incomeChange = lastIncome > 0
              ? ((currentIncome - lastIncome) / lastIncome * 100)
              : 0.0;
          final expenseChange = lastExpense > 0
              ? ((currentExpense - lastExpense) / lastExpense * 100)
              : 0.0;
          final currentBalance = currentIncome - currentExpense;
          final lastBalance = lastIncome - lastExpense;
          final balanceChange = lastBalance != 0
              ? ((currentBalance - lastBalance) / lastBalance.abs() * 100)
              : 0.0;
          final variance = currentExpense - lastExpense;
          final variancePercent =
              lastExpense > 0 ? (variance / lastExpense * 100) : 0.0;

          return CustomScrollView(
            slivers: [
              // Professional SliverAppBar with Clean Header
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                elevation: 0,
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    return const Text(
                      'Monthly Comparison',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.tertiaryContainer,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Opacity(
                            opacity: constraints.maxHeight > 100 ? 1.0 : 0.0,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                spacing.cardHorizontal,
                                spacing.sectionGap * 3,
                                spacing.cardHorizontal,
                                spacing.sectionGap,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(spacing.elementGap),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            spacing.radiusMedium,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.chartBar,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: spacing.elementGap),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Text(
                                            //   'Monthly Comparison',
                                            //   style: textTheme.headlineSmall
                                            //       ?.copyWith(
                                            //     fontWeight: FontWeight.bold,
                                            //     color: colorScheme
                                            //         .onPrimaryContainer,
                                            //   ),
                                            // ),
                                            Text(
                                              '$currentMonthName vs $lastMonthName',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onPrimaryContainer
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: EdgeInsets.all(spacing.cardInner),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface
                                          .withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(
                                        spacing.radiusMedium,
                                      ),
                                      border: Border.all(
                                        color: colorScheme.outline
                                            .withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Expense Change',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: spacing.elementGap,
                                                ),
                                                CurrencyText(
                                                  amount: variance,
                                                  fixedLength: 0,
                                                  showSign: true,
                                                  style: textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: variance < 0
                                                        ? const Color(
                                                            0xFF10B981,
                                                          )
                                                        : colorScheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    spacing.cardHorizontal,
                                                vertical: spacing.cardVertical,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (variance < 0
                                                        ? const Color(
                                                            0xFF10B981,
                                                          )
                                                        : colorScheme.error)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  spacing.radiusSmall,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    variance < 0
                                                        ? LucideIcons.arrowDown
                                                        : LucideIcons.arrowUp,
                                                    color: variance < 0
                                                        ? const Color(
                                                            0xFF10B981,
                                                          )
                                                        : colorScheme.error,
                                                    size: 16,
                                                  ),
                                                  SizedBox(
                                                    width: spacing.elementGap,
                                                  ),
                                                  Text(
                                                    '${variancePercent.abs().toStringAsFixed(1)}%',
                                                    style: textTheme.titleSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: variance < 0
                                                          ? const Color(
                                                              0xFF10B981,
                                                            )
                                                          : colorScheme.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing.elementGap),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildQuickStat(
                                                currentMonthName,
                                                currentExpense,
                                                colorScheme,
                                                textTheme,
                                                spacing,
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 30,
                                              color: colorScheme.outlineVariant
                                                  .withValues(alpha: 0.5),
                                            ),
                                            Expanded(
                                              child: _buildQuickStat(
                                                lastMonthName,
                                                lastExpense,
                                                colorScheme,
                                                textTheme,
                                                spacing,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Insight Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(spacing.cardInner),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.tertiaryContainer,
                          colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(
                            LucideIcons.lightbulb,
                            color: colorScheme.tertiary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap),
                        Expanded(
                          child: Text(
                            variance < 0
                                ? 'Great job! You\'ve reduced spending by ₹${variance.abs().toStringAsFixed(0)} this month.'
                                : 'Spending increased by ₹${variance.abs().toStringAsFixed(0)}. Review your expenses to optimize.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Comparison Bar Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  child: _buildComparisonBarChart(
                    currentIncome,
                    currentExpense,
                    currentBalance,
                    lastIncome,
                    lastExpense,
                    lastBalance,
                    currentMonthName,
                    lastMonthName,
                    colorScheme,
                    textTheme,
                    spacing,
                  ),
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.sectionGap,
                    spacing.sectionGap,
                    spacing.sectionGap,
                    spacing.elementGap,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.chartPie,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: spacing.elementGap),
                      Text(
                        'Detailed Breakdown',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comparison Cards
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ComparisonCard(
                      title: 'Income',
                      icon: LucideIcons.trendingUp,
                      color: colorScheme.primary,
                      currentAmount: currentIncome,
                      lastAmount: lastIncome,
                      percentageChange: incomeChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      spacing: spacing,
                      l10n: l10n,
                      currentLabel: currentMonthName,
                      lastLabel: lastMonthName,
                    ),
                    SizedBox(height: spacing.elementGap),
                    _ComparisonCard(
                      title: 'Expense',
                      icon: LucideIcons.trendingDown,
                      color: colorScheme.error,
                      currentAmount: currentExpense,
                      lastAmount: lastExpense,
                      percentageChange: expenseChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      spacing: spacing,
                      l10n: l10n,
                      currentLabel: currentMonthName,
                      lastLabel: lastMonthName,
                    ),
                    SizedBox(height: spacing.elementGap),
                    _ComparisonCard(
                      title: 'Balance',
                      icon: LucideIcons.wallet,
                      color: colorScheme.tertiary,
                      currentAmount: currentBalance,
                      lastAmount: lastBalance,
                      percentageChange: balanceChange,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      spacing: spacing,
                      l10n: l10n,
                      currentLabel: currentMonthName,
                      lastLabel: lastMonthName,
                    ),
                  ]),
                ),
              ),

              // Category Comparison Chart
              if (categoryData.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.sectionGap,
                      spacing.sectionGap,
                      spacing.sectionGap,
                      spacing.elementGap,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.layers,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: spacing.elementGap),
                        Text(
                          'Category Comparison',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (categoryData.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    child: _buildCategoryComparisonChart(
                      categoryData,
                      currentMonthName,
                      lastMonthName,
                      colorScheme,
                      textTheme,
                      spacing,
                      isGuestMode,
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(height: spacing.sectionGap),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComparisonBarChart(
    double currentIncome,
    double currentExpense,
    double currentBalance,
    double lastIncome,
    double lastExpense,
    double lastBalance,
    String currentMonthName,
    String lastMonthName,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final maxValue = [
      currentIncome,
      currentExpense,
      currentBalance.abs(),
      lastIncome,
      lastExpense,
      lastBalance.abs(),
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.chartBar,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                'Overview Comparison',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                    tooltipPadding: EdgeInsets.all(spacing.elementGap),
                    tooltipRoundedRadius: spacing.radiusSmall,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isCurrentMonth = rodIndex == 0;
                      final monthName =
                          isCurrentMonth ? currentMonthName : lastMonthName;
                      String category;
                      switch (groupIndex) {
                        case 0:
                          category = 'Income';
                          break;
                        case 1:
                          category = 'Expense';
                          break;
                        case 2:
                          category = 'Balance';
                          break;
                        default:
                          category = '';
                      }
                      return BarTooltipItem(
                        '$category\n$monthName\n₹${rod.toY.toStringAsFixed(0)}',
                        textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Income';
                            break;
                          case 1:
                            text = 'Expense';
                            break;
                          case 2:
                            text = 'Balance';
                            break;
                          default:
                            text = '';
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: spacing.elementGap),
                          child: Text(
                            text,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: currentIncome,
                        color: colorScheme.primary,
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                      BarChartRodData(
                        toY: lastIncome,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: currentExpense,
                        color: colorScheme.error,
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                      BarChartRodData(
                        toY: lastExpense,
                        color: colorScheme.error.withValues(alpha: 0.5),
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: currentBalance.abs(),
                        color: colorScheme.tertiary,
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                      BarChartRodData(
                        toY: lastBalance.abs(),
                        color: colorScheme.tertiary.withValues(alpha: 0.5),
                        width: 16,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(spacing.radiusSmall),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                currentMonthName,
                [colorScheme.primary, colorScheme.error, colorScheme.tertiary],
                textTheme,
                spacing,
              ),
              SizedBox(width: spacing.sectionGap),
              _buildLegendItem(
                lastMonthName,
                [
                  colorScheme.primary.withValues(alpha: 0.5),
                  colorScheme.error.withValues(alpha: 0.5),
                  colorScheme.tertiary.withValues(alpha: 0.5),
                ],
                textTheme,
                spacing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonChart(
    List<Map<String, dynamic>> categoryData,
    String currentMonthName,
    String lastMonthName,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isGuestMode,
  ) {
    final topCategories = categoryData.take(7).toList();

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.chartPie,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              Expanded(
                child: Text(
                  'Top Categories',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          ...topCategories.map((cat) {
            final categoryName = cat['name'] as String;
            final currentAmount = GuestModeUtil.applyGuestMode(
              cat['currentAmount'] as double,
              isGuestMode,
            );
            final lastAmount = GuestModeUtil.applyGuestMode(
              cat['lastAmount'] as double,
              isGuestMode,
            );
            final maxAmount =
                currentAmount > lastAmount ? currentAmount : lastAmount;
            final change = lastAmount > 0
                ? ((currentAmount - lastAmount) / lastAmount * 100)
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.elementGap * 0.75,
                          vertical: spacing.elementGap * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: (change < 0
                                  ? colorScheme.primary
                                  : colorScheme.error)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change < 0
                                  ? LucideIcons.arrowDown
                                  : LucideIcons.arrowUp,
                              color: change < 0
                                  ? colorScheme.primary
                                  : colorScheme.error,
                              size: 12,
                            ),
                            SizedBox(width: spacing.elementGap * 0.25),
                            Text(
                              '${change.abs().toStringAsFixed(0)}%',
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: change < 0
                                    ? colorScheme.primary
                                    : colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.elementGap * 0.75),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentMonthName,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹${currentAmount.toStringAsFixed(0)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.elementGap * 0.5),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusSmall),
                              child: LinearProgressIndicator(
                                value: maxAmount > 0
                                    ? currentAmount / maxAmount
                                    : 0,
                                minHeight: 8,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lastMonthName,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹${lastAmount.toStringAsFixed(0)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.elementGap * 0.5),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusSmall),
                              child: LinearProgressIndicator(
                                value:
                                    maxAmount > 0 ? lastAmount / maxAmount : 0,
                                minHeight: 8,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    List<Color> colors,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...colors.map(
          (color) => Padding(
            padding: EdgeInsets.only(right: spacing.cardHorizontalMin),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
            ),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(
    String label,
    double value,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.cardVerticalMin),
          CurrencyText(
            amount: value,
            fixedLength: 0,
            compact: false,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getComparisonData(
    IsarService isar,
    DateTime currentStart,
    DateTime currentEnd,
    DateTime lastStart,
    DateTime lastEnd,
  ) async {
    final db = await isar.getInstance();

    final currentTxns = await db.transactions
        .where()
        .dateBetween(currentStart, currentEnd)
        .findAll();

    final lastTxns =
        await db.transactions.where().dateBetween(lastStart, lastEnd).findAll();

    double currentIncome = 0, currentExpense = 0;
    double lastIncome = 0, lastExpense = 0;

    final Map<String, Map<String, double>> categoryMap = {};

    for (var txn in currentTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        currentIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        currentExpense += txn.amount;

        await txn.category.load();
        final category = txn.category.value;
        if (category != null) {
          final categoryName = category.name;
          if (!categoryMap.containsKey(categoryName)) {
            categoryMap[categoryName] = {'currentAmount': 0, 'lastAmount': 0};
          }
          categoryMap[categoryName]!['currentAmount'] =
              (categoryMap[categoryName]!['currentAmount'] ?? 0) + txn.amount;
        }
      }
    }

    for (var txn in lastTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        lastIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        lastExpense += txn.amount;

        await txn.category.load();
        final category = txn.category.value;
        if (category != null) {
          final categoryName = category.name;
          if (!categoryMap.containsKey(categoryName)) {
            categoryMap[categoryName] = {'currentAmount': 0, 'lastAmount': 0};
          }
          categoryMap[categoryName]!['lastAmount'] =
              (categoryMap[categoryName]!['lastAmount'] ?? 0) + txn.amount;
        }
      }
    }

    final categoryComparison = categoryMap.entries
        .map(
          (e) => {
            'name': e.key,
            'currentAmount': e.value['currentAmount'] ?? 0,
            'lastAmount': e.value['lastAmount'] ?? 0,
          },
        )
        .toList()
      ..sort((a, b) {
        final aTotal =
            (a['currentAmount'] as double) + (a['lastAmount'] as double);
        final bTotal =
            (b['currentAmount'] as double) + (b['lastAmount'] as double);
        return bTotal.compareTo(aTotal);
      });

    return {
      'currentIncome': currentIncome,
      'currentExpense': currentExpense,
      'lastIncome': lastIncome,
      'lastExpense': lastExpense,
      'categoryComparison': categoryComparison,
    };
  }

  static Widget _buildComparisonCardSkeleton(
    BuildContext context,
    AppSpacing spacing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Create individual skeleton boxes with shimmer
    Widget skeletonBox(
      double width,
      double height, {
      BorderRadius? borderRadius,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius:
              borderRadius ?? BorderRadius.circular(spacing.radiusSmall),
        ),
      ).animate(onComplete: (controller) => controller.repeat()).shimmer(
            duration: 1500.ms,
            color: colorScheme.surface.withValues(alpha: 0.5),
          );
    }

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              skeletonBox(
                48,
                48,
                borderRadius: BorderRadius.circular(
                  spacing.radiusMedium,
                ),
              ),
              SizedBox(width: spacing.elementGap),
              skeletonBox(100, 24),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  skeletonBox(100, 14),
                  SizedBox(height: spacing.elementGap),
                  skeletonBox(120, 24),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  skeletonBox(100, 14),
                  SizedBox(height: spacing.elementGap),
                  skeletonBox(100, 18),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          skeletonBox(150, 32),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double currentAmount;
  final double lastAmount;
  final double percentageChange;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations l10n;
  final String currentLabel;
  final String lastLabel;

  const _ComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentAmount,
    required this.lastAmount,
    required this.percentageChange,
    required this.colorScheme,
    required this.textTheme,
    required this.spacing,
    required this.l10n,
    required this.currentLabel,
    required this.lastLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentageChange >= 0;
    final changeColor = title == 'Expense'
        ? (isPositive ? colorScheme.error : colorScheme.primary)
        : (isPositive ? colorScheme.primary : colorScheme.error);

    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              SizedBox(width: spacing.elementGap * 1.5),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGap * 0.75,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                      color: changeColor,
                      size: 16,
                    ),
                    SizedBox(width: spacing.elementGap * 0.5),
                    Text(
                      '${percentageChange.abs().toStringAsFixed(1)}%',
                      style: textTheme.titleSmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 0.5),
                    Text(
                      'change',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sectionGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap * 0.5),
                  CurrencyText(
                    amount: currentAmount,
                    compact: false,
                    fixedLength: 0,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap * 0.5),
                  CurrencyText(
                    amount: lastAmount,
                    compact: false,
                    fixedLength: 0,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
