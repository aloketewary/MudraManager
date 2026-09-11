import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Theme-aware icon action with a reference-style compact circular surface.
class FinanceIconButton extends ConsumerWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? accent;
  final Color? backgroundColor;
  final bool selected;

  const FinanceIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent,
    this.backgroundColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final foregroundColor = accent ?? scheme.onSurface;
    final surfaceColor = backgroundColor ??
        (selected ? scheme.primaryContainer : scheme.surfaceContainerHighest);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: spacing.iconMD),
      style: IconButton.styleFrom(
        foregroundColor: selected ? scheme.onPrimaryContainer : foregroundColor,
        backgroundColor: surfaceColor,
        minimumSize: Size.square(spacing.touchTargetSmall),
        maximumSize: Size.square(spacing.touchTargetSmall),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: spacing.borderRadiusMedium,
        ),
      ),
    );
  }
}
