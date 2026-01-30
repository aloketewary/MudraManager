import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class CommonColorPickerButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ), // Adjust the radius for more or less rounding
          ),
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(16),
        ),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }
}
