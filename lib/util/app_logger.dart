import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility for analytics and crash reporting
class AppLogger {
  static const String _tag = 'MudraManager';

  /// Log info message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 800,
      );
    }
  }

  /// Log warning message
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 900,
      );
    }
  }

  /// Log error message with optional error object and stack trace
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  }

  /// Log user action for analytics
  static void logAction(String action, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      final params = parameters != null ? ' - $parameters' : '';
      developer.log(
        'Action: $action$params',
        name: '$_tag/Analytics',
        level: 800,
      );
    }
    // TODO: Send to analytics service (Firebase Analytics, Mixpanel, etc.)
  }

  /// Log navigation event
  static void logNavigation(String from, String to) {
    if (kDebugMode) {
      developer.log(
        'Navigation: $from → $to',
        name: '$_tag/Navigation',
        level: 800,
      );
    }
  }

  /// Log database operation
  static void logDatabase(String operation, {Map<String, dynamic>? details}) {
    if (kDebugMode) {
      final detailsStr = details != null ? ' - $details' : '';
      developer.log(
        'DB: $operation$detailsStr',
        name: '$_tag/Database',
        level: 800,
      );
    }
  }

  /// Log SMS processing
  static void logSMS(String message, {Map<String, dynamic>? details}) {
    if (kDebugMode) {
      final detailsStr = details != null ? ' - $details' : '';
      developer.log(
        'SMS: $message$detailsStr',
        name: '$_tag/SMS',
        level: 800,
      );
    }
  }

  /// Log performance metric
  static void logPerformance(String metric, Duration duration) {
    if (kDebugMode) {
      developer.log(
        'Performance: $metric took ${duration.inMilliseconds}ms',
        name: '$_tag/Performance',
        level: 800,
      );
    }
  }
}
