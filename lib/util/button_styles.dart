import 'package:flutter/material.dart';

class AppButtonStyles {
  static ButtonStyle primaryButton(ColorScheme color) {
    return FilledButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      minimumSize: Size(double.infinity, 52),
    );
  }

  static ButtonStyle secondaryButton(ColorScheme color) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: color.outline),
      minimumSize: Size(double.infinity, 52),
    );
  }

  static ButtonStyle coloredButton(Color backgroundColor, Color foregroundColor) {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      minimumSize: Size(double.infinity, 52),
    );
  }

  static ButtonStyle textButton(ColorScheme color) {
    return TextButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: Size(double.infinity, 52),
    );
  }
}
