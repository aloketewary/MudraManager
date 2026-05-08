import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';

final budgetAlertsProvider =
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
