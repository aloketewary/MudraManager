import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/screens/reusable/common_dropdown_field.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class ExpenseTrendWidget extends StatefulWidget {
  final Map<Category, List<FlSpot>> categoryTrends;

  const ExpenseTrendWidget({super.key, required this.categoryTrends});

  @override
  State<ExpenseTrendWidget> createState() => _ExpenseTrendWidgetState();
}

class _ExpenseTrendWidgetState extends State<ExpenseTrendWidget> {
  late Category selectedCategory;
  bool showLineChart = true;
  final List<DateTime> trendMonths = [];

  @override
  void initState() {
    super.initState();
    // Initialize with first available category
    selectedCategory = widget.categoryTrends.keys.first;
    DateTime now = DateTime.now();
    List.generate(12, (i) {
      trendMonths.add(DateTime(now.year, now.month - 11 + i, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.categoryTrends[selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category dropdown and chart toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonDropdownField<Category>(
                value: selectedCategory,
                items: widget.categoryTrends.keys.toList(),
                labelText: 'Category Type',
                hintText: 'Select Category',
                onChanged: (value) => setState(() => selectedCategory = value!),
                itemBuilder: (Category cat) => Row(children: [Text(cat.name.toUpperCase())]),
              ),
            ),
            SizedBox(width: 12),
            IconButton.filled(
              icon: Icon(showLineChart ? Icons.bar_chart : Icons.show_chart),
              onPressed: () {
                setState(() {
                  showLineChart = !showLineChart;
                });
              },
              iconSize: 40,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(aspectRatio: 1.7, child: showLineChart ? _buildLineChart(context, spots) : _buildBarChart(context, spots)),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, List<FlSpot> spots) {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            preventCurveOverShooting: true,
            spots: spots,
            isCurved: true,
            barWidth: 3,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(selectedCategory.colorValue ?? 0xFF000000).withAlpha(200),
                Color(selectedCategory.colorValue ?? 0xFF000000),
                color.primary,
              ],
            ),
            dotData: FlDotData(show: true),
            isStepLineChart: false,
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= spots.length) return const SizedBox.shrink();
                final month = trendMonths[index];
                return Text(DateFormat.MMM(ctxt.localeName).format(month), style: const TextStyle(fontSize: 8));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(ctxt.formatCompactNumber().format(value), style: const TextStyle(fontSize: 8));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<FlSpot> spots) {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final barGroups =
        spots.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(selectedCategory.colorValue ?? 0xFF000000).withAlpha(200),
                    Color(selectedCategory.colorValue ?? 0xFF000000),
                    color.primary,
                  ],
                ),
              ),
            ],
          );
        }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= spots.length) return const SizedBox.shrink();
                final month = trendMonths[value.toInt()];
                return Text(DateFormat.MMM(ctxt.localeName).format(month), style: const TextStyle(fontSize: 8));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(ctxt.formatCompactNumber().format(value), style: const TextStyle(fontSize: 8));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
