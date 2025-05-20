import 'dart:math';
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/models/pie_chart_card.dart' show PieCategory;
import 'package:mudra_manager/providers/status_data_provider.dart' show StatsData, statsProvider;
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/reusable/responseive_layout_builder.dart';
import 'package:mudra_manager/screens/statistics/expense_trend_widget.dart' show ExpenseTrendWidget;
import 'package:mudra_manager/screens/statistics/period_selector_screen.dart';
import 'package:mudra_manager/screens/transaction/transaction_list_screen.dart' show TransactionListScreen;
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/export_excel_pdf.dart' show exportStatsToExcel, exportStatsToPdf;
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/localization_extension.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends ConsumerState<StatisticsScreen> with TickerProviderStateMixin {
  String _period = 'Month';
  StatsData? data;
  final GlobalKey pieKey = GlobalKey();
  final GlobalKey lineKey = GlobalKey();
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  bool _isDisposed = false;
  int? touchedIndex;
  final Set<int> _disabledCategoryIndexes = {};

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    });

    _animations =
        _controllers
            .map(
              (controller) =>
                  Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
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
    final stats = ref.watch(statsProvider(_period)); // income, expense, spots, pieData, recentTxns
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return stats.when(
      data: (d) {
        setLatestData(d);
        List<PieCategory> pieData =
            d.categoryData.entries.map((entry) {
              var categoryData = d.categoryDataMap[entry.key];
              return PieCategory(name: entry.key, value: entry.value, color: Color(categoryData?.colorValue ?? 0xFF000000));
            }).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PeriodSelector(selected: _period, onChange: (p) => setState(() => _period = p)),
              const SizedBox(height: 16),
              RepaintBoundary(key: lineKey, child: buildLineChartWithLegend(d.incomeSpots, d.expenseSpots, _period)),
              const SizedBox(height: 16),
              buildMetricsRow(d.income, d.expense),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Text(
                    ctxt.statistics_weTrimDownDecimalInfoText,
                    style: textTheme.labelSmall?.copyWith(color: color.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: color.primary),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                iconColor: color.primary,
                leading: Icon(Icons.pie_chart_outline, color: color.primary),
                title: Text(ctxt.statistics_byCategoryTitleText, style: textTheme.titleMedium?.copyWith(color: color.primary)),
                subtitle: Text("Category wise expense chart", style: textTheme.labelSmall?.copyWith(color: color.primary)),
                children: [
                  RepaintBoundary(
                    key: pieKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [buildCategoryPie(pieData), buildCategoryLegend(pieData)]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: color.primary,
                maintainState: true,
                leading: Icon(Icons.trending_up_outlined, color: color.primary),
                title: Text("Expense Trend by Category", style: textTheme.titleMedium?.copyWith(color: color.primary)),
                subtitle: Text("Last 12 months category wise expense trends", style: textTheme.labelSmall?.copyWith(color: color.primary)),
                children: [ExpenseTrendWidget(categoryTrends: d.categoryTrends), SizedBox(height: 8)],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: color.primary,
                maintainState: true,
                leading: Icon(Icons.history_outlined, color: color.primary),
                title: Text(ctxt.statistics_recentTransactionsTitleText, style: textTheme.titleMedium?.copyWith(color: color.primary)),
                subtitle: Text("Last 5 latest transactions", style: textTheme.labelSmall?.copyWith(color: color.primary)),
                children: [buildRecentTransactions(d.recent), SizedBox(height: 8)],
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

  Widget buildCategoryLegend(List<PieCategory> data) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          data.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final isDisabled = _disabledCategoryIndexes.contains(index);

            return GestureDetector(
              onTap: () {
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
                      fontWeight: isDisabled ? FontWeight.normal : FontWeight.w600,
                      decoration: isDisabled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget buildMetricsRow(double income, double expense) {
    final net = income - expense;
    final ctxt = AppLocalizations.of(context)!;
    return ResponsiveLayoutBuilder(
      columnWidget: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMetricCard(ctxt.statistics_metricIncomeText, income, Icons.arrow_upward),
          SizedBox(height: 8),
          _buildMetricCard(ctxt.statistics_metricExpenseText, expense, Icons.arrow_downward),
          SizedBox(height: 8),
          _buildMetricCard(ctxt.statistics_metricNetText, net, net >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
        ],
      ),
      rowWidget: SizedBox(
        height: 200,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(ctxt.statistics_metricIncomeText, income, Icons.arrow_upward),
                _buildMetricCard(ctxt.statistics_metricExpenseText, expense, Icons.arrow_downward),
              ],
            ),
            SizedBox(height: 8),
            _buildMetricCard(ctxt.statistics_metricNetText, net, net >= 0 ? Icons.arrow_upward : Icons.arrow_downward, isNetCard: true),
          ],
        ),
      ),
      sizedBoxHeight: 280,
    );
  }

  Widget _buildMetricCard(String title, double value, IconData iconData, {bool isNetCard = false}) {
    double allBoxWidthFactor = 0.2;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: (allBoxWidthFactor * 100).toInt(),
      child: SizedBox(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(right: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: isNetCard ? color.primary : Colors.transparent,
              border: Border.all(color: color.primary), // Subtle border
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(radius: 16, child: Icon(iconData, size: 16)),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: isNetCard ? color.onPrimary : color.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                AnimatedBalance(
                  value: value,
                  style: textTheme.titleLarge?.copyWith(color: isNetCard ? color.onPrimary : color.primary),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  fixedStringLength: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildLineChartWithLegend(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots, String period) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIncome ? ctxt.statistics_chartLineIncomeText : ctxt.statistics_chartLineExpenseText}: ${ctxt.formatCurrencyWithSign(0, spot.y)}',
                        TextStyle(color: spot.bar.gradient?.colors.first, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  gradient: LinearGradient(colors: [color.primary, color.primaryFixed]),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  gradient: LinearGradient(colors: [color.tertiary, color.tertiaryFixed]),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: period == 'Today' ? 6 : 1,
                    getTitlesWidget: (value, _) {
                      // Cast value to int for _getXAxisLabel
                      final int index = value.toInt();
                      return Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _getXAxisLabel(index, period),
                          style: textTheme.bodySmall?.copyWith(color: color.onSurface, fontWeight: FontWeight.w500, fontSize: 8),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) => Text(_formatCompactNumber(value), style: textTheme.bodySmall),
                    reservedSize: 40,
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              minY: 0,
            ),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(color.primary, ctxt.statistics_chartLineIncomeText),
            const SizedBox(width: 16),
            _buildLegendItem(color.tertiary, ctxt.statistics_chartLineExpenseText),
          ],
        ),
      ],
    );
  }

  String _getXAxisLabel(int index, String filter) {
    final ctxt = AppLocalizations.of(context)!;
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        // Show hourly labels
        return ctxt.statistics_chartLineTodayHourText(ctxt.formatCompactNumber().format(index));
      case 'Week':
        // Show weekday labels
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('E', ctxt.localeName).format(date); // Mon, Tue...
      case 'Month':
        // Show dates of the month
        return ctxt.formatCompactNumber().format(index + 1);
      case 'Year':
        // Show months
        return DateFormat('MMM', ctxt.localeName).format(DateTime(now.year, index + 1));
      default:
        return DateFormat('MMM', ctxt.localeName).format(DateTime(now.year, index + 1));
    }
  }

  String _formatCompactNumber(double value) {
    final ctxt = AppLocalizations.of(context)!;
    return ctxt.formatCurrencyWithSign(1, value, compact: true);
  }

  Widget buildCategoryPie(List<PieCategory> pieData) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    if (pieData.isEmpty) {
      return NoDataFound(message: ctxt.statistics_categoryNotPresentText, iconData: Icons.category_outlined);
    }

    final total = pieData.fold<double>(0, (sum, item) => sum + item.value);
    final indexMapping = <int>[];

    return SizedBox(
      height: 280,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_disabledCategoryIndexes),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, animatedFraction, child) {
          final sections =
              pieData.asMap().entries.where((entry) => !_disabledCategoryIndexes.contains(entry.key)).map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final animatedValue = cat.value * animatedFraction;
                final isTouched = i == touchedIndex;
                final percentage = total > 0 ? (animatedValue / total) : 0.0;
                indexMapping.add(entry.key);

                return PieChartSectionData(
                  value: animatedValue,
                  gradient: LinearGradient(colors: [cat.color.withAlpha(180), cat.color.withAlpha(200), cat.color]),
                  radius: isTouched ? 80 : 60 * animatedFraction,
                  title: ctxt.formatPercentNumber(percentage),
                  titleStyle: textTheme.bodySmall?.copyWith(color: color.secondary, fontWeight: FontWeight.bold),
                );
              }).toList();

          return PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                  if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) return;

                  final touchedFilteredIndex = response.touchedSection!.touchedSectionIndex;
                  final originalIndex = touchedFilteredIndex >= 0 ? indexMapping[touchedFilteredIndex] : touchedFilteredIndex;
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
      return NoDataFound(message: ctxt.statistics_transactionNotPresentText, iconData: Icons.receipt_long_outlined);
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
            return SlideTransition(
              position: _animations[i],
              child: FadeTransition(
                opacity: _controllers[i],
                child: Card.outlined(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0), side: BorderSide(width: 1, color: color.primary)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.0),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: <Widget>[
                              Container(
                                width: 48.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: Color(t.category.value?.colorValue ?? 0xFF000000),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(IconHelper.getIconData(t.category.value?.iconName), color: color.onPrimary, size: 24.0),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text("${t.category.value?.name}", style: textTheme.labelLarge?.copyWith(color: color.primary)),
                                    Text(
                                      '${t.account.value?.name} - ${t.account.value?.accountType.name.toTitleCase()}',
                                      style: textTheme.labelMedium?.copyWith(color: color.primary),
                                    ),
                                    if (t.description != '')
                                      Text(
                                        t.description ?? '',
                                        style: textTheme.labelSmall?.copyWith(color: color.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    '${t.isExpense ? '-' : '+'} ${ctxt.formatCurrencyWithSign(2, t.amount)}',
                                    style: textTheme.titleLarge?.copyWith(color: color.primary),
                                  ),
                                  Text(
                                    DateFormat('EEE, dd MMM yyyy', ctxt.localeName).format(t.date),
                                    style: textTheme.labelSmall?.copyWith(color: color.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 300),
                  pageBuilder: (_, animation, secondaryAnimation) => TransactionListScreen(showAppBar: true),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
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
                  Navigator.pop(context);
                  Uint8List pieImage = await captureChartAsImage(pieKey);
                  Uint8List lineImage = await captureChartAsImage(lineKey);

                  exportStatsToPdf(context, data!, pieImage, lineImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(ctxt.statistics_exportToExcelButtonText),
                onTap: () {
                  Navigator.pop(context);
                  exportStatsToExcel(data!);
                },
              ),
            ],
          ),
    );
  }

  void setLatestData(StatsData d) {
    setState(() {
      data = d;
    });
  }

  Future<Uint8List> captureChartAsImage(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
