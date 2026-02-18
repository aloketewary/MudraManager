import 'package:flutter/material.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool showSign;
  final bool compact;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.maxLines,
    this.textAlign,
    this.showSign = false,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final displayText = compact
        ? '${showSign ? (amount >= 0 ? '+' : '-') : ''}${ctxt.formatCompactCurrency(amount.abs())}'
        : '${showSign ? (amount >= 0 ? '+' : '-') : ''}${ctxt.formatCurrencyWithSign(2, amount.abs())}';
    final fullText =
        '${showSign ? (amount >= 0 ? '+' : '-') : ''}${ctxt.formatCurrencyWithSign(2, amount.abs())}';

    return Tooltip(
      message: fullText,
      child: AdaptiveText(
        displayText,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        isNumeric: true,
      ),
    );
  }
}
