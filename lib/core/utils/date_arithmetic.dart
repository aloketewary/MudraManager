/// Centralized date arithmetic that handles month-end clamping.
///
/// Prevents the month-end drift bug where Jan 31 + 1 month = Mar 3
/// (Dart's DateTime auto-rolls Feb 31 → Mar 3).
///
/// All recurring transaction, bill, and budget period calculations
/// should use this instead of raw DateTime arithmetic.
class DateArithmetic {
  DateArithmetic._();

  /// Adds [months] to [from], preserving the original day where possible.
  /// If the target month has fewer days, clamps to the last day.
  ///
  /// [preferDay] overrides the day to preserve (e.g., the original startDate day
  /// for recurring transactions that may have already drifted).
  ///
  /// Examples:
  ///   addMonths(Jan 31, 1) → Feb 28 (or Feb 29 in leap year)
  ///   addMonths(Feb 28, 1) → Mar 28 (not Mar 31)
  ///   addMonths(Jan 31, 1, preferDay: 31) → Feb 28, then Mar 31
  static DateTime addMonths(DateTime from, int months, {int? preferDay}) {
    final day = preferDay ?? from.day;
    final totalMonths = from.year * 12 + (from.month - 1) + months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;
    final daysInTarget = _daysInMonth(targetYear, targetMonth);
    return DateTime(targetYear, targetMonth, day.clamp(1, daysInTarget));
  }

  /// Subtracts [months] from [from] with the same clamping logic.
  static DateTime subtractMonths(DateTime from, int months, {int? preferDay}) {
    return addMonths(from, -months, preferDay: preferDay);
  }

  /// Adds [years] to [from], handling Feb 29 → Feb 28 in non-leap years.
  static DateTime addYears(DateTime from, int years, {int? preferDay}) {
    return addMonths(from, years * 12, preferDay: preferDay);
  }

  /// Returns the number of days in a given month/year.
  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
