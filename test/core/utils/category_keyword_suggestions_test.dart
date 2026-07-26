import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/utils/category_keyword_suggestions.dart';

void main() {
  group('CategoryKeywordSuggestions', () {
    test('returns empty for very short input', () {
      expect(CategoryKeywordSuggestions.suggest('a'), isEmpty);
      expect(CategoryKeywordSuggestions.suggest(''), isEmpty);
    });

    test('exact canonical name match', () {
      final result = CategoryKeywordSuggestions.suggest('Fuel');
      expect(result, contains('petrol'));
      expect(result, contains('diesel'));
    });

    test('exact synonym match resolves to canonical entry', () {
      final result = CategoryKeywordSuggestions.suggest('Petrol');
      expect(result, contains('petrol'));
      expect(result, contains('diesel'));
    });

    test('substring match on a longer typed name', () {
      final result = CategoryKeywordSuggestions.suggest('Car Fuel Expenses');
      expect(result, isNotEmpty);
      expect(result, contains('petrol'));
    });

    test('is case-insensitive', () {
      final lower = CategoryKeywordSuggestions.suggest('groceries');
      final upper = CategoryKeywordSuggestions.suggest('GROCERIES');
      expect(lower, upper);
      expect(lower, isNotEmpty);
    });

    test('returns empty for unrelated/novel name', () {
      final result = CategoryKeywordSuggestions.suggest('Xyzzy Foobar');
      expect(result, isEmpty);
    });

    test('short synonym keys do not false-positive on unrelated words', () {
      // "pet" is a synonym key but must not match inside "carpet" via
      // substring — short keys are excluded from substring matching, so
      // this correctly returns no suggestions rather than leaking "vet".
      final result = CategoryKeywordSuggestions.suggest('Carpet Cleaning');
      expect(result, isNot(contains('vet')));
      expect(result, isEmpty);
    });

    test('pet category still resolves via exact match', () {
      final result = CategoryKeywordSuggestions.suggest('Pet');
      expect(result, contains('vet'));
    });
  });
}
