import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final showBalance = ref.watch(balanceVisibilityProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        final formattedValue = compact
            ? ctxt.formatCompactCurrency(animatedValue)
            : ctxt.formatCurrencyWithSign(fixedStringLength, animatedValue);
        final fullValue = ctxt.formatCurrencyWithSign(
          fixedStringLength,
          animatedValue,
        );

        return Tooltip(
          message: fullValue,
          child: AdaptiveText(
            '${prefix ?? ""}$formattedValue${suffix ?? ""}',
            style: style ?? Theme.of(context).textTheme.headlineMedium,
            textAlign: textAlign,
            isNumeric: true,
          ),
        );
      },
    );
  }
}
