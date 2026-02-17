import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudra_manager/providers/analytics_provider.dart';
import 'package:mudra_manager/components/currency_text.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);
    final predictionAsync = ref.watch(predictedSpendingProvider);
    final categoryTrendsAsync = ref.watch(categoryTrendsProvider);
    final spendingByDayAsync = ref.watch(spendingByDayProvider);
    
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Health Score
            healthAsync.when(
              data: (health) => Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, color: color.primary, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Financial Health Score',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${health.score}',
                              style: textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(health.score),
                              ),
                            ),
                            Text(
                              health.rating,
                              style: textTheme.titleLarge?.copyWith(
                                color: _getScoreColor(health.score),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildMetricRow('Savings Rate', '${health.savingsRate.toStringAsFixed(1)}%', color, textTheme),
                      SizedBox(height: 12),
                      _buildMetricRow('Expense Ratio', '${health.expenseRatio.toStringAsFixed(1)}%', color, textTheme),
                      if (health.insights.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Divider(),
                        SizedBox(height: 12),
                        Text(
                          'Insights',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        ...health.insights.map((insight) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 20, color: color.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  insight,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (_, __) => SizedBox.shrink(),
            ),

            SizedBox(height: 16),

            // Spending Prediction
            predictionAsync.when(
              data: (predicted) => Card(
                elevation: 0,
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: color.primary, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Spending Prediction',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Next Month',
                              style: textTheme.bodyLarge?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 8),
                            CurrencyText(
                              amount: predicted,
                              style: textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Based on last 3 months average',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (_, __) => SizedBox.shrink(),
            ),

            SizedBox(height: 16),

            // Category Trends
            categoryTrendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) return SizedBox.shrink();
                final sortedTrends = trends.values.toList()
                  ..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
                
                return Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category, color: color.primary, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Category Trends',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ...sortedTrends.take(5).map((trend) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    trend.categoryName,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      CurrencyText(
                                        amount: trend.thisMonth,
                                        style: textTheme.titleSmall,
                                      ),
                                      if (trend.changePercent != 0) ...[
                                        SizedBox(width: 8),
                                        Icon(
                                          trend.changePercent > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                          size: 16,
                                          color: trend.changePercent > 0 ? Colors.red : Colors.green,
                                        ),
                                        Text(
                                          '${trend.changePercent.abs().toStringAsFixed(0)}%',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: trend.changePercent > 0 ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (trend.thisMonth / sortedTrends.first.thisMonth).clamp(0.0, 1.0),
                                backgroundColor: color.surfaceContainerHighest,
                                color: color.primary,
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (_, __) => SizedBox.shrink(),
            ),

            SizedBox(height: 16),

            // Spending by Day of Week
            spendingByDayAsync.when(
              data: (byDay) {
                final maxSpending = byDay.values.reduce((a, b) => a > b ? a : b);
                if (maxSpending == 0) return SizedBox.shrink();

                return Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: color.primary, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Spending by Day',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxSpending * 1.2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      return Text(
                                        days[value.toInt()],
                                        style: textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _buildBarGroup(0, byDay['Mon']!, color.primary),
                                _buildBarGroup(1, byDay['Tue']!, color.primary),
                                _buildBarGroup(2, byDay['Wed']!, color.primary),
                                _buildBarGroup(3, byDay['Thu']!, color.primary),
                                _buildBarGroup(4, byDay['Fri']!, color.primary),
                                _buildBarGroup(5, byDay['Sat']!, color.primary),
                                _buildBarGroup(6, byDay['Sun']!, color.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (_, __) => SizedBox.shrink(),
            ),

            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, ColorScheme color, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
