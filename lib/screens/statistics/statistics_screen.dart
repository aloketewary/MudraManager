import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/models/pie_chart_card.dart' show PieCategory;
import 'package:mudra_manager/providers/status_data_provider.dart'
    show statsProvider;
import 'package:mudra_manager/screens/reusable/no_data_found.dart';
import 'package:mudra_manager/screens/statistics/period_selector_screen.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatsState();
}

class _StatsState extends ConsumerState<StatisticsScreen> {
  String _period = 'Month';

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
              buildLineChart(d.incomeSpots, d.expenseSpots),
              const SizedBox(height: 16),
              buildMetricsRow(d.income, d.expense),
              const SizedBox(height: 16),
              Divider(indent: 8, endIndent: 8),
              Text(
                'By Category',
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
              buildCategoryPie(pieData),
              const SizedBox(height: 16),
              Divider(indent: 8, endIndent: 8),
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

  Widget buildMetricsRow(double income, double expense) {
    final net = income - expense;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricCard('Income', income, Colors.green, Icons.arrow_upward),
        _buildMetricCard('Expense', expense, Colors.red, Icons.arrow_downward),
        _buildMetricCard(
          'Net',
          net,
          net >= 0 ? Colors.lightGreenAccent : Colors.amberAccent,
          net >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
        ),
      ],
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
        width: 80,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 80,
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
                Text(
                  '₹${value.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(color: color.primary),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLineChart(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots) {
    final color = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [color.primary, color.primaryFixed],
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [color.tertiary, color.tertiaryFixed],
              ),
            ),
          ],
          titlesData: FlTitlesData(show: true),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget buildCategoryPie(List<PieCategory> pieData) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    if (pieData.isEmpty) {
      return NoDataFound(
        message: "Category not present.",
        imagePath: 'assets/icons/512/category.png',
      );
    }
    final sections =
        pieData.map((cat) {
          return PieChartSectionData(
            value: cat.value,
            title: cat.name,
            radius: 50,
            color: cat.color,
            // use your color here
            titleStyle: textTheme.titleMedium?.copyWith(
              color: color.onSecondary,
            ),
          );
        }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
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
        imagePath: 'assets/icons/512/transaction.png',
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
                              t.account.value?.accountType.name.toUpperCase() ??
                                  '',
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
                              color: color.primary
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
}
