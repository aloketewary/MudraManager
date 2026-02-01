import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/models/pie_chart_card.dart' show PieCategory;
import 'package:mudra_manager/providers/status_data_provider.dart'
    show StatsData, statsProvider;
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/statistics/expense_trend_widget.dart'
    show ExpenseTrendWidget;
import 'package:mudra_manager/screens/statistics/widgets/period_selector_chips.dart';
import 'package:mudra_manager/screens/statistics/widgets/hero_chart_card.dart';
import 'package:mudra_manager/screens/statistics/widgets/metric_carousel_card.dart';
import 'package:mudra_manager/screens/statistics/widgets/insight_grid_card.dart';
import 'package:mudra_manager/screens/statistics/widgets/detail_action_card.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/export_excel_pdf.dart'
    show exportStatsToExcel, exportStatsToPdf;
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/localization_extension.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with TickerProviderStateMixin {
  String _period = 'Month';
  StatsData? data;
  final GlobalKey pieKey = GlobalKey();
  final GlobalKey lineKey = GlobalKey();
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  bool _isDisposed = false;
  int? touchedIndex;
  final Set<int> _disabledCategoryIndexes = {};
  bool _showIncome = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
    });

    _animations =
        _controllers
            .map(
              (controller) => Tween<Offset>(
                begin: Offset(0, 0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut),
              ),
            )
            .toList();

    _runStaggeredAnimations();
  }

  void _runStaggeredAnimations() async {
    try {
      if (_controllers.isNotEmpty) {
        for (int i = 0; i < _controllers.length; i++) {
          await Future.delayed(Duration(milliseconds: 100));
          if (_isDisposed) return; // 🔐 Important check
          _controllers[i].forward();
        }
      }
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers = List.empty();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider(_period));
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return stats.when(
      data: (d) {
        setLatestData(d);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PeriodSelectorChips(
                selected: _period,
                onChange: (p) => setState(() => _period = p),
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                key: lineKey,
                child: HeroChartCard(
                  incomeSpots: d.incomeSpots,
                  expenseSpots: d.expenseSpots,
                  period: _period,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Overview',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 12),
              MetricCarouselCard(
                income: d.income,
                expense: d.expense,
                net: d.income - d.expense,
                savingsRate: d.savingsRate,
              ),
              const SizedBox(height: 24),
              Text(
                'Insights',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 12),
              InsightGridCard(
                topCategory:
                    d.categoryData.isNotEmpty
                        ? d.categoryData.entries.first.key
                        : 'N/A',
                topCategoryAmount:
                    d.categoryData.isNotEmpty
                        ? d.categoryData.entries.first.value
                        : 0,
                topCategoryPercent:
                    d.categoryData.isNotEmpty && d.expense > 0
                        ? (d.categoryData.entries.first.value / d.expense) * 100
                        : 0,
                avgDailySpend: d.avgDailySpend,
                topCategoryColor:
                    d.categoryData.isNotEmpty
                        ? Color(
                          d
                                  .categoryDataMap[d
                                      .categoryData
                                      .entries
                                      .first
                                      .key]
                                  ?.colorValue ??
                              0xFF000000,
                        )
                        : color.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Detailed Analysis',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 12),
              DetailActionCard(
                icon: Icons.pie_chart_outline,
                title: ctxt.statistics_byCategoryTitleText,
                subtitle: 'View category breakdown',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showCategoryBreakdown(context, d);
                },
              ),
              DetailActionCard(
                icon: Icons.trending_up_outlined,
                title: 'Expense Trends',
                subtitle: 'Last 12 months trends',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showExpenseTrends(context, d);
                },
              ),
              DetailActionCard(
                icon: Icons.history_outlined,
                title: ctxt.statistics_recentTransactionsTitleText,
                subtitle: 'Last 5 transactions',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showRecentTransactions(context, d);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget buildCategoryLegend(
    Map<String, double> categoryData,
    Map<String, Category> categoryMapData,
  ) {
    final textTheme = Theme.of(context).textTheme;

    final categories =
        categoryData.entries.map((entry) {
          var category = categoryMapData[entry.key];
          return PieCategory(
            name: entry.key,
            value: entry.value,
            color: Color(category?.colorValue ?? 0xFF000000),
          );
        }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          categories.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final isDisabled = _disabledCategoryIndexes.contains(index);

            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (isDisabled) {
                    _disabledCategoryIndexes.remove(index);
                  } else {
                    _disabledCategoryIndexes.add(index);
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: cat.color),
                  const SizedBox(width: 4),
                  Text(
                    cat.name.toUpperCase(),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight:
                          isDisabled ? FontWeight.normal : FontWeight.w600,
                      decoration:
                          isDisabled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget buildCategoryPie(
    Map<String, double> categoryData,
    Map<String, Category> categoryMapData,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    if (categoryData.isEmpty) {
      return NoDataFound(
        message: ctxt.statistics_categoryNotPresentText,
        iconData: Icons.category_outlined,
      );
    }

    final categories =
        categoryData.entries.map((entry) {
          var category = categoryMapData[entry.key];
          return PieCategory(
            name: entry.key,
            value: entry.value,
            color: Color(category?.colorValue ?? 0xFF000000),
          );
        }).toList();

    final total = categories.fold<double>(0, (sum, item) => sum + item.value);
    final indexMapping = <int>[];

    return SizedBox(
      height: 280,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(
          _disabledCategoryIndexes.toString() + categoryData.keys.join(),
        ),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, animatedFraction, child) {
          final sections =
              categories
                  .asMap()
                  .entries
                  .where(
                    (entry) => !_disabledCategoryIndexes.contains(entry.key),
                  )
                  .map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final animatedValue = cat.value * animatedFraction;
                    final isTouched = i == touchedIndex;
                    final percentage =
                        total > 0 ? (animatedValue / total) : 0.0;
                    indexMapping.add(entry.key);

                    return PieChartSectionData(
                      value: animatedValue,
                      gradient: LinearGradient(
                        colors: [
                          cat.color.withAlpha(180),
                          cat.color.withAlpha(200),
                          cat.color,
                        ],
                      ),
                      radius: isTouched ? 80 : 60 * animatedFraction,
                      title: ctxt.formatPercentNumber(percentage),
                      titleStyle: textTheme.bodySmall?.copyWith(
                        color: color.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  })
                  .toList();

          return PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (
                  FlTouchEvent event,
                  PieTouchResponse? response,
                ) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    return;
                  }

                  final touchedFilteredIndex =
                      response.touchedSection!.touchedSectionIndex;
                  final originalIndex =
                      touchedFilteredIndex >= 0
                          ? indexMapping[touchedFilteredIndex]
                          : touchedFilteredIndex;
                  setState(() {
                    touchedIndex = originalIndex;
                  });
                },
              ),
              sections: sections,
              centerSpaceRadius: 40 * animatedFraction,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          );
        },
      ),
    );
  }

  Widget buildRecentTransactions(List<Transaction> list) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    if (list.isEmpty) {
      return NoDataFound(
        message: ctxt.statistics_transactionNotPresentText,
        iconData: Icons.receipt_long_outlined,
      );
    }
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: min(list.length, 5),
          itemBuilder: (c, i) {
            final t = list[i];
            t.category.loadSync();
            t.account.loadSync();
            final categoryColor = Color(
              t.category.value?.colorValue ?? 0xFF000000,
            );

            return SlideTransition(
              position: _animations[i],
              child: FadeTransition(
                opacity: _controllers[i],
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(
                          '/add-transaction',
                          extra: {'transaction': t},
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                IconHelper.getIconData(
                                  t.category.value?.iconName,
                                ),
                                color: categoryColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.category.value?.name ?? '',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${t.account.value?.name} • ${t.account.value?.accountType.name.toTitleCase()}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${t.isExpense ? '-' : '+'} ${ctxt.formatCurrencyWithSign(2, t.amount)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        t.isExpense
                                            ? color.error
                                            : color.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'MMM dd',
                                    ctxt.localeName,
                                  ).format(t.date),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Center(
          child: TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/transactions');
            },
            child: Text(ctxt.statistics_showAllButtonText.toUpperCase()),
          ),
        ),
      ],
    );
  }

  void showExportOptions(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(ctxt.statistics_exportToPdfButtonText),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  context.pop();
                  final lineImage = await captureChartAsImage(lineKey);
                  exportStatsToPdf(context, data!, null, lineImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(ctxt.statistics_exportToExcelButtonText),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.pop();
                  exportStatsToExcel(data!);
                },
              ),
            ],
          ),
    );
  }

  void _showCategoryBreakdown(BuildContext context, StatsData d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Category Breakdown',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 8),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Exp'),
                                  icon: Icon(Icons.arrow_downward, size: 16),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Inc'),
                                  icon: Icon(Icons.arrow_upward, size: 16),
                                ),
                              ],
                              selected: {_showIncome},
                              onSelectionChanged: (newSelection) {
                                final newValue = newSelection.first;
                                Navigator.of(context).pop();
                                setState(() {
                                  _showIncome = newValue;
                                  _disabledCategoryIndexes.clear();
                                  touchedIndex = null;
                                });
                                Future.microtask(
                                  () => _showCategoryBreakdown(context, d),
                                );
                              },
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: EdgeInsets.all(16),
                          children: [
                            RepaintBoundary(
                              key: pieKey,
                              child: Column(
                                children: [
                                  buildCategoryPie(
                                    _showIncome
                                        ? d.incomeCategoryData
                                        : d.categoryData,
                                    _showIncome
                                        ? d.incomeCategoryMapData
                                        : d.categoryDataMap,
                                  ),
                                  SizedBox(height: 16),
                                  buildCategoryLegend(
                                    _showIncome
                                        ? d.incomeCategoryData
                                        : d.categoryData,
                                    _showIncome
                                        ? d.incomeCategoryMapData
                                        : d.categoryDataMap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showExpenseTrends(BuildContext context, StatsData d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Expense Trends',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: EdgeInsets.all(16),
                          children: [
                            ExpenseTrendWidget(
                              categoryTrends: d.categoryTrends,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showRecentTransactions(BuildContext context, StatsData d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Recent Transactions',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: EdgeInsets.all(16),
                          children: [buildRecentTransactions(d.recent)],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void setLatestData(StatsData d) {
    setState(() {
      data = d;
    });
  }

  Future<Uint8List> captureChartAsImage(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
