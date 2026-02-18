import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';

final budgetAlertsProvider =
    StateNotifierProvider<BudgetAlertsNotifier, List<BudgetAlert>>((ref) {
      return BudgetAlertsNotifier();
    });

class BudgetAlertsNotifier extends StateNotifier<List<BudgetAlert>> {
  BudgetAlertsNotifier() : super([]);

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
