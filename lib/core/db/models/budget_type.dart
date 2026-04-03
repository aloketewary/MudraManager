
enum BudgetType {
  categoryWise,    // Budget for specific categories
  tagWise,         // Budget for specific tags
  dayWise,         // Daily budget limit
  festival,        // Festival/event specific budget
  travel,          // Travel specific budget
}

extension BudgetTypeExtension on BudgetType {
  String get displayName {
    switch (this) {
      case BudgetType.categoryWise:
        return 'Category-wise';
      case BudgetType.tagWise:
        return 'Tag-wise';
      case BudgetType.dayWise:
        return 'Daily';
      case BudgetType.festival:
        return 'Festival';
      case BudgetType.travel:
        return 'Travel';
    }
  }

  String get description {
    switch (this) {
      case BudgetType.categoryWise:
        return 'Set budgets for specific spending categories';
      case BudgetType.tagWise:
        return 'Set budgets for specific tags (e.g., Wedding, Vacation)';
      case BudgetType.dayWise:
        return 'Set a daily spending limit';
      case BudgetType.festival:
        return 'Budget for festivals and special events';
      case BudgetType.travel:
        return 'Budget for travel expenses';
    }
  }
}
