import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

/// Reference-style progress bar with optional diagonal remainder texture.
class FinanceProgressBar extends ConsumerWidget {
  final double value;
  final Color? fillColor;
  final Color? trackColor;
  final Color? stripeColor;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showStripeRemainder;
  final bool animate;
  final String? semanticLabel;

  const FinanceProgressBar({
    super.key,
    required this.value,
    this.fillColor,
    this.trackColor,
    this.stripeColor,
    this.height,
    this.borderRadius,
    this.showStripeRemainder = true,
    this.animate = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);
    final visualValue = value.clamp(0.0, 1.0).toDouble();
    final effectiveHeight = height ?? spacing.progressNormal;
    final effectiveRadius = borderRadius ?? spacing.borderRadiusSmall;
    final duration = animate && !MediaQuery.of(context).disableAnimations
        ? spacing.animNormal
        : Duration.zero;
    final effectiveTrackColor = trackColor ?? scheme.surfaceContainerHighest;
    final effectiveFillColor = fillColor ?? scheme.primary;
    final effectiveStripeColor =
        stripeColor ?? scheme.onSurfaceVariant.withValues(alpha: 0.25);

    return Semantics(
      label: semanticLabel,
      value: '${(visualValue * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: visualValue),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return SizedBox(
            width: double.infinity,
            height: effectiveHeight,
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: CustomPaint(
                painter: _ProgressBarPainter(
                  value: animatedValue,
                  trackColor: effectiveTrackColor,
                  fillColor: effectiveFillColor,
                  stripeColor: effectiveStripeColor,
                  showStripeRemainder: showStripeRemainder,
                  borderRadius: effectiveRadius,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color fillColor;
  final Color stripeColor;
  final bool showStripeRemainder;
  final BorderRadius borderRadius;

  const _ProgressBarPainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    required this.stripeColor,
    required this.showStripeRemainder,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackRRect = borderRadius.toRRect(Offset.zero & size);
    final trackPaint = Paint()..color = trackColor;
    canvas.drawRRect(trackRRect, trackPaint);

    if (showStripeRemainder) {
      canvas.save();
      canvas.clipRRect(trackRRect);
      final stripePaint = Paint()
        ..color = stripeColor
        ..strokeWidth = 1.4;
      for (var x = -size.height; x < size.width + size.height; x += 7) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          stripePaint,
        );
      }
      canvas.restore();
    }

    final fillWidth = size.width * value.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;

    final fillRRect = borderRadius.toRRect(
      Rect.fromLTWH(0, 0, fillWidth, size.height),
    );
    canvas.drawRRect(fillRRect, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.stripeColor != stripeColor ||
        oldDelegate.showStripeRemainder != showStripeRemainder ||
        oldDelegate.borderRadius != borderRadius;
  }
}
