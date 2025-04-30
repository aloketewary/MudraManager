import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart' show Category;

class NestedCircularChart extends StatelessWidget {
  final double total;
  final double spent;
  final Map<String, double> spentCategories;
  final List<Category> categories;

  const NestedCircularChart({
    super.key,
    required this.total,
    required this.spent,
    required this.spentCategories,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 50,
        sections: _generatePieChartSections(context),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(BuildContext context) {
    final remaining = total - spent;
    final totalSpent = spentCategories.values.fold(
      0,
      (sum, value) => sum + value.toInt(),
    );
    final List<PieChartSectionData> sections = [];
    final color = Theme.of(context).colorScheme;

    // 1. Segment for Remaining (if any)
    if (remaining > 0) {
      sections.add(
        PieChartSectionData(
          value: remaining,
          color: color.secondary,
          title: '${(remaining / total * 100).toStringAsFixed(1)}%',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.black),
        ),
      );
    }

    // 2. Segments for Spent Categories
    spentCategories.forEach((title, value) {
      final percentageOfTotal = (value / total * 100);
      final percentageOfSpent = (value / spent * 100);
      const double radius = 40; // Keep the same radius for merging

      sections.add(
        PieChartSectionData(
          value: value,
          color: _getColorForCategory(title),
          // You'll need to define this
          title:
              '$title\n${percentageOfTotal.toStringAsFixed(1)}% (of Total)\n${percentageOfSpent.toStringAsFixed(1)}% (of Spent)',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      );
    });

    return sections;
  }

  _getColorForCategory(title) {
    final category = categories.firstWhere(
      (category) => category.name == title,
    );
    return Color(category.colorValue ?? 0xFF000000);
  }
}
