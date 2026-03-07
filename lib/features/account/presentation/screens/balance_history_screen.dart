import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/features/account/data/balance_history_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/account/presentation/widgets/balance_history_chart.dart';

class BalanceHistoryScreen extends ConsumerWidget {
  final Account account;

  const BalanceHistoryScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceHistory = ref.watch(balanceHistoryProvider(account.id));
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.name,
              style: textTheme.titleMedium,
            ),
            Text(
              'Balance History',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: balanceHistory.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: color.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No balance history yet',
                    style: textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add transactions to see balance trends',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BalanceHistoryChart(
              snapshots: snapshots,
              accountName: account.name,
              isGuestMode: isGuestMode,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: color.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load history',
                style: textTheme.titleMedium?.copyWith(color: color.error),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
