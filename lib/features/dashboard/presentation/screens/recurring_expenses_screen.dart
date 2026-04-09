import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

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
    final spacing = ref.watch(spacingProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixed Expenses'),
      ),
      body: dashboardAsync.when(
        data: (data) {
          final expenses = data.recurringExpenses;

          if (expenses.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noRecurring,
              iconData: LucideIcons.repeat,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(spacing.elementGap),
            itemCount: expenses.length,
            itemBuilder: (context, i) {
              final expense = expenses[i];
              final category = expense.category.value;
              final daysUntilDue =
                  expense.nextDueDate.difference(DateTime.now()).inDays;

              return Card(
                margin: EdgeInsets.only(bottom: spacing.cardVertical),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(spacing.cardVertical),
                    decoration: BoxDecoration(
                      color: color.errorContainer,
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                    child: Icon(LucideIcons.repeat, color: color.error, size: 24),
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
                    formatCurrency(expense.amount, decimals: 0),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: EdgeInsets.all(spacing.cardVertical),
          itemCount: 5,
          itemBuilder: (context, index) => Card(
            margin: EdgeInsets.only(bottom: spacing.cardVertical),
            child: Padding(
              padding: EdgeInsets.all(spacing.cardHorizontalMax),
              child: Row(
                children: [
                  SkeletonLoader(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  SizedBox(width: spacing.cardHorizontalMax),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: double.infinity,
                          height: spacing.cardHorizontalMax,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        SizedBox(height: spacing.cardHorizontal),
                        SkeletonLoader(
                          width: 100,
                          height: 14,
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.cardHorizontal),
                  SkeletonLoader(
                    width: 60,
                    height: 20,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }
}
