import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';

class BudgetAlertBanner extends ConsumerWidget {
  final List<BudgetAlert> alerts;
  final VoidCallback onDismiss;

  const BudgetAlertBanner({
    super.key,
    required this.alerts,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final alert = alerts.first;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch<AppSpacing>(spacingProvider);

    final isCritical = alert.threshold == 100;
    final accentColor = isCritical ? colorScheme.error : const Color(0xFFF59E0B);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: isCritical
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: () {
            HapticFeedback.mediumImpact();
            _showDetails(context, alert);
          },
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert icon container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    LucideIcons.triangleAlert,
                    color: accentColor,
                    size: 20,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(),
                SizedBox(width: spacing.elementGap),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.budget.name,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing.elementGapUltraMin),
                      Row(
                        children: [
                          Text(
                            '${formatCurrency(alert.spent, decimals: 0)}',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            ' / ${formatCurrency(alert.budget.amount, decimals: 0)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.elementGapMin),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (alert.percentage / 100).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ).animate().fadeIn(duration: 300.ms),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDismiss();
                    },
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  void _showDetails(BuildContext context, BudgetAlert alert) {
    final ctxt = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    color: alert.threshold == 100 ? colorScheme.error : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    alert.budget.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                context,
                ctxt.label_budget_with_colon,
                formatCurrency(alert.budget.amount, decimals: 0),
                colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                ctxt.label_spent_with_colon,
                formatCurrency(alert.spent, decimals: 0),
                alert.threshold == 100 ? colorScheme.error : const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                ctxt.label_percentage_with_colon,
                '${alert.percentage.toStringAsFixed(1)}%',
                colorScheme.primary,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Progress',
                  value: (alert.percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    alert.threshold == 100 ? colorScheme.error : const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(ctxt.common_ok),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}
