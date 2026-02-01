import 'package:flutter/material.dart';

class AppColors {
  // Trip Status Colors
  static const Color tripActive = Color(0xFF4CAF50);
  static const Color tripActiveDark = Color(0xFF2E7D32);
  static const Color tripUpcoming = Color(0xFF2196F3);
  static const Color tripUpcomingDark = Color(0xFF1565C0);
  static const Color tripPast = Color(0xFFFF9800);
  static const Color tripPastDark = Color(0xFFE65100);
  static const Color tripCompleted = Color(0xFF9E9E9E);
  static const Color tripCompletedDark = Color(0xFF616161);

  // Financial Colors - Fresh & Elegant
  static const Color income = Color(0xFF10B981);
  static const Color incomeDark = Color(0xFF059669);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseDark = Color(0xFFDC2626);
  static const Color transfer = Color(0xFF3B82F6);
  static const Color transferDark = Color(0xFF2563EB);

  // Bill Status Colors
  static const Color billOverdue = Color(0xFFF44336);
  static const Color billOverdueDark = Color(0xFFC62828);
  static const Color billDueSoon = Color(0xFFFF9800);
  static const Color billDueSoonDark = Color(0xFFE65100);
  static const Color billNormal = Color(0xFF2196F3);
  static const Color billNormalDark = Color(0xFF1565C0);

  // Dashboard Colors - Modern & Fresh
  static const Color netWorth = Color(0xFF8B5CF6);
  static const Color netWorthDark = Color(0xFF7C3AED);
  static const Color cardShadow = Color(0x0D000000);
  static const Color cardShadowColored = Color(0x40000000);

  // Utility Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteTransparent = Color(0x33FFFFFF);
  static const Color whiteSemiTransparent = Color(0xE6FFFFFF);
  static const Color shadow = Color(0x4D4CAF50);
  static const Color dark = Color(0xFF000000);


  // Glassmorphism gradient helper
  static List<Color> glassGradient(Color baseColor, bool isDark) {
    return isDark
        ? [baseColor.withValues(alpha: 0.12), baseColor.withValues(alpha: 0.04)]
        : [baseColor.withValues(alpha: 0.06), baseColor.withValues(alpha: 0.02)];
  }

  // Glassmorphism shadow helper
  static List<BoxShadow> glassShadow(Color baseColor, bool isDark) {
    return [
      BoxShadow(
        color: isDark ? cardShadow : baseColor.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
      if (!isDark)
        BoxShadow(
          color: baseColor.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
    ];
  }

  static Color textColor(bool isDark) {
    return isDark ? white : dark;
  }
}
