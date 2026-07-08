import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetAmountInput extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefix: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CurrencyBadge(code: BaseCurrency.code, size: 16),
        ),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
      ),
    );
  }
}
