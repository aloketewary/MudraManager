import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double? minFontSize;
  final double? maxFontSize;
  final bool isNumeric;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.minFontSize = 12,
    this.maxFontSize,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxFontSize = maxFontSize ?? (style?.fontSize ?? 14);
    final effectiveMinFontSize = minFontSize ?? 12;
    
    // For numeric content, use clip instead of ellipsis to preserve precision
    final effectiveOverflow = isNumeric ? TextOverflow.clip : (overflow ?? TextOverflow.ellipsis);
    
    return AutoSizeText(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: effectiveOverflow,
      minFontSize: effectiveMinFontSize > effectiveMaxFontSize ? effectiveMaxFontSize : effectiveMinFontSize,
      maxFontSize: effectiveMaxFontSize,
    );
  }
}
