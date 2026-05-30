import 'package:flutter/material.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';

/// A drop-in Text replacement that auto-decrypts any ENC: prefixed string.
/// Use this anywhere user-facing encrypted fields (name, email, etc.) are shown.
class SafeText extends StatelessWidget {
  final String? text;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SafeText(
    this.text, {
    super.key,
    this.fallback = '',
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      FieldEncryptionService.safeDisplay(text, fallback),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// String extension for inline safe decryption.
extension SafeDecrypt on String? {
  /// Returns decrypted value if encrypted, otherwise returns self or fallback.
  String safe([String fallback = '']) =>
      FieldEncryptionService.safeDisplay(this, fallback);
}

/// Non-nullable variant so `.safe()` works on `String` too.
extension SafeDecryptNonNull on String {
  String safe([String fallback = '']) =>
      FieldEncryptionService.safeDisplay(this, fallback);
}
