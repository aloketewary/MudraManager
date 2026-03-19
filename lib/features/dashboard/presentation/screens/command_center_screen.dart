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
            (sum, acc) => sum + (acc.initialBalance ?? 0),
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
                  .fold<double>(0, (sum, t) => sum + t.amount);

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
                              icon: Icon(Icons.search, color: color.onSurface),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                // Navigate to search
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.notifications_outlined,
                                  color: color.onSurface),
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
                          Text(
                            '₹${totalBalance.toStringAsFixed(2)}',
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
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    color.errorContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: color.error.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline,
                                      size: 16, color: color.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Money hold: ₹${pendingAmount.toStringAsFixed(2)}',
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
                            'Available: ₹${availableBalance.toStringAsFixed(2)}',
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
                              borderRadius: BorderRadius.circular(20),
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
                                          ? Icons.credit_card
                                          : Icons.account_balance_wallet,
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
                                        Text(
                                          '₹${(primaryAccount.initialBalance ?? 0).toStringAsFixed(2)}',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading accounts')),
      ),
    );
  }
}
