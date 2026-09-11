import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_ui_tokens.dart';

/// Compact status, metric, or percentage chip.
class FinancePill extends ConsumerWidget {
  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? semanticLabel;

  const FinancePill({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final foreground = foregroundColor ?? scheme.primary;

    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap,
          vertical: spacing.elementGapMin,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? foreground.withValues(alpha: 0.12),
          borderRadius: FinanceUiTokens.pillRadius(),
          border: Border.fromBorderSide(
            BorderSide(
              color: borderColor ?? foreground.withValues(alpha: 0.24),
              width: spacing.strokeThin,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: spacing.iconSM, color: foreground),
              SizedBox(width: spacing.elementGapMin),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
