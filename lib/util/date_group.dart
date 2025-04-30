enum DateGroup { today, yesterday, thisMonth, thisYear, older }

extension DateGroupLabel on DateGroup {
  String get label {
    switch (this) {
      case DateGroup.today:     return 'Today';
      case DateGroup.yesterday: return 'Yesterday';
      case DateGroup.thisMonth: return 'This Month';
      case DateGroup.thisYear:  return 'This Year';
      case DateGroup.older:     return 'Older';
    }
  }
}

DateGroup groupForDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (date.isAfter(today)) return DateGroup.today;
  if (date.isAfter(yesterday)) return DateGroup.yesterday;
  if (date.year == now.year && date.month == now.month) return DateGroup.thisMonth;
  if (date.year == now.year) return DateGroup.thisYear;
  return DateGroup.older;
}
