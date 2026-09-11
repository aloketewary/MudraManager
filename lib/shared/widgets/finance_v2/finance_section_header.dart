import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Section title with an optional reference-style trailing action.
class FinanceSectionHeader extends ConsumerWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final IconData? icon;
  final Color? accent;

  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final foreground = accent ?? scheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: spacing.touchTargetSmall,
            height: spacing.touchTargetSmall,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.12),
              borderRadius: spacing.borderRadiusMedium,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: spacing.iconSM, color: foreground),
          ),
          SizedBox(width: spacing.elementGap),
        ],
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailingLabel != null)
          Semantics(
            button: onTrailingTap != null,
            label: trailingLabel,
            child: InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGapMin,
                  vertical: spacing.elementGapMin,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingLabel!,
                      style: textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: spacing.elementGapUltraMin),
                    Icon(
                      Icons.chevron_right,
                      size: spacing.iconSM,
                      color: foreground,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
