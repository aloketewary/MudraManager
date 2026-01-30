import 'package:mudra_manager/db/models/category.dart' as db_category;

class CategoryMatcher {
  static final Map<String, List<String>> defaultKeywords = {
    'food': [
      'swiggy',
      'zomato',
      'uber eats',
      'dominos',
      'mcdonald',
      'kfc',
      'pizza',
      'restaurant',
      'cafe',
      'food',
      'dining',
      'burger',
      'biryani',
      'meal',
    ],
    'transport': [
      'uber',
      'ola',
      'rapido',
      'petrol',
      'fuel',
      'parking',
      'toll',
      'metro',
      'bus',
      'taxi',
      'cab',
      'auto',
      'bike',
      'car',
    ],
    'shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'meesho',
      'shopping',
      'mall',
      'store',
      'retail',
      'purchase',
    ],
    'bill': [
      'electricity',
      'water',
      'gas',
      'internet',
      'broadband',
      'mobile recharge',
      'dth',
      'bill payment',
      'utility',
      'airtel',
      'jio',
      'vodafone',
      'bsnl',
    ],
    'entertainment': [
      'netflix',
      'prime',
      'hotstar',
      'spotify',
      'youtube',
      'movie',
      'cinema',
      'pvr',
      'inox',
      'gaming',
      'subscription',
    ],
    'health': [
      'pharmacy',
      'hospital',
      'doctor',
      'medicine',
      'apollo',
      'medplus',
      'health',
      'clinic',
      'medical',
      'pharma',
    ],
    'grocery': [
      'bigbasket',
      'grofers',
      'blinkit',
      'zepto',
      'dunzo',
      'grocery',
      'supermarket',
      'dmart',
      'reliance fresh',
      'more',
    ],
    'education': [
      'school',
      'college',
      'university',
      'course',
      'tuition',
      'education',
      'training',
      'udemy',
      'coursera',
      'byju',
    ],
    'investment': [
      'mutual fund',
      'sip',
      'stock',
      'share',
      'zerodha',
      'groww',
      'upstox',
      'investment',
      'trading',
    ],
    'insurance': [
      'insurance',
      'premium',
      'policy',
      'lic',
      'hdfc life',
      'icici prudential',
    ],
    'transfer': [
      'transfer',
      'sent',
      'upi',
      'imps',
      'neft',
      'rtgs',
    ],
    'salary': [
      'salary',
      'credited',
      'income',
      'payment received',
    ],
  };

  static db_category.Category? matchByKeywords(
    String smsBody,
    List<db_category.Category> categories,
  ) {
    if (categories.isEmpty) return null;

    final bodyLower = smsBody.toLowerCase();

    // Try matching with default keywords
    for (var entry in defaultKeywords.entries) {
      final keywordGroup = entry.key;
      final keywords = entry.value;

      for (var keyword in keywords) {
        if (bodyLower.contains(keyword)) {
          // Find category that matches this keyword group
          final cat = categories.cast<db_category.Category?>().firstWhere(
            (c) => c?.name.toLowerCase().contains(keywordGroup) ?? false,
            orElse: () => null,
          );
          if (cat != null) return cat;
        }
      }
    }

    // Fallback: try direct category name matching
    for (var cat in categories) {
      if (bodyLower.contains(cat.name.toLowerCase())) {
        return cat;
      }
    }

    return null;
  }

  static db_category.Category? getFallbackCategory(
    List<db_category.Category> categories,
    double? amount,
  ) {
    if (categories.isEmpty) return null;

    final amt = amount?.abs() ?? 0;

    // Large amounts (>5000) -> likely bills or shopping
    if (amt > 5000) {
      final cat = categories.cast<db_category.Category?>().firstWhere(
        (c) =>
            (c?.name.toLowerCase().contains('bill') ?? false) ||
            (c?.name.toLowerCase().contains('shopping') ?? false),
        orElse: () => null,
      );
      if (cat != null) return cat;
    }

    // Small amounts (<500) -> likely food or transport
    if (amt < 500) {
      final cat = categories.cast<db_category.Category?>().firstWhere(
        (c) =>
            (c?.name.toLowerCase().contains('food') ?? false) ||
            (c?.name.toLowerCase().contains('transport') ?? false),
        orElse: () => null,
      );
      if (cat != null) return cat;
    }

    // Default to "Other" or "Misc"
    final other = categories.cast<db_category.Category?>().firstWhere(
      (c) =>
          (c?.name.toLowerCase().contains('other') ?? false) ||
          (c?.name.toLowerCase().contains('misc') ?? false),
      orElse: () => categories.isNotEmpty ? categories.first : null,
    );

    return other;
  }
}
