import 'package:flutter/material.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class InsightGridCard extends StatelessWidget {
  final String topCategory;
  final double topCategoryAmount;
  final double topCategoryPercent;
  final double avgDailySpend;
  final Color topCategoryColor;

  const InsightGridCard({
    super.key,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategoryPercent,
    required this.avgDailySpend,
    required this.topCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTopCategoryCard(context)),
            SizedBox(width: 12),
            Expanded(child: _buildAvgDailyCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildTopCategoryCard(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.surface,
        border: Border.all(color: color.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: topCategoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Top Category',
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topCategory,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                ctxt.formatCurrencyWithSign(0, topCategoryAmount),
                style: textTheme.titleMedium?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${topCategoryPercent.toStringAsFixed(0)}% of expenses',
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvgDailyCard(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.surface,
        border: Border.all(color: color.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: color.primary),
              SizedBox(width: 6),
              Text(
                'Daily Average',
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctxt.formatCurrencyWithSign(0, avgDailySpend),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'per day',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [color.primary, color.primaryContainer],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
