import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SnackbarType { error, success, info, warning }

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message,
    SnackbarType type, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final context = scaffoldMessengerKey.currentContext;
    if (context == null) return;

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    messenger.clearSnackBars();

    final (bg, fg, accent) = _colorRoles(type, color);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(type), size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
        duration: actionLabel != null ? const Duration(seconds: 8) : duration,
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: actionLabel != null,
        closeIconColor: fg.withValues(alpha: 0.7),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: accent,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        message,
        SnackbarType.error,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static void success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        message,
        SnackbarType.success,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static void info(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        message,
        SnackbarType.info,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static void warning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        message,
        SnackbarType.warning,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static IconData _icon(SnackbarType type) => switch (type) {
        SnackbarType.error => LucideIcons.circleX,
        SnackbarType.success => LucideIcons.circleCheck,
        SnackbarType.info => LucideIcons.info,
        SnackbarType.warning => LucideIcons.triangleAlert,
      };

  /// Returns (background, foreground, accent) using M3 tonal color roles.
  static (Color, Color, Color) _colorRoles(
    SnackbarType type,
    ColorScheme color,
  ) {
    return switch (type) {
      SnackbarType.error => (
          color.errorContainer,
          color.onErrorContainer,
          color.error,
        ),
      SnackbarType.success => (
          color.primaryContainer,
          color.onPrimaryContainer,
          color.primary,
        ),
      SnackbarType.info => (
          color.secondaryContainer,
          color.onSecondaryContainer,
          color.secondary,
        ),
      SnackbarType.warning => (
          color.tertiaryContainer,
          color.onTertiaryContainer,
          color.tertiary,
        ),
    };
  }
}
