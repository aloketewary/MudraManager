import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class PendingSplitsSection extends StatelessWidget {
  final List<Transaction> pendingTransactions;
  final int tripId;

  const PendingSplitsSection({
    super.key,
    required this.pendingTransactions,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (pendingTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final txn in pendingTransactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(txn.date);
      grouped.putIfAbsent(dateKey, () => []).add(txn);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.pending_actions, color: color.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending Splits',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pendingTransactions.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...sortedDates.map((dateKey) {
          final txns = grouped[dateKey]!;
          final date = DateTime.parse(dateKey);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          String dateLabel;
          if (date == today) {
            dateLabel = 'Today';
          } else if (date == yesterday) {
            dateLabel = 'Yesterday';
          } else {
            dateLabel = DateFormat('MMM d').format(date);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  dateLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...txns.map((txn) => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    elevation: 0,
                    color: color.surfaceContainerHighest,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showSplitOptions(context, txn);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.receipt,
                                size: 20,
                                color: color.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn.description ?? 'Expense',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (txn.category.value?.name != null)
                                    Text(
                                      txn.category.value!.name,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${formatCurrency(txn.amount, decimals: 0)}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: color.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          );
        }),
      ],
    );
  }

  void _showSplitOptions(BuildContext context, Transaction txn) {
    final color = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Split ${txn.description ?? "Expense"}',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SplitOptionButton(
                    icon: Icons.people,
                    label: 'Equal',
                    color: color.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.addTripTransaction, extra: {
                        'tripId': tripId,
                        'transactionId': txn.id,
                        'splitType': 'equal',
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SplitOptionButton(
                    icon: Icons.percent,
                    label: 'Percentage',
                    color: color.secondary,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.addTripTransaction, extra: {
                        'tripId': tripId,
                        'transactionId': txn.id,
                        'splitType': 'percentage',
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SplitOptionButton(
                    icon: Icons.edit,
                    label: 'Custom',
                    color: color.tertiary,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.addTripTransaction, extra: {
                        'tripId': tripId,
                        'transactionId': txn.id,
                        'splitType': 'custom',
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SplitOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
