import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

class HeroChartCard extends StatelessWidget {
  final List<FlSpot> incomeSpots;
  final List<FlSpot> expenseSpots;
  final String period;

  const HeroChartCard({
    super.key,
    required this.incomeSpots,
    required this.expenseSpots,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: color.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: color.primary, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Income vs Expense',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isIncome = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isIncome ? ctxt.statistics_chartLineIncomeText : ctxt.statistics_chartLineExpenseText}: ${ctxt.formatCurrencyWithSign(0, spot.y)}',
                            TextStyle(
                              color: spot.bar.gradient?.colors.first,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: period == 'Today' ? 6 : 1,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _getXAxisLabel(value.toInt(), period, ctxt),
                              style: textTheme.bodySmall?.copyWith(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          ctxt.formatCurrencyWithSign(1, value, compact: true),
                          style: textTheme.bodySmall?.copyWith(fontSize: 9),
                        ),
                        reservedSize: 35,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(
                  Colors.green.shade500,
                  ctxt.statistics_chartLineIncomeText,
                ),
                const SizedBox(width: 16),
                _buildLegend(
                  Colors.red.shade500,
                  ctxt.statistics_chartLineExpenseText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getXAxisLabel(int index, String filter, AppLocalizations ctxt) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return ctxt.statistics_chartLineTodayHourText(
          ctxt.formatCompactNumber().format(index),
        );
      case 'Week':
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('E', ctxt.localeName).format(date);
      case 'Month':
        return ctxt.formatCompactNumber().format(index + 1);
      case 'Year':
        return DateFormat(
          'MMM',
          ctxt.localeName,
        ).format(DateTime(now.year, index + 1));
      default:
        return DateFormat(
          'MMM',
          ctxt.localeName,
        ).format(DateTime(now.year, index + 1));
    }
  }
}
