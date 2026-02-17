import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/providers/filter_provider.dart';
import 'package:mudra_manager/screens/reusable/period_calendar_selector.dart';
import 'package:mudra_manager/components/currency_text.dart';

class CashFlowCard extends ConsumerWidget {
  final double globalPadding;
  final PeriodType selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;

  const CashFlowCard({
    super.key,
    required this.globalPadding,
    required this.selectedPeriod,
    this.customStart,
    this.customEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = selectedPeriod == PeriodType.custom && customStart != null && customEnd != null
        ? ref.watch(customDateRangeTransactionsProvider('${customStart!.millisecondsSinceEpoch}_${customEnd!.millisecondsSinceEpoch}'))
        : ref.watch(periodBasedTransactionsProvider(
            selectedPeriod == PeriodType.day ? 'day' :
            selectedPeriod == PeriodType.week ? 'week' :
            selectedPeriod == PeriodType.month ? 'month' :
            selectedPeriod == PeriodType.year ? 'year' : 'month'
          ));

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return summary.when(
      data: (data) {
        final income = data['income'] ?? 0.0;
        final expense = data['expense'] ?? 0.0;
        final netFlow = income - expense;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: globalPadding),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerLow,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/transactions');
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
                          'Cash Flow',
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
                                tween: Tween(begin: 0.0, end: netFlow),
                                builder: (context, value, child) {
                                  return CurrencyText(
                                    amount: value,
                                    style: textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: netFlow >= 0 ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                'Net Flow',
                                style: textTheme.titleMedium?.copyWith(
                                  color: netFlow >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildMetric('Income', income, Colors.green, textTheme),
                              SizedBox(height: 8),
                              _buildMetric('Expense', expense, Colors.red, textTheme),
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
                            netFlow >= 0
                                ? 'Positive cash flow this period'
                                : 'Expenses exceeded income this period',
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

  Widget _buildMetric(String label, double value, Color labelColor, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: labelColor,
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
