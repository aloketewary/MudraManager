import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/utils/category_noise_words.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

class _LearnedRuleMatchEvidence {
  const _LearnedRuleMatchEvidence({
    required this.recipientExact,
    required this.recipientPartial,
    required this.merchantExact,
    required this.merchantPartial,
    required this.accountMatch,
    required this.amountMatch,
  });

  final bool recipientExact;
  final bool recipientPartial;
  final bool merchantExact;
  final bool merchantPartial;
  final bool accountMatch;
  final bool amountMatch;

  int get identityTier {
    if (recipientExact || merchantExact) return 3;
    if (recipientPartial || merchantPartial) return 2;
    return 0;
  }

  bool get hasSignal => identityTier > 0 || accountMatch || amountMatch;

  /// Lexicographic specificity: identity, account, then amount.
  int compareTo(_LearnedRuleMatchEvidence other) {
    final identityComparison = identityTier.compareTo(other.identityTier);
    if (identityComparison != 0) return identityComparison;

    final accountComparison =
        (accountMatch ? 1 : 0).compareTo(other.accountMatch ? 1 : 0);
    if (accountComparison != 0) return accountComparison;

    return (amountMatch ? 1 : 0).compareTo(other.amountMatch ? 1 : 0);
  }
}

class CategoryMatcher {
  static const _noiseWords = kCategoryNoiseWords;

  /// Canonical identity used for learned merchant-rule matching.
  static String? normalizeIdentity(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static _LearnedRuleMatchEvidence _matchEvidence(
    TransactionInfo txn,
    CategoryRule rule,
  ) {
    final transactionRecipient = normalizeIdentity(txn.account?.sendTo);
    final transactionMerchant = normalizeIdentity(txn.account?.bankName);
    final ruleRecipient = normalizeIdentity(rule.recipientName);
    final ruleMerchant = normalizeIdentity(rule.merchantName);

    final recipientExact =
        ruleRecipient != null && transactionRecipient == ruleRecipient;
    final merchantExact =
        ruleMerchant != null && transactionMerchant == ruleMerchant;
    final recipientPartial = !recipientExact &&
        ruleRecipient != null &&
        transactionRecipient != null &&
        transactionRecipient.contains(ruleRecipient);
    final merchantPartial = !merchantExact &&
        ruleMerchant != null &&
        transactionMerchant != null &&
        transactionMerchant.contains(ruleMerchant);

    final transactionAccount = txn.account?.no?.trim();
    final ruleAccount = rule.accountNumber?.trim();
    final accountMatch = transactionAccount != null &&
        transactionAccount.isNotEmpty &&
        ruleAccount != null &&
        ruleAccount.isNotEmpty &&
        transactionAccount == ruleAccount;

    final amount = double.tryParse(txn.money ?? '');
    final amountMin = rule.amountMin;
    final amountMax = rule.amountMax;
    final amountMatch = amount != null &&
        amount.isFinite &&
        amountMin != null &&
        amountMax != null &&
        amountMin.isFinite &&
        amountMax.isFinite &&
        amountMin <= amountMax &&
        amount >= amountMin &&
        amount <= amountMax;

    return _LearnedRuleMatchEvidence(
      recipientExact: recipientExact,
      recipientPartial: recipientPartial,
      merchantExact: merchantExact,
      merchantPartial: merchantPartial,
      accountMatch: accountMatch,
      amountMatch: amountMatch,
    );
  }

  static Category? matchByKeywords(String text, List<Category> categories) {
    if (text.trim().isEmpty || categories.isEmpty) return null;
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
        if (_noiseWords.contains(keyword)) continue;
        if (!lowerText.contains(keyword)) continue;

        // Longer keywords = more specific = higher score
        score += keyword.length * 2;

        // Bonus for exact word boundary match (not just substring)
        if (RegExp(r'\b' + RegExp.escape(keyword) + r'\b')
            .hasMatch(lowerText)) {
          score += 10;
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
    List<Category> categories,
    double? amount,
  ) {
    if (categories.isEmpty) return null;

    // Try to find "Others" or "Miscellaneous" category
    final fallbackNames = [
      'others',
      'other',
      'miscellaneous',
      'misc',
      'general',
    ];
    for (final name in fallbackNames) {
      final match =
          categories.where((c) => c.name.toLowerCase() == name).firstOrNull;
      if (match != null) return match;
    }

    // Return first category as last resort
    return categories.first;
  }

  /// Returns most specific eligible learned rule, or null when no rule can
  /// safely provide an automatic category suggestion.
  static CategoryRule? findBestLearnedRule(
    TransactionInfo txn,
    List<CategoryRule> rules, {
    Set<String>? availableCategoryIds,
  }) {
    CategoryRule? bestMatch;
    _LearnedRuleMatchEvidence? bestEvidence;

    for (final rule in rules) {
      if (rule.confidence <= 40 || rule.categoryId.trim().isEmpty) continue;
      if (availableCategoryIds != null &&
          !availableCategoryIds.contains(rule.categoryId)) {
        continue;
      }

      final evidence = _matchEvidence(txn, rule);
      if (!evidence.hasSignal) continue;

      if (bestMatch == null ||
          _compareLearnedRules(
                rule,
                evidence,
                bestMatch,
                bestEvidence!,
              ) >
              0) {
        bestMatch = rule;
        bestEvidence = evidence;
      }
    }

    return bestMatch;
  }

  /// Learned-rule precedence gate. Does not invoke generic matching.
  static String? suggestCategoryFromRules(
    TransactionInfo txn,
    List<CategoryRule> rules, {
    Set<String>? availableCategoryIds,
  }) {
    return findBestLearnedRule(
      txn,
      rules,
      availableCategoryIds: availableCategoryIds,
    )?.categoryId;
  }

  static int _compareLearnedRules(
    CategoryRule candidate,
    _LearnedRuleMatchEvidence candidateEvidence,
    CategoryRule current,
    _LearnedRuleMatchEvidence currentEvidence,
  ) {
    final specificityComparison = candidateEvidence.compareTo(currentEvidence);
    if (specificityComparison != 0) return specificityComparison;

    final confidenceComparison =
        candidate.confidence.compareTo(current.confidence);
    if (confidenceComparison != 0) return confidenceComparison;

    final matchCountComparison =
        candidate.matchCount.compareTo(current.matchCount);
    if (matchCountComparison != 0) return matchCountComparison;

    // Stable key intentionally excludes lastUsed. Lower key wins ties.
    return _canonicalRuleKey(current).compareTo(_canonicalRuleKey(candidate));
  }

  static String _canonicalRuleKey(CategoryRule rule) {
    return [
      normalizeIdentity(rule.recipientName) ?? '',
      normalizeIdentity(rule.merchantName) ?? '',
      rule.accountNumber?.trim() ?? '',
      rule.categoryId,
      rule.id.toString(),
    ].join('\u0000');
  }

  /// Creates or updates a rule when user categorizes a transaction.
  ///
  /// Identity lookup uses the same canonical representation as learned-rule
  /// matching. Existing rule metadata remains intact apart from learning
  /// counters, category correction, and maintenance timestamp.
  static CategoryRule createOrUpdateRule(
    TransactionInfo txn,
    String categoryId,
    List<CategoryRule> existingRules,
  ) {
    final recipient = normalizeIdentity(txn.account?.sendTo);
    final merchant = normalizeIdentity(txn.account?.bankName);
    final account = _normalizeAccount(txn.account?.no);

    // Preserve recipient-first lookup when both identities are present. This
    // avoids list-order-dependent updates when separate rules match each
    // identity, while still collapsing case/whitespace variants into one rule.
    CategoryRule? existing;
    if (recipient != null) {
      for (final rule in existingRules) {
        if (normalizeIdentity(rule.recipientName) == recipient) {
          existing = rule;
          break;
        }
      }
    }
    if (existing == null && merchant != null) {
      for (final rule in existingRules) {
        if (normalizeIdentity(rule.merchantName) == merchant) {
          existing = rule;
          break;
        }
      }
    }

    if (existing != null) {
      existing.matchCount++;
      existing.confidence = (existing.confidence + 10).clamp(0, 100).toInt();
      existing.lastUsed = DateTime.now();
      existing.categoryId = categoryId;
      return existing;
    }

    return CategoryRule(
      recipientName: recipient,
      merchantName: merchant,
      accountNumber: account,
      categoryId: categoryId,
      matchCount: 1,
      confidence: 50,
    );
  }

  static String? _normalizeAccount(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
