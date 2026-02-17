import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/components/currency_text.dart';

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
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var categoryColor = Color(category.colorValue ?? 0xFF000000);
    final ctxt = AppLocalizations.of(context)!;

    final progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > allocated;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIconData(category.iconName),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (isOverBudget)
                  Icon(Icons.warning_amber_rounded, size: 16, color: color.error),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: CurrencyText(
                    amount: spent,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  ' / ',
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Flexible(
                  child: CurrencyText(
                    amount: allocated,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: categoryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? color.error : categoryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
