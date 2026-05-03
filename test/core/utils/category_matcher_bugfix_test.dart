import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/robust_category_matcher.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/features/sms/data/category_matcher_service.dart';

void main() {
  late List<Category> categories;

  setUp(() {
    categories = [
      Category.create(
        name: 'Food & Dining',
        categoryType: CategoryType.expense,
        keywords: ['swiggy', 'zomato', 'food', 'restaurant', 'coffee', 'chai'],
      ),
      Category.create(
        name: 'Transportation',
        categoryType: CategoryType.expense,
        keywords: ['uber', 'ola', 'cab', 'metro', 'petrol'],
      ),
      Category.create(
        name: 'Shopping',
        categoryType: CategoryType.expense,
        keywords: ['amazon', 'flipkart', 'mall'],
      ),
      Category.create(
        name: 'Utilities',
        categoryType: CategoryType.expense,
        keywords: ['electricity', 'water', 'internet', 'recharge'],
      ),
      Category.create(
        name: 'Others',
        categoryType: CategoryType.expense,
        keywords: [],
      ),
    ];
  });

  // ── Bug #1: \b fails on special-char keywords ──

  group('Bug #1 — word boundary with special chars', () {
    test('keyword with & matches at word boundary', () {
      final cats = [
        Category.create(
          name: 'Health & Fitness',
          categoryType: CategoryType.expense,
          keywords: ['gym', 'health & fitness'],
        ),
        Category.create(name: 'Others', categoryType: CategoryType.expense),
      ];

      final result = RobustCategoryMatcher.match(
        text: 'Paid for health & fitness membership',
        allCategories: cats,
        relevantCategories: cats,
      );
      expect(result.category?.name, 'Health & Fitness');
    });

    test('keyword with hyphen matches correctly', () {
      final cats = [
        Category.create(
          name: 'E-Wallet',
          categoryType: CategoryType.expense,
          keywords: ['e-wallet', 'paytm'],
        ),
        Category.create(name: 'Others', categoryType: CategoryType.expense),
      ];

      final result = RobustCategoryMatcher.match(
        text: 'Payment via e-wallet for groceries',
        allCategories: cats,
        relevantCategories: cats,
      );
      expect(result.category?.name, 'E-Wallet');
    });
  });

  // ── Bug #2: firstWhereOrNull extension removed ──

  group('Bug #2 — no extension conflict', () {
    test('fallback still finds Others without custom extension', () {
      final result = RobustCategoryMatcher.match(
        text: 'completely unknown transaction xyz',
        allCategories: categories,
        relevantCategories: categories,
      );
      expect(result.category?.name, 'Others');
      expect(result.matchStrategy, 'default_fallback');
    });
  });

  // ── Bug #4: single keyword skipped in CategoryMatcherService ──

  group('Bug #4 — single short keyword now matches', () {
    test('single exact keyword "cab" matches Transportation', () {
      final result = CategoryMatcherService.matchCategory(
        'Rs 200 debited for cab ride on 15-Jan-24',
        categories,
        false,
      );
      expect(result?.name, 'Transportation');
    });

    test('single exact keyword "ola" matches Transportation', () {
      final result = CategoryMatcherService.matchCategory(
        'Rs 150 paid to Ola for auto',
        categories,
        false,
      );
      expect(result?.name, 'Transportation');
    });

    test('single keyword "chai" matches Food', () {
      final result = CategoryMatcherService.matchCategory(
        'Rs 30 debited at chai tapri',
        categories,
        false,
      );
      expect(result?.name, 'Food & Dining');
    });
  });

  // ── Bug #5: merchant regex captures garbage ──

  group('Bug #5 — merchant regex word cap', () {
    test('captures short merchant name', () {
      final merchant = CategoryMatcherService.detectMerchant(
        'debited at Amazon on 15-Jan-24',
        categories,
      );
      expect(merchant?.toLowerCase(), contains('amazon'));
    });

    test('captures multi-word merchant up to 5 words', () {
      final merchant = CategoryMatcherService.detectMerchant(
        'debited at AMAZON SELLER SERVICES PVT LTD on 15-Jan-24',
        categories,
      );
      expect(merchant, isNotNull);
    });

    test('does not capture excessively long garbage', () {
      final merchant = CategoryMatcherService.detectMerchant(
        'debited at A B C D E F G H I J K L M N O P Q R on 15-Jan-24',
        categories,
      );
      // Should either be null or capped — not 30 chars of single letters
      if (merchant != null) {
        expect(merchant.split(' ').length, lessThanOrEqualTo(5));
      }
    });
  });

  // ── Bug #6: empty text guard ──

  group('Bug #6 — empty text handling', () {
    test('RobustCategoryMatcher returns fallback for empty text', () {
      final result = RobustCategoryMatcher.match(
        text: '',
        allCategories: categories,
        relevantCategories: categories,
      );
      expect(result.category?.name, 'Others');
    });

    test('RobustCategoryMatcher returns fallback for whitespace-only text', () {
      final result = RobustCategoryMatcher.match(
        text: '   \t\n  ',
        allCategories: categories,
        relevantCategories: categories,
      );
      expect(result.category?.name, 'Others');
    });

    test('CategoryMatcher returns null for empty text', () {
      final result = CategoryMatcher.matchByKeywords('', categories);
      expect(result, isNull);
    });

    test('CategoryMatcher returns null for whitespace-only text', () {
      final result = CategoryMatcher.matchByKeywords('   ', categories);
      expect(result, isNull);
    });
  });

  // ── Bug #9: noise name check incomplete ──

  group('Bug #9 — noise name filtering', () {
    test('INR prefix rejected as merchant name', () {
      final merchant = CategoryMatcherService.detectMerchant(
        'sent to INR 5000 from account XX1234. Ref 123',
        categories,
      );
      // "INR 5000" should not be a valid merchant
      expect(
        merchant == null || !merchant.startsWith('INR'),
        isTrue,
      );
    });

    test('name starting with digit rejected', () {
      final merchant = CategoryMatcherService.detectMerchant(
        'sent to 12345 Random Name from account XX1234. Ref 123',
        categories,
      );
      expect(
        merchant == null || !RegExp(r'^\d').hasMatch(merchant),
        isTrue,
      );
    });
  });

  // ── Bug #7: noise words in Strategy 2 ──

  group('Bug #7 — noise words filtered in keyword exact match', () {
    test('polluted keywords do not cause false match in RobustCategoryMatcher', () {
      final polluted = [
        Category.create(
          name: 'Food & Dining',
          categoryType: CategoryType.expense,
          keywords: ['debited', 'account', 'balance', 'food'],
        ),
        Category.create(
          name: 'Others',
          categoryType: CategoryType.expense,
          keywords: [],
        ),
      ];

      // SMS with only banking noise — no food keywords
      final result = RobustCategoryMatcher.match(
        text: 'Rs 2000 debited from account XX1234. Avl balance Rs 5000',
        allCategories: polluted,
        relevantCategories: polluted,
      );
      expect(result.category?.name, isNot('Food & Dining'));
    });
  });
}
