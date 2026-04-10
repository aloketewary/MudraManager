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
    final hasAction = actionLabel != null;
    final snackDuration = hasAction ? const Duration(seconds: 6) : duration;

    messenger.showSnackBar(
      SnackBar(
        content: hasAction
            ? _UndoSnackbarContent(
                message: message,
                actionLabel: actionLabel,
                onAction: onAction ?? () {},
                duration: snackDuration,
                fg: fg,
                accent: accent,
                textTheme: textTheme,
                type: type,
              )
            : Row(
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
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: hasAction ? 10 : 14,
        ),
        elevation: 0,
        duration: snackDuration,
        dismissDirection: DismissDirection.horizontal,
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

/// Snackbar content with countdown ring + undo button.
class _UndoSnackbarContent extends StatefulWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Duration duration;
  final Color fg;
  final Color accent;
  final TextTheme textTheme;
  final SnackbarType type;

  const _UndoSnackbarContent({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.fg,
    required this.accent,
    required this.textTheme,
    required this.type,
  });

  @override
  State<_UndoSnackbarContent> createState() => _UndoSnackbarContentState();
}

class _UndoSnackbarContentState extends State<_UndoSnackbarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Countdown ring with icon
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1.0 - _controller.value,
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                  color: widget.accent,
                  backgroundColor: widget.accent.withValues(alpha: 0.15),
                ),
                Icon(
                  SnackbarService._icon(widget.type),
                  size: 14,
                  color: widget.accent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Message
        Expanded(
          child: Text(
            widget.message,
            style: widget.textTheme.bodyMedium?.copyWith(
              color: widget.fg,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Undo button
        TextButton(
          onPressed: () {
            widget.onAction();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            widget.actionLabel,
            style: widget.textTheme.labelLarge?.copyWith(
              color: widget.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
