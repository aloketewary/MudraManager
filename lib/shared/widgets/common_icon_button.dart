import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CommonIconPickerButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final String label;
  final Color? textColor;
  final Color? iconBackGroundColor;
  final IconData? selectedIcon;

  const CommonIconPickerButton({
    super.key,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    required this.label,
    this.textColor,
    this.selectedIcon = LucideIcons.plus,
    this.iconBackGroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

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
          padding: const EdgeInsets.all(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(color: textColor),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: iconBackGroundColor ?? color.primary,
              child: Icon(selectedIcon, color: color.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
