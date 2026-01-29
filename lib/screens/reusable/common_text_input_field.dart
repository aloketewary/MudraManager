import 'package:flutter/material.dart';
import 'package:mudra_manager/theme/design_tokens.dart';

class CommonTextInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? iconData;
  final TextInputType inputType;
  final FormFieldValidator<String>? validateField;

  const CommonTextInputField({
    super.key,
    this.controller,
    this.labelText = '',
    this.iconData,
    this.inputType = TextInputType.text,
    this.hintText,
    this.validateField,
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
    var color = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing8),
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusMedium,
          boxShadow: _isFocused 
            ? AppElevation.elevation1(color.primary)
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
              borderRadius: DesignTokens.borderRadiusMedium,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignTokens.borderRadiusMedium,
              borderSide: BorderSide(
                color: color.primary,
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignTokens.borderRadiusMedium,
              borderSide: BorderSide(
                color: color.outline,
                width: 1.0,
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
          keyboardType: widget.inputType,
          validator: widget.validateField,
        ),
      ),
    );
  }
}
