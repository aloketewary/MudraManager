import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class AnimatedBalance extends ConsumerWidget {
  final double value;
  final TextStyle? style;
  final TextOverflow? overflow;
  final Duration duration;
  final int fixedStringLength;
  final TextAlign textAlign;
  final String? suffix;
  final String? prefix;
  final bool compact;
  final String? currencyCode;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.overflow,
    this.fixedStringLength = 2,
    this.textAlign = TextAlign.left,
    this.suffix,
    this.prefix,
    this.compact = true,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(balanceVisibilityProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        return CurrencyText(
          amount: animatedValue,
          currencyCode: currencyCode,
          style: style ?? Theme.of(context).textTheme.headlineMedium,
          textAlign: textAlign,
          compact: compact,
          fixedLength: fixedStringLength,
          prefixText: prefix,
          suffixText: suffix,
          showSign: true,
          showPositiveSign: false,
        );
      },
    );
  }
}
