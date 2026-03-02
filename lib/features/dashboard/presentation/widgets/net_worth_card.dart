import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class NetWorthCard extends ConsumerWidget {
  final double globalPadding;

  const NetWorthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider('Month'));
    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);

    return totalBalanceAsync.when(
      data: (netWorth) {
        if (netWorth == 0) return const SizedBox.shrink();
        
        final displayNetWorth = GuestModeUtil.applyGuestMode(netWorth, isGuestMode);

        return statsAsync.when(
          data: (stats) {
            final displayIncome = GuestModeUtil.applyGuestMode(stats.income, isGuestMode);
            final displayExpense = GuestModeUtil.applyGuestMode(stats.expense, isGuestMode);
            final displaySavingsRate = GuestModeUtil.applyGuestMode(stats.savingsRate, isGuestMode);

            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: globalPadding),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/statistics');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: color.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Net Worth',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right,
                                color: color.onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween(begin: 0.0, end: displayNetWorth),
                                      builder: (context, value, child) {
                                        return CurrencyText(
                                          amount: value,
                                          style: textTheme.displaySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: displayNetWorth >= 0 ? Colors.green : Colors.red,
                                          ),
                                          showSign: true,
                                        );
                                      },
                                    ),
                                    Text(
                                      'This Month',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildMetric('Income', displayIncome, color, textTheme),
                                    const SizedBox(height: 8),
                                    _buildMetric('Expense', displayExpense, color, textTheme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: color.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayNetWorth >= 0
                                      ? 'Great! You saved ${displaySavingsRate.toStringAsFixed(1)}% this month'
                                      : 'Spending exceeded income this month',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetric(
    String label,
    double displayValue,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: displayValue,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
