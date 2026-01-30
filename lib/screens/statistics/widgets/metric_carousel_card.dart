import 'package:flutter/material.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';

class MetricCarouselCard extends StatelessWidget {
  final double income;
  final double expense;
  final double net;
  final double savingsRate;

  const MetricCarouselCard({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
    required this.savingsRate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildMetricCard(
            context,
            'Income',
            income,
            Icons.arrow_upward,
            [Colors.green.shade400, Colors.green.shade600],
            savingsRate > 0 ? savingsRate : null,
          ),
          _buildMetricCard(
            context,
            'Expense',
            expense,
            Icons.arrow_downward,
            [Colors.red.shade400, Colors.red.shade600],
            null,
          ),
          _buildMetricCard(
            context,
            'Net',
            net,
            net >= 0 ? Icons.trending_up : Icons.trending_down,
            net >= 0
                ? [Colors.blue.shade400, Colors.blue.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            null,
          ),
          _buildMetricCard(
            context,
            'Savings',
            savingsRate,
            Icons.savings_outlined,
            [Colors.purple.shade400, Colors.purple.shade600],
            null,
            isPercent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    double value,
    IconData icon,
    List<Color> gradientColors,
    double? progress, {
    bool isPercent = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                AnimatedBalance(
                  value: isPercent ? value : value,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  suffix: isPercent ? '%' : null,
                  fixedStringLength: isPercent ? 1 : 0,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null)
                  SizedBox(height: 8),
                if (progress != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                if (progress != null)
                  SizedBox(height: 4),
                if (progress != null)
                  Text(
                    'Saved ${progress.toStringAsFixed(1)}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
