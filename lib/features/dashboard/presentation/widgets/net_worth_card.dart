import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class NetWorthCard extends ConsumerWidget {
  final double globalPadding;

  const NetWorthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider('Month'));
    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return totalBalanceAsync.when(
      data: (netWorth) {
        if (netWorth == 0) return const SizedBox.shrink();

        return statsAsync.when(
          data: (stats) {
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
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      tween: Tween(begin: 0.0, end: netWorth),
                                      builder: (context, value, child) {
                                        return CurrencyText(
                                          amount: value,
                                          style: textTheme.displaySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: netWorth >= 0
                                                    ? Colors.green
                                                    : Colors.red,
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
                                    _buildMetric(
                                      'Income',
                                      stats.income,
                                      color,
                                      textTheme,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMetric(
                                      'Expense',
                                      stats.expense,
                                      color,
                                      textTheme,
                                    ),
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
                                  netWorth >= 0
                                      ? 'Great! You saved ${stats.savingsRate.toStringAsFixed(1)}% this month'
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
    double value,
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
          amount: value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
