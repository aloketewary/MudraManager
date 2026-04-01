import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TypeToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;
  final String expenseLabel;
  final String incomeLabel;

  const TypeToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
    this.expenseLabel = 'Expense',
    this.incomeLabel = 'Income',
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOption(
              label: expenseLabel,
              icon: LucideIcons.circleMinus,
              isSelected: isExpense,
              selectedColor: color.error,
              color: color,
              textTheme: textTheme,
              onTap: () {
                HapticFeedback.mediumImpact();
                onChanged(true);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildOption(
              label: incomeLabel,
              icon: LucideIcons.circlePlus,
              isSelected: !isExpense,
              selectedColor: color.primary,
              color: color,
              textTheme: textTheme,
              onTap: () {
                HapticFeedback.mediumImpact();
                onChanged(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required ColorScheme color,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? selectedColor
                  : color.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? selectedColor
                    : color.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
