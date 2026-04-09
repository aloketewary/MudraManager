import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

/// Currency symbol badge.
///
/// Default: symbol only (₹, $, €). Clean and compact.
/// [showCode]: adds 3-letter code below for multi-currency contexts.
/// For non-clean symbols (AED, CHF), always shows code as the symbol.
class CurrencyBadge extends StatelessWidget {
  final String code;
  final double size;
  final Color? color;
  final bool showCode;

  const CurrencyBadge({
    super.key,
    required this.code,
    this.size = 14,
    this.color,
    this.showCode = false,
  });

  factory CurrencyBadge.fromAmountStyle({
    Key? key,
    required String code,
    required TextStyle? amountStyle,
    Color? color,
    bool showCode = false,
  }) {
    return CurrencyBadge(
      key: key,
      code: code,
      size: amountStyle?.fontSize ?? 14,
      color: color ?? amountStyle?.color,
      showCode: showCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = kCurrencies[code];
    final hasCleanSymbol = meta?.cleanSymbol ?? false;
    final baseColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    final symbolColor = baseColor;
    final symbolSize = (size * 0.52).clamp(7.0, 28.0);
    final iconSize = (size * 0.42).clamp(6.0, 22.0);

    if (!showCode) {
      // Symbol only — clean inline display
      if (hasCleanSymbol) {
        return Text(
          meta!.symbol,
          style: TextStyle(
            fontSize: symbolSize,
            fontWeight: FontWeight.w700,
            color: symbolColor,
            height: 1.0,
          ),
        );
      }
      // Non-clean symbol: show code as text (AED, CHF)
      return Text(
        code,
        style: TextStyle(
          fontSize: (size * 0.36).clamp(6.0, 16.0),
          fontWeight: FontWeight.w600,
          color: symbolColor,
          height: 1.0,
          letterSpacing: 0.2,
        ),
      );
    }

    // showCode: stacked symbol + code (for multi-currency / input contexts)
    final codeColor = baseColor.withValues(alpha: 0.7);
    final codeSize = (size * 0.28).clamp(5.0, 13.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCleanSymbol)
          Text(
            meta!.symbol,
            style: TextStyle(
              fontSize: symbolSize,
              fontWeight: FontWeight.w700,
              color: symbolColor,
              height: 1.0,
            ),
          )
        else
          Icon(
            LucideIcons.circle,
            size: iconSize,
            color: symbolColor,
          ),
        Text(
          code,
          style: TextStyle(
            fontSize: codeSize,
            fontWeight: FontWeight.w600,
            color: codeColor,
            height: 1.0,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
