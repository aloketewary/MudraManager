import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';

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

  /// Currency code to display. Null = base currency.
  final String? currencyCode;

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
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final effectiveCode = currencyCode ?? BaseCurrency.code;
    final meta = kCurrencies[effectiveCode];
    final isBase = currencyCode == null;
    final sign = _getSign();

    // Format the number (no symbol — badge handles that)
    final String numberText;
    if (isBase && compact) {
      // Use Indian notation for base currency compact (L, Cr, K)
      final raw = ctxt.formatCompactCurrency(amount.abs(), fixedStringLength: fixedLength);
      numberText = _stripSymbol(raw);
    } else {
      final digits = fixedLength;
      final locale = ctxt.localeName == 'hi' ? 'hi_IN' : ctxt.localeName;
      final fmt = NumberFormat.currency(
        locale: locale,
        symbol: '',
        decimalDigits: digits,
      );
      numberText = fmt.format(amount.abs());
    }

    final displayText =
        '${prefixText != null ? '$prefixText ' : ''}$numberText${suffixText != null ? ' $suffixText' : ''}';

    return Tooltip(
      message: _buildTooltip(ctxt, effectiveCode, meta, sign),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (sign.isNotEmpty)
            Text(sign, style: style),
          CurrencyBadge.fromAmountStyle(
            code: effectiveCode,
            amountStyle: style,
          ),
          SizedBox(width: ((style?.fontSize ?? 14) * 0.12).clamp(2.0, 6.0)),
          Flexible(
            child: AdaptiveText(
              displayText,
              style: style,
              maxLines: maxLines,
              textAlign: textAlign,
              isNumeric: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Strip currency symbol prefix from formatted string.
  /// e.g. "₹5.2K" -> "5.2K", "SAR5.2K" -> "5.2K"
  String _stripSymbol(String formatted) {
    // Remove known symbol
    final symbol = BaseCurrency.symbol;
    if (formatted.startsWith(symbol)) {
      return formatted.substring(symbol.length);
    }
    // Remove any leading non-digit, non-dot, non-minus chars
    final match = RegExp(r'^[^\d.]*').firstMatch(formatted);
    if (match != null && match.group(0)!.isNotEmpty) {
      return formatted.substring(match.group(0)!.length);
    }
    return formatted;
  }

  /// Full uncompacted number with symbol/code — Google Pay style tooltip.
  /// Clean symbol: "₹12,34,567.00" | No clean symbol: "USD 1,234,567.00"
  String _buildTooltip(
    AppLocalizations ctxt,
    String code,
    CurrencyMeta? meta,
    String sign,
  ) {
    final digits = meta?.decimalDigits ?? 2;
    final locale = ctxt.localeName == 'hi' ? 'hi_IN' : ctxt.localeName;
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: digits,
    );
    final formatted = fmt.format(amount.abs());
    final hasClean = meta?.cleanSymbol ?? false;
    if (hasClean) return '$sign${meta!.symbol}$formatted';
    return '$sign$code $formatted';
  }

  String _getSign() {
    if (!showSign) return '';
    if (amount >= 0 && isExpense == false) {
      return showPositiveSign ? '+' : '';
    }
    return '-';
  }
}
