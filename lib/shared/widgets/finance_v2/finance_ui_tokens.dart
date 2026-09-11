import 'package:flutter/material.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Semantic visual helpers for the V2 finance UI primitives.
///
/// These helpers deliberately read the active Material scheme instead of
/// introducing a second hardcoded palette. The reference accent becomes the
/// active theme primary, including dark and AMOLED variants.
class FinanceUiTokens {
  FinanceUiTokens._();

  static Color surface(
    ColorScheme scheme, {
    bool elevated = false,
  }) {
    if (scheme.brightness == Brightness.dark) {
      return elevated ? scheme.surfaceContainer : scheme.surfaceContainerLow;
    }
    return elevated ? scheme.surface : scheme.surfaceContainerLow;
  }

  static Color muted(ColorScheme scheme) => scheme.onSurfaceVariant;

  static BorderSide border(
    ColorScheme scheme,
    AppSpacing spacing, {
    Color? accent,
    double alpha = 0.22,
  }) {
    final borderColor = accent ?? scheme.outlineVariant;
    return BorderSide(
      color: borderColor.withValues(alpha: alpha),
      width: spacing.strokeThin,
    );
  }

  static List<BoxShadow> shadow(
    ColorScheme scheme,
    AppSpacing spacing, {
    Color? tint,
  }) {
    return [
      BoxShadow(
        color: (tint ?? scheme.shadow).withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.18 : 0.06,
        ),
        blurRadius: spacing.sectionGap,
        offset: Offset(0, spacing.cardVertical),
      ),
    ];
  }

  static BorderRadius pillRadius() => BorderRadius.circular(999);
}
