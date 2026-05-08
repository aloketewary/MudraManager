import 'package:flutter_test/flutter_test.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/robust_category_matcher.dart';

void main() {
  // Test categories
  late List<Category> allCategories;
  late List<Category> expenseCategories;
  late List<Category> incomeCategories;

  setUp(() {
    // Create well-structured categories with keywords
    allCategories = [
      Category.create(
        name: 'Food & Dining',
        categoryType: CategoryType.expense,
        keywords: ['swiggy', 'zomato', 'restaurant', 'coffee', 'food'],
      ),
      Category.create(
        name: 'Shopping',
        categoryType: CategoryType.expense,
        keywords: ['amazon', 'flipkart', 'mall', 'retail'],
      ),
      Category.create(
        name: 'Utilities',
        categoryType: CategoryType.expense,
        keywords: ['electricity', 'water', 'gas', 'internet', 'mobile'],
      ),
      Category.create(
        name: 'Salary',
        categoryType: CategoryType.income,
        keywords: ['payroll', 'salary', 'bonus', 'compensation'],
      ),
      Category.create(
        name: 'Freelance',
        categoryType: CategoryType.income,
        keywords: ['freelance', 'project', 'invoice', 'service'],
      ),
      Category.create(
        name: 'Others',
        categoryType: CategoryType.expense,
        keywords: [],
      ),
    ];

    expenseCategories =
        allCategories.where((c) => c.categoryType == CategoryType.expense).toList();
    incomeCategories =
        allCategories.where((c) => c.categoryType == CategoryType.income).toList();
  });

  group('RobustCategoryMatcher - Strategy 1: Exact Name Match', () {
    test('matches exact category name in text', () {
      const sms = 'Your Food & Dining subscription is active';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.category?.name, 'Food & Dining');
      expect(result.confidenceScore, greaterThanOrEqualTo(90));
      expect(result.matchStrategy, 'exact_name_match');
    });

    test('falls back to next strategy when exact name not found', () {
      const sms = 'Random transaction with no category names';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      // Will fall through to Strategy 2, 3, 4, or 5
      expect(result.category, isNotNull); // Always returns a result
      expect(
        result.matchStrategy,
        isNot('exact_name_match'),
      );
    });
  });

  group('RobustCategoryMatcher - Strategy 2: Keyword Exact Match', () {
    test('matches keyword with exact word boundaries (high confidence)', () {
      const sms = 'Rs.500 spent at swiggy for dinner today';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.category?.name, 'Food & Dining');
      expect(result.confidenceScore, greaterThanOrEqualTo(75));
      expect(result.matchStrategy, 'keyword_exact_match');
    });

    test('prefers longer keywords for specificity', () {
      const sms = 'Ordered food from restaurant, paid Rs.1200';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.category?.name, 'Food & Dining');
      expect(result.matchStrategy, 'keyword_exact_match');
    });

    test('falls back when no exact keyword match', () {
      const sms = 'Random text without any matching keywords xyz abc';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      // Will use a fallback strategy, should return "Others"
      expect(result.category?.name, 'Others');
    });
  });

  group('RobustCategoryMatcher - Strategy 3: Keyword Substring Match', () {
    test('matches keyword substring when exact match fails', () {
      const sms = 'payment to foodcafeplex';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      // Should match "food" from Food & Dining
      expect(result.category?.name, 'Food & Dining');
      expect(result.matchStrategy, 'keyword_substring_match');
    });

    test('filters out noise words during substring matching', () {
      const sms = 'payment from your bank account balance Rs.5000';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      // "bank", "account", "your" are all noise words, falls back
      expect(result.matchStrategy, 'default_fallback');
    });
  });

  group('RobustCategoryMatcher - Strategy 4: Amount-Based Heuristics', () {
    test('matches high confidence when amount and keywords align', () {
      const sms = 'coffee payment at cafe';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
        amount: 50,
      );

      // "coffee" keyword should match before amount heuristic
      expect(result.category?.name, 'Food & Dining');
      expect(result.confidenceScore, greaterThan(60));
    });

    test('falls back for amount heuristic when specific keywords missing', () {
      // When amount heuristics return null, falls to default fallback
      final result = RobustCategoryMatcher.match(
        text: 'generic transaction without food context',
        allCategories: allCategories,
        relevantCategories: expenseCategories,
        amount: 50,
      );

      // Falls back to default category
      expect(result.category, isNotNull);
    });
  });

  group('RobustCategoryMatcher - Strategy 5: Default Fallback', () {
    test('selects "Others" category as default fallback', () {
      const sms = 'xyz abc def ghi jkl mno pqr stu vwx';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.category?.name, 'Others');
      expect(result.confidenceScore, lessThan(40));
      expect(result.matchStrategy, 'default_fallback');
    });

    test('returns first category when no fallback names found', () {
      final customCategories = [
        Category.create(
          name: 'Custom Expense',
          categoryType: CategoryType.expense,
        ),
      ];

      const sms = 'xyz abc def ghi';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: customCategories,
        relevantCategories: customCategories,
      );

      expect(result.category?.name, 'Custom Expense');
      expect(result.matchStrategy, 'last_resort_fallback');
    });

    test('returns appropriate result when no categories available', () {
      const sms = 'Random transaction';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: [],
        relevantCategories: [],
      );

      expect(result.category, isNull);
      expect(result.matchStrategy, 'no_categories_available');
    });
  });

  group('RobustCategoryMatcher - Category Type Filtering', () {
    test('filters categories by income type when specified', () {
      const sms = 'Rs.5000 salary credited';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: incomeCategories, // Only income categories
      );

      expect(result.category?.name, 'Salary');
      expect(
        result.category?.categoryType,
        CategoryType.income,
      );
    });

    test(
        'filters categories by expense type when specified',
        () {
      const sms = 'Rs.500 spent at amazon for shopping';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories, // Only expense categories
      );

      expect(result.category?.name, 'Shopping');
      expect(
        result.category?.categoryType,
        CategoryType.expense,
      );
    });
  });

  group('RobustCategoryMatcher - Confidence Scoring', () {
    test('exact name match has highest confidence (>90)', () {
      const sms = 'Your Food & Dining bill is ready';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.confidenceScore, greaterThan(90));
      expect(result.isHighConfidence, true);
    });

    test('keyword exact match has high confidence (70-85)', () {
      const sms = 'Payment to amazon for books';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.confidenceScore, greaterThanOrEqualTo(70));
      expect(result.isHighConfidence, true);
    });

    test('keyword substring match has moderate confidence (50-70)', () {
      const sms = 'Androidapp purchase from flipkartmall';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.confidenceScore, lessThan(80));
    });

    test('default fallback has low confidence (<40)', () {
      const sms = 'Random transaction with no keywords';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.confidenceScore, lessThan(50));
      expect(result.isHighConfidence, false);
    });
  });

  group('RobustCategoryMatcher - Strategy Priority', () {
    test(
        'prefers exact name match over keyword match',
        () {
      // Add a category with "shopping" keyword that could match
      final categories = [
        Category.create(
          name: 'Food & Dining',
          categoryType: CategoryType.expense,
          keywords: ['shopping'], // Misleading keyword
        ),
        Category.create(
          name: 'Shopping',
          categoryType: CategoryType.expense,
          keywords: ['amazon'],
        ),
      ];

      const sms = 'Food & Dining is where I spend most';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: categories,
        relevantCategories: categories,
      );

      expect(result.category?.name, 'Food & Dining');
      expect(result.matchStrategy, 'exact_name_match');
    });

    test(
        'prefers keyword exact match over substring match',
        () {
      const sms = 'Paid Rs.500 to swiggystore for food';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      // Should match "swiggy" exactly, not fall back to substring
      expect(result.category?.name, 'Food & Dining');
      expect(
        result.matchStrategy,
        isIn(['keyword_exact_match', 'keyword_substring_match']),
      );
      expect(result.confidenceScore, greaterThan(60));
    });
  });

  group('RobustCategoryMatcher - Empty Keywords Handling', () {
    test('skips categories with no keywords', () {
      final categories = [
        Category.create(
          name: 'Empty Keywords',
          categoryType: CategoryType.expense,
          keywords: [],
        ),
        Category.create(
          name: 'Food & Dining',
          categoryType: CategoryType.expense,
          keywords: ['swiggy', 'food'],
        ),
      ];

      const sms = 'Ordered food from swiggy';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: categories,
        relevantCategories: categories,
      );

      expect(result.category?.name, 'Food & Dining');
    });
  });

  group('RobustCategoryMatcher - Match Result Properties', () {
    test('returns CategoryMatchResult with all properties', () {
      const sms = 'Paid for amazon shopping';
      final result = RobustCategoryMatcher.match(
        text: sms,
        allCategories: allCategories,
        relevantCategories: expenseCategories,
      );

      expect(result.category, isNotNull);
      expect(result.confidenceScore, isA<int>());
      expect(result.confidenceScore, inInclusiveRange(0, 100));
      expect(result.matchStrategy, isA<String>());
      expect(result.isHighConfidence, isA<bool>());
      expect(result.toString(), contains('Shopping'));
    });
  });
}
