import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lightweight inline error widget for async `.when(error:)` handlers.
///
/// Use instead of `SizedBox.shrink()` when the error section is part of
/// a scrollable screen (not the only content). For full-screen errors,
/// use `NoDataFound` instead.
class InlineError extends StatelessWidget {
  final String? message;

  const InlineError({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 16,
            color: color.error.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'Failed to load',
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
