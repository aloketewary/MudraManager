import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

/// Global build-error fallback UI.
///
/// Flutter already catches exceptions thrown during a widget's build phase
/// internally (in `ComponentElement.performRebuild`) and substitutes
/// whatever `ErrorWidget.builder` returns in place of the failing widget —
/// it does not rethrow to callers. That makes `ErrorWidget.builder` the
/// correct, framework-provided hook for this, not a local `try/catch`
/// wrapper: a plain `try { ... } catch` around a widget's own `build()`
/// method cannot observe errors from its returned child subtree, because
/// that subtree is mounted by the framework *after* `build()` returns, in
/// a different call frame.
///
/// Call [ErrorBoundary.install] once during app startup (see `main.dart`).
/// This replaces Flutter's default debug red-screen / release gray-screen
/// with a friendly, on-brand fallback, and only the failing subtree is
/// replaced — sibling widgets keep rendering normally.
class ErrorBoundary {
  ErrorBoundary._();

  static void install() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      final log = AppLog(getLogger(), 'ErrorBoundary');
      log.e('Widget build error', details.exception, details.stack);
      // In debug builds, keep Flutter's default red screen with the full
      // exception + widget inspector affordances — losing that during
      // development costs more than it protects. Only swap to the
      // friendly fallback in release/profile builds where a red screen
      // would otherwise ship to real users.
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      return _ErrorFallback(details: details);
    };
  }
}

class _ErrorFallback extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorFallback({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 24, color: theme.colorScheme.error),
          const SizedBox(height: 4),
          Text(
            'Something went wrong',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
