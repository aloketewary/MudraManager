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
  final bool? isExpense;
  final int fixedLength;
  final String? suffixText;
  final String? prefixText;
  final bool showPositiveSign;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.maxLines,
    this.textAlign,
    this.showSign = false,
    this.compact = true,
    this.isExpense = false,
    this.fixedLength = 2,
    this.suffixText,
    this.prefixText,
    this.showPositiveSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final displayText = compact
        ? '${_getSign()}${ctxt.formatCompactCurrency(amount.abs(), fixedStringLength: fixedLength)}'
        : '${_getSign()}${ctxt.formatCurrencyWithSign(fixedLength, amount.abs())}';
    final fullText =
        '${_getSign()}${ctxt.formatCurrencyWithSign(fixedLength, amount.abs())}';

    return Tooltip(
      message: fullText,
      child: AdaptiveText(
        '${prefixText != null ? '$prefixText ' : ''}$displayText${suffixText != null ? ' $suffixText' : ''}',
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        isNumeric: true,
      ),
    );
  }

  String _getSign() {
    String sign = '';
    if (showSign) {
      if (amount >= 0 && isExpense == false) {
        sign = showPositiveSign ? '+' : '';
      } else {
        sign = '-';
      }
    }
    return sign;
  }
}
