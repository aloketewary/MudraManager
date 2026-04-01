import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HeroAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Color accentColor;
  final VoidCallback? onCalculatorTap;
  final List<int>? quickAmounts;

  const HeroAmountInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.accentColor,
    this.onCalculatorTap,
    this.quickAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor.withValues(alpha: 0.2),
              ),
              prefixText: '₹ ',
              prefixStyle: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              filled: false,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: onCalculatorTap != null
                  ? IconButton(
                      onPressed: onCalculatorTap,
                      icon: Icon(
                        LucideIcons.calculator,
                        color: accentColor.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    )
                  : null,
            ),
          ),
          if (quickAmounts != null && quickAmounts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: quickAmounts!.map((amt) {
                  return ActionChip(
                    label: Text(
                      '₹$amt',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => controller.text = amt.toString(),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: accentColor.withValues(alpha: 0.08),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
