import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/util/localization_extension.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.glassGradient(color.primary, isDark),
        ),
        border: Border.all(
          color: color.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppColors.glassShadow(color.primary, isDark),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: color.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Income vs Expense',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 220,
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
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _getXAxisLabel(value.toInt(), period, ctxt),
                            style: textTheme.bodySmall?.copyWith(fontSize: 10),
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
                        style: textTheme.bodySmall,
                      ),
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                minY: 0,
              ),
              duration: Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green.shade500, ctxt.statistics_chartLineIncomeText),
              SizedBox(width: 24),
              _buildLegend(Colors.red.shade500, ctxt.statistics_chartLineExpenseText),
            ],
          ),
        ],
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
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _getXAxisLabel(int index, String filter, AppLocalizations ctxt) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return ctxt.statistics_chartLineTodayHourText(ctxt.formatCompactNumber().format(index));
      case 'Week':
        final date = now.subtract(Duration(days: 6 - index));
        return DateFormat('E', ctxt.localeName).format(date);
      case 'Month':
        return ctxt.formatCompactNumber().format(index + 1);
      case 'Year':
        return DateFormat('MMM', ctxt.localeName).format(DateTime(now.year, index + 1));
      default:
        return DateFormat('MMM', ctxt.localeName).format(DateTime(now.year, index + 1));
    }
  }
}
