import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

/// Debug-only overflow detector.
/// Hooks into FlutterError to catch and log all RenderFlex/RenderBox overflows
/// with the widget path so you know exactly where to fix.
///
/// Usage: call `OverflowDetector.init()` in main() before runApp().
class OverflowDetector {
  static final _log = AppLog(getLogger(), 'OverflowDetector');
  static final List<String> overflowLog = [];

  static void init() {
    if (!kDebugMode) return;

    final originalHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        final entry =
            '⚠️ OVERFLOW: ${details.context?.toStringDeep() ?? "unknown"}\n'
            '   ${message.split('\n').first}';
        overflowLog.add(entry);
        _log.w(entry);
      }
      originalHandler?.call(details);
    };

    _log.i('Overflow detector active — overflows will be logged');
  }
}
