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
    final textTheme = Theme.of(context).textTheme;
    final periods = ['Today', 'Week', 'Month', 'Year'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period.toUpperCase()),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.mediumImpact();
                onChange(period);
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
        }).toList(),
      ),
    );
  }
}
