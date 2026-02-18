import 'package:mudra_manager/core/db/models/category.dart';

class CategoryMatcher {
  static Category? matchByKeywords(String text, List<Category> categories) {
    final lowerText = text.toLowerCase();
    
    for (final category in categories) {
      final keywords = [
        category.name.toLowerCase(),
        ...?category.keywords?.map((k) => k.toLowerCase()),
      ];
      
      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          return category;
        }
      }
    }
    
    return null;
  }

  static Category? getFallbackCategory(List<Category> categories, double? amount) {
    if (categories.isEmpty) return null;
    
    // Return first category as fallback
    return categories.first;
  }
}
