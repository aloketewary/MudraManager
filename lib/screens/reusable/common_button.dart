import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backGroundColor;
  final Color? textColor;
  final IconData? iconData;
  final TextStyle? textStyle;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backGroundColor,
    this.iconData,
    this.textColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconData != null) Icon(iconData, color: Colors.white, size: 24),
          if (iconData != null) SizedBox(width: 12),
          Text(text.toUpperCase()),
        ],
      ),
    );
  }
}
