import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/transactions/domain/filter_state.dart';

/// Manages how the user is narrowing the currently visible dataset.
///
/// This is query state — it determines which subset of fetched data is shown.
/// Separate from ViewMode (what dataset) and interaction state (selection, displayLimit).
class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setType(TransactionTypeFilter type) =>
      state = state.copyWith(type: type);

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: () => categoryId);

  void setTag(int? tagId) => state = state.copyWith(tagId: () => tagId);

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void clearAll() => state = const FilterState();

  void clearCategory() => state = state.copyWith(categoryId: () => null);

  void clearTag() => state = state.copyWith(tagId: () => null);

  void clearSearch() => state = state.copyWith(searchQuery: '');
}

final filterStateProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);
