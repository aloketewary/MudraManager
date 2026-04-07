import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:table_calendar/table_calendar.dart';

enum PeriodType { day, week, month, year, custom }

class PeriodCalendarSelector extends StatefulWidget {
  final PeriodType selectedPeriod;
  final DateTime? customStart;
  final DateTime? customEnd;
  final Function(PeriodType period, DateTime? start, DateTime? end) onChanged;
  final AppSpacing spacing;

  const PeriodCalendarSelector({
    super.key,
    required this.selectedPeriod,
    this.customStart,
    this.customEnd,
    required this.onChanged,
    required this.spacing,
  });

  @override
  State<PeriodCalendarSelector> createState() => _PeriodCalendarSelectorState();
}

class _PeriodCalendarSelectorState extends State<PeriodCalendarSelector> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  AppSpacing get spacing => widget.spacing;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.customStart;
    _rangeEnd = widget.customEnd;
  }

  @override
  void didUpdateWidget(PeriodCalendarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customStart != oldWidget.customStart ||
        widget.customEnd != oldWidget.customEnd) {
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
        final end = start.add(const Duration(days: 6));
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showPeriodSelector(context);
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: EdgeInsets.all(spacing.cardInner),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.elementGap),
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: color.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: spacing.elementGap),
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
                Icons.keyboard_arrow_down_rounded,
                color: color.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodSelector(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool showCalendar = false;
          DateTime focusedDay = DateTime.now();

          return Container(
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontal,
              spacing.cardVertical,
              spacing.cardHorizontal,
              spacing.cardVerticalMax + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                Text(
                  'Select Period',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: spacing.sectionGap),

                // Period grid — 2 columns, full width
                Row(
                  children: [
                    Expanded(
                      child: _buildGridChip(
                        PeriodType.day, 'Today', Icons.today_rounded,
                        color, textTheme, ctx, setModalState,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGridChip(
                        PeriodType.week, 'This Week', Icons.view_week_rounded,
                        color, textTheme, ctx, setModalState,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildGridChip(
                        PeriodType.month, 'This Month', Icons.calendar_view_month_rounded,
                        color, textTheme, ctx, setModalState,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGridChip(
                        PeriodType.year, 'This Year', Icons.calendar_view_day_rounded,
                        color, textTheme, ctx, setModalState,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Custom range — full width, same height
                _buildGridChip(
                  PeriodType.custom, 'Custom Range', Icons.date_range_rounded,
                  color, textTheme, ctx, setModalState,
                ),

                // Calendar (shown when custom is tapped)
                if (widget.selectedPeriod == PeriodType.custom ||
                    showCalendar) ...[
                  SizedBox(height: spacing.elementGap),
                  TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime.now(),
                    focusedDay: focusedDay,
                    calendarFormat: CalendarFormat.month,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    selectedDayPredicate: (day) => false,
                    onRangeSelected: (start, end, focused) {
                      setModalState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                        focusedDay = focused;
                      });
                      if (start != null && end != null) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _rangeStart = start;
                          _rangeEnd = end;
                        });
                        widget.onChanged(PeriodType.custom, start, end);
                        Navigator.pop(ctx);
                      }
                    },
                    onPageChanged: (focused) {
                      setModalState(() => focusedDay = focused);
                    },
                    enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
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
                      rangeHighlightColor:
                          color.primaryContainer.withValues(alpha: 0.3),
                      todayTextStyle: TextStyle(color: color.onSurface),
                      rangeStartTextStyle: TextStyle(color: color.onPrimary),
                      rangeEndTextStyle: TextStyle(color: color.onPrimary),
                      disabledTextStyle: TextStyle(
                        color: color.onSurface.withValues(alpha: 0.3),
                      ),
                      weekendTextStyle: TextStyle(color: color.onSurface),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridChip(
    PeriodType period,
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    BuildContext ctx,
    StateSetter setModalState,
  ) {
    final isSelected = widget.selectedPeriod == period;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (period == PeriodType.custom) {
            setModalState(() {});
            setState(() {});
            widget.onChanged(PeriodType.custom, _rangeStart, _rangeEnd);
          } else {
            widget.onChanged(period, null, null);
            Navigator.pop(ctx);
          }
        },
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.cardHorizontal,
            vertical: spacing.cardVertical,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.primaryContainer
                : color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? color.primary.withValues(alpha: 0.5)
                  : color.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color.primary : color.onSurfaceVariant,
              ),
              SizedBox(width: spacing.elementGap),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected ? color.primary : color.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
