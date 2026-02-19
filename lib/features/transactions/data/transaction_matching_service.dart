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
    if (pending.account == null || pending.account!.isEmpty) {
      debugPrint('No account number in pending transaction');
      return null;
    }

    // 1. Try to find a matching account (match last 4 digits)
    Account? matchedAccount;
    final pendingAccTrimmed = pending.account!.trim();
    debugPrint('Looking for account ending with: $pendingAccTrimmed');
    
    for (var acc in accounts) {
      final dbAccNo = acc.accountNumber?.trim();
      debugPrint('Checking account: ${acc.name} - $dbAccNo');
      if (dbAccNo != null && dbAccNo.endsWith(pendingAccTrimmed)) {
        matchedAccount = acc;
        debugPrint('Account matched: ${acc.name}');
        break;
      }
    }

    if (matchedAccount == null) {
      debugPrint('No matching account found for: $pendingAccTrimmed');
      return null;
    }

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

    if (relevantCategories.isEmpty) {
      debugPrint('No relevant categories found for type: ${(pending.isIncome ?? false) ? "income" : "expense"}');
      return null;
    }

    debugPrint('Found ${relevantCategories.length} relevant categories');

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
    } else {
      debugPrint('Category matched: ${matchedCategory.name}');
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