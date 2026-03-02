import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class MonthlyComparisonScreen extends ConsumerWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isar = ref.watch(isarServiceProvider);
    final isGuestMode = ref.watch(guestModeProvider);
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Comparison')),
      body: FutureBuilder<Map<String, double>>(
        future: _getComparisonData(
          isar,
          currentMonthStart,
          currentMonthEnd,
          lastMonthStart,
          lastMonthEnd,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildComparisonCardSkeleton(context),
                const SizedBox(height: 12),
                _buildComparisonCardSkeleton(context),
                const SizedBox(height: 12),
                _buildComparisonCardSkeleton(context),
              ],
            );
          }

          final data = snapshot.data!;
          final rawCurrentIncome = data['currentIncome']!;
          final rawCurrentExpense = data['currentExpense']!;
          final rawLastIncome = data['lastIncome']!;
          final rawLastExpense = data['lastExpense']!;
          final currentIncome = GuestModeUtil.applyGuestMode(rawCurrentIncome, isGuestMode);
          final currentExpense = GuestModeUtil.applyGuestMode(rawCurrentExpense, isGuestMode);
          final lastIncome = GuestModeUtil.applyGuestMode(rawLastIncome, isGuestMode);
          final lastExpense = GuestModeUtil.applyGuestMode(rawLastExpense, isGuestMode);

          final incomeChange = lastIncome > 0
              ? ((currentIncome - lastIncome) / lastIncome * 100)
              : 0.0;
          final expenseChange = lastExpense > 0
              ? ((currentExpense - lastExpense) / lastExpense * 100)
              : 0.0;
          final currentBalance = currentIncome - currentExpense;
          final lastBalance = lastIncome - lastExpense;
          final balanceChange = lastBalance != 0
              ? ((currentBalance - lastBalance) / lastBalance.abs() * 100)
              : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ComparisonCard(
                title: 'Income',
                icon: Icons.trending_up,
                color: colorScheme.primary,
                currentAmount: currentIncome,
                lastAmount: lastIncome,
                percentageChange: incomeChange,
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
              _ComparisonCard(
                title: 'Expense',
                icon: Icons.trending_down,
                color: colorScheme.error,
                currentAmount: currentExpense,
                lastAmount: lastExpense,
                percentageChange: expenseChange,
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
              _ComparisonCard(
                title: 'Balance',
                icon: Icons.account_balance_wallet,
                color: colorScheme.tertiary,
                currentAmount: currentBalance,
                lastAmount: lastBalance,
                percentageChange: balanceChange,
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, double>> _getComparisonData(
    IsarService isar,
    DateTime currentStart,
    DateTime currentEnd,
    DateTime lastStart,
    DateTime lastEnd,
  ) async {
    final db = await isar.getInstance();

    final currentTxns = await db.transactions
        .where()
        .dateBetween(currentStart, currentEnd)
        .findAll();

    final lastTxns = await db.transactions
        .where()
        .dateBetween(lastStart, lastEnd)
        .findAll();

    double currentIncome = 0, currentExpense = 0;
    double lastIncome = 0, lastExpense = 0;

    for (var txn in currentTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        currentIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        currentExpense += txn.amount;
      }
    }

    for (var txn in lastTxns) {
      if (!txn.isExpense && !txn.isTransfer) {
        lastIncome += txn.amount;
      } else if (txn.isExpense && !txn.isTransfer) {
        lastExpense += txn.amount;
      }
    }

    return {
      'currentIncome': currentIncome,
      'currentExpense': currentExpense,
      'lastIncome': lastIncome,
      'lastExpense': lastExpense,
    };
  }

  static Widget _buildComparisonCardSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 100,
                  height: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 100, height: 14),
                    const SizedBox(height: 8),
                    SkeletonLoader(width: 120, height: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonLoader(width: 100, height: 14),
                    const SizedBox(height: 8),
                    SkeletonLoader(width: 100, height: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonLoader(
              width: 150,
              height: 32,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double currentAmount;
  final double lastAmount;
  final double percentageChange;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;

  const _ComparisonCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentAmount,
    required this.lastAmount,
    required this.percentageChange,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentageChange >= 0;
    final color = Theme.of(context).colorScheme;
    final changeColor = title == 'Expense'
        ? (isPositive ? color.error : color.primary)
        : (isPositive ? color.primary : color.error);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Month',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.formatCurrencyWithSign(0, currentAmount),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Month',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.formatCurrencyWithSign(0, lastAmount),
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentageChange.abs().toStringAsFixed(1)}%',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'vs last month',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
