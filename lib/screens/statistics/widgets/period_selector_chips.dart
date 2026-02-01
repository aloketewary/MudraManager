import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/theme/app_colors.dart';

class PeriodSelectorChips extends StatelessWidget {
  final String selected;
  final Function(String) onChange;

  const PeriodSelectorChips({
    super.key,
    required this.selected,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final periods = ['Today', 'Week', 'Month', 'Year'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onChange(period);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                child: Text(
                  period.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: isSelected ? color.primary : color.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
