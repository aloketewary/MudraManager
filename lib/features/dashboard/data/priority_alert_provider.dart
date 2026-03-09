import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/goal/data/goal_provider.dart';

class PriorityAlert {
  final String title;
  final String message;
  final String route;
  final AlertType type;

  PriorityAlert({
    required this.title,
    required this.message,
    required this.route,
    required this.type,
  });
}

enum AlertType {
  urgent,    // Red/Orange - immediate action needed
  warning,   // Yellow - attention needed
  info,      // Blue - informational
}

final priorityAlertProvider = FutureProvider.autoDispose<PriorityAlert?>((ref) async {
  final isar = ref.watch(isarServiceProvider);
  final db = await isar.getInstance();
  
  // Check for bills due in next 2 days
  final now = DateTime.now();
  final twoDaysLater = now.add(const Duration(days: 2));
  
  final upcomingBills = await db.recurringTransactions
      .where()
      .filter()
      .isActiveEqualTo(true)
      .and()
      .nextDueDateBetween(now, twoDaysLater)
      .findAll();
  
  if (upcomingBills.isNotEmpty) {
    final tomorrow = now.add(const Duration(days: 1));
    final billsDueTomorrow = upcomingBills.where((b) => 
      b.nextDueDate.year == tomorrow.year &&
      b.nextDueDate.month == tomorrow.month &&
      b.nextDueDate.day == tomorrow.day
    ).length;
    
    if (billsDueTomorrow > 0) {
      return PriorityAlert(
        title: 'Action Needed',
        message: '$billsDueTomorrow bill${billsDueTomorrow > 1 ? 's' : ''} due tomorrow',
        route: '/recurring-transactions',
        type: AlertType.urgent,
      );
    }
    
    return PriorityAlert(
      title: 'Upcoming Bills',
      message: '${upcomingBills.length} bill${upcomingBills.length > 1 ? 's' : ''} due in 2 days',
      route: '/recurring-transactions',
      type: AlertType.warning,
    );
  }
  
  // Check for budget overruns
  final budgetsAsync = await ref.watch(budgetsWithProgressProvider.future);
  final overBudget = budgetsAsync.where((b) => b.spent > b.budget.amount).toList();
  
  if (overBudget.isNotEmpty) {
    return PriorityAlert(
      title: 'Budget Alert',
      message: '${overBudget.length} budget${overBudget.length > 1 ? 's' : ''} exceeded',
      route: '/budget-dashboard',
      type: AlertType.urgent,
    );
  }
  
  // Check for budgets near limit (>90%)
  final nearLimit = budgetsAsync.where((b) {
    final percent = (b.spent / b.budget.amount * 100);
    return percent >= 90 && percent < 100;
  }).toList();
  
  if (nearLimit.isNotEmpty) {
    return PriorityAlert(
      title: 'Budget Warning',
      message: '${nearLimit.length} budget${nearLimit.length > 1 ? 's' : ''} near limit',
      route: '/budget-dashboard',
      type: AlertType.warning,
    );
  }
  
  // Check for goals near completion (>80%)
  final goalsAsync = await ref.watch(goalsProvider.future);
  final nearCompletion = goalsAsync.where((g) => 
    g.isActive && g.progressPercent >= 80 && g.progressPercent < 100
  ).toList();
  
  if (nearCompletion.isNotEmpty) {
    return PriorityAlert(
      title: 'Goal Progress',
      message: '${nearCompletion.length} goal${nearCompletion.length > 1 ? 's' : ''} almost complete!',
      route: '/goal-screen',
      type: AlertType.info,
    );
  }
  
  return null;
});
