import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';

class SwipeableWeeklyCalendar extends StatefulWidget {
  final bool allowFutureDateSelection;
  final Function onDateSelected;
  final DateTime? existingDateTime;

  const SwipeableWeeklyCalendar({
    super.key,
    required this.allowFutureDateSelection,
    required this.onDateSelected,
    required this.existingDateTime,
  });

  @override
  State<SwipeableWeeklyCalendar> createState() =>
      _SwipeableWeeklyCalendarState();
}

class _SwipeableWeeklyCalendarState extends State<SwipeableWeeklyCalendar> {
  late DateTime _currentDate;
  List<DateTime> _firstDaysOfVisibleWeeks = [];

  @override
  void initState() {
    super.initState();
    _currentDate = widget.existingDateTime ?? DateTime.now();
    _updateVisibleWeeksBasedOnCurrent(
      _firstDaysOfVisibleWeeks.length == 2,
      _currentDate,
    );
  }

  void _updateVisibleWeeksBasedOnCurrent(
    bool showTwoWeeks,
    DateTime currentDate,
  ) {
    final now = currentDate;
    final weekday = now.weekday == DateTime.sunday ? 7 : now.weekday;
    final firstDayOfCurrentWeek = now.subtract(Duration(days: weekday - 1));
    _firstDaysOfVisibleWeeks = [firstDayOfCurrentWeek];
    if (showTwoWeeks) {
      _firstDaysOfVisibleWeeks.add(
        firstDayOfCurrentWeek.add(const Duration(days: 7)),
      );
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      final isShowingTwoWeeks = _firstDaysOfVisibleWeeks.length == 2;
      _currentDate = _currentDate.subtract(const Duration(days: 7));
      _updateVisibleWeeksBasedOnCurrent(isShowingTwoWeeks, _currentDate);
    });
  }

  void _goToNextWeek() {
    setState(() {
      final isShowingTwoWeeks = _firstDaysOfVisibleWeeks.length == 2;
      _currentDate = _currentDate.add(const Duration(days: 7));
      _updateVisibleWeeksBasedOnCurrent(isShowingTwoWeeks, _currentDate);
    });
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(DateTime.now().year - 5, 1),
      lastDate: widget.allowFutureDateSelection
          ? DateTime(DateTime.now().year + 5, 12)
          : DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      if (widget.allowFutureDateSelection || !picked.isAfter(DateTime.now())) {
        setState(() {
          _currentDate = picked;
          _updateVisibleWeeksBasedOnCurrent(
            _firstDaysOfVisibleWeeks.length == 2,
            _currentDate,
          );
        });
      } else {
        // Optionally show a message to the user that future dates are not allowed
        SnackbarService.warning(BuddyMessages.futureDate);
      }
    }
  }

  void _loadNextWeek() {
    if (_firstDaysOfVisibleWeeks.length < 2) {
      // Only load if not already showing two weeks
      setState(() {
        _firstDaysOfVisibleWeeks.add(
          _firstDaysOfVisibleWeeks.last.add(const Duration(days: 7)),
        );
      });
    }
  }

  void _collapseWeek() {
    if (_firstDaysOfVisibleWeeks.length > 1) {
      // Only collapse if showing two weeks
      setState(() {
        _firstDaysOfVisibleWeeks.removeLast();
      });
    }
  }

  Widget _buildWeekRow(DateTime firstDayOfWeek) {
    final daysOfWeek = List.generate(
      7,
      (index) => firstDayOfWeek.add(Duration(days: index)),
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(children: daysOfWeek.map((day) => _buildDay(day)).toList()),
    );
  }

  Widget _buildDay(DateTime day) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFutureDate = DateTime(day.year, day.month, day.day).isAfter(today);
    final ctxt = AppLocalizations.of(context)!;

    final isSameDay =
        day.year == _currentDate.year &&
        day.month == _currentDate.month &&
        day.day == _currentDate.day;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () {
            if (widget.allowFutureDateSelection || !isFutureDate) {
              setState(() {
                _currentDate = day;
                widget.onDateSelected(day);
              });
            } else {
              SnackbarService.warning(BuddyMessages.futureDate);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSameDay
                  ? color.primary
                  : (isFutureDate && !widget.allowFutureDateSelection
                        ? Colors.grey[700]
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('d', ctxt.localeName).format(day),
                  style: textTheme.titleLarge?.copyWith(
                    color: isSameDay
                        ? color.onPrimary
                        : (isFutureDate && !widget.allowFutureDateSelection
                              ? Colors.grey[900]
                              : color.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        const double sensitivity = 20.0; // Adjust this value
        if (details.primaryVelocity! > sensitivity) {
          // Swipe Down
          _loadNextWeek();
        } else if (details.primaryVelocity! < -sensitivity) {
          // Swipe Up
          _collapseWeek();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              // horizontal: 8.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Previous',
                  icon: Icon(LucideIcons.chevronLeft, color: color.primary),
                  onPressed: _goToPreviousWeek,
                ),
                GestureDetector(
                  onTap: () => _selectMonthYear(context),
                  child: Text(
                    DateFormat(
                      'MMMM yyyy',
                      ctxt.localeName,
                    ).format(_currentDate),
                    style: textTheme.titleLarge?.copyWith(color: color.primary),
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  icon: Icon(LucideIcons.chevronRight, color: color.primary),
                  onPressed: _goToNextWeek,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_monday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_tuesday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_wednesday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_thursday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_friday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_saturday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ctxt.calendar_week_sunday_initial_text,
                      style: TextStyle(color: color.onSurface),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: _firstDaysOfVisibleWeeks
                .map((firstDay) => _buildWeekRow(firstDay))
                .toList(),
          ),
        ],
      ),
    );
  }
}
