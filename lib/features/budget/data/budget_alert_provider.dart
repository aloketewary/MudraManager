import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';

/// Provides budget alerts - updated on dashboard load and transaction creation
final budgetAlertsProvider = FutureProvider<List<BudgetAlert>>((ref) async {
  final alertService = ref.watch(budgetAlertServiceProvider);
  return await alertService.checkBudgetsOnDashboardLoad();
});

/// Notifier for managing alerts that persist across dashboard reloads
final budgetAlertsNotifierProvider =
    NotifierProvider<BudgetAlertsNotifier, List<BudgetAlert>>(
  BudgetAlertsNotifier.new,
);

class BudgetAlertsNotifier extends Notifier<List<BudgetAlert>> {
  @override
  List<BudgetAlert> build() => [];

  void addAlerts(List<BudgetAlert> alerts) {
    state = [...state, ...alerts];
  }

  void dismissAlert(BudgetAlert alert) {
    state = state.where((a) => a.budget.id != alert.budget.id).toList();
  }

  void dismissAll() {
    state = [];
  }
}

