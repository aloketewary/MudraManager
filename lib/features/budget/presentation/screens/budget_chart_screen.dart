import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

class NestedCircularChart extends StatefulWidget {
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
  State<NestedCircularChart> createState() => NestedCircularChartState();
}

class NestedCircularChartState extends State<NestedCircularChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedFraction, child) {
        return PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  touchedIndex = response?.touchedSection?.touchedSectionIndex;
                });
              },
            ),
            sections: _generateAnimatedSections(context, animatedFraction),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _generateAnimatedSections(
    BuildContext context,
    double animatedFraction,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final remaining = widget.total - widget.spent;
    final List<PieChartSectionData> sections = [];
    final color = Theme.of(context).colorScheme;

    // Add remaining budget
    if (remaining > 0) {
      sections.add(
        PieChartSectionData(
          value: remaining * animatedFraction,
          color: color.secondary,
          radius: touchedIndex == 0 ? 40 : 35,
          title: ctxt.formatPercentNumber(
            (remaining / widget.total) * animatedFraction,
          ),
          titleStyle: TextStyle(fontSize: 10, color: color.onSecondary),
        ),
      );
    }

    // Add spent categories
    final int indexOffset = remaining > 0 ? 1 : 0;
    int i = 0;
    widget.spentCategories.forEach((title, value) {
      final idx = i + indexOffset;
      final valuePercent = value / widget.total;
      final spentPercent = value / widget.spent;

      sections.add(
        PieChartSectionData(
          value: value * animatedFraction,
          gradient: LinearGradient(
            colors: [
              _getColorForCategory(title).withAlpha(180),
              _getColorForCategory(title).withAlpha(200),
              _getColorForCategory(title),
            ],
          ),
          radius: touchedIndex == idx ? 40 : 35,
          title: title,
          titleStyle: TextStyle(
            fontSize: 8,
            color: color.secondary,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 1)],
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  Color _getColorForCategory(String title) {
    final category = widget.categories.firstWhere(
      (c) => c.name == title,
      orElse: () => Category()..colorValue = 0xFF9E9E9E, // grey fallback
    );
    return Color(category.colorValue ?? 0xFF9E9E9E);
  }
}
