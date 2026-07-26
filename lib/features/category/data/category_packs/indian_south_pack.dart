import 'category_pack.dart';

class IndianSouthPack extends CategoryPack {
  static final instance = IndianSouthPack._();
  IndianSouthPack._();

  @override
  String get id => 'com.mudra.pack.indian_south';
  @override
  String get name => 'Indian (South)';
  @override
  String get description => 'South India cuisine & culture';
  @override
  String get icon => 'map';
  @override
  int get color => 0xFF4CAF50;
  @override
  List<String> get extendsPackIds =>
      ['com.mudra.pack.default', 'com.mudra.pack.indian_common'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Dosa & Idli',
          icon: 'restaurant',
          color: 0xFFFF9800,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Filter Coffee',
          icon: 'coffee',
          color: 0xFF795548,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Thali Meals',
          icon: 'restaurant',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Silk Sarees',
          icon: 'clothing',
          color: 0xFF9C27B0,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Temple/Church',
          icon: 'spa',
          color: 0xFFFF5722,
          parent: 'Religious & Spiritual',
        ),
        CategoryDef(
          name: 'Festival Expenses',
          icon: 'celebration',
          color: 0xFFE91E63,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Jewelry',
          icon: 'gem',
          color: 0xFFFFEB3B,
          parent: 'Shopping',
        ),
      ];
}
