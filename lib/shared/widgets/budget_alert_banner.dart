import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';

class BudgetAlertBanner extends StatelessWidget {
  final List<BudgetAlert> alerts;
  final VoidCallback onDismiss;

  const BudgetAlertBanner({
    super.key,
    required this.alerts,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final alert = alerts.first;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final color = alert.threshold == 100
        ? colorScheme.error
        : alert.threshold == 90
        ? const Color(0xFFF59E0B)
        : const Color(0xFFFBBF24);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context, alert),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  alert.threshold == 100
                      ? LucideIcons.circleAlert
                      : LucideIcons.triangleAlert,
                  color: color,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.threshold == 100
                            ? 'Budget Exceeded!'
                            : 'Budget Alert: ${alert.threshold}%',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert.budget.name}: ${formatCurrency(alert.spent, decimals: 0)} / ${formatCurrency(alert.budget.amount, decimals: 0)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(LucideIcons.x),
                  onPressed: onDismiss,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, BudgetAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.budget.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrencyText(amount: alert.budget.amount, prefixText: 'Budget:', compact: false, fixedLength: 0),
            CurrencyText(amount: alert.spent, prefixText: 'Spent:', compact: false, fixedLength: 0),
            Text('Percentage: ${alert.percentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              semanticsLabel: 'Progress',
              value: alert.percentage / 100,
              backgroundColor: Colors.grey[300],
              color: alert.threshold == 100
                  ? FinanceColors.statusDanger
                  : alert.threshold == 90
                  ? FinanceColors.statusWarning
                  : Colors.amber,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
