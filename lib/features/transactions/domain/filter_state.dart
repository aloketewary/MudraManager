/// How the user is narrowing the currently visible dataset.
///
/// This is filtering — NOT dataset selection (that's [TransactionViewMode]).
/// Contains only semantic filter criteria, no display state.
enum TransactionTypeFilter {
  all,
  income,
  expense,
}

class FilterState {
  final TransactionTypeFilter type;
  final int? categoryId;
  final int? tagId;
  final String searchQuery;

  const FilterState({
    this.type = TransactionTypeFilter.all,
    this.categoryId,
    this.tagId,
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      type != TransactionTypeFilter.all ||
      categoryId != null ||
      tagId != null ||
      searchQuery.isNotEmpty;

  FilterState copyWith({
    TransactionTypeFilter? type,
    int? Function()? categoryId,
    int? Function()? tagId,
    String? searchQuery,
  }) {
    return FilterState(
      type: type ?? this.type,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      tagId: tagId != null ? tagId() : this.tagId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          other.type == type &&
          other.categoryId == categoryId &&
          other.tagId == tagId &&
          other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(type, categoryId, tagId, searchQuery);
}
