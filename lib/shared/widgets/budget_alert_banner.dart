import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
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

    final accentColor = alert.threshold == 100
        ? colorScheme.error
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accentColor.withValues(alpha: 0.08),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.mediumImpact();
          _showDetails(context, alert);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.budget.name} \u2022 ${alert.percentage.toInt()}%',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatCurrency(alert.spent, decimals: 0)} / ${formatCurrency(alert.budget.amount, decimals: 0)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDismiss();
                },
                child: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, BudgetAlert alert) {
    final ctxt = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.budget.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrencyText(
              amount: alert.budget.amount,
              prefixText: ctxt.label_budget_with_colon,
              compact: false,
              fixedLength: 0,
            ),
            CurrencyText(
              amount: alert.spent,
              prefixText: ctxt.label_spent_with_colon,
              compact: false,
              fixedLength: 0,
            ),
            Text(
              '${ctxt.label_percentage_with_colon} ${alert.percentage.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                semanticsLabel: 'Progress',
                value: (alert.percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: alert.threshold == 100
                    ? colorScheme.error
                    : const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ctxt.common_ok),
          ),
        ],
      ),
    );
  }
}
