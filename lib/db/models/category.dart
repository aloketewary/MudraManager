import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@collection
@JsonSerializable()
class Category {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true, caseSensitive: false)
  late String name; // e.g., "Groceries", "Salary", "Entertainment"

  @Index()
  @enumerated
  late CategoryType categoryType; // true = Expense, false = Income

  // Optional: Link to a parent category for sub-categories
  // final parentCategory = IsarLink<Category>();

  // Optional: Icon identifier or color for UI representation
  String? iconName;
  int? colorValue;

  List<String>? keywords;

  // Isar requires a default constructor
  Category();

  // Optional: Convenience constructor
  Category.create({
    required this.name,
    this.categoryType = CategoryType.expense, // Default to expense
    this.keywords,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

enum CategoryType { income, expense }
