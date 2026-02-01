import 'package:flutter/material.dart';
import 'package:mudra_manager/screens/reusable/animated_balance.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            AppColors.income,
            isDark,
            savingsRate > 0 ? savingsRate : null,
          ),
          _buildMetricCard(
            context,
            'Expense',
            expense,
            Icons.arrow_downward,
            AppColors.expense,
            isDark,
            null,
          ),
          _buildMetricCard(
            context,
            'Net',
            net,
            net >= 0 ? Icons.trending_up : Icons.trending_down,
            net >= 0 ? AppColors.transfer : Color(0xFFFF9800),
            isDark,
            null,
          ),
          _buildMetricCard(
            context,
            'Savings',
            savingsRate,
            Icons.savings_outlined,
            AppColors.netWorth,
            isDark,
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
    Color baseColor,
    bool isDark,
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
          colors: AppColors.glassGradient(baseColor, isDark),
        ),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppColors.glassShadow(baseColor, isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: baseColor.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: baseColor, size: 20),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          color: baseColor,
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
                    color: baseColor,
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
                      backgroundColor: baseColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(baseColor),
                      minHeight: 6,
                    ),
                  ),
                if (progress != null)
                  SizedBox(height: 4),
                if (progress != null)
                  Text(
                    'Saved ${progress.toStringAsFixed(1)}%',
                    style: textTheme.labelSmall?.copyWith(
                      color: baseColor.withValues(alpha: 0.8),
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
