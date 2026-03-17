import 'package:flutter/material.dart';

enum SnackbarType { error, success, info, warning }

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message, SnackbarType type) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    // Clear any existing snackbar to prevent animation status
    // listener from firing on a deactivated widget tree
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void error(String message) => show(message, SnackbarType.error);
  static void success(String message) => show(message, SnackbarType.success);
  static void info(String message) => show(message, SnackbarType.info);
  static void warning(String message) => show(message, SnackbarType.warning);

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.error:
        return const Color(0xFFD32F2F);
      case SnackbarType.success:
        return const Color(0xFF388E3C);
      case SnackbarType.info:
        return const Color(0xFF1976D2);
      case SnackbarType.warning:
        return const Color(0xFFF57C00);
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.info:
        return Icons.info_outline;
      case SnackbarType.warning:
        return Icons.warning_amber_outlined;
    }
  }
}
