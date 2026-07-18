import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Enhanced date header with backdrop blur and smooth styling.
///
/// Features:
/// - Glassmorphism effect with backdrop blur
/// - Animated entry and state transitions
/// - Responsive spacing
/// - Accessible semantics
class StyledDateHeader extends ConsumerWidget {
  /// The date text to display
  final String dateText;

  /// Whether this is a "Today" header
  final bool isToday;

  /// Whether this is a "Yesterday" header
  final bool isYesterday;

  const StyledDateHeader({
    super.key,
    required this.dateText,
    this.isToday = false,
    this.isYesterday = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    // Determine styling based on date type
    final headerColor = isToday
        ? colorScheme.primary
        : isYesterday
            ? colorScheme.tertiary
            : colorScheme.onSurfaceVariant;

    final containerColor = isToday
        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
        : isYesterday
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.25)
            : Colors.transparent;

    final iconColor = isToday
        ? colorScheme.primary
        : isYesterday
            ? colorScheme.tertiary
            : colorScheme.onSurfaceVariant;

    return TweenAnimationBuilder<double>(
      duration: isReducedMotion ? Duration.zero : spacing.animNormal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.9, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical * 0.5,
            ),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(spacing.radiusSmall + 4),
              border: Border.all(
                color: (isToday || isYesterday)
                    ? headerColor.withValues(alpha: 0.2)
                    : colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: spacing.strokeThin,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal * 0.75,
                vertical: spacing.cardVertical * 0.5,
              ),
              child: _DateContent(
                dateText: dateText,
                isToday: isToday,
                isYesterday: isYesterday,
                iconColor: iconColor,
                headerColor: headerColor,
                spacing: spacing,
                textTheme: textTheme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateContent extends StatelessWidget {
  final String dateText;
  final bool isToday;
  final bool isYesterday;
  final Color iconColor;
  final Color headerColor;
  final AppSpacing spacing;
  final TextTheme textTheme;

  const _DateContent({
    required this.dateText,
    required this.isToday,
    required this.isYesterday,
    required this.iconColor,
    required this.headerColor,
    required this.spacing,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isToday || isYesterday)
          Container(
            padding: EdgeInsets.all(spacing.elementGapUltraMin + 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Icon(
              isToday ? LucideIcons.calendarCheck : LucideIcons.history,
              size: spacing.iconSM,
              color: iconColor,
            ),
          ),
        SizedBox(width: spacing.elementGap),
        AnimatedDefaultTextStyle(
          duration: spacing.animFast,
          style: textTheme.labelMedium?.copyWith(
            color: headerColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            height: 1.2,
          ) ?? const TextStyle(),
          child: Text(dateText.toUpperCase()),
        ),
      ],
    );
  }
}