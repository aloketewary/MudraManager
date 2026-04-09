import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback? onCalculatorTap;

  const AmountInput({
    super.key,
    required this.controller,
    this.errorText,
    this.onCalculatorTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color.primary,
      ),
      decoration: InputDecoration(
        prefix: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CurrencyBadge(code: BaseCurrency.code, size: 16),
        ),
        prefixStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color.primary,
        ),
        hintText: '0.00',
        errorText: errorText,
        suffixIcon: onCalculatorTap != null
            ? IconButton(
                icon: const Icon(LucideIcons.calculator),
                onPressed: onCalculatorTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
