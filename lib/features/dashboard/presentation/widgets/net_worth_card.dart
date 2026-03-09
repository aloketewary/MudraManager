import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:fl_chart/fl_chart.dart';

class NetWorthCard extends ConsumerWidget {
  final double globalPadding;

  const NetWorthCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider('Month'));
    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);
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
                  color: color.primaryContainer,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push('/net-worth');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: historyAsync.when(
                            data: (history) => _buildMiniChart(history, color),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Net Worth',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: color.onPrimaryContainer.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: color.onPrimaryContainer.withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: displayNetWorth),
                                builder: (context, value, child) {
                                  return CurrencyText(
                                    amount: value,
                                    style: textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: color.onPrimaryContainer,
                                      fontSize: 32,
                                    ),
                                    showSign: false,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    displayNetWorth >= 0 ? Icons.trending_up : Icons.trending_down,
                                    size: 14,
                                    color: displayNetWorth >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${displaySavingsRate.toStringAsFixed(1)}% savings rate',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const DashboardCardSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const DashboardCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniChart(List<NetWorthHistoryPoint> history, ColorScheme color) {
    if (history.isEmpty) return const SizedBox.shrink();
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.netWorth)).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 140,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.4,
                preventCurveOverShooting: true,
                color: color.onPrimaryContainer.withValues(alpha: 0.3),
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.onPrimaryContainer.withValues(alpha: 0.1),
                      color.onPrimaryContainer.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
