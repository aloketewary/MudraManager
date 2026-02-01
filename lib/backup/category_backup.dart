import 'package:mudra_manager/backup/backable_model.dart' show BackupAdapter;
import 'package:mudra_manager/db/models/category.dart' show Category, CategoryType;

class CategoryBackup implements BackupAdapter<Category> {
  final int id;
  final String name;
  final CategoryType categoryType;
  final String? iconName;
  final int? colorValue;

  CategoryBackup.fromCategory(Category category)
      : id = category.id,
        name = category.name,
        categoryType = category.categoryType,
        iconName = category.iconName,
        colorValue = category.colorValue;

  // Don't use to add values
  CategoryBackup():
      id = 0,
      name = '',
      categoryType = CategoryType.expense,
      iconName = '',
      colorValue = 0;

  @override
  Map<String, dynamic> toBackupJson() => {
    'id': id,
    'name': name,
    'categoryType': categoryType.index, // Store enum as index
    'iconName': iconName,
    'colorValue': colorValue,
  };

  @override
  Category fromBackupJson(Map<String, dynamic> json, Map<String, dynamic> linkedRefs) {
    final category = Category()
      ..id = json['id']
      ..name = json['name']
      ..categoryType = CategoryType.values[json['categoryType'] as int]
      ..iconName = json['iconName'] as String?
      ..colorValue = json['colorValue'] as int?;

    return category;
  }
}