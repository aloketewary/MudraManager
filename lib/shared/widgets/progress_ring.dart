import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Shared circular progress ring with a sweep gradient stroke and a
/// visibility-gated entrance animation.
///
/// Consolidates what used to be three near-identical `_CompactRingPainter`
/// + `TweenAnimationBuilder` copies across the budget overview, goal, and
/// financial health dashboard cards. The ring only plays its entrance
/// animation once, when it first scrolls into view — not on every
/// unrelated provider rebuild — then tracks live [progress] changes.
class ProgressRing extends StatefulWidget {
  /// Target progress. Values outside 0.0-1.0 are clamped.
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

  /// Gap between the ring's outer edge and the [size] bounding box.
  final double insetPadding;
  final Duration duration;
  final Curve curve;

  /// Builds the centered label from the current *animated* value
  /// (0.0-1.0), not the raw [progress] target. Return `null` for no label.
  final Widget Function(double animatedValue)? labelBuilder;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 48,
    this.strokeWidth = 6,
    this.insetPadding = 4,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.labelBuilder,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  final Key _visibilityKey = UniqueKey();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: widget.curve);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.progress.clamp(0.0, 1.0);

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3 && !_started) {
          _started = true;
          _ctrl.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final value = _started ? _anim.value * target : 0.0;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    progress: value,
                    color: widget.color,
                    strokeWidth: widget.strokeWidth,
                    insetPadding: widget.insetPadding,
                  ),
                ),
                if (widget.labelBuilder != null) widget.labelBuilder!(value),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double insetPadding;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.insetPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - insetPadding;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: [color, color.withValues(alpha: 0.6), color],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
