import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/features/account/data/balance_history_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/features/account/presentation/widgets/balance_history_chart.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class BalanceHistoryScreen extends ConsumerWidget {
  final Account account;

  const BalanceHistoryScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceHistory = ref.watch(balanceHistoryProvider(account.id));
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountColor = Color(account.colorValue ?? Colors.blue.toARGB32());

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name, style: textTheme.titleLarge),
        elevation: 0,
      ),
      body: balanceHistory.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 64,
                    color: color.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    BuddyMessages.noData,
                    style: textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add transactions to see balance trends',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final currentBalance = snapshots.last.balance;
          final firstBalance = snapshots.first.balance;
          final change = currentBalance - firstBalance;
          final changePercent =
              firstBalance != 0 ? (change / firstBalance.abs() * 100) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Hero balance card
                _buildHeroCard(
                  currentBalance,
                  change,
                  changePercent,
                  accountColor,
                  isGuestMode,
                  color,
                  textTheme,
                ),
                const SizedBox(height: 20),

                // Chart
                BalanceHistoryChart(
                  snapshots: snapshots,
                  accountColor: accountColor,
                  isGuestMode: isGuestMode,
                ),
                const SizedBox(height: 20),

                // Stats row
                _buildStatsRow(
                  snapshots,
                  isGuestMode,
                  color,
                  textTheme,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: color.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load history',
                style: textTheme.titleMedium?.copyWith(color: color.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    double currentBalance,
    double change,
    double changePercent,
    Color accountColor,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final isPositive = change >= 0;
    final changeColor =
        isPositive ? color.primary : color.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accountColor.withValues(alpha: 0.12),
            color.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accountColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  account.accountType.icon,
                  color: accountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Balance',
                style: textTheme.labelLarge?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CurrencyText(
            amount: GuestModeUtil.applyGuestMode(
              currentBalance,
              isGuestMode,
            ),
            compact: false,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
                  size: 14,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                CurrencyText(
                  amount: GuestModeUtil.applyGuestMode(
                    change.abs(),
                    isGuestMode,
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' (${changePercent.abs().toStringAsFixed(1)}%)',
                  style: textTheme.labelMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    List snapshots,
    bool isGuestMode,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final balances = snapshots.map((s) => s.balance as double).toList();
    final highest = balances.reduce((a, b) => a > b ? a : b);
    final lowest = balances.reduce((a, b) => a < b ? a : b);
    final avg = balances.reduce((a, b) => a + b) / balances.length;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            'Highest',
            GuestModeUtil.applyGuestMode(highest, isGuestMode),
            LucideIcons.arrowUp,
            color.primary,
            color,
            textTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statPill(
            'Lowest',
            GuestModeUtil.applyGuestMode(lowest, isGuestMode),
            LucideIcons.arrowDown,
            color.error,
            color,
            textTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statPill(
            'Average',
            GuestModeUtil.applyGuestMode(avg, isGuestMode),
            LucideIcons.minus,
            color.secondary,
            color,
            textTheme,
          ),
        ),
      ],
    );
  }

  Widget _statPill(
    String label,
    double value,
    IconData icon,
    Color pillColor,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: pillColor),
          const SizedBox(height: 6),
          CurrencyText(
            amount: value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
