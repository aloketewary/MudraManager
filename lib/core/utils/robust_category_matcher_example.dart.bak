// Example usage of RobustCategoryMatcher

import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/robust_category_matcher.dart';

// ── Example 1: Basic SMS category matching ──
void exampleBasicUsage(List<Category> allCategories) {
  const smsBody = 'Rs.500 spent on Swiggy for food delivery';
  const amount = 500.0;
  const isIncome = false;

  final expenseCategories = allCategories
      .where((c) => c.categoryType == CategoryType.expense)
      .toList();

  final result = RobustCategoryMatcher.match(
    text: smsBody,
    allCategories: allCategories,
    relevantCategories: expenseCategories,
    amount: amount,
    isIncome: isIncome,
  );

  print('Category: ${result.category?.name}');
  print('Confidence: ${result.confidenceScore}% (${result.isHighConfidence ? "HIGH" : "LOW"})');
  print('Strategy: ${result.matchStrategy}');
  // Output:
  // Category: Food & Dining
  // Confidence: 85% (HIGH)
  // Strategy: keyword_exact_match
}

// ── Example 2: Using confidence for decision-making ──
void exampleConfidenceThreshold(
  String smsBody,
  List<Category> allCategories,
) {
  final expenseCategories = allCategories
      .where((c) => c.categoryType == CategoryType.expense)
      .toList();

  final result = RobustCategoryMatcher.match(
    text: smsBody,
    allCategories: allCategories,
    relevantCategories: expenseCategories,
  );

  if (result.confidenceScore >= 70) {
    // Auto-approve with high-confidence category
    _approveTransaction(result.category!);
  } else if (result.confidenceScore >= 40) {
    // Suggest category but require user review
    _suggestAndReview(result.category!, result.confidenceScore);
  } else {
    // Low confidence, mark for manual review
    _markForManualReview(result.category!);
  }
}

// ── Example 3: Fallback always returns a valid result ──
void exampleGuaranteedResult(
  String ambiguousText,
  List<Category> categories,
) {
  final result = RobustCategoryMatcher.match(
    text: ambiguousText,
    allCategories: categories,
    relevantCategories: categories,
  );

  // result.category is NEVER null, even for ambiguous text
  // It will use fallback strategies to provide a reasonable default
  print('Matched: ${result.category?.name} (confidence: ${result.confidenceScore}%)');

  // You can check the strategy to understand how it matched:
  if (result.matchStrategy == 'default_fallback') {
    // User should review this categorization
    _flagForReview(result);
  }
}

// ── Example 4: Integration with SMS Activity Service ──
// In sms_activity_service.dart, you could use it like:
Future<String?> getSuggestedCategory(
  String smsBody,
  List<Category> allCategories,
  bool? isIncome,
) async {
  final relevantCategories = allCategories
      .where((c) => isIncome == null ||
          (isIncome && c.categoryType == CategoryType.income) ||
          (!isIncome && c.categoryType == CategoryType.expense))
      .toList();

  final result = RobustCategoryMatcher.match(
    text: smsBody,
    allCategories: allCategories,
    relevantCategories: relevantCategories,
    isIncome: isIncome,
  );

  // Only return category if confidence is sufficiently high
  return result.confidenceScore >= 50 ? result.category?.name : null;
}

// ── Example 5: Confidence Thresholds ──
// Recommended thresholds:
const thresholds = {
  'autoApprove': 75, // Automatically categorize without review
  'suggest': 50, // Suggest but require confirmation
  'manualReview': 30, // Flag for manual categorization
  'fallback': 0, // Always has a fallback category
};

// Usage:
void processTransaction(
  String description,
  List<Category> categories,
) {
  final result = RobustCategoryMatcher.match(
    text: description,
    allCategories: categories,
    relevantCategories: categories,
  );

  switch (result.confidenceScore) {
    case >= thresholds['autoApprove']!:
      _autoApprove(result.category!);
    case >= thresholds['suggest']!:
      _suggestCategory(result.category!, result.confidenceScore);
    case >= thresholds['manualReview']!:
      _flagForReview(result.category!);
    default:
      _useDefaultCategory(result.category!);
  }
}

// ── Example 6: Strategy Analysis ──
// The matcher provides strategy information for debugging:
void analyzeMatchingStrategy(
  String text,
  List<Category> categories,
) {
  final result = RobustCategoryMatcher.match(
    text: text,
    allCategories: categories,
    relevantCategories: categories,
  );

  final strategies = {
    'exact_name_match': 'Category name found in text (highest quality)',
    'keyword_exact_match': 'Keyword with exact word boundaries matched',
    'keyword_substring_match':
        'Keyword found as substring (may have false positives)',
    'amount_based_heuristic':
        'Matched using amount patterns (low confidence)',
    'default_fallback': 'Using default category (no matches found)',
    'last_resort_fallback': 'Single category available (worst case)',
    'no_categories_available': 'No categories provided',
  };

  print('Match Strategy: ${result.matchStrategy}');
  print('Details: ${strategies[result.matchStrategy]}');
  print('Confidence: ${result.confidenceScore}%');
  print('Result: ${result.category?.name ?? "None"}');
}

// ── Mock functions for examples ──
void _approveTransaction(Category category) =>
    print('Auto-approved with category: ${category.name}');
void _suggestAndReview(Category category, int confidence) =>
    print('Suggested: ${category.name} ($confidence% confidence)');
void _markForManualReview(Category category) =>
    print('Marked for review: ${category.name}');
void _flagForReview(CategoryMatchResult result) =>
    print('Flagged for review: ${result.category?.name}');
void _useDefaultCategory(Category category) =>
    print('Using default: ${category.name}');
