import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInput extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

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
              tooltip: 'Calculator',
                icon: const Icon(LucideIcons.calculator),
                onPressed: onCalculatorTap,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
      ),
    );
  }
}
