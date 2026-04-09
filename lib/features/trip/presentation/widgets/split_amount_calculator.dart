import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplitAmountCalculator extends StatelessWidget {
  final double totalAmount;
  final int participantCount;
  final Map<String, double> customSplits;
  final Function(Map<String, double>) onSplitsChanged;

  const SplitAmountCalculator({
    super.key,
    required this.totalAmount,
    required this.participantCount,
    required this.customSplits,
    required this.onSplitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final equalSplit = participantCount > 0 ? totalAmount / participantCount : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Split Amount',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('${formatCurrency(equalSplit.toDouble(), decimals: equalSplit.truncateToDouble() == equalSplit ? 0 : 2)} each'),
                  backgroundColor: color.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${formatCurrency(totalAmount, decimals: 2)}',
              style: textTheme.bodyLarge,
            ),
            Text(
              '$participantCount participants',
              style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
