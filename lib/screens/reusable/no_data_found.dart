import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  final String message;
  final String? imagePath;
  final IconData? iconData;
  final Widget? action;

  const NoDataFound({
    super.key,
    required this.message,
    this.imagePath,
    this.iconData,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    assert(imagePath != null || iconData != null);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child:
                imagePath != null
                    ? Image.asset(imagePath!, width: 128)
                    : Icon(iconData, size: 128, color: color.primary),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: color.primary),
            ),
          ),
          if (action != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: action!,
            ),
        ],
      ),
    );
  }
}
