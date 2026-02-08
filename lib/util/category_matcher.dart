import 'package:mudra_manager/db/models/category.dart';

class CategoryMatcher {
  static final Map<String, List<String>> defaultKeywords = {
    'Food': [
      'swiggy', 'zomato', 'uber eats', 'dominos', 'mcdonald',
      'kfc', 'pizza', 'restaurant', 'cafe', 'food', 'dining', 'burger', 'coffee', 'meal'
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'petrol', 'fuel', 'parking',
      'toll', 'metro', 'bus', 'taxi', 'cab', 'ride', 'transport'
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho',
      'shopping', 'mall', 'store', 'fashion', 'retail', 'shop'
    ],
    'Bills': [
      'electricity', 'water', 'gas', 'internet', 'broadband',
      'mobile recharge', 'dth', 'bill payment', 'airtel', 'jio', 'vi', 'bsnl', 'bill', 'utility'
    ],
    'Entertainment': [
      'netflix', 'prime', 'hotstar', 'spotify', 'youtube',
      'movie', 'cinema', 'pvr', 'inox', 'bookmyshow', 'entertainment'
    ],
    'Healthcare': [
      'pharmacy', 'hospital', 'doctor', 'medicine', 'apollo',
      'medplus', 'health', 'clinic', 'lab', 'medical'
    ],
    'Grocery': [
      'bigbasket', 'grofers', 'blinkit', 'zepto', 'dunzo',
      'grocery', 'supermarket', 'dmart', 'kirana', 'vegetable', 'fruit', 'veggie', 'groceries'
    ],
  };

  static Category? matchByKeywords(
    String smsBody,
    List<Category> categories,
  ) {
    final bodyLower = smsBody.toLowerCase();

    // First try user-defined keywords
    for (var cat in categories) {
      if (cat.keywords != null) {
        for (var keyword in cat.keywords!) {
          if (bodyLower.contains(keyword.toLowerCase())) {
            return cat;
          }
        }
      }
    }

    // Then try default keywords with flexible category name matching
    for (var entry in defaultKeywords.entries) {
      final categoryName = entry.key;
      final keywords = entry.value;

      for (var keyword in keywords) {
        if (bodyLower.contains(keyword)) {
          // Try exact match first
          try {
            final cat = categories.firstWhere(
              (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
            );
            return cat;
          } catch (_) {}

          // Try partial match (e.g., "Grocery" matches "Groceries")
          try {
            final cat = categories.firstWhere(
              (c) => c.name.toLowerCase().contains(categoryName.toLowerCase().split(' ').first) ||
                     categoryName.toLowerCase().contains(c.name.toLowerCase()),
            );
            return cat;
          } catch (_) {
            // Category with this name doesn't exist in user's DB
            continue;
          }
        }
      }
    }

    return null;
  }

  static Category? getFallbackCategory(List<Category> categories, double? amount) {
    if (categories.isEmpty) return null;
    
    final absAmount = amount?.abs() ?? 0;

    // Large amounts (>5000) -> likely bills or shopping
    if (absAmount > 5000) {
      try {
        return categories.firstWhere(
          (c) => c.name.toLowerCase().contains('bill') ||
                 c.name.toLowerCase().contains('shopping'),
        );
      } catch (_) {}
    }
    // Small amounts (<500) -> likely food or transport
    else if (absAmount < 500) {
      try {
        return categories.firstWhere(
          (c) => c.name.toLowerCase().contains('food') ||
                 c.name.toLowerCase().contains('transport'),
        );
      } catch (_) {}
    }

    // Default to "Other" or "Misc"
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase().contains('other') ||
               c.name.toLowerCase().contains('misc'),
      );
    } catch (_) {
      return categories.first;
    }
  }
}