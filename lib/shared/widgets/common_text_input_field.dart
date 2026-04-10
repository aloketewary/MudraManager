import 'package:flutter/material.dart';

class CommonTextInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? iconData;
  final TextInputType inputType;
  final FormFieldValidator<String>? validateField;
  final ValueChanged<String>? onChanged;

  const CommonTextInputField({
    super.key,
    this.controller,
    this.labelText = '',
    this.iconData,
    this.inputType = TextInputType.text,
    this.hintText,
    this.validateField,
    this.onChanged,
  });

  @override
  State<CommonTextInputField> createState() => _CommonTextInputFieldState();
}

class _CommonTextInputFieldState extends State<CommonTextInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: color.primary.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(
              widget.iconData,
              color: _isFocused ? color.primary : color.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color.primary, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color.outline, width: 1.0),
            ),
          ),
          textInputAction: TextInputAction.next,
          keyboardType: widget.inputType,
          validator: widget.validateField,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
