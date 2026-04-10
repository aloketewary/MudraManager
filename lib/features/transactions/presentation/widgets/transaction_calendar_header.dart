import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransactionCalendarHeader extends StatelessWidget {
  final bool useInfiniteScroll;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final DateTime selectedDate;
  final bool showCalendar;
  final bool showMonthPicker;
  final VoidCallback onToggleCalendar;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onResetMonth;
  final VoidCallback onToggleMonthPicker;
  final VoidCallback onToggleViewMode;

  const TransactionCalendarHeader({
    super.key,
    required this.useInfiniteScroll,
    this.filterStartDate,
    this.filterEndDate,
    required this.selectedDate,
    required this.showCalendar,
    required this.showMonthPicker,
    required this.onToggleCalendar,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onResetMonth,
    required this.onToggleMonthPicker,
    required this.onToggleViewMode,
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

    return Material(
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
                child: Icon(LucideIcons.calendar, color: color.primary, size: 20),
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
                    if (useInfiniteScroll && filterStartDate == null)
                      Text(
                        'Scroll to load more',
                        style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
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
                        icon: const Icon(LucideIcons.chevronLeft, size: 22),
                        tooltip: 'Previous Month',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onPreviousMonth();
                        },
                      ),
                      if (!_isSameMonth(selectedDate, DateTime.now()))
                        IconButton(
                          icon: Icon(LucideIcons.refreshCw, size: 20, color: color.primary),
                          tooltip: 'Reset to Current Month',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onResetMonth();
                          },
                        )
                      else
                        IconButton(
                          icon: Icon(LucideIcons.calendar, size: 20, color: color.primary),
                          tooltip: 'Select Month',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onToggleMonthPicker();
                          },
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 22),
                        tooltip: 'Next Month',
                        onPressed: _isSameMonth(selectedDate, DateTime.now())
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                onNextMonth();
                              },
                      ),
                    ],
                    IconButton(
                      icon: Icon(
                        useInfiniteScroll && filterStartDate == null
                            ? LucideIcons.list
                            : LucideIcons.infinity,
                        size: 20,
                        color: color.primary,
                      ),
                      tooltip: useInfiniteScroll ? 'Month View' : 'All Transactions',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onToggleViewMode();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                showCalendar || showMonthPicker
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
