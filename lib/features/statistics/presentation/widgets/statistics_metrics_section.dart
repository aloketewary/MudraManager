import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/net_worth_service.dart';
import 'package:mudra_manager/features/dashboard/data/status_data_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsMetricsSection extends ConsumerWidget {
  final StatsData data;

  const StatisticsMetricsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGuestMode = ref.watch(guestModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stats_overview,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: spacing.sectionGap),
        Row(
          children: [
            Expanded(
              child: _PulseCard(
                label: l10n.stats_income,
                value: data.income,
                cardColor: color.primary,
                icon: LucideIcons.arrowUp,
                sparkline: data.incomeSpots,
                isGuestMode: isGuestMode,
                spacing: spacing,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _PulseCard(
                label: l10n.stats_expense,
                value: data.expense,
                cardColor: color.error,
                icon: LucideIcons.arrowDown,
                sparkline: data.expenseSpots,
                isGuestMode: isGuestMode,
                spacing: spacing,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap),
        _NetWorthCard(
          isGuestMode: isGuestMode,
          savingsRate: data.savingsRate,
          savingsSpots: data.savingsSpots,
          spacing: spacing,
        ),
      ],
    );
  }
}

class _NetWorthCard extends ConsumerWidget {
  final bool isGuestMode;
  final double savingsRate;
  final List<FlSpot> savingsSpots;
  final AppSpacing spacing;

  const _NetWorthCard({
    required this.isGuestMode,
    required this.savingsRate,
    required this.savingsSpots,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final totalBalanceAsync = ref.watch(totalAccountBalanceProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider);

    return totalBalanceAsync.when(
      data: (totalBalance) {
        final netWorthSpots = historyAsync.maybeWhen(
          data: (history) => history
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
              .toList(),
          orElse: () => <FlSpot>[],
        );

        return Row(
          children: [
            Expanded(
              child: _PulseCard(
                label: l10n.stats_netWorth,
                value: totalBalance,
                cardColor: color.primary,
                icon: LucideIcons.wallet,
                sparkline: netWorthSpots,
                isGuestMode: isGuestMode,
                spacing: spacing,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: _PulseCard(
                label: l10n.stats_savings,
                value: savingsRate,
                cardColor: color.tertiary,
                icon: LucideIcons.piggyBank,
                sparkline: savingsSpots,
                isGuestMode: isGuestMode,
                isPercentage: true,
                spacing: spacing,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const InlineError(),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final String label;
  final double value;
  final Color cardColor;
  final IconData icon;
  final List<FlSpot> sparkline;
  final bool isGuestMode;
  final bool isPercentage;
  final AppSpacing spacing;

  const _PulseCard({
    required this.label,
    required this.value,
    required this.cardColor,
    required this.icon,
    required this.sparkline,
    required this.isGuestMode,
    this.isPercentage = false,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (sparkline.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 70,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sparkline,
                            isCurved: true,
                            color: cardColor.withValues(alpha: 0.4),
                            barWidth: 0,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cardColor.withValues(alpha: 0.05),
                                  cardColor.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: cardColor, size: 20),
                SizedBox(height: spacing.elementGap),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.elementGapMin),
                isPercentage
                    ? Text(
                        '${value.toStringAsFixed(1)}%',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : CurrencyText(
                        amount: GuestModeUtil.applyGuestMode(
                          value,
                          isGuestMode,
                        ),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                if (sparkline.isNotEmpty) const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
