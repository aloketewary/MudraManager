import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter, Backupable;
import 'package:mudra_manager/db/models/budget.dart' show Budget, BudgetRecurrence;
import 'package:mudra_manager/db/models/budget_category_allocation.dart' show BudgetCategoryAllocation;
import 'package:mudra_manager/db/models/category.dart' show Category;

class BudgetBackup implements BackupAdapter<Budget> {
  final int id;
  final bool isArchived;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> categoryIds; // Store linked Category IDs
  final BudgetRecurrence recurrence;
  final List<int> allocationIds; // Store linked BudgetCategoryAllocation IDs

  BudgetBackup.fromBudget(Budget budget)
      : id = budget.id,
        isArchived = budget.isArchived,
        name = budget.name,
        amount = budget.amount,
        startDate = budget.startDate,
        endDate = budget.endDate,
        categoryIds = budget.categories.map((link) => link.id).toList(),
        recurrence = budget.recurrence,
        allocationIds = budget.allocations.map((link) => link.id).toList();

  BudgetBackup():
      id = 0,
      isArchived = false,
      name = '',
      amount = 0.0,
      startDate = DateTime.now(),
      endDate = DateTime.now(),
      categoryIds = [],
      recurrence = BudgetRecurrence.monthly,
      allocationIds = [];

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'isArchived': isArchived,
    'name': name,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'categoryIds': categoryIds,
    'recurrence': recurrence.index, // Store enum as index
    'allocationIds': allocationIds,
  };

  @override
  Budget fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final budget = Budget()
      ..id = json['id']
      ..isArchived = json['isArchived'] as bool? ?? false
      ..name = json['name']
      ..amount = json['amount']
      ..startDate = DateTime.parse(json['startDate'])
      ..endDate = DateTime.parse(json['endDate'])
      ..recurrence = BudgetRecurrence.values[json['recurrence'] as int];

    // Re-link Categories (IsarLinks)
    final categoryMap = linkedRefs['Category'] as Map<int, dynamic>?;
    final categoryIds = json['categoryIds'] as List<dynamic>? ?? [];
    if (categoryMap != null) {
      for (final categoryId in categoryIds) {
        final category = categoryMap[categoryId];
        if (category != null) {
          budget.categories.add(category);
        }
      }
    }

    // Re-link BudgetCategoryAllocations (IsarLinks)
    final allocationMap = linkedRefs['BudgetCategoryAllocation'] as Map<int, dynamic>?;
    final allocationIds = json['allocationIds'] as List<dynamic>? ?? [];
    if (allocationMap != null) {
      for (final allocationId in allocationIds) {
        final allocation = allocationMap[allocationId];
        if (allocation != null) {
          budget.allocations.add(allocation);
        }
      }
    }

    return budget;
  }
}