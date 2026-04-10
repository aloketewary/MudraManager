import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/services/settlement_service.dart';

class LiveBalanceCard extends StatelessWidget {
  final List<ParticipantBalance> balances;
  final VoidCallback onSettleUp;

  const LiveBalanceCard({
    super.key,
    required this.balances,
    required this.onSettleUp,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (balances.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 0,
        color: color.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(LucideIcons.circleCheck, color: color.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Settled Up!',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.primary,
                      ),
                    ),
                    Text(
                      'No pending balances',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: color.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.wallet, color: color.primary),
                const SizedBox(width: 12),
                Text(
                  'Live Balances',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...balances.map((pb) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: pb.isOwed
                            ? color.primary.withValues(alpha: 0.2)
                            : color.error.withValues(alpha: 0.2),
                        child: Text(
                          pb.participant.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pb.isOwed ? color.primary : color.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pb.participant.name,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.7,
                                minHeight: 6,
                                backgroundColor: color.surface,
                                valueColor: AlwaysStoppedAnimation(
                                  pb.isOwed ? color.primary : color.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${pb.isOwed ? '+' : '-'}${formatCurrency(pb.amount, decimals: 0)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pb.isOwed ? color.primary : color.error,
                        ),
                      ),
                    ],
                  ),
                ),),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSettleUp,
                icon: const Icon(LucideIcons.banknote),
                label: const Text('Settle Up Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
