import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/localization_extension.dart';

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
    final ctxt = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        return Text(
          ctxt.formatLocalizedNumberWithSign(fixedStringLength, locale, animatedValue),
          style: style ?? Theme.of(context).textTheme.headlineMedium,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
