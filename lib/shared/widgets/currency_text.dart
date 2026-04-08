import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

/// Displays a currency amount: `₹12.5K`, `$1,234`, `AED 367`
///
/// Symbol is slightly muted, number is bold.
/// Long-press tooltip shows full uncompacted value.
///
/// Rules:
/// - Never shows both symbol + code (symbol only by default)
/// - Compact mode: <10K full, 10K-99.9K → K, 1L-99L → L, 1Cr+ → Cr
/// - Non-compact: locale-grouped full number
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

  /// Show currency code alongside symbol (for multi-currency screens).
  final bool showCode;

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
    this.showCode = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final effectiveCode = currencyCode ?? BaseCurrency.code;
    final meta = kCurrencies[effectiveCode];
    final isBase = currencyCode == null;
    final sign = _getSign();

    // Format the number
    final String numberText;
    if (isBase && compact) {
      numberText = _formatCompact(ctxt, amount.abs(), fixedLength);
    } else {
      final locale = ctxt.localeName == 'hi' ? 'hi_IN' : ctxt.localeName;
      final fmt = NumberFormat.currency(
        locale: locale,
        symbol: '',
        decimalDigits: fixedLength,
      );
      numberText = fmt.format(amount.abs());
    }

    // Build symbol prefix
    final symbolText = _symbolPrefix(meta, effectiveCode);

    final displayText =
        '${prefixText != null ? '$prefixText ' : ''}$numberText${suffixText != null ? ' $suffixText' : ''}';

    // Style: symbol slightly muted, number inherits full style
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final symbolStyle = effectiveStyle.copyWith(
      color: (effectiveStyle.color ?? Theme.of(context).colorScheme.onSurface)
          .withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    );

    return Tooltip(
      message: _buildTooltip(ctxt, effectiveCode, meta, sign),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (sign.isNotEmpty)
            Text(sign, style: effectiveStyle),
          Text(symbolText, style: symbolStyle),
          if (showCode && (meta?.cleanSymbol ?? false))
            Text(
              ' ',
              style: symbolStyle.copyWith(fontSize: (effectiveStyle.fontSize ?? 14) * 0.3),
            ),
          if (showCode && (meta?.cleanSymbol ?? false))
            Text(
              effectiveCode,
              style: symbolStyle.copyWith(
                fontSize: (effectiveStyle.fontSize ?? 14) * 0.6,
                letterSpacing: 0.3,
              ),
            ),
          Flexible(
            child: AdaptiveText(
              displayText,
              style: effectiveStyle,
              maxLines: maxLines,
              textAlign: textAlign,
              isNumeric: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the symbol prefix string.
  /// Clean symbol: "₹", "$", "€" (no space)
  /// Non-clean: "AED " (code + space)
  String _symbolPrefix(CurrencyMeta? meta, String code) {
    if (meta?.cleanSymbol ?? false) return meta!.symbol;
    return '$code ';
  }

  /// Compact formatting: Indian notation for base currency.
  /// <10K → full grouped number
  /// 10K–99.9K → 12.5K
  /// 1L–99.9L → 2.3L
  /// 1Cr+ → 1.2Cr
  String _formatCompact(AppLocalizations ctxt, double value, int decimals) {
    if (value.abs() >= 10000000) {
      return '${_trimTrailing((value / 10000000).toStringAsFixed(decimals))}${ctxt.currency_crore_short}';
    } else if (value.abs() >= 100000) {
      return '${_trimTrailing((value / 100000).toStringAsFixed(decimals))}${ctxt.currency_lakh_short}';
    } else if (value.abs() >= 10000) {
      return '${_trimTrailing((value / 1000).toStringAsFixed(decimals))}${ctxt.currency_thousand_short}';
    }
    // Below 10K: full grouped number
    final locale = ctxt.localeName == 'hi' ? 'hi_IN' : ctxt.localeName;
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 0,
    );
    return fmt.format(value);
  }

  /// Remove trailing zeros: "12.50" → "12.5", "12.0" → "12", "12" → "12"
  String _trimTrailing(String value) {
    if (!value.contains('.')) return value;
    var trimmed = value.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.endsWith('.')) trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  /// Full uncompacted number — shown on long-press tooltip.
  /// Clean symbol: "₹12,34,567" | Non-clean: "AED 1,234,567"
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
