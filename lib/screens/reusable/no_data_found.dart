import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  final String message;
  final String imagePath;

  const NoDataFound({
    super.key,
    required this.message,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Image.asset(imagePath, width: 128),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
