import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetCategoryAllocation extends StatelessWidget {
  final String categoryName;
  final double allocatedAmount;
  final double totalBudget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCategoryAllocation({
    super.key,
    required this.categoryName,
    required this.allocatedAmount,
    required this.totalBudget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percentage = totalBudget > 0 ? (allocatedAmount / totalBudget * 100) : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(categoryName, style: textTheme.titleSmall),
        subtitle: LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(color.primary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formatCurrency(allocatedAmount, code: BaseCurrency.code)}',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                onEdit();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
