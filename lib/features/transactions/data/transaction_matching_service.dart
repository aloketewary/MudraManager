import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/utils/robust_category_matcher.dart';
import 'package:mudra_manager/features/transactions/data/models/pending_transaction_data.dart';

/// Account-number comparison boundary for SMS and transaction matching.
/// Uses accountSuffixHash first. Plaintext fallback is allowed only for legacy values
/// already resolved by caller; ciphertext and safe display values never match.
class AccountMatchingBoundary {
  static bool matches(Account account, String? accountToken) {
    final token = accountToken?.trim();
    if (token == null || token.isEmpty) return false;
    if (account.matchesSuffix(token)) return true;

    final stored = account.accountNumber?.trim();
    if (stored == null ||
        stored.isEmpty ||
        stored.startsWith('ENC:') ||
        stored.startsWith('••••') ||
        stored.startsWith('****')) {
      return false;
    }

    final suffix =
        token.length <= 4 ? token : token.substring(token.length - 4);
    return stored.length >= suffix.length && stored.endsWith(suffix);
  }

  static Account? firstMatch(
    Iterable<Account> accounts,
    String? accountToken, {
    bool activeOnly = false,
  }) {
    return accounts
        .where((account) => !activeOnly || account.isActive)
        .where((account) => matches(account, accountToken))
        .firstOrNull;
  }
}

class TransactionMatchingService {
  static final _log = AppLog(getLogger(), 'TxnMatching');

  /// Matches a pending transaction to an account and category using various strategies.
  /// If [preMatchedCategory] is provided, skips category matching and uses it directly.
  static MatchingResult? matchTransaction({
    required PendingTransactionData pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
    db_category.Category? preMatchedCategory,
  }) {
    final account = pending.account;
    final isIncome = pending.isIncome;
    final body = pending.body;
    final amount = pending.amount;
    final fromBank = pending.fromBank;

    if (account == null || account.isEmpty) {
      _log.d('No account number in pending transaction');
      return null;
    }

    // 1. Match suffix metadata first. Legacy plaintext is only compared inside
    // this boundary; ciphertext and masked provider values fail closed.
    final matchedAccount = AccountMatchingBoundary.firstMatch(
      accounts,
      account,
    );

    // Fallback: Match by bank name for credit cards
    Account? selectedAccount = matchedAccount;
    if (selectedAccount == null && fromBank != null) {
      for (var acc in accounts) {
        if (acc.accountType == AccountType.creditCard &&
            acc.name.toLowerCase().contains(fromBank.toLowerCase())) {
          selectedAccount = acc;
          _log.i('Account matched by bank fallback');
          break;
        }
      }
    }

    if (selectedAccount == null) {
      _log.d('No matching account found');
      return null;
    }

    // 2. Use pre-matched category or find one
    if (preMatchedCategory != null) {
      _log.i('Using pre-matched category: ${preMatchedCategory.name}');
      return MatchingResult(
          account: selectedAccount, category: preMatchedCategory,);
    }

    // 3. Filter categories by type (income/expense)
    final relevantCategories = categories
        .where(
          (c) =>
              (isIncome == true &&
                  c.categoryType == db_category.CategoryType.income) ||
              (isIncome == false &&
                  c.categoryType == db_category.CategoryType.expense),
        )
        .toList();

    if (relevantCategories.isEmpty) {
      _log.d(
          'No relevant categories found for type: ${(isIncome ?? false) ? "income" : "expense"}',);
      return null;
    }

    // 4. Try robust category matching with confidence scoring
    final matchResult = RobustCategoryMatcher.match(
      text: body,
      allCategories: categories,
      relevantCategories: relevantCategories,
      amount: amount,
      isIncome: isIncome,
    );

    db_category.Category? matchedCategory = matchResult.category;

    // Log the matching strategy and confidence
    if (matchedCategory != null) {
      _log.i(
          'Category matched: ${matchedCategory.name} (${matchResult.confidenceScore}% confidence via ${matchResult.matchStrategy})',);
    }

    // 5. Fallback with smart logic based on amount
    matchedCategory ??= CategoryMatcher.getFallbackCategory(
      relevantCategories,
      amount,
    );

    if (matchedCategory != null) {
      _log.i('Category matched: ${matchedCategory.name}');
    }

    if (matchedCategory != null) {
      return MatchingResult(
          account: selectedAccount, category: matchedCategory,);
    }

    return null;
  }
}

class MatchingResult {
  final Account account;
  final db_category.Category category;
  MatchingResult({required this.account, required this.category});
}
