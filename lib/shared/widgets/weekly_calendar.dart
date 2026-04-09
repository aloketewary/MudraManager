import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyCalendar extends StatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  DateTime _currentDate = DateTime.now();
  late DateTime _firstDayOfWeek;

  @override
  void initState() {
    super.initState();
    _updateFirstDayOfWeek();
  }

  void _updateFirstDayOfWeek() {
    final now = _currentDate;
    final weekday = now.weekday == DateTime.sunday ? 7 : now.weekday;
    _firstDayOfWeek = now.subtract(Duration(days: weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
      _updateFirstDayOfWeek();
    });
  }

  void _nextWeek() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 7));
      _updateFirstDayOfWeek();
    });
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(DateTime.now().year - 5, 1),
      // Adjust range as needed
      lastDate: DateTime(DateTime.now().year + 5, 12),
      // Adjust range as needed
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _currentDate = picked;
        _updateFirstDayOfWeek();
      });
    }
  }

  Widget _buildDay(DateTime day) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isSameDay =
        day.year == _currentDate.year &&
        day.month == _currentDate.month &&
        day.day == _currentDate.day;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () {
            setState(() {
              _currentDate = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSameDay ? color.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  DateFormat('d').format(day),
                  style: textTheme.titleLarge?.copyWith(
                    color: isSameDay ? color.onPrimary : color.onSurface,
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
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final currentWeekDays = List.generate(
      7,
      (index) => _firstDayOfWeek.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: _previousWeek,
              ),
              GestureDetector(
                onTap: () => _selectMonthYear(context),
                child: Text(
                  DateFormat('MMMM yyyy').format(_currentDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children:
                daysOfWeek
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: currentWeekDays.map((day) => _buildDay(day)).toList(),
          ),
        ),
        // You can add the "You have Spend..." section below this
      ],
    );
  }
}
