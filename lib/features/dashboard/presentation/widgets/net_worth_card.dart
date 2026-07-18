import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/features/dashboard/presentation/providers/dashboard_data_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class NetWorthCard extends ConsumerWidget {
  final double globalPadding;

  const NetWorthCard({super.key, this.globalPadding = 16.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final netWorthDataAsync = ref.watch(netWorthProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final spacing = ref.watch(spacingProvider);

    return dashboardAsync.when(
      data: (dashboardData) {
        final totalBalance = GuestModeUtil.applyGuestMode(
          dashboardData.totalBalance,
          isGuestMode,
        );
        final income = GuestModeUtil.applyGuestMode(
          dashboardData.totalIncome,
          isGuestMode,
        );
        final expense = GuestModeUtil.applyGuestMode(
          dashboardData.totalExpense,
          isGuestMode,
        );
        final savingsRate =
            income > 0 ? ((income - expense) / income) * 100 : 0.0;

        if (totalBalance == 0) return const SizedBox.shrink();

        return ProCardGate(
          feature: ProFeature.netWorth,
          borderRadius: 20,
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: globalPadding, vertical: 8),
            child: Card(
              elevation: 0,
              color: color.primaryContainer,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.netWorth);
                },
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: Stack(
                  children: [
                    // Background chart
                    Positioned.fill(
                      child: historyAsync.when(
                        data: (history) => _buildMiniChart(history, color, spacing),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.landmark,
                                  size: 20,
                                  color: color.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Net Worth',
                                style: textTheme.titleMedium?.copyWith(
                                  color: color.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                LucideIcons.chevronRight,
                                color: color.onPrimaryContainer
                                    .withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Net Worth Amount — the number the user came here for
                          AmountGlow(
                            color: color.primary,
                            child: AnimatedBalance(
                              value: totalBalance,
                              duration: const Duration(milliseconds: 1500),
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color.onPrimaryContainer,
                                fontSize: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Metrics Row
                          netWorthDataAsync.when(
                            data: (netWorthData) {
                              final displayMonthlyChange =
                                  GuestModeUtil.applyGuestMode(
                                netWorthData.monthlyChange,
                                isGuestMode,
                              );
                              final displayAssets =
                                  GuestModeUtil.applyGuestMode(
                                netWorthData.totalAssets,
                                isGuestMode,
                              );
                              final displayLiabilities =
                                  GuestModeUtil.applyGuestMode(
                                netWorthData.totalLiabilities,
                                isGuestMode,
                              );

                              return Column(
                                children: [
                                  // Monthly change
                                  Row(
                                    children: [
                                      Icon(
                                        displayMonthlyChange >= 0
                                            ? LucideIcons.trendingUp
                                            : LucideIcons.trendingDown,
                                        size: 16,
                                        color: displayMonthlyChange >= 0
                                            ? color.primary
                                            : color.error,
                                      ),
                                      const SizedBox(width: 6),
                                      CurrencyText(
                                        amount: displayMonthlyChange.abs(),
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: color.onPrimaryContainer
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        showSign: false,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'this month',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onPrimaryContainer
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: savingsRate >= 20
                                              ? color.primary
                                                  .withValues(alpha: 0.2)
                                              : color.onPrimaryContainer
                                                  .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              spacing.radiusMedium,),
                                        ),
                                        child: Text(
                                          '${savingsRate.toStringAsFixed(0)}% savings',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: color.onPrimaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Assets vs Liabilities
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MetricChip(
                                          label: 'Assets',
                                          amount: displayAssets,
                                          icon: LucideIcons.arrowUp,
                                          color: color.primary,
                                          textTheme: textTheme,
                                          colorScheme: color,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _MetricChip(
                                          label: 'Liabilities',
                                          amount: displayLiabilities,
                                          icon: LucideIcons.arrowDown,
                                          color: color.error,
                                          textTheme: textTheme,
                                          colorScheme: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                            loading: () => Row(
                              children: [
                                Icon(
                                  LucideIcons.trendingUp,
                                  size: 16,
                                  color: color.onPrimaryContainer
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${savingsRate.toStringAsFixed(1)}% savings rate',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => const SizedBox.shrink(),
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
  }

  Widget _buildMiniChart(
    List<NetWorthHistoryPoint> history,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(spacing.radiusSmall * 1.25),
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
              color: color.onPrimaryContainer.withValues(alpha: 0.2),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.onPrimaryContainer.withValues(alpha: 0.08),
                    color.onPrimaryContainer.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends ConsumerWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _MetricChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CurrencyText(
            amount: amount,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            showSign: false,
          ),
        ],
      ),
    );
  }
}
