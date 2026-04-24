import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final bool showCalendar;
  final bool useInfiniteScroll;
  final VoidCallback onToggleCalendar;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onResetToday;
  final VoidCallback onToggleView;
  final bool canGoNext;

  const DateRangeSelector({
    super.key,
    required this.selectedDate,
    this.filterStartDate,
    this.filterEndDate,
    required this.showCalendar,
    required this.useInfiniteScroll,
    required this.onToggleCalendar,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onResetToday,
    required this.onToggleView,
    required this.canGoNext,
  });

  String _getDateRangeText() {
    if (filterStartDate != null && filterEndDate != null) {
      return '${DateFormat.MMMd().format(filterStartDate!)} - ${DateFormat.MMMd().format(filterEndDate!)}';
    }
    return DateFormat.yMMMM().format(selectedDate);
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onToggleCalendar();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.calendar,
                    color: color.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        useInfiniteScroll && filterStartDate == null
                            ? 'All Transactions'
                            : _getDateRangeText(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      Text(
                        useInfiniteScroll && filterStartDate == null
                            ? 'Scroll to load more'
                            : 'Tap to change',
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!useInfiniteScroll || filterStartDate != null) ...[
                        IconButton(
                          tooltip: 'Previous',
                          icon: const Icon(LucideIcons.chevronLeft, size: 22),
                          onPressed: onPreviousMonth,
                        ),
                        if (!_isSameMonth(selectedDate, DateTime.now()))
                          IconButton(
                            tooltip: 'Refresh',
                            icon: Icon(LucideIcons.refreshCw, size: 20, color: color.primary),
                            onPressed: onResetToday,
                          ),
                        IconButton(
                          tooltip: 'Next',
                          icon: const Icon(LucideIcons.chevronRight, size: 22),
                          onPressed: canGoNext ? onNextMonth : null,
                        ),
                      ],
                      IconButton(
                        tooltip: 'List',
                        icon: Icon(
                          useInfiniteScroll && filterStartDate == null
                              ? LucideIcons.list
                              : LucideIcons.infinity,
                          size: 20,
                          color: color.primary,
                        ),
                        onPressed: onToggleView,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  showCalendar
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  color: color.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
