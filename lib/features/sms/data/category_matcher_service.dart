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
    // Extract actual merchant/payee name from SMS patterns
    final merchant = _extractMerchantFromSms(smsBody);
    if (merchant != null) return merchant;

    // No keyword-based fallback — substring matching produces false positives
    return null;
  }

  static String? _extractMerchantFromSms(String smsBody) {
    // UPI VPA pattern: "to VPA suraj@okaxis" → extract name part
    final vpaMatch = RegExp(
      r'(?:to|from)\s+VPA\s+([a-zA-Z0-9._]+)@',
      caseSensitive: false,
    ).firstMatch(smsBody);
    if (vpaMatch != null) {
      return _humanizeName(vpaMatch.group(1)!);
    }

    // "to/from Name" pattern for UPI — captures multi-word names
    // e.g. "paid to Suraj Mondal" or "received from Suraj Mondal"
    final nameMatch = RegExp(
      r'(?:paid\s+to|sent\s+to|received\s+from|transferred\s+to|from)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){0,3})',
    ).firstMatch(smsBody);
    if (nameMatch != null) {
      final name = nameMatch.group(1)!.trim();
      // Filter out common false positives
      if (!_isNoiseName(name)) return name;
    }

    // "at MERCHANT" pattern for card/POS (cap at 5 words to avoid garbage)
    // e.g. "debited at Amazon" or "spent at Swiggy"
    final atMatch = RegExp(
      r'(?:at|At)\s+([A-Za-z][A-Za-z0-9]+(?:\s+[A-Za-z0-9&\-]+){0,4})(?:\s+on|\s+Ref|\.|\s*$)',
    ).firstMatch(smsBody);
    if (atMatch != null) {
      final name = atMatch.group(1)!.trim();
      if (!_isNoiseName(name)) return name;
    }

    return null;
  }

  static final _noiseNames = {
    'bank',
    'a/c',
    'account',
    'inr',
    'rs',
    'upi',
    'neft',
    'imps',
    'rtgs',
    'ref',
    'avl',
    'bal',
    'your',
    'the',
    'for',
  };

  static bool _isNoiseName(String name) {
    final lower = name.toLowerCase();
    return name.length < 2 ||
        _noiseNames.contains(lower) ||
        RegExp(r'^\d').hasMatch(name) ||
        RegExp(r'^(INR|RS|USD|EUR|GBP|AED)\b', caseSensitive: false)
            .hasMatch(name);
  }

  static String _humanizeName(String vpaId) {
    // "suraj.mondal" → "Suraj Mondal"
    return vpaId
        .replaceAll(RegExp(r'[._]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String? detectPaymentType(String smsBody) {
    final bodyLower = smsBody.toLowerCase();

    if (bodyLower.contains('upi') || bodyLower.contains('vpa')) {
      return PaymentType.upi;
    }
    if (bodyLower.contains('card') ||
        bodyLower.contains('credit') ||
        bodyLower.contains('debit')) {
      return PaymentType.card;
    }
    if (bodyLower.contains('netbanking') || bodyLower.contains('net banking')) {
      return PaymentType.netBanking;
    }
    if (bodyLower.contains('wallet') ||
        bodyLower.contains('paytm') ||
        bodyLower.contains('phonepe')) {
      return PaymentType.wallet;
    }

    return null;
  }

  static Category? matchCategory(
    String smsBody,
    List<Category> categories,
    bool? isIncome,
  ) {
    final bodyLower = smsBody.toLowerCase();

    // Filter by type when known; otherwise consider both income and expense categories.
    final validCategories = isIncome == null
        ? categories.toList()
        : categories.where((c) => c.categoryType ==
            (isIncome ? CategoryType.income : CategoryType.expense),).toList();

    // Keyword matching with scoring (prioritize longer, more specific keywords)
    Category? bestMatch;
    int maxScore = 0;

    for (final category in validCategories) {
      if (category.keywords == null || category.keywords!.isEmpty) continue;

      int score = 0;
      int exactMatches = 0;
      int wordMatches = 0;

      for (final keyword in category.keywords!) {
        final keywordLower = keyword.toLowerCase();
        if (bodyLower.contains(keywordLower)) {
          // Longer keywords = more specific = higher score
          score += keywordLower.length * 2;

          // Bonus for exact word match (not just substring)
          if (RegExp(r'\b' + RegExp.escape(keywordLower) + r'\b')
              .hasMatch(bodyLower)) {
            score += 15; // Increased from 10
            exactMatches++;
            wordMatches++;
          } else {
            wordMatches++;
          }
        }
      }

      // Require at least 1 exact match for consideration
      if (exactMatches < 1 && wordMatches < 1) continue;

      // Additional penalty for common false positive categories like "subscription"
      if (category.name.toLowerCase().contains('subscription') ||
          category.name.toLowerCase().contains('service')) {
        score = (score * 0.7).round(); // 30% penalty
      }

      if (score > maxScore && score >= 20) { // Minimum threshold
        maxScore = score;
        bestMatch = category;
      }
    }

    return bestMatch;
  }
}
