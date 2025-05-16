import 'dart:math';
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/models/pie_chart_card.dart' show PieCategory;
import 'package:mudra_manager/providers/status_data_provider.dart'
    show StatsData, statsProvider;
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/reusable/responseive_layout_builder.dart';
import 'package:mudra_manager/screens/statistics/period_selector_screen.dart';
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

class StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _period = 'Month';
  StatsData? data;
  final GlobalKey pieKey = GlobalKey();
  final GlobalKey lineKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // You’d fetch data via Riverpod providers based on _period:
    final stats = ref.watch(
      statsProvider(_period),
    ); // income, expense, spots, pieData, recentTxns
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return stats.when(
      data: (d) {
        setLatestData(d);
        List<PieCategory> pieData =
            d.categoryData.entries.map((entry) {
              var categoryData = d.categoryDataMap[entry.key];
              return PieCategory(
                name: entry.key,
                value: entry.value,
                color: Color(categoryData?.colorValue ?? 0xFF000000),
              );
            }).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PeriodSelector(
                selected: _period,
                onChange: (p) => setState(() => _period = p),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: lineKey,
                child: buildLineChartWithLegend(
                  d.incomeSpots,
                  d.expenseSpots,
                  _period,
                ),
              ),
              const SizedBox(height: 16),
              buildMetricsRow(d.income, d.expense),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Text(
                    'We trim down decimal places, please round off if required.',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(indent: 8, endIndent: 8, color: color.primary),
              Text(
                'By Category',
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
              RepaintBoundary(
                key: pieKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildCategoryPie(pieData),
                    buildCategoryLegend(pieData),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(indent: 8, endIndent: 8, color: color.primary),
              Text(
                'Recent Transactions',
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
              buildRecentTransactions(d.recent),
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
          data.map((cat) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: cat.color),
                const SizedBox(width: 4),
                Text(cat.name, style: textTheme.labelMedium),
              ],
            );
          }).toList(),
    );
  }

  Widget buildMetricsRow(double income, double expense) {
    final net = income - expense;
    return ResponsiveLayoutBuilder(
      columnWidget: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMetricCard('Income', income, Colors.green, Icons.arrow_upward),
          SizedBox(height: 8),
          _buildMetricCard(
            'Expense',
            expense,
            Colors.red,
            Icons.arrow_downward,
          ),
          SizedBox(height: 8),
          _buildMetricCard(
            'Net',
            net,
            net >= 0 ? Colors.lightGreenAccent : Colors.amberAccent,
            net >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ],
      ),
      rowWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCard('Income', income, Colors.green, Icons.arrow_upward),
          _buildMetricCard(
            'Expense',
            expense,
            Colors.red,
            Icons.arrow_downward,
          ),
          _buildMetricCard(
            'Net',
            net,
            net >= 0 ? Colors.lightGreenAccent : Colors.amberAccent,
            net >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ],
      ),
      sizedBoxHeight: 280,
    );
  }

  Widget _buildMetricCard(
    String title,
    double value,
    Color colorScheme,
    IconData iconData,
  ) {
    double allBoxWidthFactor = 0.2;
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: (allBoxWidthFactor * 100).toInt(),
      child: SizedBox(
        // width: 80,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            // width: 80,
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(right: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              // color: color.primary,
              // Light background color
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                AnimatedBalance(
                  value: value,
                  style: textTheme.titleLarge?.copyWith(color: color.primary),
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildLineChartWithLegend(
    List<FlSpot> incomeSpots,
    List<FlSpot> expenseSpots,
    String period,
  ) {
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
                  // tooltipBgColor: color.surfaceVariant,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIncome ? 'Income' : 'Expense'}: ${ctxt.formatLocalizedNumberWithSign(0, ctxt.localeName, spot.y)}',
                        TextStyle(
                          color: spot.bar.gradient?.colors.first,
                          fontWeight: FontWeight.bold,
                        ),
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
                  gradient: LinearGradient(
                    colors: [color.primary, color.primaryFixed],
                  ),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  gradient: LinearGradient(
                    colors: [color.tertiary, color.tertiaryFixed],
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: period == 'Today' ? 6 : 1,
                    getTitlesWidget:
                        (value, _) => Text(
                          _getXAxisLabel(value.toInt(), period),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, _) => Text(
                          _formatCompactNumber(value),
                          style: textTheme.bodySmall,
                        ),
                    reservedSize: 40,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              minY: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(color.primary, "Income"),
            const SizedBox(width: 16),
            _buildLegendItem(color.tertiary, "Expense"),
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
        return '${index}h';
      case 'Week':
        // Show weekday labels
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('E', ctxt.localeName).format(date); // Mon, Tue...
      case 'Month':
        // Show dates of the month
        return ctxt.formatLocalizedNumber(ctxt.localeName).format(index + 1);
      case 'Year':
        // Show months
        return DateFormat(
          'MMM',
          ctxt.localeName,
        ).format(DateTime(now.year, index + 1));
      default:
        return DateFormat(
          'MMM',
          ctxt.localeName,
        ).format(DateTime(now.year, index + 1));
    }
  }

  String _formatCompactNumber(double value) {
    final ctxt = AppLocalizations.of(context)!;
    return ctxt.formatLocalizedNumberWithSign(
      1,
      ctxt.localeName,
      value,
      compact: true,
    );
  }

  Widget buildCategoryPie(List<PieCategory> pieData) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (pieData.isEmpty) {
      return NoDataFound(
        message: "Category not present.",
        iconData: Icons.category_outlined,
      );
    }

    final total = pieData.fold<double>(0, (sum, item) => sum + item.value);

    final sections =
        pieData.map((cat) {
          final percentage =
              total > 0 ? (cat.value / total * 100).toStringAsFixed(1) : '0';
          return PieChartSectionData(
            value: cat.value,
            title: '$percentage%',
            radius: 60,
            color: cat.color,
            titleStyle: textTheme.bodySmall?.copyWith(
              color: color.onSecondary,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget buildRecentTransactions(List<Transaction> list) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    if (list.isEmpty) {
      return NoDataFound(
        message: "Transactions not present.",
        iconData: Icons.receipt_long_outlined,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: min(list.length, 5),
      itemBuilder: (c, i) {
        final t = list[i];
        t.category.loadSync();
        t.account.loadSync();
        return Card.outlined(
          // shadowColor: color.surface,
          // color: Color(t.category.value?.colorValue ?? 0x00FFFEEE).withAlpha(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(width: 1, color: color.primary),
          ),
          child: InkWell(
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
                          color: Color(
                            t.category.value?.colorValue ?? 0xFF000000,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            IconHelper.getIconData(t.category.value?.iconName),
                            color: color.onPrimary,
                            size: 24.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "${t.category.value?.name}",
                              style: textTheme.labelLarge?.copyWith(
                                color: color.primary,
                              ),
                            ),
                            Text(
                              '${t.account.value?.name} - ${t.account.value?.accountType.name.toTitleCase()}',
                              style: textTheme.labelMedium?.copyWith(
                                color: color.primary,
                              ),
                            ),
                            if (t.description != '')
                              Text(
                                t.description ?? '',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.primary,
                                ),
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
                            "${t.isExpense ? "-" : "+"} ₹${t.amount}",
                            style: textTheme.titleLarge?.copyWith(
                              color: color.primary,
                            ),
                          ),
                          Text(
                            DateFormat('EEE, dd MMM yyyy').format(t.date),
                            style: textTheme.labelSmall?.copyWith(
                              color: color.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export to PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  Uint8List pieImage = await captureChartAsImage(pieKey);
                  Uint8List lineImage = await captureChartAsImage(lineKey);

                  exportStatsToPdf(context, data!, pieImage, lineImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export to Excel'),
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
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
