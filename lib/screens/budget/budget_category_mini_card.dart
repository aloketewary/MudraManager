import 'package:flutter/material.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate progress with safety
    final progress = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > allocated;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.glassGradient(categoryColor, isDark),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: categoryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: AppColors.glassShadow(categoryColor, isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  IconHelper.getIconData(category.iconName),
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (isOverBudget)
                Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.expense),
            ],
          ),
          const Spacer(),
          Text(
            category.name,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: categoryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${ctxt.formatCurrencyWithSign(0, spent)} / ${ctxt.formatCurrencyWithSign(0, allocated)}",
            style: textTheme.bodySmall?.copyWith(
              color: categoryColor.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: categoryColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? AppColors.expense : categoryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
