import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';

void main() {
  late List<Category> categories;

  setUp(() {
    categories = [
      Category.create(
        name: 'Food & Dining',
        categoryType: CategoryType.expense,
        keywords: ['swiggy', 'zomato', 'restaurant', 'food', 'dining', 'cafe'],
      ),
      Category.create(
        name: 'Grocery',
        categoryType: CategoryType.expense,
        keywords: ['grocery', 'vegetable', 'supermarket', 'bigbasket', 'kirana'],
      ),
      Category.create(
        name: 'Transport',
        categoryType: CategoryType.expense,
        keywords: ['uber', 'ola', 'petrol', 'fuel', 'metro', 'bus'],
      ),
      Category.create(
        name: 'Other',
        categoryType: CategoryType.expense,
      ),
      Category.create(
        name: 'Salary',
        categoryType: CategoryType.income,
        keywords: ['salary', 'payroll'],
      ),
    ];
  });

  group('CategoryMatcher.matchByKeywords', () {
    test('matches by keyword in text', () {
      final result = CategoryMatcher.matchByKeywords(
        'Payment to Swiggy for food order',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });

    test('matches by category name', () {
      final result = CategoryMatcher.matchByKeywords(
        'Grocery shopping at store',
        categories,
      );
      expect(result?.name, 'Grocery');
    });

    test('longer keyword match wins', () {
      // "supermarket" (11 chars) > "grocery" (7 chars)
      final result = CategoryMatcher.matchByKeywords(
        'Bought items at supermarket grocery',
        categories,
      );
      // Both match Grocery, score = 11 + 7 = 18
      expect(result?.name, 'Grocery');
    });

    test('no match returns null', () {
      final result = CategoryMatcher.matchByKeywords(
        'Random unknown transaction xyz',
        categories,
      );
      expect(result, null);
    });

    test('case insensitive matching', () {
      final result = CategoryMatcher.matchByKeywords(
        'UBER ride to airport',
        categories,
      );
      expect(result?.name, 'Transport');
    });

    test('empty text returns null', () {
      final result = CategoryMatcher.matchByKeywords('', categories);
      expect(result, null);
    });

    test('empty categories returns null', () {
      final result = CategoryMatcher.matchByKeywords('some text', []);
      expect(result, null);
    });

    test('category without keywords matches by name only', () {
      final result = CategoryMatcher.matchByKeywords(
        'Other expenses for the month',
        categories,
      );
      expect(result?.name, 'Other');
    });
  });

  group('CategoryMatcher.getFallbackCategory', () {
    test('returns Other category when available', () {
      final result = CategoryMatcher.getFallbackCategory(categories, null);
      expect(result?.name, 'Other');
    });

    test('returns first category when no Other exists', () {
      final noOther = categories.where((c) => c.name != 'Other').toList();
      final result = CategoryMatcher.getFallbackCategory(noOther, null);
      expect(result, isNotNull);
      expect(result?.name, 'Food & Dining');
    });

    test('returns null for empty list', () {
      final result = CategoryMatcher.getFallbackCategory([], null);
      expect(result, null);
    });

    test('amount parameter does not crash', () {
      final result = CategoryMatcher.getFallbackCategory(categories, 500.0);
      expect(result, isNotNull);
    });
  });

  group('Keyword matching edge cases', () {
    test('partial keyword match works', () {
      // "food" is in "foodcourt"
      final result = CategoryMatcher.matchByKeywords(
        'Paid at foodcourt',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });

    test('multiple categories match — highest score wins', () {
      // "food" matches Food & Dining, "grocery" matches Grocery
      final result = CategoryMatcher.matchByKeywords(
        'food grocery store',
        categories,
      );
      // "grocery" (7) + "food & dining" name doesn't match "food grocery store"
      // "food" (4) matches Food & Dining
      // "grocery" (7) matches Grocery → higher score
      expect(result?.name, 'Grocery');
    });

    test('special characters in text', () {
      final result = CategoryMatcher.matchByKeywords(
        'Paid ₹500 to Zomato (food delivery)',
        categories,
      );
      expect(result?.name, 'Food & Dining');
    });
  });
}
