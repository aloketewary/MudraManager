import 'package:mudra_manager/core/db/models/category.dart';

class PaymentType {
  static const upi = 'UPI';
  static const card = 'Card';
  static const netBanking = 'Net Banking';
  static const wallet = 'Wallet';
  static const cash = 'Cash';
}

class CategoryMatcherService {
  static String? detectMerchant(String smsBody, List<Category> categories) {
    final bodyLower = smsBody.toLowerCase();
    
    // Check all categories for keyword matches
    for (final category in categories) {
      if (category.keywords == null) continue;
      for (final keyword in category.keywords!) {
        if (bodyLower.contains(keyword.toLowerCase())) {
          return keyword; // Return the matched keyword as merchant name
        }
      }
    }
    return null;
  }

  static String? detectPaymentType(String smsBody) {
    final bodyLower = smsBody.toLowerCase();
    
    if (bodyLower.contains('upi') || bodyLower.contains('vpa')) {
      return PaymentType.upi;
    }
    if (bodyLower.contains('card') || bodyLower.contains('credit') || bodyLower.contains('debit')) {
      return PaymentType.card;
    }
    if (bodyLower.contains('netbanking') || bodyLower.contains('net banking')) {
      return PaymentType.netBanking;
    }
    if (bodyLower.contains('wallet') || bodyLower.contains('paytm') || bodyLower.contains('phonepe')) {
      return PaymentType.wallet;
    }
    
    return null;
  }

  static Category? matchCategory(
    String smsBody,
    List<Category> categories,
    bool isIncome,
  ) {
    final bodyLower = smsBody.toLowerCase();
    final type = isIncome ? CategoryType.income : CategoryType.expense;
    
    // Filter by type
    final validCategories = categories.where((c) => c.categoryType == type).toList();
    
    // Keyword matching with scoring
    Category? bestMatch;
    int maxMatches = 0;
    
    for (final category in validCategories) {
      if (category.keywords == null || category.keywords!.isEmpty) continue;
      
      int matches = 0;
      for (final keyword in category.keywords!) {
        if (bodyLower.contains(keyword.toLowerCase())) {
          matches++;
        }
      }
      
      if (matches > maxMatches) {
        maxMatches = matches;
        bestMatch = category;
      }
    }
    
    return bestMatch;
  }
}
