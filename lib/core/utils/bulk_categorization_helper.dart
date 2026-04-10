import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

/// Helper for bulk categorization of pending transactions
class BulkCategorizationHelper {
  final CategoryRuleService ruleService;

  BulkCategorizationHelper(this.ruleService);

  /// Groups similar transactions together for bulk categorization
  /// Returns: `Map<String, List<TransactionInfo>>`
  /// Key = grouping identifier (recipient/merchant)
  /// Value = list of similar transactions
  Map<String, List<TransactionInfo>> groupSimilarTransactions(
    List<TransactionInfo> transactions,
  ) {
    final Map<String, List<TransactionInfo>> groups = {};

    for (final txn in transactions) {
      // Create grouping key based on recipient or merchant
      String? groupKey;

      if (txn.account?.sendTo != null && txn.account!.sendTo!.isNotEmpty) {
        // UPI transactions - group by recipient
        groupKey = 'UPI:${txn.account!.sendTo!.toLowerCase()}';
      } else if (txn.account?.bankName != null && txn.account!.bankName!.isNotEmpty) {
        // Non-UPI - group by merchant/bank
        groupKey = 'MERCHANT:${txn.account!.bankName!.toLowerCase()}';
      } else if (txn.account?.no != null && txn.account!.no!.isNotEmpty) {
        // Group by account number
        groupKey = 'ACCOUNT:${txn.account!.no}';
      }

      if (groupKey != null) {
        groups.putIfAbsent(groupKey, () => []);
        groups[groupKey]!.add(txn);
      }
    }

    return groups;
  }

  /// Smart bulk categorization workflow
  /// Returns: Map with categorized and uncategorized transactions
  Future<BulkCategorizationResult> processBulkTransactions(
    List<TransactionInfo> pendingTransactions,
  ) async {
    final result = BulkCategorizationResult();

    // Step 1: Group similar transactions
    final groups = groupSimilarTransactions(pendingTransactions);

    // Step 2: Process each group
    for (final entry in groups.entries) {
      final groupKey = entry.key;
      final transactions = entry.value;

      if (transactions.isEmpty) continue;

      // Get suggestion for first transaction in group
      final firstTxn = transactions.first;
      final suggestedCategoryId = await ruleService.suggestCategory(firstTxn);

      if (suggestedCategoryId != null) {
        // High confidence suggestion exists
        result.autoSuggested[groupKey] = BulkGroup(
          transactions: transactions,
          suggestedCategoryId: suggestedCategoryId,
          recipientName: firstTxn.account?.sendTo ?? firstTxn.account?.bankName,
          count: transactions.length,
        );
      } else {
        // No suggestion - needs manual categorization
        result.needsManualReview[groupKey] = BulkGroup(
          transactions: transactions,
          recipientName: firstTxn.account?.sendTo ?? firstTxn.account?.bankName,
          count: transactions.length,
        );
      }
    }

    return result;
  }

  /// Apply category to all transactions in a group and learn from it
  Future<void> applyCategoryToGroup(
    List<TransactionInfo> transactions,
    String categoryId,
  ) async {
    if (transactions.isEmpty) return;

    // Learn from the first transaction (representative of the group)
    await ruleService.learnFromCategorization(transactions.first, categoryId);

    // The rule is now created/updated
    // All future transactions to this recipient/merchant will be auto-suggested
  }

  /// Get statistics for bulk categorization
  BulkStats getStats(BulkCategorizationResult result) {
    int autoSuggestedCount = 0;
    int needsReviewCount = 0;

    for (final group in result.autoSuggested.values) {
      autoSuggestedCount += group.count;
    }

    for (final group in result.needsManualReview.values) {
      needsReviewCount += group.count;
    }

    return BulkStats(
      totalGroups: result.autoSuggested.length + result.needsManualReview.length,
      autoSuggestedGroups: result.autoSuggested.length,
      needsReviewGroups: result.needsManualReview.length,
      autoSuggestedTransactions: autoSuggestedCount,
      needsReviewTransactions: needsReviewCount,
    );
  }
}

/// Result of bulk categorization
class BulkCategorizationResult {
  // Groups with auto-suggestions (can be bulk-approved)
  Map<String, BulkGroup> autoSuggested = {};

  // Groups needing manual review (no suggestion available)
  Map<String, BulkGroup> needsManualReview = {};
}

/// A group of similar transactions
class BulkGroup {
  final List<TransactionInfo> transactions;
  final String? suggestedCategoryId;
  final String? recipientName;
  final int count;

  BulkGroup({
    required this.transactions,
    this.suggestedCategoryId,
    this.recipientName,
    required this.count,
  });

  double get totalAmount {
    return transactions.fold(0.0, (sum, txn) {
      final amount = double.tryParse(txn.money ?? '0') ?? 0.0;
      return sum + amount;
    });
  }
}

/// Statistics for bulk categorization
class BulkStats {
  final int totalGroups;
  final int autoSuggestedGroups;
  final int needsReviewGroups;
  final int autoSuggestedTransactions;
  final int needsReviewTransactions;

  BulkStats({
    required this.totalGroups,
    required this.autoSuggestedGroups,
    required this.needsReviewGroups,
    required this.autoSuggestedTransactions,
    required this.needsReviewTransactions,
  });

  double get autoSuggestedPercentage {
    final total = autoSuggestedTransactions + needsReviewTransactions;
    return total > 0 ? (autoSuggestedTransactions / total) * 100 : 0;
  }
}

/// EXAMPLE USAGE:
/// 
/// ```dart
/// // Step 1: Scan SMS and get 500+ transactions
/// final pendingTransactions = await scanSMS();
/// 
/// // Step 2: Process bulk
/// final bulkHelper = BulkCategorizationHelper(categoryRuleService);
/// final result = await bulkHelper.processBulkTransactions(pendingTransactions);
/// 
/// // Step 3: Show stats
/// final stats = bulkHelper.getStats(result);
/// print('Auto-suggested: ${stats.autoSuggestedTransactions} transactions');
/// print('Needs review: ${stats.needsReviewTransactions} transactions');
/// 
/// // Step 4: Show UI for bulk approval
/// // For auto-suggested groups:
/// for (final entry in result.autoSuggested.entries) {
///   final group = entry.value;
///   showBulkApprovalCard(
///     recipientName: group.recipientName,
///     count: group.count,
///     totalAmount: group.totalAmount,
///     suggestedCategory: getCategoryName(group.suggestedCategoryId),
///     onApprove: () async {
///       // Apply to all transactions in group
///       await bulkHelper.applyCategoryToGroup(
///         group.transactions,
///         group.suggestedCategoryId!,
///       );
///       // Save all transactions
///       await saveTransactions(group.transactions, group.suggestedCategoryId!);
///     },
///   );
/// }
/// 
/// // For needs review groups:
/// for (final entry in result.needsManualReview.entries) {
///   final group = entry.value;
///   showManualReviewCard(
///     recipientName: group.recipientName,
///     count: group.count,
///     totalAmount: group.totalAmount,
///     onCategorySelect: (categoryId) async {
///       // Apply to all transactions in group
///       await bulkHelper.applyCategoryToGroup(group.transactions, categoryId);
///       // Save all transactions
///       await saveTransactions(group.transactions, categoryId);
///     },
///   );
/// }
/// ```
