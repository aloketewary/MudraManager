import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/util/localization_extension.dart';

class AnimatedBalance extends ConsumerWidget {
  final double value;
  final TextStyle? style;
  final TextOverflow? overflow;
  final Duration duration;
  final int fixedStringLength;
  final TextAlign textAlign;
  final String? suffix;
  final String? prefix;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;
    final showBalance = ref.watch(balanceVisibilityProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, _) {
        final formattedValue = ctxt.formatCurrencyWithSign(
          fixedStringLength,
          animatedValue,
        );
        return Text(
          '${prefix ?? ""}$formattedValue${suffix ?? ""}',
          style: style ?? Theme.of(context).textTheme.headlineMedium,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
