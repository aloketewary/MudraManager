import 'category_pack.dart';

class FoodiePack extends CategoryPack {
  static final instance = FoodiePack._();
  FoodiePack._();

  @override
  String get id => 'com.mudra.pack.foodie';
  @override
  String get name => 'Foodie';
  @override
  String get description => 'Dining, delivery & culinary adventures';
  @override
  String get icon => 'restaurant';
  @override
  int get color => 0xFFFF9800;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Street Food',
          icon: 'fastfood',
          color: 0xFFFF5722,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Fine Dining',
          icon: 'wine',
          color: 0xFF9C27B0,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Cafe & Coffee',
          icon: 'coffee',
          color: 0xFF795548,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Food Delivery',
          icon: 'delivery',
          color: 0xFFFF5722,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Bakery & Desserts',
          icon: 'cake',
          color: 0xFFE91E63,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Sweets & Mithai',
          icon: 'candy',
          color: 0xFFE91E63,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Tea & Chai',
          icon: 'cup_soda',
          color: 0xFF795548,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Cooking Ingredients',
          icon: 'wheat',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Kitchen Gadgets',
          icon: 'cooking',
          color: 0xFF607D8B,
          parent: 'Shopping',
        ),
      ];
}
