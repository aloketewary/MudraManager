import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/features/transactions/domain/filter_state.dart';

void main() {
  group('FilterState', () {
    test('default has no active filters', () {
      const state = FilterState();
      expect(state.hasActiveFilters, false);
    });

    test('type filter makes it active', () {
      const state = FilterState(type: TransactionTypeFilter.expense);
      expect(state.hasActiveFilters, true);
    });

    test('category filter makes it active', () {
      const state = FilterState(categoryId: 5);
      expect(state.hasActiveFilters, true);
    });

    test('tag filter makes it active', () {
      const state = FilterState(tagId: 3);
      expect(state.hasActiveFilters, true);
    });

    test('search query makes it active', () {
      const state = FilterState(searchQuery: 'food');
      expect(state.hasActiveFilters, true);
    });

    test('empty search query does not make it active', () {
      const state = FilterState(searchQuery: '');
      expect(state.hasActiveFilters, false);
    });

    test('copyWith preserves unchanged fields', () {
      const original = FilterState(
        type: TransactionTypeFilter.expense,
        categoryId: 5,
        tagId: 3,
        searchQuery: 'food',
      );

      final updated = original.copyWith(searchQuery: 'rent');

      expect(updated.type, TransactionTypeFilter.expense);
      expect(updated.categoryId, 5);
      expect(updated.tagId, 3);
      expect(updated.searchQuery, 'rent');
    });

    test('copyWith can clear nullable fields', () {
      const original = FilterState(categoryId: 5, tagId: 3);

      final updated = original.copyWith(
        categoryId: () => null,
        tagId: () => null,
      );

      expect(updated.categoryId, isNull);
      expect(updated.tagId, isNull);
    });

    test('equality works by value', () {
      const a = FilterState(type: TransactionTypeFilter.income, categoryId: 5);
      const b = FilterState(type: TransactionTypeFilter.income, categoryId: 5);
      const c = FilterState(type: TransactionTypeFilter.expense, categoryId: 5);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
