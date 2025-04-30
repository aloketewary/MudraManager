import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/budget.dart' show Budget;
import 'package:mudra_manager/db/models/category.dart' show Category;

part 'budget_category_allocation.g.dart';

@collection
class BudgetCategoryAllocation {
  Id id = Isar.autoIncrement;

  late double amount;

  final category = IsarLink<Category>();
  final budget = IsarLink<Budget>();
}
