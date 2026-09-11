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

    return Semantics(
      label: semanticLabel,
      value: '${(visualValue * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: visualValue),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return SizedBox(
            height: effectiveHeight,
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: trackColor ?? scheme.surfaceContainerHighest,
                  ),
                  if (showStripeRemainder)
                    CustomPaint(
                      painter: _DiagonalStripePainter(
                        color: stripeColor ??
                            scheme.onSurfaceVariant.withValues(alpha: 0.25),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: animatedValue,
                      child: ColoredBox(
                        color: fillColor ?? scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  final Color color;

  const _DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    for (var x = -size.height; x < size.width + size.height; x += 7) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
