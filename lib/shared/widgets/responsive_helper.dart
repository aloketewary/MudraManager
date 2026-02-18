import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile;
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }

  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }

  static bool isLargeText(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.3;
  }

  static bool shouldUseSingleColumn(BuildContext context) {
    return isSmallScreen(context) || isLargeText(context);
  }

  static double getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  static double getResponsiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) return width * 0.3;
    if (isTablet(context)) return width * 0.45;
    return width - 32;
  }

  static int getGridCrossAxisCount(BuildContext context, {int defaultCount = 2}) {
    if (shouldUseSingleColumn(context)) return 1;
    return 2; // Max 2 columns for utility screen
  }

  static double getGridAspectRatio(BuildContext context, {required double defaultRatio, required double singleColumnRatio}) {
    return shouldUseSingleColumn(context) ? singleColumnRatio : defaultRatio;
  }

  static double getResponsiveSize(BuildContext context, {required double mobile, double? tablet, double? desktop}) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}
