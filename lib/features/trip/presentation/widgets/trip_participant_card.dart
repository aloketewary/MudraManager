import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';

class TripParticipantCard extends StatelessWidget {
  final String name;
  final double amountPaid;
  final double amountOwed;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TripParticipantCard({
    super.key,
    required this.name,
    required this.amountPaid,
    required this.amountOwed,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final balance = amountPaid - amountOwed;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.primaryContainer,
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(color: color.onPrimaryContainer),
          ),
        ),
        title: Text(name, style: textTheme.titleMedium),
        subtitle: Text(
          balance >= 0 ? 'Gets back ${formatCurrency(balance.abs(), decimals: 2)}' : 'Owes ${formatCurrency(balance.abs(), decimals: 2)}',
          style: TextStyle(
            color: balance >= 0 ? FinanceColors.statusGood : FinanceColors.statusDanger,
          ),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
