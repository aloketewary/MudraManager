import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class BalanceHistoryChart extends ConsumerWidget {
  final List<BalanceSnapshot> snapshots;
  final Color accountColor;
  final bool isGuestMode;

  const BalanceHistoryChart({
    super.key,
    required this.snapshots,
    required this.accountColor,
    required this.isGuestMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        GuestModeUtil.applyGuestMode(e.value.balance, isGuestMode),
      );
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.15;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctxt.balanceHistory_trend,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.sectionGap),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range > 0 ? range / 3 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: color.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        interval: range > 0 ? range / 3 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value == minY - padding || value == maxY + padding) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatCurrencyCompact(value),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: _calcBottomInterval(snapshots.length),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= snapshots.length) {
                            return const SizedBox.shrink();
                          }
                          final date = snapshots[index].date;
                          return Padding(
                            padding: EdgeInsets.only(top: spacing.elementGapMin),
                            child: Text(
                              safeDateFormat('d MMM', ctxt.localeName).format(date),
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => color.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date = index >= 0 && index < snapshots.length
                              ? snapshots[index].date
                              : DateTime.now();
                          return LineTooltipItem(
                            '${safeDateFormat('dd MMM', ctxt.localeName).format(date)}\n${formatCurrencyCompact(spot.y)}',
                            textTheme.labelSmall?.copyWith(
                              color: color.onSurface,
                              fontWeight: FontWeight.w600,
                            ) ?? const TextStyle(),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minY: minY - padding,
                  maxY: maxY + padding,
                  clipData: const FlClipData.all(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: accountColor,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          if (index == spots.length - 1) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: accountColor,
                              strokeWidth: 2,
                              strokeColor: color.surface,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 0, color: Colors.transparent,
                            strokeWidth: 0, strokeColor: Colors.transparent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accountColor.withValues(alpha: 0.15),
                            accountColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcBottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 3;
    return 5;
  }
}
