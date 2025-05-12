import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/db/models/budget_category_allocation.dart'
    show BudgetCategoryAllocation;
import 'category.dart'; // Import for linking

part 'budget.g.dart';

@collection
@JsonSerializable()
class Budget {
  Id id = Isar.autoIncrement;

  @Index()
  bool isArchived = false;

  late String name; // e.g., "Monthly Food Budget", "Entertainment Q1"

  late double amount; // The target budget amount

  @Index() // Index start date for finding active budgets
  late DateTime startDate;

  @Index() // Index end date for finding active budgets
  late DateTime endDate;

  // Link to the categories this budget applies to.
  // A budget can apply to one or more categories.
  @Index() // Indexing helps find budgets related to specific categories
  final categories = IsarLinks<Category>();

  // Optional: Add a field for recurrence (e.g., 'monthly', 'yearly', 'none')
  @enumerated
  late BudgetRecurrence recurrence;

  final allocations = IsarLinks<BudgetCategoryAllocation>();

  // Isar requires a default constructor
  Budget();

  // Optional: Convenience constructor
  Budget.create({
    required this.name,
    required this.amount,
    required this.startDate,
    required this.endDate,
    // You would assign category links AFTER creating the Budget object
  });

  // Note: The current spending against the budget is not stored here.
  // It needs to be CALCULATED dynamically by querying Transactions
  // that fall within the budget's date range AND belong to the linked categories.
  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetToJson(this);
}

// Example Enum (defined outside the class)
enum BudgetRecurrence { none, daily, weekly, monthly, yearly }
