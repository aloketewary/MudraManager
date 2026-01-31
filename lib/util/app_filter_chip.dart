import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.width = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(right: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: isSelected ? color.primary : Colors.transparent,
          border: Border.all(color: color.primary),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: isSelected ? color.onPrimary : color.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}