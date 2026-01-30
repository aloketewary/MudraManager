import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class CommonIconPickerButton extends StatelessWidget {
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
    this.selectedIcon = Icons.add,
    this.iconBackGroundColor,
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
          padding: const EdgeInsets.all(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(color: textColor),
            ),
            SizedBox(width: 12),
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
