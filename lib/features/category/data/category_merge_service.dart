import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/category_rule.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';

/// Merges [source] category into [target] category.
///
/// Re-links all transactions, recurring transactions, budget allocations,
/// and learned category rules from source → target, then deletes source.
class CategoryMergeService {
  final IsarService _isarService;
  final AppLog _log;

  CategoryMergeService(this._isarService, this._log);

  /// Returns a preview of what will be affected.
  Future<MergePreview> preview(int sourceId, int targetId) async {
    final isar = await _isarService.getInstance();

    final txnCount = await isar.transactions
        .filter()
        .category((q) => q.idEqualTo(sourceId))
        .count();

    final recurringCount = await isar.recurringTransactions
        .filter()
        .category((q) => q.idEqualTo(sourceId))
        .count();

    final allocCount = await isar.budgetCategoryAllocations
        .filter()
        .category((q) => q.idEqualTo(sourceId))
        .count();

    final ruleCount = await isar.categoryRules
        .where()
        .categoryIdEqualTo(sourceId.toString())
        .count();

    return MergePreview(
      transactionCount: txnCount,
      recurringCount: recurringCount,
      budgetAllocationCount: allocCount,
      ruleCount: ruleCount,
    );
  }

  /// Merge [sourceId] into [targetId]. Returns total items re-linked.
  Future<int> merge(int sourceId, int targetId) async {
    final isar = await _isarService.getInstance();

    final source = await isar.categorys.get(sourceId);
    final target = await isar.categorys.get(targetId);
    if (source == null || target == null) return 0;

    int total = 0;

    await isar.writeTxn(() async {
      // 1. Re-link transactions
      final txns = await isar.transactions
          .filter()
          .category((q) => q.idEqualTo(sourceId))
          .findAll();
      for (final txn in txns) {
        txn.category.value = target;
        await isar.transactions.put(txn);
        await txn.category.save();
      }
      total += txns.length;

      // 2. Re-link recurring transactions
      final recurring = await isar.recurringTransactions
          .filter()
          .category((q) => q.idEqualTo(sourceId))
          .findAll();
      for (final r in recurring) {
        r.category.value = target;
        await isar.recurringTransactions.put(r);
        await r.category.save();
      }
      total += recurring.length;

      // 3. Re-link budget allocations (or merge if target already has one)
      final allocs = await isar.budgetCategoryAllocations
          .filter()
          .category((q) => q.idEqualTo(sourceId))
          .findAll();
      for (final alloc in allocs) {
        await alloc.budget.load();
        final budget = alloc.budget.value;
        if (budget == null) continue;

        // Check if target already has an allocation in this budget
        final existing = await isar.budgetCategoryAllocations
            .filter()
            .category((q) => q.idEqualTo(targetId))
            .budget((q) => q.idEqualTo(budget.id))
            .findFirst();

        if (existing != null) {
          // Merge amounts
          existing.amount += alloc.amount;
          await isar.budgetCategoryAllocations.put(existing);
          await isar.budgetCategoryAllocations.delete(alloc.id);
        } else {
          // Re-link to target
          alloc.category.value = target;
          await isar.budgetCategoryAllocations.put(alloc);
          await alloc.category.save();
        }
      }
      total += allocs.length;

      // 4. Update budget category links
      final budgets = await isar.budgets.where().findAll();
      for (final budget in budgets) {
        await budget.categories.load();
        final hasSource =
            budget.categories.any((c) => c.id == sourceId);
        if (hasSource) {
          budget.categories.removeWhere((c) => c.id == sourceId);
          if (!budget.categories.any((c) => c.id == targetId)) {
            budget.categories.add(target);
          }
          await budget.categories.save();
        }
      }

      // 5. Update learned category rules
      final rules = await isar.categoryRules
          .where()
          .categoryIdEqualTo(sourceId.toString())
          .findAll();
      for (final rule in rules) {
        rule.categoryId = targetId.toString();
        await isar.categoryRules.put(rule);
      }
      total += rules.length;

      // 6. Merge keywords
      final sourceKeywords = source.keywords ?? [];
      final targetKeywords = target.keywords ?? [];
      final merged = {...targetKeywords, ...sourceKeywords}.toList();
      if (merged.length > targetKeywords.length) {
        target.keywords = merged;
        await isar.categorys.put(target);
      }

      // 7. Delete source category
      await isar.categorys.delete(sourceId);
    });

    _log.i(
      'Merged "${source.name}" → "${target.name}": $total items re-linked',
    );
    return total;
  }
}

class MergePreview {
  final int transactionCount;
  final int recurringCount;
  final int budgetAllocationCount;
  final int ruleCount;

  const MergePreview({
    required this.transactionCount,
    required this.recurringCount,
    required this.budgetAllocationCount,
    required this.ruleCount,
  });

  int get totalAffected =>
      transactionCount + recurringCount + budgetAllocationCount + ruleCount;

  bool get isEmpty => totalAffected == 0;
}
