import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CommonColorPickerButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final String label;
  final Color? textColor;

  const CommonColorPickerButton({
    super.key,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    
    // Calculate proper text color based on background color brightness
    final bgLuminance = (backgroundColor ?? Colors.blue).computeLuminance();
    final calculatedTextColor = textColor ?? (bgLuminance > 0.5 ? Colors.black : Colors.white);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              spacing.radiusMedium,
            ), // Adjust the radius for more or less rounding
          ),
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(16),
        ),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(color: calculatedTextColor),
        ),
      ),
    );
  }
}
