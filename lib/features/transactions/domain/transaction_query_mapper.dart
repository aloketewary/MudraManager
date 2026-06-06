import 'package:mudra_manager/features/transactions/domain/filter_state.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_query.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';

/// Maps application-layer state (ViewMode + FilterState) into a
/// repository-level [TransactionQuery].
///
/// This function lives in the application layer because it knows about
/// [TransactionViewMode] and [FilterState]. The [TransactionQuery] it
/// produces is a dumb data object that the repository can consume without
/// importing any application-state types.
TransactionQuery createTransactionQuery(
  TransactionViewMode mode,
  FilterState filters,
) {
  final DateTime? startDate;
  final DateTime? endDate;

  switch (mode) {
    case InfiniteView():
      // Recent stream — let the repository decide the performance window.
      // We pass null dates; the caller/repository applies its own recency limit.
      startDate = null;
      endDate = null;

    case MonthView(:final year, :final month):
      startDate = DateTime(year, month, 1);
      // Last moment of the month
      endDate = DateTime(year, month + 1, 1)
          .subtract(const Duration(microseconds: 1));

    case DateRangeView(:final start, :final end):
      startDate = DateTime(start.year, start.month, start.day);
      endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
  }

  return TransactionQuery(
    startDate: startDate,
    endDate: endDate,
    type: filters.type,
    categoryId: filters.categoryId,
    tagId: filters.tagId,
    searchQuery: filters.searchQuery,
  );
}
