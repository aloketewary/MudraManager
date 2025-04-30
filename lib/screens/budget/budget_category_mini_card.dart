import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/util/icon_helper.dart';

class BudgetCategoryMiniCard extends StatelessWidget {
  final Category category;
  final double allocated;
  final double spent;

  const BudgetCategoryMiniCard({
    super.key,
    required this.category,
    required this.allocated,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    var colorTheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var categoryColor = Color(category.colorValue ?? 0xFF000000);
    return GestureDetector(
      onTap: () => {},
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: categoryColor.withAlpha(58), // Light background color
          border: Border.all(color: categoryColor), // Subtle border
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Icon(
                  IconHelper.getIconData(category.iconName),
                  color: Colors.white,
                  size: 24,
                ),
                Text(
                  "${(spent / allocated * 100).toStringAsFixed(0)}%",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorTheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorTheme.onPrimaryContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "₹${spent.toStringAsFixed(0)}",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorTheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "₹${allocated.toStringAsFixed(0)}",
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorTheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: spent / allocated,
                  semanticsValue: spent.toStringAsFixed(0),
                  backgroundColor: colorTheme.onSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
