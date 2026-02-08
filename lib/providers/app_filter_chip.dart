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

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: FilterChip(
        label: Text(label.toUpperCase()),
        selected: isSelected,
        onSelected: (_) {
          HapticFeedback.mediumImpact();
          onTap();
        },
        backgroundColor: color.surfaceContainerHighest,
        selectedColor: color.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? color.onPrimaryContainer : color.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        showCheckmark: false,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}