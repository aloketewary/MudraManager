import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final periods = ['Today', 'Week', 'Month', 'Year'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(period),
              onSelected: (_) {
                HapticFeedback.mediumImpact();
                onChange(period);
              },
              backgroundColor: color.surface,
              selectedColor: color.primary,
              labelStyle: TextStyle(
                color: isSelected ? color.onPrimary : color.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              elevation: isSelected ? 4 : 0,
              shadowColor: color.shadow,
            ),
          );
        }).toList(),
      ),
    );
  }
}
