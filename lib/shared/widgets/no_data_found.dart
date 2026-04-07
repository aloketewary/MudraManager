import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NoDataFound extends StatelessWidget {
  final String message;
  final String? description;
  final String? imagePath;
  final IconData? iconData;
  final Widget? action;

  const NoDataFound({
    super.key,
    required this.message,
    this.description,
    this.imagePath,
    this.iconData,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    assert(imagePath != null || iconData != null);

    // Split message on \n — first line is title, rest is subtitle
    final parts = message.split('\n');
    final title = parts.first;
    final subtitle =
        description ?? (parts.length > 1 ? parts.sublist(1).join('\n') : null);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon / Image
            _buildVisual(color, isDark)
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: color.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(
                  begin: 0.15,
                  end: 0,
                  duration: 400.ms,
                  delay: 100.ms,
                  curve: Curves.easeOut,
                ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 400.ms,
                    delay: 200.ms,
                    curve: Curves.easeOut,
                  ),
            ],

            // Action
            if (action != null) ...[
              const SizedBox(height: 24),
              action!
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    delay: 300.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(ColorScheme color, bool isDark) {
    if (imagePath != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.surfaceContainerHighest,
        ),
        child: Image.asset(imagePath!, width: 80, height: 80),
      );
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
            color.secondaryContainer.withValues(alpha: isDark ? 0.2 : 0.3),
          ],
        ),
      ),
      child: Icon(
        iconData,
        size: 36,
        color: color.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
