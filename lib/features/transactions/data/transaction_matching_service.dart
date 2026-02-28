import 'package:flutter/foundation.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class TransactionMatchingService {
  static final _log = AppLog(getLogger(), 'TxnMatching');

  /// Matches a pending transaction to an account and category using various strategies.
  static MatchingResult? matchTransaction({
    required PendingTransaction pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) {
    if (pending.account == null || pending.account!.isEmpty) {
      _log.d('No account number in pending transaction');
      return null;
    }

    // 1. Try to find a matching account (match last 4 digits)
    Account? matchedAccount;
    final pendingAccTrimmed = pending.account!.trim();
    _log.d('Looking for account ending with: $pendingAccTrimmed');
    
    for (var acc in accounts) {
      final dbAccNo = acc.accountNumber?.trim();
      if (dbAccNo != null && dbAccNo.endsWith(pendingAccTrimmed)) {
        matchedAccount = acc;
        _log.i('Account matched: ${acc.name}');
        break;
      }
    }

    // Fallback: Match by bank name for credit cards
    if (matchedAccount == null && pending.fromBank != null) {
      for (var acc in accounts) {
        if (acc.accountType == AccountType.creditCard &&
            acc.name.toLowerCase().contains(pending.fromBank!.toLowerCase())) {
          matchedAccount = acc;
          _log.i('Account matched by bank name: ${acc.name}');
          break;
        }
      }
    }

    if (matchedAccount == null) {
      _log.d('No matching account found for: $pendingAccTrimmed');
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
      _log.d('No relevant categories found for type: ${(pending.isIncome ?? false) ? "income" : "expense"}');
      return null;
    }

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

    if (matchedCategory != null) {
      _log.i('Category matched: ${matchedCategory.name}');
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