import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight error tracker for debugging.
///
/// Stores the last 50 errors in SharedPreferences.
/// No Isar schema change needed — works immediately.
///
/// Usage:
/// ```dart
/// ErrorTracker.record('sms_pipeline', 'Failed to parse SMS from HDFCBK', error);
/// final errors = await ErrorTracker.getRecent();
/// ```
class ErrorTracker {
  static const _key = 'app_error_log';
  static const _maxEntries = 50;

  ErrorTracker._();

  static Future<void> record(String source, String message, [Object? error]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_key) ?? [];

      final entry = jsonEncode({
        'source': source,
        'message': message,
        'error': error?.toString(),
        'time': DateTime.now().toIso8601String(),
      });

      existing.add(entry);
      if (existing.length > _maxEntries) {
        existing.removeRange(0, existing.length - _maxEntries);
      }

      await prefs.setStringList(_key, existing);
    } catch (_) {
      // Don't let error tracking cause errors
    }
  }

  static Future<List<ErrorEntry>> getRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = prefs.getStringList(_key) ?? [];
      return entries.reversed.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return ErrorEntry(
          source: map['source'] as String? ?? '',
          message: map['message'] as String? ?? '',
          error: map['error'] as String?,
          time: DateTime.tryParse(map['time'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class ErrorEntry {
  final String source;
  final String message;
  final String? error;
  final DateTime time;

  ErrorEntry({
    required this.source,
    required this.message,
    this.error,
    required this.time,
  });
}
