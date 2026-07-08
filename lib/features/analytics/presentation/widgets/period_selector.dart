import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/shared/widgets/period_calendar_selector.dart'
    show PeriodType;

class PeriodSelector extends ConsumerWidget {
  final DateTime selectedDate;
  final PeriodType periodType;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final Function(PeriodType) onPeriodTypeChanged;

  const PeriodSelector({
    super.key,
    required this.selectedDate,
    required this.periodType,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPeriodTypeChanged,
  });

  String _getDateText() {
    switch (periodType) {
      case PeriodType.day:
        return DateFormat.MMMd().format(selectedDate);
      case PeriodType.week:
        final startOfWeek = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}';
      case PeriodType.month:
        return DateFormat.yMMMM().format(selectedDate);
      case PeriodType.year:
        return DateFormat.y().format(selectedDate);
      case PeriodType.custom:
        return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous',
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () {
              HapticFeedback.lightImpact();
              onPrevious();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _getDateText(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SegmentedButton<PeriodType>(
                  segments: const [
                    ButtonSegment(
                      value: PeriodType.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(value: PeriodType.year, label: Text('Year')),
                  ],
                  selected: {periodType},
                  onSelectionChanged: (Set<PeriodType> selected) {
                    HapticFeedback.mediumImpact();
                    onPeriodTypeChanged(selected.first);
                  },
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next',
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: () {
              HapticFeedback.lightImpact();
              onNext();
            },
          ),
        ],
      ),
    );
  }
}
