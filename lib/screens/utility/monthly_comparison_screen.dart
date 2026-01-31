import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class MonthlyComparisonScreen extends ConsumerWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isar = ref.watch(isarServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Comparison'),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _getComparisonData(isar, currentMonthStart, currentMonthEnd, lastMonthStart, lastMonthEnd),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final currentIncome = data['currentIncome']!;
          final currentExpense = data['currentExpense']!;
          final lastIncome = data['lastIncome']!;
          final lastExpense = data['lastExpense']!;

          final incomeChange = lastIncome > 0 ? ((currentIncome - lastIncome) / lastIncome * 100) : 0.0;
          final expenseChange = lastExpense > 0 ? ((currentExpense - lastExpense) / lastExpense * 100) : 0.0;
          final currentBalance = currentIncome - currentExpense;
          final lastBalance = lastIncome - lastExpense;
          final balanceChange = lastBalance != 0 ? ((currentBalance - lastBalance) / lastBalance.abs() * 100) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ComparisonCard(
                title: 'Income',
                icon: Icons.trending_up,
                color: Colors.green,
                currentAmount: currentIncome,
                lastAmount: lastIncome,
                percentageChange: incomeChange,
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
              _ComparisonCard(
                title: 'Expense',
                icon: Icons.trending_down,
                color: Colors.red,
                currentAmount: currentExpense,
                lastAmount: lastExpense,
                percentageChange: expenseChange,
                colorScheme: colorScheme,
                textTheme: textTheme,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
              _ComparisonCard(
                title: 'Balance',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
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
    final changeColor = title == 'Expense' 
        ? (isPositive ? Colors.red : Colors.green)
        : (isPositive ? Colors.green : Colors.red);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
                      color: color,
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
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'vs last month',
                  style: textTheme.labelSmall?.copyWith(
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
