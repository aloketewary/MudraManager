import 'package:flutter/material.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

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
            const SizedBox(width: 12),
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

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 6),
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
                AdaptiveText(
                  topCategory,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: topCategoryColor,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                CurrencyText(
                  amount: topCategoryAmount,
                  style: textTheme.titleMedium?.copyWith(
                    color: topCategoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
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
      ),
    );
  }

  Widget _buildAvgDailyCard(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: color.primary,
                ),
                const SizedBox(width: 6),
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
                CurrencyText(
                  amount: avgDailySpend,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.primary,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
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
                color: color.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
