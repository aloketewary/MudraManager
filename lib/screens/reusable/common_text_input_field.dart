import 'package:flutter/material.dart';

class CommonTextInputField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(iconData),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          // fillColor: Colors.transparent,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: color.secondary
            )
          ),
        ),
        textInputAction: TextInputAction.next,
        keyboardType: inputType,
        validator: validateField,
      ),
    );
  }
}
