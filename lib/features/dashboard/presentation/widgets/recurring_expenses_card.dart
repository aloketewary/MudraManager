import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';

final recurringExpensesProvider = FutureProvider<List<RecurringTransaction>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return await isar.recurringTransactions
      .filter()
      .isActiveEqualTo(true)
      .and()
      .isExpenseEqualTo(true)
      .sortByNextDueDate()
      .findAll();
});

class RecurringExpensesCard extends ConsumerWidget {
  final double globalPadding;

  const RecurringExpensesCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringExpensesProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return recurring.when(
      data: (expenses) {
        if (expenses.isEmpty) return const SizedBox.shrink();

        final monthlyTotal = expenses
            .where((e) => e.frequency == Frequency.monthly)
            .fold(0.0, (sum, e) => sum + e.amount);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding, vertical: 16),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerHigh,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/recurring-expenses'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.repeat, color: color.error, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fixed Expenses', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${expenses.length} subscriptions', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: color.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Monthly Total', style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                    Text('₹${monthlyTotal.toStringAsFixed(0)}', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
