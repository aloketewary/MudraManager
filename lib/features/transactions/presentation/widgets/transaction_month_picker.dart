import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransactionMonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthSelected;

  const TransactionMonthPicker({
    super.key,
    required this.selectedDate,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthDate = DateTime(selectedDate.year, month, 1);
                  final isSelected = selectedDate.month == month;
                  final isFuture = monthDate.isAfter(DateTime.now());

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isFuture
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              onMonthSelected(DateTime(selectedDate.year, month, 1));
                            },
                      borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.primaryContainer
                              : color.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Tone.current.borderRadius),
                          border: Border.all(
                            color: isSelected ? color.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat.MMM().format(DateTime(2000, month)),
                          style: textTheme.titleSmall?.copyWith(
                            color: isFuture
                                ? color.onSurface.withValues(alpha: 0.3)
                                : isSelected
                                    ? color.primary
                                    : color.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _YearSelector(
                selectedDate: selectedDate,
                onYearChanged: (year) {
                  onMonthSelected(DateTime(year, selectedDate.month, 1));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<int> onYearChanged;

  const _YearSelector({
    required this.selectedDate,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onYearChanged(selectedDate.year - 1);
            },
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            label: Text('${selectedDate.year - 1}'),
            style: TextButton.styleFrom(foregroundColor: color.onSurface),
          ),
          Text(
            '${selectedDate.year}',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.primary,
            ),
          ),
          TextButton.icon(
            onPressed: selectedDate.year >= DateTime.now().year
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onYearChanged(selectedDate.year + 1);
                  },
            icon: const Icon(LucideIcons.chevronRight, size: 18),
            label: Text('${selectedDate.year + 1}'),
            style: TextButton.styleFrom(
              foregroundColor: selectedDate.year >= DateTime.now().year
                  ? color.onSurface.withValues(alpha: 0.3)
                  : color.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
