import 'package:flutter/animation.dart';

/// Enterprise Dashboard Constants
/// Centralized configuration for dashboard feature
class DashboardConstants {
  /// Maximum width for dashboard content on large screens
  static const double maxWidth = 600.0;

  /// Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration slideDuration = Duration(milliseconds: 400);
  static const Duration revealDelay = Duration(milliseconds: 60);

  /// Initialization delays
  static const Duration initDelayDuration = Duration(seconds: 3);

  /// User onboarding thresholds
  static const int newUserHoursThreshold = 24;

  /// Widget reveal configuration
  static const int maxVisibleWidgetsInitially = 1;

  /// Refresh configuration
  static const Duration minRefreshInterval = Duration(milliseconds: 500);

  /// Budget alert thresholds
  static const int budgetWarningThreshold = 80;
  static const int budgetCriticalThreshold = 100;

  /// Bill due date thresholds (in days)
  static const int billDueToday = 0;
  static const int billDueSoon = 3;
  static const int billUpcoming = 30;

  /// Privacy and security
  static const int biometricTimeoutMinutes = 5;
  static const int sessionTimeoutMinutes = 15;

  /// Data refresh intervals
  static const Duration quickRefreshInterval = Duration(seconds: 30);
  static const Duration fullRefreshInterval = Duration(minutes: 5);

  /// Animation curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOutBack = Curves.easeOutBack;
}