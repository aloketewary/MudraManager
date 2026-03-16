import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSpacing {
  // Card spacing
    final double cardHorizontalMin;
  final double cardHorizontal;
  final double cardHorizontalMax;
  final double cardVerticalMin;
  final double cardVertical;
  final double cardVerticalMax;
  final double cardInner;

  // Section spacing
  final double sectionGap;
  final double elementGap;

  // Border radius
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
}

final spacingProvider = Provider<AppSpacing>((ref) {
  return const AppSpacing();
});
