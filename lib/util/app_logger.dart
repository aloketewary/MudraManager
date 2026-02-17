import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '[MudraManager]';
  
  // Log levels
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('$_prefix [INFO] ${tag != null ? "[$tag] " : ""}$message');
    }
  }
  
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('$_prefix [DEBUG] ${tag != null ? "[$tag] " : ""}$message');
    }
  }
  
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('$_prefix [WARNING] ${tag != null ? "[$tag] " : ""}$message');
    }
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('$_prefix [ERROR] ${tag != null ? "[$tag] " : ""}$message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }
  
  // Feature-specific loggers
  static void transaction(String message) => info(message, tag: 'Transaction');
  static void widget(String message) => info(message, tag: 'Widget');
  static void database(String message) => info(message, tag: 'Database');
  static void navigation(String message) => info(message, tag: 'Navigation');
  static void sms(String message) => info(message, tag: 'SMS');
  static void notification(String message) => info(message, tag: 'Notification');
}
