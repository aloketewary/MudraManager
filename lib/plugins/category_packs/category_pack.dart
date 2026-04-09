import 'package:mudra_manager/core/db/models/category.dart';

class CategoryDef {
  final String name;
  final String icon;
  final int color;
  final CategoryType type;
  final String? parent;

  const CategoryDef({
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.expense,
    this.parent,
  });

  Category toCategory() => Category()
    ..name = name
    ..categoryType = type
    ..iconName = icon
    ..colorValue = color;
}

abstract class CategoryPack {
  String get id;
  String get name;
  String get description;
  String get icon;
  int get color;
  List<String> get extendsPackIds;
  List<CategoryDef> get categories;

  /// If true, this pack is an internal dependency and not shown in marketplace UI.
  bool get hidden => false;

  List<String> get allCategoryNames => categories.map((c) => c.name).toList();
}

class CategoryPackRegistry {
  static final Map<String, CategoryPack> _packs = {};

  static void register(CategoryPack pack) => _packs[pack.id] = pack;
  static CategoryPack? get(String id) => _packs[id];
  static List<CategoryPack> get all => _packs.values.toList();

  /// Only packs visible in marketplace UI.
  static List<CategoryPack> get visible =>
      _packs.values.where((p) => !p.hidden).toList();

  static bool isPack(String id) => _packs.containsKey(id);
}
