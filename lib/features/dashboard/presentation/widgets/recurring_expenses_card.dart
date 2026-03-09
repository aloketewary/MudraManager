import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

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

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: globalPadding),
              child: Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/recurring-transactions');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.repeat, color: color.error, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bill Control Center',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${monthlyTotal.toStringAsFixed(0)}/month • ${expenses.length} bills',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: const DashboardCardSkeleton(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
