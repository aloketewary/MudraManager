import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(right: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: isSelected
              ? LinearGradient(
                  colors: AppColors.glassGradient(color.primary, isDark),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : color.surface,
          border: Border.all(
            color: isSelected ? color.primary.withValues(alpha: 0.3) : color.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? AppColors.glassShadow(color.primary, isDark) : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: isSelected ? color.primary : color.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}