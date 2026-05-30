import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: accountsAsync.when(
        data: (accounts) {
          final totalBalance = accounts.fold<double>(
            0,
            (sum, acc) => sum + (acc.initialBalance),
          );

          final transactionService = ref.watch(transactionProvider);
          final transactionsFuture = transactionService.getAll();

          return FutureBuilder<List<Transaction>>(
            future: transactionsFuture,
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? [];

              // Calculate pending/hold amount (transactions from last 3 days)
              final now = DateTime.now();
              final threeDaysAgo = now.subtract(const Duration(days: 3));
              final pendingAmount = transactions
                  .where((t) => t.date.isAfter(threeDaysAgo) && t.isExpense)
                  .fold<double>(0, (sum, t) => sum + t.baseAmount);

              final availableBalance = totalBalance - pendingAmount;
              final primaryAccount =
                  accounts.isNotEmpty ? accounts.first : null;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primaryContainer.withValues(alpha: 0.3),
                      color.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top Action Bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Search',
                              icon: Icon(LucideIcons.search, color: color.onSurface),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                // Navigate to search
                              },
                            ),
                            IconButton(
                              tooltip: 'Notifications',
                              icon: Icon(LucideIcons.bell,
                                  color: color.onSurface,),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.push(AppRoutes.notifications);
                              },
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Glance Zone - Total Balance
                      Column(
                        children: [
                          Text(
                            'Total Balance',
                            style: textTheme.bodyLarge?.copyWith(
                              color: color.onSurface.withValues(alpha: 0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CurrencyText(
                            amount: totalBalance,
                            compact: false,
                            fixedLength: 2,
                            style: textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 56,
                              color: color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Money Hold Pill
                          if (pendingAmount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10,),
                              decoration: BoxDecoration(
                                color:
                                    color.errorContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                                border: Border.all(
                                  color: color.error.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.lock,
                                      size: 16, color: color.error,),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Money hold: ${formatCurrency(pendingAmount, code: BaseCurrency.code, decimals: 2)}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: color.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Available: ${formatCurrency(availableBalance, code: BaseCurrency.code, decimals: 2)}',
                            style: textTheme.bodyLarge?.copyWith(
                              color: color.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Card Representation
                      if (primaryAccount != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.primary.withValues(alpha: 0.9),
                                  color.primary.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: color.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      primaryAccount.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: color.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Icon(
                                      primaryAccount.accountType ==
                                              AccountType.creditCard
                                          ? LucideIcons.creditCard
                                          : LucideIcons.wallet,
                                      color: color.onPrimary
                                          .withValues(alpha: 0.7),
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  '•••• •••• •••• ${primaryAccount.accountNumber?.substring(primaryAccount.accountNumber!.length - 4) ?? "****"}',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: color.onPrimary,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Balance',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: color.onPrimary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        CurrencyText(
                                          amount: primaryAccount.initialBalance,
                                          compact: false,
                                          fixedLength: 2,
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            color: color.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (primaryAccount.accountType ==
                                        AccountType.creditCard)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Valid Thru',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: color.onPrimary
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '12/24',
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              color: color.onPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: AccountCardSkeleton()),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }
}
