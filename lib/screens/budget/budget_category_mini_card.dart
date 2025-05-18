import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class BudgetCategoryMiniCard extends StatelessWidget {
  final Category category;
  final double allocated;
  final double spent;

  const BudgetCategoryMiniCard({super.key, required this.category, required this.allocated, required this.spent});

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var categoryColor = Color(category.colorValue ?? 0xFF000000);
    final ctxt = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => {},
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [color.surfaceDim, color.surface, categoryColor.withAlpha(90)],
          ),
          border: Border.all(color: color.primary), // Subtle border
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Icon(IconHelper.getIconData(category.iconName), color: color.primary, size: 24),
                Text(
                  ctxt.formatPercentNumber((spent / allocated)),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: color.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: color.primary),
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      ctxt.formatCurrencyWithSign(0, spent),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: color.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ctxt.formatCurrencyWithSign(0, allocated),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: color.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: spent / allocated,
                  semanticsValue: spent.toStringAsFixed(0),
                  backgroundColor: color.secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(color.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
