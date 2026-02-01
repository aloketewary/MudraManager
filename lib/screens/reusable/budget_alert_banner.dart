import 'package:flutter/material.dart';
import 'package:mudra_manager/service/budget_alert_service.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
        ? AppColors.expense
        : alert.threshold == 90
            ? Color(0xFFF59E0B)
            : Color(0xFFFBBF24);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
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
                      ? Icons.error
                      : Icons.warning_amber_rounded,
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
                        '${alert.budget.name}: ₹${alert.spent.toStringAsFixed(0)} / ₹${alert.budget.amount.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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
            Text('Budget: ₹${alert.budget.amount.toStringAsFixed(0)}'),
            Text('Spent: ₹${alert.spent.toStringAsFixed(0)}'),
            Text('Percentage: ${alert.percentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: alert.percentage / 100,
              backgroundColor: Colors.grey[300],
              color: alert.threshold == 100
                  ? Colors.red
                  : alert.threshold == 90
                      ? Colors.orange
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
