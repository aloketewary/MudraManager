import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/recurring_expenses_card.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  String _formatFrequency(Frequency freq) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringExpensesProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Expenses'),
      ),
      body: recurring.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat_outlined,
                      size: 64, color: color.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No recurring expenses', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Patterns will be detected automatically',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: color.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, i) {
              final expense = expenses[i];
              final category = expense.category.value;
              final daysUntilDue =
                  expense.nextDueDate.difference(DateTime.now()).inDays;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.repeat, color: color.error, size: 24),
                  ),
                  title: Text(
                    category?.name ?? 'Uncategorized',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatFrequency(expense.frequency)),
                      if (daysUntilDue >= 0)
                        Text(
                          'Due in $daysUntilDue days',
                          style: TextStyle(
                            color: daysUntilDue <= 3
                                ? color.error
                                : color.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '₹${expense.amount.toStringAsFixed(0)}',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading expenses')),
      ),
    );
  }
}
