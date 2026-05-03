import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/category_noise_words.dart';

/// Result of category matching with confidence and strategy info
class CategoryMatchResult {
  final Category? category;
  final int confidenceScore; // 0-100
  final String matchStrategy; // Name of the strategy that matched
  final bool isHighConfidence; // >= 70

  CategoryMatchResult({
    required this.category,
    required this.confidenceScore,
    required this.matchStrategy,
  }) : isHighConfidence = confidenceScore >= 70;

  @override
  String toString() =>
      'Match(${category?.name ?? "None"}, score=$confidenceScore, strategy=$matchStrategy)';
}

/// Robust category matcher with layered fallback strategies
class RobustCategoryMatcher {
  /// Match text to a category using multiple strategies with fallback
  static CategoryMatchResult match({
    required String text,
    required List<Category> allCategories,
    required List<Category> relevantCategories,
    double? amount,
    bool? isIncome,
  }) {
    if (text.trim().isEmpty) {
      return _applyDefaultFallback(
        relevantCategories.isEmpty ? allCategories : relevantCategories,
        amount,
      );
    }

    if (relevantCategories.isEmpty) {
      return _applyDefaultFallback(allCategories, amount);
    }

    // Strategy 1: Exact category name match (highest priority)
    final exactNameResult = _tryExactNameMatch(text, relevantCategories);
    if (exactNameResult.category != null) {
      return exactNameResult;
    }

    // Strategy 2: Keyword exact word boundary matching
    final keywordExactResult = _tryKeywordExactMatch(text, relevantCategories);
    if (keywordExactResult.category != null) {
      return keywordExactResult;
    }

    // Strategy 3: Keyword substring matching (less strict)
    final keywordSubstringResult =
        _tryKeywordSubstringMatch(text, relevantCategories);
    if (keywordSubstringResult.category != null) {
      return keywordSubstringResult;
    }

    // Strategy 4: Amount-based heuristics (for common patterns)
    final amountBasedResult = amount != null
        ? _tryAmountBasedMatch(text, relevantCategories, amount)
        : null;
    if (amountBasedResult?.category != null) {
      return amountBasedResult!;
    }

    // Strategy 5: Default fallback
    return _applyDefaultFallback(relevantCategories, amount);
  }

  /// Strategy 1: Exact category name match
  static CategoryMatchResult _tryExactNameMatch(
    String text,
    List<Category> categories,
  ) {
    final textLower = text.toLowerCase();
    for (final category in categories) {
      if (textLower.contains(category.name.toLowerCase())) {
        return CategoryMatchResult(
          category: category,
          confidenceScore: 95, // Very high confidence
          matchStrategy: 'exact_name_match',
        );
      }
    }
    return CategoryMatchResult(
      category: null,
      confidenceScore: 0,
      matchStrategy: 'exact_name_match',
    );
  }

  /// Strategy 2: Keyword exact word boundary matching (highest quality)
  static CategoryMatchResult _tryKeywordExactMatch(
    String text,
    List<Category> categories,
  ) {
    final textLower = text.toLowerCase();
    Category? bestMatch;
    int maxScore = 0;

    for (final category in categories) {
      if (category.keywords == null || category.keywords!.isEmpty) continue;

      int score = 0;
      int matches = 0;

      for (final keyword in category.keywords!) {
        final keywordLower = keyword.toLowerCase();
        if (kCategoryNoiseWords.contains(keywordLower)) continue;
        if (_hasWordBoundaryMatch(textLower, keywordLower)) {
          score += keywordLower.length * 3;
          matches++;
        }
      }

      if (matches > 0 && score > maxScore) {
        maxScore = score;
        bestMatch = category;
      }
    }

    if (bestMatch != null) {
      return CategoryMatchResult(
        category: bestMatch,
        confidenceScore: (80 + (maxScore ~/ 10).clamp(0, 20)),
        matchStrategy: 'keyword_exact_match',
      );
    }

    return CategoryMatchResult(
      category: null,
      confidenceScore: 0,
      matchStrategy: 'keyword_exact_match',
    );
  }

  /// Strategy 3: Keyword substring matching (more permissive)
  static CategoryMatchResult _tryKeywordSubstringMatch(
    String text,
    List<Category> categories,
  ) {
    final textLower = text.toLowerCase();
    Category? bestMatch;
    int maxScore = 0;

    for (final category in categories) {
      if (category.keywords == null || category.keywords!.isEmpty) continue;

      int score = 0;
      int matches = 0;

      for (final keyword in category.keywords!) {
        final keywordLower = keyword.toLowerCase();
        if (kCategoryNoiseWords.contains(keywordLower)) continue;

        if (textLower.contains(keywordLower)) {
          score += keywordLower.length * 2;
          matches++;
        }
      }

      if (matches > 0 && score > maxScore) {
        maxScore = score;
        bestMatch = category;
      }
    }

    if (bestMatch != null) {
      final confidenceScore =
          (60 + (maxScore ~/ 10).clamp(0, 15)).clamp(0, 100);
      return CategoryMatchResult(
        category: bestMatch,
        confidenceScore: confidenceScore,
        matchStrategy: 'keyword_substring_match',
      );
    }

    return CategoryMatchResult(
      category: null,
      confidenceScore: 0,
      matchStrategy: 'keyword_substring_match',
    );
  }

  /// Strategy 4: Amount-based heuristics for common patterns
  static CategoryMatchResult? _tryAmountBasedMatch(
    String text,
    List<Category> categories,
    double amount,
  ) {
    final textLower = text.toLowerCase();

    // Very small amounts (< 100) often go to food/coffee
    if (amount < 100 &&
        (textLower.contains('food') ||
            textLower.contains('coffee') ||
            textLower.contains('restaurant'))) {
      final match = categories
          .where(
            (c) =>
                c.name.toLowerCase().contains('food') ||
                c.name.toLowerCase().contains('dining'),
          )
          .firstOrNull;
      if (match != null) {
        return CategoryMatchResult(
          category: match,
          confidenceScore: 50,
          matchStrategy: 'amount_based_heuristic',
        );
      }
    }

    // Round amounts (10, 50, 100, 500, 1000, 5000) often go to transfers/utilities
    const roundAmounts = {10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000};
    if (roundAmounts.contains(amount.toInt())) {
      final match = categories
          .where(
            (c) =>
                c.name.toLowerCase().contains('transfer') ||
                c.name.toLowerCase().contains('utility'),
          )
          .firstOrNull;
      if (match != null) {
        return CategoryMatchResult(
          category: match,
          confidenceScore: 45,
          matchStrategy: 'amount_based_heuristic',
        );
      }
    }

    return null;
  }

  /// Strategy 5: Default fallback (catch-all)
  static CategoryMatchResult _applyDefaultFallback(
    List<Category> categories,
    double? amount,
  ) {
    if (categories.isEmpty) {
      return CategoryMatchResult(
        category: null,
        confidenceScore: 0,
        matchStrategy: 'no_categories_available',
      );
    }

    // Try to find "Others", "Miscellaneous", or "General"
    const fallbackNames = [
      'others',
      'other',
      'miscellaneous',
      'misc',
      'general',
      'uncategorized',
    ];

    for (final name in fallbackNames) {
      final match = categories
          .where((c) => c.name.toLowerCase() == name)
          .firstOrNull;
      if (match != null) {
        return CategoryMatchResult(
          category: match,
          confidenceScore: 30,
          matchStrategy: 'default_fallback',
        );
      }
    }

    // Last resort: return first category
    return CategoryMatchResult(
      category: categories.first,
      confidenceScore: 20,
      matchStrategy: 'last_resort_fallback',
    );
  }

  /// Word boundary match that handles keywords with special characters.
  /// `\b` only works at word-char boundaries — fails for keywords like
  /// "food & dining" or "e-wallet". This checks the chars before/after
  /// the match instead.
  static bool _hasWordBoundaryMatch(String text, String keyword) {
    var start = 0;
    while (true) {
      final idx = text.indexOf(keyword, start);
      if (idx == -1) return false;

      final before = idx > 0 ? text[idx - 1] : ' ';
      final afterIdx = idx + keyword.length;
      final after = afterIdx < text.length ? text[afterIdx] : ' ';

      if (_isNonWord(before) && _isNonWord(after)) return true;
      start = idx + 1;
    }
  }

  static bool _isNonWord(String ch) =>
      !RegExp(r'[a-zA-Z0-9]').hasMatch(ch);
}
