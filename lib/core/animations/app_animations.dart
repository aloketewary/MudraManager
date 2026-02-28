import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);

  static const defaultCurve = Curves.easeOutCubic;
  static const bounceCurve = Curves.elasticOut;

  static Duration staggerDelay(int index, {int baseMs = 50}) {
    return Duration(milliseconds: baseMs * index);
  }
}

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int staggerMs;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    final delay = AppAnimations.staggerDelay(index, baseMs: staggerMs);
    return child.animate()
        .fadeIn(delay: delay, duration: AppAnimations.normal)
        .slideY(delay: delay, duration: AppAnimations.normal, begin: 0.1);
  }
}
