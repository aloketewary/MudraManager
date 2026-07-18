import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Displays monthly spending metric with trend indicator.
/// Used at top of transaction list screens.
///
/// Features:
/// - Responsive typography with font scaling support
/// - Smooth animations for trend changes
/// - Accessibility-ready with proper semantics
/// - Theming via AppSpacing for consistent spacing
class SpendMetric extends ConsumerWidget {
  final String label;
  final String amount;
  final String? changePercent;
  final bool isPositiveChange;

  const SpendMetric({
    super.key,
    required this.label,
    required this.amount,
    this.changePercent,
    this.isPositiveChange = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Get text scale factor for responsive typography
    final textScaler = MediaQuery.of(context).textScaler;
    final textScaleFactor = textScaler.scale(11) / 11;
    final isReducedMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with tracking
        AnimatedDefaultTextStyle(
          duration: isReducedMotion ? Duration.zero : spacing.animFast,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11 * textScaleFactor,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          child: Text(label),
        ),
        SizedBox(height: spacing.elementGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Amount with smooth scaling animation
            TweenAnimationBuilder<double>(
              duration: isReducedMotion ? Duration.zero : spacing.animNormal,
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.9, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: AnimatedDefaultTextStyle(
                duration: isReducedMotion ? Duration.zero : spacing.animFast,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 46 * textScaleFactor,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
                child: Text(amount),
              ),
            ),
            if (changePercent != null) ...[
              SizedBox(width: spacing.elementGapMin),
              // Animated trend badge
              _TrendBadge(
                changePercent: changePercent!,
                isPositiveChange: isPositiveChange,
                spacing: spacing,
                colorScheme: colorScheme,
                isReducedMotion: isReducedMotion,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Animated trend indicator badge
class _TrendBadge extends StatelessWidget {
  final String changePercent;
  final bool isPositiveChange;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final bool isReducedMotion;

  const _TrendBadge({
    required this.changePercent,
    required this.isPositiveChange,
    required this.spacing,
    required this.colorScheme,
    required this.isReducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = isPositiveChange
        ? colorScheme.primary
        : colorScheme.error;

    return AnimatedContainer(
      duration: isReducedMotion ? Duration.zero : spacing.animFast,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: spacing.strokeThin,
        ),
        color: trendColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall + 2),
      ),
      child: AnimatedDefaultTextStyle(
        duration: isReducedMotion ? Duration.zero : spacing.animFast,
        style: TextStyle(
          color: trendColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        child: Text(changePercent),
      ),
    );
  }
}