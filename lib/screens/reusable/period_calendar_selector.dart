import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

enum PeriodType { day, week, month, year, custom }

class PeriodCalendarSelector extends StatefulWidget {
  final PeriodType selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;
  final Function(PeriodType period, DateTime? start, DateTime? end) onChanged;

  const PeriodCalendarSelector({
    super.key,
    required this.selectedPeriod,
    this.customStart,
    this.customEnd,
    required this.onChanged,
  });

  @override
  State<PeriodCalendarSelector> createState() => _PeriodCalendarSelectorState();
}

class _PeriodCalendarSelectorState extends State<PeriodCalendarSelector> {
  bool _showCalendar = false;
  bool _isSelectingCustom = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.customStart;
    _rangeEnd = widget.customEnd;
  }

  @override
  void didUpdateWidget(PeriodCalendarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customStart != oldWidget.customStart || widget.customEnd != oldWidget.customEnd) {
      _rangeStart = widget.customStart;
      _rangeEnd = widget.customEnd;
    }
  }

  String _getPeriodText() {
    final now = DateTime.now();
    switch (widget.selectedPeriod) {
      case PeriodType.day:
        return DateFormat.MMMd().format(now);
      case PeriodType.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(Duration(days: 6));
        return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}';
      case PeriodType.month:
        return DateFormat.yMMMM().format(now);
      case PeriodType.year:
        return DateFormat.y().format(now);
      case PeriodType.custom:
        if (widget.customStart != null && widget.customEnd != null) {
          return '${DateFormat.MMMd().format(widget.customStart!)} - ${DateFormat.MMMd().format(widget.customEnd!)}';
        }
        return 'Select Range';
    }
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
          color: color.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _showCalendar = !_showCalendar);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: color.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getPeriodText(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _showCalendar
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: color.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showCalendar) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip(PeriodType.day, 'Day', Icons.today_rounded),
                  _buildPeriodChip(PeriodType.week, 'Week', Icons.view_week_rounded),
                  _buildPeriodChip(PeriodType.month, 'Month', Icons.calendar_view_month_rounded),
                  _buildPeriodChip(PeriodType.year, 'Year', Icons.calendar_view_day_rounded),
                  _buildPeriodChip(PeriodType.custom, 'Custom', Icons.date_range_rounded),
                ],
              ),
            ),
            if (widget.selectedPeriod == PeriodType.custom || _isSelectingCustom)
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  selectedDayPredicate: (day) => false,
                  onRangeSelected: (start, end, focusedDay) {
                    setState(() {
                      _rangeStart = start;
                      _rangeEnd = end;
                      _focusedDay = focusedDay;
                    });
                    if (start != null && end != null) {
                      HapticFeedback.lightImpact();
                      widget.onChanged(PeriodType.custom, start, end);
                      setState(() => _showCalendar = false);
                    }
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                  enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    rangeStartDecoration: BoxDecoration(
                      color: color.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: color.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeHighlightColor: color.primaryContainer.withOpacity(0.3),
                    todayTextStyle: TextStyle(color: color.onSurface),
                    rangeStartTextStyle: TextStyle(color: color.onPrimary),
                    rangeEndTextStyle: TextStyle(color: color.onPrimary),
                    disabledTextStyle: TextStyle(color: color.onSurface.withOpacity(0.3)),
                    weekendTextStyle: TextStyle(color: color.onSurface),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(PeriodType period, String label, IconData icon) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = widget.selectedPeriod == period || (period == PeriodType.custom && _isSelectingCustom);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (period == PeriodType.custom) {
            setState(() => _isSelectingCustom = true);
          } else {
            setState(() => _isSelectingCustom = false);
            widget.onChanged(period, null, null);
            setState(() => _showCalendar = false);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.primaryContainer : color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color.primary : color.onSurface,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? color.primary : color.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
