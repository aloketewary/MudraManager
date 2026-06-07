import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final Map<String, Color> categoryColors;

  const CategoryPieChart({
    super.key,
    required this.categoryData,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    final sections = categoryData.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title:
            '${(entry.value / categoryData.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1)}%',
        color: categoryColors[entry.key] ?? Colors.grey,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40),
    );
  }
}
