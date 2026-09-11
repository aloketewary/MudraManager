import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';

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

  // Tags for tag-wise budgets
  @Index()
  final budgetTags = IsarLinks<Tag>();

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

    // Compare calendar days, not instants. This keeps an occurrence current
    // through its exact inclusive end date, including end-of-day transactions.
    final evaluationDay = DateArithmetic.startOfDay(now);
    DateTime currentStart = startDate;
    DateTime currentEnd = endDate;
    var occurrence = 0;

    // Preserve original start/end anchors independently. In particular,
    // Jan-31 -> Feb-29 must become Mar-31, not Mar-29.
    while (DateArithmetic.startOfDay(currentEnd).isBefore(evaluationDay)) {
      occurrence++;
      switch (recurrence) {
        case BudgetRecurrence.daily:
          currentStart = startDate.add(Duration(days: occurrence));
          currentEnd = endDate.add(Duration(days: occurrence));
          break;
        case BudgetRecurrence.weekly:
          currentStart = startDate.add(Duration(days: occurrence * 7));
          currentEnd = endDate.add(Duration(days: occurrence * 7));
          break;
        case BudgetRecurrence.monthly:
          currentStart = DateArithmetic.addMonths(
            startDate,
            occurrence,
            preferDay: startDate.day,
          );
          currentEnd = DateArithmetic.addMonths(
            endDate,
            occurrence,
            preferDay: endDate.day,
          );
          break;
        case BudgetRecurrence.yearly:
          currentStart = DateArithmetic.addYears(
            startDate,
            occurrence,
            preferDay: startDate.day,
          );
          currentEnd = DateArithmetic.addYears(
            endDate,
            occurrence,
            preferDay: endDate.day,
          );
          break;
        case BudgetRecurrence.none:
          return (currentStart, currentEnd);
      }
    }
    return (currentStart, currentEnd);
  }
}
