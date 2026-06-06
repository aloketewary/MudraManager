/// Represents how the user has chosen the dataset to view.
///
/// This is navigation/query scope — NOT filtering.
/// - [InfiniteView]: Recent transaction stream (no fixed date boundary)
/// - [MonthView]: All transactions within a specific calendar month
/// - [DateRangeView]: All transactions within an arbitrary date range
sealed class TransactionViewMode {
  const TransactionViewMode();
}

/// Recent transaction stream. The repository decides how to scope this
/// (e.g. pagination, recency window). The UI doesn't encode the limit.
final class InfiniteView extends TransactionViewMode {
  const InfiniteView();
}

/// A specific calendar month.
final class MonthView extends TransactionViewMode {
  final int year;
  final int month;

  const MonthView(this.year, this.month);
}

/// An arbitrary date range chosen by the user.
final class DateRangeView extends TransactionViewMode {
  final DateTime start;
  final DateTime end;

  const DateRangeView(this.start, this.end);
}
