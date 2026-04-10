import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/category_resolver.dart';
import 'package:mudra_manager/features/import_export/models/import_models.dart';

void main() {
  group('CategoryResolver - known categories', () {
    test('food resolves with correct icon and type', () {
      final cat = CategoryResolver.createCategory('Food');
      expect(cat.name, 'Food');
      expect(cat.iconName, 'utensils');
      expect(cat.categoryType, CategoryType.expense);
      expect(cat.colorValue, isNotNull);
      expect(cat.keywords, isNotEmpty);
    });

    test('grocery resolves', () {
      final cat = CategoryResolver.createCategory('Grocery');
      expect(cat.iconName, 'shopping_cart');
      expect(cat.categoryType, CategoryType.expense);
    });

    test('transport resolves', () {
      final cat = CategoryResolver.createCategory('Transport');
      expect(cat.iconName, 'car');
    });

    test('salary resolves as income', () {
      final cat = CategoryResolver.createCategory('Salary');
      expect(cat.categoryType, CategoryType.income);
      expect(cat.iconName, 'wallet');
    });

    test('freelance resolves as income', () {
      final cat = CategoryResolver.createCategory('Freelance Income');
      expect(cat.categoryType, CategoryType.income);
    });

    test('refund resolves as income', () {
      final cat = CategoryResolver.createCategory('Refund');
      expect(cat.categoryType, CategoryType.income);
    });

    test('interest resolves as income', () {
      final cat = CategoryResolver.createCategory('Interest Earned');
      expect(cat.categoryType, CategoryType.income);
    });
  });

  group('CategoryResolver - fuzzy matching', () {
    test('partial match works: "Food & Dining"', () {
      final cat = CategoryResolver.createCategory('Food & Dining');
      expect(cat.iconName, 'utensils');
    });

    test('keyword match: "Uber Ride"', () {
      final cat = CategoryResolver.createCategory('Uber Ride');
      expect(cat.iconName, 'car'); // matches 'uber' keyword in transport
    });

    test('keyword match: "Netflix Subscription"', () {
      final cat = CategoryResolver.createCategory('Netflix Subscription');
      expect(cat.iconName, isNotNull);
      expect(cat.categoryType, CategoryType.expense);
    });

    test('keyword match: "Amazon Shopping"', () {
      final cat = CategoryResolver.createCategory('Amazon Shopping');
      expect(cat.categoryType, CategoryType.expense);
    });

    test('keyword match: "Hospital Visit"', () {
      final cat = CategoryResolver.createCategory('Hospital Visit');
      expect(cat.iconName, 'heart_pulse');
    });
  });

  group('CategoryResolver - unknown categories', () {
    test('unknown name gets fallback icon and color', () {
      final cat = CategoryResolver.createCategory('Xyzzy Random Thing');
      expect(cat.name, 'Xyzzy Random Thing');
      expect(cat.iconName, 'circle');
      expect(cat.colorValue, isNotNull);
      expect(cat.categoryType, CategoryType.expense); // default
    });

    test('isKnown returns false for unknown', () {
      expect(CategoryResolver.isKnown('Xyzzy'), false);
    });

    test('isKnown returns true for known', () {
      expect(CategoryResolver.isKnown('Food'), true);
      expect(CategoryResolver.isKnown('Salary'), true);
    });
  });

  group('CategoryResolver - type inference', () {
    test('expense categories infer expense', () {
      expect(CategoryResolver.inferType('Shopping'), CategoryType.expense);
      expect(CategoryResolver.inferType('Rent'), CategoryType.expense);
      expect(CategoryResolver.inferType('EMI'), CategoryType.expense);
    });

    test('income categories infer income', () {
      expect(CategoryResolver.inferType('Salary'), CategoryType.income);
      expect(CategoryResolver.inferType('Freelance'), CategoryType.income);
      expect(CategoryResolver.inferType('Refund'), CategoryType.income);
    });

    test('unknown defaults to expense', () {
      expect(CategoryResolver.inferType('Unknown'), CategoryType.expense);
    });
  });

  group('CategoryResolver - keywords', () {
    test('created category has keywords', () {
      final cat = CategoryResolver.createCategory('Food');
      expect(cat.keywords, isNotNull);
      expect(cat.keywords, contains('restaurant'));
      expect(cat.keywords, contains('dining'));
    });

    test('unknown category has null keywords', () {
      final cat = CategoryResolver.createCategory('Xyzzy');
      expect(cat.keywords, isNull);
    });
  });

  group('ImportRow', () {
    test('valid when date and amount present', () {
      final row = ImportRow(
        rowIndex: 2,
        date: DateTime(2024, 6, 15),
        amount: 500,
      );
      expect(row.isValid, true);
    });

    test('invalid when date is null', () {
      final row = const ImportRow(rowIndex: 2, amount: 500);
      expect(row.isValid, false);
    });

    test('invalid when amount is null', () {
      final row = ImportRow(rowIndex: 2, date: DateTime.now());
      expect(row.isValid, false);
    });

    test('invalid when amount is 0', () {
      final row = ImportRow(rowIndex: 2, date: DateTime.now(), amount: 0);
      expect(row.isValid, false);
    });

    test('invalid when error is set', () {
      final row = ImportRow(
        rowIndex: 2,
        date: DateTime.now(),
        amount: 500,
        error: 'Bad data',
      );
      expect(row.isValid, false);
    });

    test('defaults to expense', () {
      final row = const ImportRow(rowIndex: 2);
      expect(row.isExpense, true);
    });
  });

  group('ImportResult', () {
    test('total = imported + skipped + duplicates', () {
      const result = ImportResult(imported: 10, skipped: 3, duplicates: 2);
      expect(result.total, 15);
    });

    test('categoriesCreated defaults to 0', () {
      const result = ImportResult(imported: 5);
      expect(result.categoriesCreated, 0);
    });

    test('tracks categories created', () {
      const result = ImportResult(imported: 10, categoriesCreated: 3);
      expect(result.categoriesCreated, 3);
    });

    test('empty result', () {
      const result = ImportResult();
      expect(result.total, 0);
      expect(result.errors, isEmpty);
    });
  });
}
