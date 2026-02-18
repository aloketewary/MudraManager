import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;

  const BudgetAmountInput({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
