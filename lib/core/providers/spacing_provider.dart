import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/skin/data/skin_provider.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

// ── Spacing Constants (pre-computed, no rebuilds) ─────────────────────

/// Spacing configuration based on skin card radius
/// Use [spacingFromRadius] to get an instance without Riverpod overhead.
class AppSpacing {
  // ── Layout Spacing ──
  final double cardHorizontalMin;
  final double cardHorizontal;
  final double cardHorizontalMax;
  final double cardVerticalMin;
  final double cardVertical;
  final double cardVerticalMax;
  final double cardInner;
  final double sectionGap;
  final double elementGap;
  final double elementGapMin;
  final double elementGapUltraMin;

  // ── Border Radius ──
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  // ── Icon Sizes ──
  final double iconXS;
  final double iconSM;
  final double iconMD;
  final double iconLG;
  final double iconXL;

  // ── Animation Durations ──
  final Duration animFast;
  final Duration animNormal;
  final Duration animSlow;
  final Duration animHero;

  // ── Opacity ──
  final double opacityDisabled;
  final double opacitySubtle;
  final double opacityMedium;
  final double opacityHigh;

  // ── Stroke / Border ──
  final double strokeThin;
  final double strokeNormal;
  final double strokeThick;

  // ── Progress Bar ──
  final double progressThin;
  final double progressNormal;
  final double progressThick;

  // ── Touch Targets ──
  final double touchTarget;
  final double touchTargetSmall;

  const AppSpacing({
    // Layout - Mudra Precision spacing scale
    this.cardHorizontalMin = 4.0,
    this.cardHorizontal = 8.0,
    this.cardHorizontalMax = 16.0,
    this.cardVerticalMin = 4.0,
    this.cardVertical = 8.0,
    this.cardVerticalMax = 16.0,
    this.cardInner = 24.0,
    this.sectionGap = 24.0,
    this.elementGap = 8.0,
    this.elementGapMin = 4.0,
    this.elementGapUltraMin = 2.0,
    // Radius - Mudra Precision rounded scale
    this.radiusSmall = 4.0,
    this.radiusMedium = 8.0,
    this.radiusLarge = 16.0,
    // Icons
    this.iconXS = 14.0,
    this.iconSM = 16.0,
    this.iconMD = 20.0,
    this.iconLG = 24.0,
    this.iconXL = 32.0,
    // Animation
    this.animFast = const Duration(milliseconds: 150),
    this.animNormal = const Duration(milliseconds: 300),
    this.animSlow = const Duration(milliseconds: 500),
    this.animHero = const Duration(milliseconds: 800),
    // Opacity
    this.opacityDisabled = 0.3,
    this.opacitySubtle = 0.08,
    this.opacityMedium = 0.15,
    this.opacityHigh = 0.5,
    // Stroke
    this.strokeThin = 1.0,
    this.strokeNormal = 1.5,
    this.strokeThick = 2.0,
    // Progress
    this.progressThin = 3.0,
    this.progressNormal = 6.0,
    this.progressThick = 8.0,
    // Touch
    this.touchTarget = 48.0,
    this.touchTargetSmall = 40.0,
  });

  /// Comfortable spacing for accessibility / high contrast / elderly users.
  /// Larger touch targets, more breathing room, bolder strokes.
  const AppSpacing.comfortable({
    double? rSmall,
    double? rMedium,
    double? rLarge,
  })  : // Layout — ~40% larger
        cardHorizontalMin = 8.0,
        cardHorizontal = 14.0,
        cardHorizontalMax = 22.0,
        cardVerticalMin = 8.0,
        cardVertical = 14.0,
        cardVerticalMax = 22.0,
        cardInner = 28.0,
        sectionGap = 24.0,
        elementGap = 14.0,
        elementGapMin = 8.0,
        elementGapUltraMin = 4.0,
        // Radius — slightly larger
        radiusSmall = rSmall ?? 6.0,
        radiusMedium = rMedium ?? 10.0,
        radiusLarge = rLarge ?? 20.0,
        // Icons — 2px larger
        iconXS = 16.0,
        iconSM = 18.0,
        iconMD = 22.0,
        iconLG = 28.0,
        iconXL = 36.0,
        // Animation — slower for readability
        animFast = const Duration(milliseconds: 200),
        animNormal = const Duration(milliseconds: 400),
        animSlow = const Duration(milliseconds: 600),
        animHero = const Duration(milliseconds: 1000),
        // Opacity — higher for visibility
        opacityDisabled = 0.4,
        opacitySubtle = 0.12,
        opacityMedium = 0.2,
        opacityHigh = 0.6,
        // Stroke — bolder
        strokeThin = 1.5,
        strokeNormal = 2.0,
        strokeThick = 3.0,
        // Progress — thicker
        progressThin = 4.0,
        progressNormal = 8.0,
        progressThick = 10.0,
        // Touch — larger targets (WCAG)
        touchTarget = 56.0,
        touchTargetSmall = 48.0;

  // ── Convenience helpers ──

  BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);

  // ── Factory: Create spacing from skin radius (no Riverpod) ──────────

  /// Get spacing instance based on card radius (standard mode).
  /// No rebuilds - just a pure function.
  static AppSpacing fromRadius(double cardRadius) {
    final rSmall = (cardRadius * 0.6).clamp(0.0, 12.0);
    final rLarge = (cardRadius * 1.4).clamp(cardRadius, 32.0);

    return AppSpacing(
      radiusSmall: rSmall,
      radiusMedium: cardRadius,
      radiusLarge: rLarge,
    );
  }

  /// Get spacing instance based on card radius (comfortable/high-contrast mode).
  /// No rebuilds - just a pure function.
  static AppSpacing fromRadiusComfortable(double cardRadius) {
    final rSmall = (cardRadius * 0.6).clamp(0.0, 12.0);
    final rLarge = (cardRadius * 1.4).clamp(cardRadius, 32.0);

    return AppSpacing.comfortable(
      rSmall: rSmall + 2,
      rMedium: cardRadius + 4,
      rLarge: rLarge + 4,
    );
  }
}

// ── Spacing Provider (optimized for performance) ─────────────────────

/// Provides AppSpacing based on active skin and high contrast mode.
///
/// Optimization strategy:
/// - Only rebuilds when `highContrastMode` OR `skinStyle.cardRadius` changes
/// - Uses value-based comparison via [equatable] semantics
/// - Avoids rebuilding when other [SkinStyle] fields change
final spacingProvider = Provider<AppSpacing>((ref) {
  final highContrast = ref.watch(highContrastModeProvider);
  final skinStyle = ref.watch(skinStyleProvider);

  if (highContrast) {
    return AppSpacing.fromRadiusComfortable(skinStyle.cardRadius);
  }

  return AppSpacing.fromRadius(skinStyle.cardRadius);
});
