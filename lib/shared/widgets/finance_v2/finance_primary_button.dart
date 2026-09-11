import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Full-width or compact primary action used by V2 finance screens.
class FinancePrimaryButton extends ConsumerWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool loading;
  final String? semanticLabel;

  const FinancePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.loading = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: backgroundColor ?? scheme.primary,
      foregroundColor: foregroundColor ?? scheme.onPrimary,
      minimumSize: Size(0, spacing.touchTargetSmall),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardInner,
        vertical: spacing.elementGap,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: spacing.borderRadiusLarge,
      ),
    );
    final effectiveOnPressed = loading ? null : onPressed;
    final buttonChild = loading
        ? SizedBox(
            width: spacing.iconSM,
            height: spacing.iconSM,
            child: CircularProgressIndicator(
              strokeWidth: spacing.strokeThin,
              color: foregroundColor ?? scheme.onPrimary,
            ),
          )
        : null;

    final button = icon != null && buttonChild == null
        ? FilledButton.icon(
            onPressed: effectiveOnPressed,
            style: buttonStyle,
            icon: Icon(icon, size: spacing.iconMD),
            label: Text(label),
          )
        : FilledButton(
            onPressed: effectiveOnPressed,
            style: buttonStyle,
            child: buttonChild ?? Text(label),
          );

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: button,
      ),
    );
  }
}
