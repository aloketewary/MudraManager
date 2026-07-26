import 'package:flutter/material.dart';

/// Standard transaction row with icon, metadata, and amount.
/// Used in transaction lists.
class TransactionRow extends StatelessWidget {
  final String title;
  final String meta;
  final String amount;
  final bool isInflow;
  final IconData icon;
  final VoidCallback? onTap;

  const TransactionRow({
    super.key,
    required this.title,
    required this.meta,
    required this.amount,
    required this.isInflow,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary.withOpacity(0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isInflow ? '+' : ''}$amount',
            style: TextStyle(
              color: isInflow
                  ? colorScheme.primary
                  : colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Group header for temporal sections (Today, Yesterday, etc.).
class TemporalSectionHeader extends StatelessWidget {
  final String title;

  const TemporalSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}