import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

class CategoryMatcher {
  static Category? matchByKeywords(String text, List<Category> categories) {
    final lowerText = text.toLowerCase();
    Category? bestMatch;
    int maxScore = 0;

    for (final category in categories) {
      int score = 0;
      final keywords = [
        category.name.toLowerCase(),
        ...?category.keywords?.map((k) => k.toLowerCase()),
      ];

      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          // Longer keywords get higher priority
          score += keyword.length;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestMatch = category;
      }
    }

    return bestMatch;
  }

  static Category? getFallbackCategory(
      List<Category> categories, double? amount) {
    if (categories.isEmpty) return null;

    // Try to find "Others" or "Miscellaneous" category
    final fallbackNames = [
      'others',
      'other',
      'miscellaneous',
      'misc',
      'general'
    ];
    for (final name in fallbackNames) {
      final match =
          categories.where((c) => c.name.toLowerCase() == name).firstOrNull;
      if (match != null) return match;
    }

    // Return first category as last resort
    return categories.first;
  }

  /// Smart category suggestion based on learned rules
  static String? suggestCategoryFromRules(
    TransactionInfo txn,
    List<CategoryRule> rules,
  ) {
    if (rules.isEmpty) return null;

    CategoryRule? bestMatch;
    int highestScore = 0;

    for (final rule in rules) {
      int score = 0;

      // Match recipient name (highest priority)
      if (rule.recipientName != null &&
          txn.account?.sendTo != null &&
          txn.account!.sendTo!
              .toLowerCase()
              .contains(rule.recipientName!.toLowerCase())) {
        score += 50;
      }

      // Match merchant/bank name
      if (rule.merchantName != null &&
          txn.account?.bankName != null &&
          txn.account!.bankName!
              .toLowerCase()
              .contains(rule.merchantName!.toLowerCase())) {
        score += 30;
      }

      // Match account number
      if (rule.accountNumber != null && txn.account?.no == rule.accountNumber) {
        score += 20;
      }

      // Match amount range
      if (rule.amountMin != null &&
          rule.amountMax != null &&
          txn.money != null) {
        final amount = double.tryParse(txn.money!);
        if (amount != null &&
            amount >= rule.amountMin! &&
            amount <= rule.amountMax!) {
          score += 10;
        }
      }

      // Boost by confidence and usage
      score = (score * (rule.confidence / 100)).round();
      score += (rule.matchCount > 5 ? 10 : rule.matchCount * 2);

      if (score > highestScore) {
        highestScore = score;
        bestMatch = rule;
      }
    }

    // Only suggest if confidence is high enough (40% threshold)
    return highestScore >= 40 ? bestMatch?.categoryId : null;
  }

  /// Creates or updates a rule when user categorizes a transaction
  static CategoryRule createOrUpdateRule(
    TransactionInfo txn,
    String categoryId,
    List<CategoryRule> existingRules,
  ) {
    // Try to find existing rule by recipient or merchant
    CategoryRule? existing;

    if (txn.account?.sendTo != null) {
      existing = existingRules
          .where((r) =>
              r.recipientName?.toLowerCase() ==
              txn.account?.sendTo?.toLowerCase())
          .firstOrNull;
    }

    if (existing == null && txn.account?.bankName != null) {
      existing = existingRules
          .where((r) =>
              r.merchantName?.toLowerCase() ==
              txn.account?.bankName?.toLowerCase())
          .firstOrNull;
    }

    if (existing != null) {
      // Update existing rule
      existing.matchCount++;
      existing.confidence = (existing.confidence + 10).clamp(0, 100);
      existing.lastUsed = DateTime.now();
      existing.categoryId = categoryId; // Update category if changed
      return existing;
    }

    // Create new rule
    final rule = CategoryRule(
      recipientName: txn.account?.sendTo,
      merchantName: txn.account?.bankName,
      accountNumber: txn.account?.no,
      categoryId: categoryId,
      matchCount: 1,
      confidence: 50,
    );
    rule.lastUsed = DateTime.now();
    return rule;
  }
}
