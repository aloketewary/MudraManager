import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/common_dropdown_field.dart';

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
  List<Category> subcategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.categoryTrends.isEmpty) return;
    selectedCategory = widget.categoryTrends.keys.first;
    final DateTime now = DateTime.now();
    List.generate(12, (i) {
      trendMonths.add(DateTime(now.year, now.month - 11 + i, 1));
    });
    _loadSubcategories();
  }

  void _loadSubcategories() {
    subcategories = widget.categoryTrends.keys.where((cat) {
      cat.parentCategory.loadSync();
      return cat.parentCategory.value?.id == selectedCategory.id;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTrends.isEmpty) {
      return const Center(child: Text('No category trends available'));
    }

    final spots = widget.categoryTrends[selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonDropdownField<Category>(
                value: selectedCategory,
                items: widget.categoryTrends.keys.toList(),
                labelText: 'Category Type',
                hintText: 'Select Category',
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                    _loadSubcategories();
                  });
                },
                itemBuilder: (Category cat) =>
                    Row(children: [Text(cat.name.toUpperCase())]),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              icon: Icon(showLineChart ? Icons.bar_chart : LucideIcons.chartLine),
              onPressed: () => setState(() => showLineChart = !showLineChart),
              iconSize: 40,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.7,
          child: showLineChart
              ? _buildLineChart(context, spots)
              : _buildBarChart(context, spots),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, List<FlSpot> spots) {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    // Build line bars: parent + subcategories
    final lineBars = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 3,
        gradient: LinearGradient(
          colors: [
            Color(selectedCategory.colorValue ?? 0xFF000000).withAlpha(200),
            Color(selectedCategory.colorValue ?? 0xFF000000),
          ],
        ),
        dotData: const FlDotData(show: true),
      ),
    ];

    // Add subcategory lines
    for (final subcat in subcategories) {
      final subSpots = widget.categoryTrends[subcat] ?? [];
      if (subSpots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: subSpots,
            isCurved: true,
            barWidth: 2,
            color: Color(subcat.colorValue ?? 0xFF000000).withAlpha(150),
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        );
      }
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= spots.length) return const SizedBox.shrink();
                final month = trendMonths[index];
                return Text(
                  DateFormat.MMM(ctxt.localeName).format(month),
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  ctxt.formatCompactNumber().format(value),
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<FlSpot> spots) {
    final ctxt = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    final barGroups = spots.map((spot) {
      final x = spot.x.toInt();
      final rods = <BarChartRodData>[
        BarChartRodData(
          toY: spot.y,
          color: Color(selectedCategory.colorValue ?? 0xFF000000),
          width: subcategories.isEmpty ? 20 : 10,
        ),
      ];

      // Add subcategory bars
      for (final subcat in subcategories) {
        final subSpots = widget.categoryTrends[subcat] ?? [];
        if (x < subSpots.length) {
          rods.add(
            BarChartRodData(
              toY: subSpots[x].y,
              color: Color(subcat.colorValue ?? 0xFF000000).withAlpha(150),
              width: 10,
            ),
          );
        }
      }

      return BarChartGroupData(x: x, barRods: rods);
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
                return Text(
                  DateFormat.MMM(ctxt.localeName).format(month),
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  ctxt.formatCompactNumber().format(value),
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }
}
