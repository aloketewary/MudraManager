import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';

class TransactionMatchingService {
  /// Matches a pending transaction to an account and category using various strategies.
  static MatchingResult? matchTransaction({
    required PendingTransaction pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) {
    if (pending.account == null || pending.account!.isEmpty) return null;

    // 1. Try to find a matching account (match last 4 digits)
    Account? matchedAccount;
    final pendingAccTrimmed = pending.account!.trim();
    for (var acc in accounts) {
      final dbAccNo = acc.accountNumber?.trim();
      if (dbAccNo != null && dbAccNo.endsWith(pendingAccTrimmed)) {
        matchedAccount = acc;
        break;
      }
    }

    if (matchedAccount == null) return null;

    // 2. Filter categories by type (income/expense)
    final relevantCategories =
        categories
            .where(
              (c) =>
                  (pending.isIncome == true &&
                      c.categoryType == db_category.CategoryType.income) ||
                  (pending.isIncome == false &&
                      c.categoryType == db_category.CategoryType.expense),
            )
            .toList();

    if (relevantCategories.isEmpty) return null;

    // 3. Try keyword-based matching
    db_category.Category? matchedCategory = CategoryMatcher.matchByKeywords(
      pending.body,
      relevantCategories,
    );

    // 4. Fallback with smart logic based on amount
    matchedCategory ??= CategoryMatcher.getFallbackCategory(
      relevantCategories,
      pending.amount,
    );

    // 5. Debug logging
    if (matchedCategory == null) {
      debugPrint(
        'No category match for: ${pending.body.substring(0, pending.body.length > 50 ? 50 : pending.body.length)}... '
        '(Amount: ${pending.amount}, Sender: ${pending.sender})',
      );
    }

    if (matchedCategory != null) {
      return MatchingResult(account: matchedAccount, category: matchedCategory);
    }

    return null;
  }
}

class MatchingResult {
  final Account account;
  final db_category.Category category;
  MatchingResult({required this.account, required this.category});
}