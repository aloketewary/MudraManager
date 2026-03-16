import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/core/db/models/balance_snapshot.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class BalanceHistoryChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        GuestModeUtil.applyGuestMode(e.value.balance, isGuestMode),
      );
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15;

    return Card(
      elevation: 0,
      color: color.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Trend',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calcInterval(minY, maxY),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: color.outlineVariant.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
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
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: textTheme.labelSmall?.copyWith(
                                color: color.onSurfaceVariant
                                    .withValues(alpha: 0.6),
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
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date = index >= 0 && index < snapshots.length
                              ? snapshots[index].date
                              : DateTime.now();
                          return LineTooltipItem(
                            '${date.day}/${date.month}\n₹${spot.y.toStringAsFixed(0)}',
                            textTheme.labelSmall?.copyWith(
                                  color: accountColor,
                                  fontWeight: FontWeight.bold,
                                ) ??
                                const TextStyle(),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minY: minY - padding,
                  maxY: maxY + padding,
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
                          // Only show dot on last point
                          if (index == spots.length - 1) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: accountColor,
                              strokeWidth: 2,
                              strokeColor: color.surface,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeWidth: 0,
                            strokeColor: Colors.transparent,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accountColor.withValues(alpha: 0.2),
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

  double _calcInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1000;
    if (range > 100000) return 25000;
    if (range > 10000) return 5000;
    if (range > 1000) return 500;
    return 100;
  }

  double _calcBottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 3;
    return 5;
  }
}
