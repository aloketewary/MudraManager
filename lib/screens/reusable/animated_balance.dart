import 'package:flutter/material.dart';

class AnimatedBalance extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final TextOverflow? overflow;
  final Duration duration;
  final int fixedStringLength;
  final TextAlign textAlign;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.overflow,
    this.fixedStringLength = 2,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        var isNegative = animatedValue < 0;
        return Text(
          "${isNegative ? "-" : ""} ₹${animatedValue.abs().toStringAsFixed(fixedStringLength)}",
          style: style ?? Theme.of(context).textTheme.headlineMedium,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
