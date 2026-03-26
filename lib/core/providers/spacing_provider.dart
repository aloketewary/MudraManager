// lib/core/providers/spacing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/theme/theme_provider.dart';

class AppSpacing {
  final double cardHorizontalMin;
  final double cardHorizontal;
  final double cardHorizontalMax;
  final double cardVerticalMin;
  final double cardVertical;
  final double cardVerticalMax;
  final double cardInner;
  final double sectionGap;
  final double elementGap;
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  const AppSpacing({
    this.cardHorizontalMin = 4.0,
    this.cardHorizontal = 8.0,
    this.cardHorizontalMax = 16.0,
    this.cardVerticalMin = 4.0,
    this.cardVertical = 8.0,
    this.cardVerticalMax = 16.0,
    this.cardInner = 16.0,
    this.sectionGap = 16.0,
    this.elementGap = 8.0,
    this.radiusSmall = 8.0,
    this.radiusMedium = 12.0,
    this.radiusLarge = 16.0,
  });

  /// Comfortable spacing for accessibility / elderly users
  const AppSpacing.comfortable()
      : cardHorizontalMin = 8.0,
        cardHorizontal = 14.0,
        cardHorizontalMax = 22.0,
        cardVerticalMin = 8.0,
        cardVertical = 14.0,
        cardVerticalMax = 22.0,
        cardInner = 22.0,
        sectionGap = 24.0,
        elementGap = 14.0,
        radiusSmall = 10.0,
        radiusMedium = 16.0,
        radiusLarge = 20.0;
}

final spacingProvider = Provider<AppSpacing>((ref) {
  final highContrast = ref.watch(highContrastModeProvider);
  return highContrast ? const AppSpacing.comfortable() : const AppSpacing();
});
