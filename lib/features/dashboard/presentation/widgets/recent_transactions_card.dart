import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class RecentTransactionsCard extends ConsumerWidget {
  final int maxTransactions;

  const RecentTransactionsCard({
    super.key,
    this.maxTransactions = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final transactions = ref.watch(dashboardTransactionsProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    if (transactions.isEmpty) return const SizedBox.shrink();

    // Get recent transactions (sorted by date, most recent first)
    final recentTransactions = transactions.take(maxTransactions).toList();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: color.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.receiptText,
                    color: color.primary,
                    size: 20,
                  ),
                  SizedBox(width: spacing.cardVertical),
                  AdaptiveText(
                    'Recent Transactions',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/transactions');
                    },
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: color.onSurface,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: color.outlineVariant),

            // Transaction List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: recentTransactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72,
                color: color.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                transaction.category.loadSync();
                transaction.account.loadSync();

                final category = transaction.category.value;
                final account = transaction.account.value;
                final displayAmount = GuestModeUtil.applyGuestMode(
                  transaction.amount,
                  isGuestMode,
                );

                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Navigate to transaction detail or edit
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardInner,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(category?.colorValue ?? 0xFF6200EE)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            IconHelper.getIconData(category?.iconName),
                            color: Color(category?.colorValue ?? 0xFF6200EE),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Category & Account Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdaptiveText(
                                category?.name ?? 'Uncategorized',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              AdaptiveText(
                                account?.name ?? 'Unknown',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),

                        // Amount & Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CurrencyText(
                              amount: displayAmount,
                              showSign: true,
                              isExpense: transaction.isExpense,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: transaction.isExpense
                                    ? color.error
                                    : color.primary,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(transaction.date, ctxt),
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations ctxt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE', ctxt.localeName).format(date);
    } else {
      return DateFormat('MMM dd', ctxt.localeName).format(date);
    }
  }
}
