import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class ChartLegend extends StatelessWidget {
  final Map<String, double> spentCategories;
  final List<Category> categories;
  final double total;
  final double spent;

  const ChartLegend({super.key, required this.spentCategories, required this.categories, required this.total, required this.spent});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          spentCategories.entries.map((entry) {
            final name = entry.key;
            final value = entry.value;
            final color = _getColorForCategory(name);
            final percent = total > 0 ? (value / total * 100) : 0;
            final valuePercent = value / total;
            final spentPercent = value / spent;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Flexible(
                  child: Text(
                    ctxt.budget_dashboardPieChartLabelText(ctxt.formatPercentNumber((spentPercent)), name, ctxt.formatPercentNumber((valuePercent))),
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Color _getColorForCategory(String title) {
    final category = categories.firstWhere((c) => c.name == title, orElse: () => Category()..colorValue = 0xFF9E9E9E);
    return Color(category.colorValue ?? 0xFF9E9E9E);
  }
}
