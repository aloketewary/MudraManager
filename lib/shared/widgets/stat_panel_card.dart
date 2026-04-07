import 'package:flutter/material.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/trend_indicator.dart';

/// Reusable stat panel — accent-tinted card with icon, label, animated amount,
/// and optional trend indicator. Matches the cash flow card style.
class StatPanelCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color accent;
  final double? previousAmount;
  final bool trendInverted;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const StatPanelCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.accent,
    this.previousAmount,
    this.trendInverted = false,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: accent.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(icon, size: 16, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AdaptiveText(
                      label.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBalance(
                value: amount,
                style: textTheme.headlineMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
                fixedStringLength: 0,
                overflow: TextOverflow.fade,
              ),
              if (previousAmount != null && previousAmount! > 0) ...[
                const SizedBox(height: 6),
                TrendIndicator(
                  current: amount,
                  previous: previousAmount!,
                  isIncome: !trendInverted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
