import 'package:flutter/material.dart';

/// Glass-styled text field with semi-transparent surface.
///
/// Features:
/// - 16px border radius
/// - Semi-transparent fill (alpha 0.6-0.7)
/// - Subtle border matching outline variant
///
/// Usage:
/// ```dart
/// GlassTextField(
///   controller: _controller,
///   focusNode: _focusNode,
///   decoration: InputDecoration(labelText: 'Name'),
///   textTheme: Theme.of(context).textTheme,
///   validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextTheme textTheme;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;

  const GlassTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.decoration,
    required this.textTheme,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: decoration,
        style: textTheme.bodyLarge,
        validator: validator,
      ),
    );
  }
}