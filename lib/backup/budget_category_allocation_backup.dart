import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/budget.dart' show Budget;
import 'package:mudra_manager/db/models/budget_category_allocation.dart' show BudgetCategoryAllocation;
import 'package:mudra_manager/db/models/category.dart' show Category;

class BudgetCategoryAllocationBackup implements BackupAdapter<BudgetCategoryAllocation> {
  final int id;
  final double amount;
  final int? categoryId; // Store linked Category ID
  final int? budgetId; // Store linked Budget ID

  BudgetCategoryAllocationBackup.fromBudgetCategoryAllocation(BudgetCategoryAllocation allocation)
    : id = allocation.id,
      amount = allocation.amount,
      categoryId = allocation.category.value?.id,
      budgetId = allocation.budget.value?.id;

  BudgetCategoryAllocationBackup():
      id = 0,
      amount = 0,
      categoryId = null,
      budgetId = null;

  @override
  Map<String, dynamic> toBackupJson() => {'id': id, 'amount': amount, 'categoryId': categoryId, 'budgetId': budgetId};

  @override
  BudgetCategoryAllocation fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final allocation =
        BudgetCategoryAllocation()
          ..id = json['id']
          ..amount = json['amount'];

    // Re-link Category (IsarLink)
    final categoryMap = linkedRefs['Category'] as Map<int, dynamic>?;
    final categoryId = json['categoryId'];
    if (categoryMap != null && categoryId != null) {
      allocation.category.value = categoryMap[categoryId];
    }

    // Re-link Budget (IsarLink)
    final budgetMap = linkedRefs['Budget'] as Map<int, dynamic>?;
    final budgetId = json['budgetId'];
    if (budgetMap != null && budgetId != null) {
      allocation.budget.value = budgetMap[budgetId];
    }

    return allocation;
  }
}
