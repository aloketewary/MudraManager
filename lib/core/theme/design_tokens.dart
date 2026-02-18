import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, sizing, and visual properties
/// across the Mudra Manager application
class DesignTokens {
  DesignTokens._();

  // ============================================================================
  // SPACING SCALE
  // ============================================================================
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ============================================================================
  // BORDER RADIUS SCALE
  // ============================================================================
  /// Small radius for chips, tags
  static const double radiusSmall = 12.0;
  
  /// Medium radius for input fields, buttons
  static const double radiusMedium = 16.0;
  
  /// Large radius for cards
  static const double radiusLarge = 20.0;
  
  /// Extra large radius for large panels
  static const double radiusXLarge = 24.0;

  // Convenience BorderRadius objects
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);

  // ============================================================================
  // ELEVATION / SHADOW LEVELS
  // ============================================================================
  static const double elevation0 = 0.0;
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;
  static const double elevation4 = 16.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // OPACITY VALUES
  // ============================================================================
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityLight = 0.12;
}

/// Elevation helper class for consistent shadow implementation
class AppElevation {
  AppElevation._();

  /// Minimal elevation for subtle depth (2dp)
  static List<BoxShadow> elevation1(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Standard elevation for cards (4dp)
  static List<BoxShadow> elevation2(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Enhanced elevation for emphasis (8dp)
  static List<BoxShadow> elevation3(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Strong elevation for modals and floating elements (16dp)
  static List<BoxShadow> elevation4(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  /// Colored shadow for accent elements (great for cards with accent colors)
  static List<BoxShadow> coloredElevation(Color accentColor, {double intensity = 0.3}) => [
        BoxShadow(
          color: accentColor.withOpacity(intensity),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
}
