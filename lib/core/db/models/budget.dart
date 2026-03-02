import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';

import 'category.dart';

part 'budget.g.dart';

@collection
@JsonSerializable()
class Budget {
  Id id = Isar.autoIncrement;

  @Index()
  bool isArchived = false;

  @enumerated
  late BudgetType budgetType; // categoryWise, dayWise, festival, travel

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

  bool notifiedAt80 = false;
  bool notifiedAt90 = false;
  bool notifiedAt100 = false;

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

extension BudgetRecurrenceExtension on Budget {
  (DateTime, DateTime) getCurrentPeriodRange(DateTime now) {
    if (recurrence == BudgetRecurrence.none) {
      return (startDate, endDate);
    }

    DateTime currentStart = startDate;
    DateTime currentEnd = endDate;

    // If 'now' is before the initial range, return the initial range.
    if (now.isBefore(currentStart)) {
      return (currentStart, currentEnd);
    }

    // Fast-forward to the period containing 'now'.
    while (currentEnd.isBefore(now)) {
      switch (recurrence) {
        case BudgetRecurrence.daily:
          currentStart = currentStart.add(const Duration(days: 1));
          currentEnd = currentEnd.add(const Duration(days: 1));
          break;
        case BudgetRecurrence.weekly:
          currentStart = currentStart.add(const Duration(days: 7));
          currentEnd = currentEnd.add(const Duration(days: 7));
          break;
        case BudgetRecurrence.monthly:
          currentStart = _addMonths(currentStart, 1);
          currentEnd = _addMonths(currentEnd, 1);
          break;
        case BudgetRecurrence.yearly:
          currentStart = DateTime(
            currentStart.year + 1,
            currentStart.month,
            currentStart.day,
          );
          currentEnd = DateTime(
            currentEnd.year + 1,
            currentEnd.month,
            currentEnd.day,
          );
          break;
        case BudgetRecurrence.none:
          return (currentStart, currentEnd);
      }
    }
    return (currentStart, currentEnd);
  }

  DateTime _addMonths(DateTime dt, int months) {
    final nextYear = dt.year + (dt.month + months - 1) ~/ 12;
    final nextMonth = (dt.month + months - 1) % 12 + 1;
    var next = DateTime(nextYear, nextMonth, dt.day);
    if (next.month != nextMonth) {
      // Handle rolling over to next month if day > daysInMonth
      next = DateTime(nextYear, nextMonth + 1, 0);
    }
    return next;
  }
}
