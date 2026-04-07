import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';

/// Compact vertical currency badge: symbol on top, 3-letter code below.
/// If no clean symbol exists, shows a generic coin icon instead.
///
/// Single source of truth for currency visual identity across the app.
class CurrencyBadge extends StatelessWidget {
  final String code;
  final double size;
  final Color? color;

  const CurrencyBadge({
    super.key,
    required this.code,
    this.size = 14,
    this.color,
  });

  factory CurrencyBadge.fromAmountStyle({
    Key? key,
    required String code,
    required TextStyle? amountStyle,
    Color? color,
  }) {
    return CurrencyBadge(
      key: key,
      code: code,
      size: amountStyle?.fontSize ?? 14,
      color: color ?? amountStyle?.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = kCurrencies[code];
    final hasCleanSymbol = meta?.cleanSymbol ?? false;
    final baseColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    final symbolColor = baseColor;
    final codeColor = baseColor.withValues(alpha: 0.7);

    final symbolSize = (size * 0.52).clamp(7.0, 28.0);
    final codeSize = (size * 0.28).clamp(5.0, 13.0);
    final iconSize = (size * 0.42).clamp(6.0, 22.0);

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
