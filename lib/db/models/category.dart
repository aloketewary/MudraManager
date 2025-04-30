import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, caseSensitive: false)
  late String name; // e.g., "Groceries", "Salary", "Entertainment"

  @enumerated
  late CategoryType categoryType; // true = Expense, false = Income

  // Optional: Link to a parent category for sub-categories
  // final parentCategory = IsarLink<Category>();

  // Optional: Icon identifier or color for UI representation
  String? iconName;
  int? colorValue;

  // Isar requires a default constructor
  Category();

  // Optional: Convenience constructor
  Category.create({
    required this.name,
    this.categoryType = CategoryType.expense, // Default to expense
  });
}

enum CategoryType { income, expense }