import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

class TripExpenseItem extends StatelessWidget {
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final String? currencyCode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TripExpenseItem({
    super.key,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    this.currencyCode,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.primaryContainer,
          child: Icon(LucideIcons.receipt, color: color.primary, size: 20),
        ),
        title: Text(description, style: textTheme.titleSmall),
        subtitle: Text(
          '${DateFormat.MMMd().format(date)} • Paid by $paidBy',
          style: textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCurrency(amount, code: currencyCode, decimals: 2),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
