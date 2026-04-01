import 'package:mudra_manager/core/services/category_rule_service.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

/// Example 1: When adding a new transaction from SMS
///
/// Call this in your SMS processing or transaction add screen
Future<void> exampleAddTransactionWithSuggestion({
  required TransactionInfo txnInfo,
  required CategoryRuleService ruleService,
  required Function(String? suggestedCategoryId) onSuggestion,
}) async {
  // Get smart category suggestion
  final suggestedCategoryId = await ruleService.suggestCategory(txnInfo);

  if (suggestedCategoryId != null) {
    // Show suggestion to user
    onSuggestion(suggestedCategoryId);
    // User can accept or choose different category
  } else {
    // No suggestion, user must choose manually
    onSuggestion(null);
  }
}

/// Example 2: When user selects a category
///
/// Call this after user confirms the category selection
Future<void> exampleLearnFromUserChoice({
  required TransactionInfo txnInfo,
  required String selectedCategoryId,
  required CategoryRuleService ruleService,
}) async {
  // Learn from user's choice
  await ruleService.learnFromCategorization(txnInfo, selectedCategoryId);

  // The system will now remember this pattern for future transactions
}

/// Example 3: Complete flow in a transaction add screen
///
/// This shows the full integration in your UI
class TransactionAddScreenExample {
  final CategoryRuleService ruleService;

  TransactionAddScreenExample(this.ruleService);

  Future<void> handleNewTransaction(TransactionInfo txnInfo) async {
    // Step 1: Get suggestion
    final suggestedCategoryId = await ruleService.suggestCategory(txnInfo);

    String? finalCategoryId;

    if (suggestedCategoryId != null) {
      // Step 2: Show suggestion dialog
      final userAccepted = await showSuggestionDialog(
        suggestedCategoryId: suggestedCategoryId,
        recipientName: txnInfo.account?.sendTo ?? txnInfo.account?.bankName,
      );

      if (userAccepted) {
        finalCategoryId = suggestedCategoryId;
      } else {
        // User wants to choose different category
        finalCategoryId = await showCategoryPicker();
      }
    } else {
      // Step 3: No suggestion, show category picker
      finalCategoryId = await showCategoryPicker();
    }

    if (finalCategoryId != null) {
      // Step 4: Save transaction with category
      await saveTransaction(txnInfo, finalCategoryId);

      // Step 5: Learn from this categorization
      await ruleService.learnFromCategorization(txnInfo, finalCategoryId);
    }
  }

  // Mock methods - replace with your actual UI
  Future<bool> showSuggestionDialog({
    required String suggestedCategoryId,
    String? recipientName,
  }) async {
    // Show dialog: "Categorize as [CategoryName] for [RecipientName]?"
    // Return true if user accepts, false if they want to choose different
    return true;
  }

  Future<String?> showCategoryPicker() async {
    // Show your category picker UI
    return null;
  }

  Future<void> saveTransaction(
      TransactionInfo txnInfo, String categoryId) async {
    // Save to database
  }
}

/// Example 4: Periodic cleanup (optional)
///
/// Run this monthly to clean up old unused rules
Future<void> examplePeriodicCleanup(CategoryRuleService ruleService) async {
  await ruleService.cleanupOldRules(daysOld: 180); // 6 months
}

/// INTEGRATION CHECKLIST:
/// 
/// 1. ✅ Run code generation: dart run build_runner build --delete-conflicting-outputs
/// 2. ✅ Initialize CategoryRuleService in your app
/// 3. ✅ In transaction add flow:
///    - Call suggestCategory() to get suggestion
///    - Show suggestion dialog if available
///    - Call learnFromCategorization() after user selects category
/// 4. ✅ Optional: Add periodic cleanup in background task
/// 
/// BENEFITS:
/// - First transaction to "SUKANTA BEHERA" → User selects "Friends"
/// - Second transaction to "SUKANTA BEHERA" → Auto-suggests "Friends" ✓
/// - After 5 matches → Confidence = 100%, very reliable suggestion
/// - Works for UPI recipients, merchants, and account numbers
