import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/finance_v2/finance_ui_tokens.dart';

/// V2 rounded surface for cards, grouped rows, and interactive finance panels.
class FinanceSurface extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? accent;
  final BorderRadius? borderRadius;
  final BorderSide? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const FinanceSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.accent,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final effectiveRadius = borderRadius ?? spacing.borderRadiusLarge;
    final effectiveBorder =
        border ?? FinanceUiTokens.border(scheme, spacing, accent: accent);
    final effectiveShadow =
        boxShadow ?? FinanceUiTokens.shadow(scheme, spacing, tint: accent);

    final surfaceContent = Padding(
      padding: padding ?? EdgeInsets.all(spacing.cardInner),
      child: child,
    );

    final interactiveContent = onTap == null
        ? surfaceContent
        : InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius,
            child: surfaceContent,
          );

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: gradient == null
              ? color ?? FinanceUiTokens.surface(scheme)
              : null,
          gradient: gradient,
          borderRadius: effectiveRadius,
          border: Border.fromBorderSide(effectiveBorder),
          boxShadow: effectiveShadow,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: Material(
            color: Colors.transparent,
            child: interactiveContent,
          ),
        ),
      ),
    );
  }
}
