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
          balance >= 0 ? 'Gets back ₹${balance.abs().toStringAsFixed(2)}' : 'Owes ₹${balance.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
