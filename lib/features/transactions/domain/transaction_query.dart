import 'package:mudra_manager/features/transactions/domain/filter_state.dart';

/// Repository-level query contract.
///
/// This object knows nothing about [TransactionViewMode] or UI concepts.
/// It's a dumb data object that the repository uses to fetch transactions.
class TransactionQuery {
  /// Start of the date range (inclusive). Null = no lower bound.
  final DateTime? startDate;

  /// End of the date range (inclusive). Null = no upper bound.
  final DateTime? endDate;

  /// Transaction type filter.
  final TransactionTypeFilter type;

  /// Filter by specific category ID.
  final int? categoryId;

  /// Filter by specific tag ID.
  final int? tagId;

  /// Text search against transaction descriptions.
  final String searchQuery;

  const TransactionQuery({
    this.startDate,
    this.endDate,
    this.type = TransactionTypeFilter.all,
    this.categoryId,
    this.tagId,
    this.searchQuery = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionQuery &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.type == type &&
          other.categoryId == categoryId &&
          other.tagId == tagId &&
          other.searchQuery == searchQuery;

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, type, categoryId, tagId, searchQuery);
}
