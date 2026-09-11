import 'package:flutter/material.dart';
import 'package:mudra_manager/shared/widgets/amount_glow.dart';
import 'package:mudra_manager/shared/widgets/animated_balance.dart';

/// Shared animated money display. Glow is opt-in for the single hero amount.
class FinanceAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String? currencyCode;
  final Duration duration;
  final int fixedStringLength;
  final bool compact;
  final bool glow;
  final Color? glowColor;
  final String? prefix;
  final String? suffix;
  final TextOverflow? overflow;

  const FinanceAmount({
    super.key,
    required this.value,
    this.style,
    this.currencyCode,
    this.duration = const Duration(milliseconds: 500),
    this.fixedStringLength = 0,
    this.compact = false,
    this.glow = false,
    this.glowColor,
    this.prefix,
    this.suffix,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : this.duration;
    final amount = AnimatedBalance(
      value: value,
      currencyCode: currencyCode,
      style: style,
      duration: duration,
      fixedStringLength: fixedStringLength,
      compact: compact,
      prefix: prefix,
      suffix: suffix,
      overflow: overflow,
    );

    if (!glow) return amount;

    return AmountGlow(
      color: glowColor ?? Theme.of(context).colorScheme.primary,
      child: amount,
    );
  }
}
