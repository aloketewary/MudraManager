/// Domain-level attention items.
///
/// These represent facts that deserve user attention.
/// They contain NO localized strings, NO routes, NO colors, NO icons.
/// Pure business facts only.
sealed class AttentionItem {
  const AttentionItem();
}

final class BudgetOverLimit extends AttentionItem {
  final String budgetName;
  final int overCount;

  const BudgetOverLimit({required this.budgetName, required this.overCount});
}

final class BudgetNearLimit extends AttentionItem {
  final String budgetName;
  final int nearCount;

  const BudgetNearLimit({required this.budgetName, required this.nearCount});
}

final class BillDueTomorrow extends AttentionItem {
  final int count;
  final String? billName;

  const BillDueTomorrow({required this.count, this.billName});
}

final class BillDueSoon extends AttentionItem {
  final int count;
  final int daysUntil;
  final String? billName;

  const BillDueSoon({
    required this.count,
    required this.daysUntil,
    this.billName,
  });
}

final class GoalNearCompletion extends AttentionItem {
  final int count;

  const GoalNearCompletion({required this.count});
}
