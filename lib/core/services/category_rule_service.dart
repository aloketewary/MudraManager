import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';

class CategoryRuleService {
  final Isar isar;

  CategoryRuleService(this.isar);

  /// Get all category rules
  Future<List<CategoryRule>> getAllRules() async {
    return await isar.categoryRules.where().findAll();
  }

  /// Suggest category for a transaction based on learned rules
  Future<String?> suggestCategory(TransactionInfo txn) async {
    final rules = await getAllRules();
    return CategoryMatcher.suggestCategoryFromRules(txn, rules);
  }

  /// Save or update a rule when user categorizes a transaction
  Future<void> learnFromCategorization(
    TransactionInfo txn,
    String categoryId,
  ) async {
    final existingRules = await getAllRules();
    final rule = CategoryMatcher.createOrUpdateRule(txn, categoryId, existingRules);

    await isar.writeTxn(() async {
      await isar.categoryRules.put(rule);
    });
  }

  /// Clean up old unused rules (optional maintenance)
  Future<void> cleanupOldRules({int daysOld = 180}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await isar.writeTxn(() async {
      final oldRules = await isar.categoryRules
          .filter()
          .lastUsedLessThan(cutoffDate)
          .and()
          .matchCountLessThan(3) // Only delete if rarely used
          .findAll();
      
      for (final rule in oldRules) {
        await isar.categoryRules.delete(rule.id);
      }
    });
  }
}
