import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CommonIconPickerButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final String label;
  final Color? textColor;
  final Color? iconBackGroundColor;
  final IconData? selectedIcon;
  final String? tooltip;

  const CommonIconPickerButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    required this.label,
    this.textColor,
    this.selectedIcon = LucideIcons.plus,
    this.iconBackGroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    final effectiveBgColor = backgroundColor ?? color.primary;
    final effectiveTextColor = textColor ?? color.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: tooltip ?? label,
        child: FilledButton(
          onPressed: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: spacing.borderRadiusMedium,
            ),
            backgroundColor: effectiveBgColor,
            foregroundColor: effectiveTextColor,
            padding: const EdgeInsets.all(10),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: textTheme.titleMedium?.copyWith(color: effectiveTextColor),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: iconBackGroundColor ?? color.primaryContainer,
                child: Icon(
                  selectedIcon,
                  color: color.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
