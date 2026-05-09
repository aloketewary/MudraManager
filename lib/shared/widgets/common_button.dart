import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';

class CommonButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backGroundColor;
  final Color? textColor;
  final IconData? iconData;
  final TextStyle? textStyle;
  final bool isOutlined;
  final double? width;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backGroundColor,
    this.iconData,
    this.textColor,
    this.textStyle,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    final buttonColor = backGroundColor ?? color.primary;
    final contentColor =
        textColor ?? (isOutlined ? buttonColor : color.onPrimary);

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: contentColor,
            side: BorderSide(color: buttonColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconData != null) ...[
                Icon(iconData, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: textStyle ??
                    textTheme.labelLarge?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: contentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: textStyle ??
                  textTheme.labelLarge?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
