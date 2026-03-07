import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Process Now',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              try {
                await ref.read(recurringTransactionServiceProvider).processRecurringTransactions();
                if (context.mounted) {
                  SnackbarService.success('Recurring transactions processed! Check your transactions list.');
                }
              } catch (e) {
                if (context.mounted) {
                  SnackbarService.error('Error: $e');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(Icons.repeat, size: 64, color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'How it works',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set up recurring transactions for regular income or expenses. They will be automatically created based on your schedule.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => ctx.pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: recurringAsync.when(
        data: (recurring) {
          if (recurring.isEmpty) {
            return const NoDataFound(
              message: 'No recurring transactions',
              iconData: Icons.repeat,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            itemCount: recurring.length,
            itemBuilder: (context, index) {
              final item = recurring[index];
              return _RecurringCard(item: item);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: 4,
          itemBuilder: (context, index) => const SkeletonListTile(),
        ),
        error: (_, __) =>
            const Center(child: Text('Error loading recurring transactions')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-recurring');
        },
        icon: const Icon(Icons.add),
        label: const Text('ADD'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  final RecurringTransaction item;

  const _RecurringCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    final color = item.isExpense ? colorScheme.error : colorScheme.primary;
    final frequencyText = _getFrequencyText(item.frequency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/add-recurring', extra: {'recurring': item}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconHelper.iconFromName(
                    item.category.value?.iconName ?? 'category',
                  ),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.value?.name ?? 'Unknown',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$frequencyText • Next: ${DateFormat('MMM d').format(item.nextDueDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!item.isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Inactive',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.isExpense ? '-' : '+'}₹${GuestModeUtil.applyGuestMode(item.amount, isGuestMode).toStringAsFixed(0)}',
                    style: textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.account.value?.name ?? '',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFrequencyText(Frequency freq) {
    switch (freq) {
      case Frequency.daily:
        return 'Daily';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.yearly:
        return 'Yearly';
    }
  }
}
