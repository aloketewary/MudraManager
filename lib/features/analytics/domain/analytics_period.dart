/// Strongly typed analytics period — replaces string-based period keys.
///
/// Pure domain model. No Riverpod. No Flutter.
/// Riverpod family providers use [key] for caching.
sealed class AnalyticsPeriod {
  const AnalyticsPeriod();

  /// Stable string key for Riverpod family caching.
  String get key;

  /// Whether this period is a monthly view (enables month-specific rules).
  bool get isMonthly => this is MonthPeriod;

  /// Resolve to concrete start/end dates.
  ({DateTime start, DateTime end}) resolve() {
    final now = DateTime.now();
    return switch (this) {
      TodayPeriod() => (
          start: DateTime(now.year, now.month, now.day),
          end: now,
        ),
      WeekPeriod() => (
          start: now.subtract(const Duration(days: 6)),
          end: now,
        ),
      MonthPeriod() => (
          start: DateTime(now.year, now.month, 1),
          end: now,
        ),
      YearPeriod() => (
          start: DateTime(now.year, 1, 1),
          end: now,
        ),
      CustomPeriod(:final start, :final end) => (
          start: start,
          end: DateTime(end.year, end.month, end.day, 23, 59, 59),
        ),
    };
  }

  /// Period type label for aggregation service.
  String get periodType => switch (this) {
        TodayPeriod() => 'Today',
        WeekPeriod() => 'Week',
        MonthPeriod() => 'Month',
        YearPeriod() => 'Year',
        CustomPeriod() => 'Custom',
      };
}

final class TodayPeriod extends AnalyticsPeriod {
  const TodayPeriod();

  @override
  String get key => 'Today';
}

final class WeekPeriod extends AnalyticsPeriod {
  const WeekPeriod();

  @override
  String get key => 'Week';
}

final class MonthPeriod extends AnalyticsPeriod {
  const MonthPeriod();

  @override
  String get key => 'Month';
}

final class YearPeriod extends AnalyticsPeriod {
  const YearPeriod();

  @override
  String get key => 'Year';
}

final class CustomPeriod extends AnalyticsPeriod {
  const CustomPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  String get key =>
      '${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}';
}

/// Parses a string key back into a typed [AnalyticsPeriod].
/// Used by providers that receive family keys as strings.
class AnalyticsPeriodParser {
  const AnalyticsPeriodParser._();

  static AnalyticsPeriod fromKey(String key) {
    return switch (key) {
      'Today' => const TodayPeriod(),
      'Week' => const WeekPeriod(),
      'Month' => const MonthPeriod(),
      'Year' => const YearPeriod(),
      _ when key.contains('_') => _parseCustom(key),
      _ => const MonthPeriod(),
    };
  }

  static CustomPeriod _parseCustom(String key) {
    final parts = key.split('_');
    return CustomPeriod(
      start: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      end: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
    );
  }
}
