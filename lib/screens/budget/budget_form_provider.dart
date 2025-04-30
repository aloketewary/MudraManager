import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/budget.dart'
    show Budget, BudgetRecurrence;
import 'package:mudra_manager/db/models/category.dart' show Category;

class BudgetFormController extends StateNotifier<Budget> {
  BudgetFormController() : super(Budget());

  void setName(String name) => state = state..name = name;

  void setAmount(double amount) => state = state..amount = amount;

  void setStartDate(DateTime date) => state = state..startDate = date;

  void setEndDate(DateTime date) => state = state..endDate = date;

  void setRecurrence(BudgetRecurrence recurrence) =>
      state = state..recurrence = recurrence;

  void setCategories(List<Category> categories) {
    state.categories.clear();
    state.categories.addAll(categories);
  }
}

final budgetFormProvider = StateNotifierProvider<BudgetFormController, Budget>(
  (ref) => BudgetFormController(),
);
