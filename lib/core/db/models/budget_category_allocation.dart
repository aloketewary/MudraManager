import 'package:isar_community/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/category.dart';

part 'budget_category_allocation.g.dart';

@collection
@JsonSerializable()
class BudgetCategoryAllocation {
  Id id = Isar.autoIncrement;

  late double amount;

  final category = IsarLink<Category>();
  final budget = IsarLink<Budget>();

  BudgetCategoryAllocation();

  factory BudgetCategoryAllocation.fromJson(Map<String, dynamic> json) => _$BudgetCategoryAllocationFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetCategoryAllocationToJson(this);
}
