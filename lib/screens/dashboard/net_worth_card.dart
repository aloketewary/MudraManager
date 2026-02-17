import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/components/currency_text.dart';
import 'package:mudra_manager/providers/status_data_provider.dart';

class NetWorthCard extends ConsumerWidget {
  final double globalPadding;

  const NetWorthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider('Month'));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return statsAsync.when(
      data: (stats) {
        final netWorth = stats.income - stats.expense;
        if (netWorth == 0) return SizedBox.shrink();
        
        return Container(
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
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: color.primary),
                        SizedBox(width: 8),
                        Text(
                          'Net Worth',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: netWorth),
                                builder: (context, value, child) {
                                  return CurrencyText(
                                    amount: value,
                                    style: textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: netWorth >= 0 ? Colors.green : Colors.red,
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
                              SizedBox(height: 8),
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
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: color.primary),
                        SizedBox(width: 8),
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
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }

  Widget _buildMetric(String label, double value, ColorScheme color, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        CurrencyText(
          amount: value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
