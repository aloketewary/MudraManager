import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Badge for showing count, status, or small text with background.
/// Used for pending counts, trial days, active status, etc.
class StatusBadge extends ConsumerWidget {
  const StatusBadge(
    this.text, {
    super.key,
    this.textColor,
    this.backgroundColor,
    this.fontSize = 9,
  });

  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final effectiveTextColor = textColor ?? color.primary;
    final effectiveBackgroundColor =
        backgroundColor ?? color.primary.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
