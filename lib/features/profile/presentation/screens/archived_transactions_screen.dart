import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/db/models/archived_transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';

final _archivedTxnProvider =
    FutureProvider<List<ArchivedTransaction>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return isar.archivedTransactions
      .where()
      .sortByArchivedAtDesc()
      .findAll();
});

class ArchivedTransactionsScreen extends ConsumerWidget {
  const ArchivedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final asyncTxns = ref.watch(_archivedTxnProvider);

    return Scaffold(
      appBar: AppBar(title: Text(BuddyMessages.archivedTransactionsTitle)),
      body: asyncTxns.when(
        data: (txns) {
          if (txns.isEmpty) {
            return NoDataFound(
              message: BuddyMessages.noArchivedTransactions,
              iconData: LucideIcons.archive,
            );
          }

          // Group by archivedAt date (each currency change batch)
          final grouped = <String, List<ArchivedTransaction>>{};
          for (final txn in txns) {
            final key =
                '${txn.archivedFromBase} → ${txn.archivedToBase}  •  ${DateFormat('MMM dd, yyyy').format(txn.archivedAt)}';
            grouped.putIfAbsent(key, () => []).add(txn);
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final entry = grouped.entries.elementAt(i);
              final batch = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 16),
                  // Batch header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.arrowLeftRight,
                          size: 14,
                          color: color.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.primary,
                            ),
                          ),
                        ),
                        Text(
                          '${batch.length}',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Transaction cards
                  ...batch.map(
                    (txn) => _ArchivedTxnCard(txn: txn),
                  ),
                ],
              );
            },
          );
        },
        loading: () => ListView(children: List.generate(5, (_) => TransactionCardSkeleton())),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }
}

class _ArchivedTxnCard extends StatelessWidget {
  final ArchivedTransaction txn;
  const _ArchivedTxnCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = txn.isExpense ? color.error : color.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Category icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                txn.isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.categoryName ?? txn.description ?? 'Transaction',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (txn.accountName != null) txn.accountName!,
                      DateFormat('MMM dd, yyyy').format(txn.date),
                    ].join(' • '),
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CurrencyText(
                  amount: txn.amount,
                  currencyCode: txn.currencyCode ?? txn.archivedFromBase,
                  showSign: true,
                  isExpense: txn.isExpense,
                  compact: false,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                if (txn.convertedAmount != null)
                  Text(
                    '${formatCurrency(txn.convertedAmount!, code: txn.archivedFromBase, decimals: 2)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.6),
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
