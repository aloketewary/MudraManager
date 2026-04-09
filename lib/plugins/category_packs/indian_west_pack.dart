import 'category_pack.dart';

class IndianWestPack extends CategoryPack {
  static final instance = IndianWestPack._();
  IndianWestPack._();

  @override
  String get id => 'com.mudra.pack.indian_west';
  @override
  String get name => 'Indian (West)';
  @override
  String get description => 'West India street food & festivals';
  @override
  String get icon => 'map';
  @override
  int get color => 0xFFFF9800;
  @override
  List<String> get extendsPackIds =>
      ['com.mudra.pack.default', 'com.mudra.pack.indian_common'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Vada Pav',
          icon: 'fastfood',
          color: 0xFFFF9800,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Pav Bhaji',
          icon: 'restaurant',
          color: 0xFFFF5722,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Dabeli',
          icon: 'fastfood',
          color: 0xFFE91E63,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Navratri/Garba',
          icon: 'celebration',
          color: 0xFF9C27B0,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Jewelry',
          icon: 'gem',
          color: 0xFFFFEB3B,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Festival Expenses',
          icon: 'celebration',
          color: 0xFFE91E63,
          parent: 'Entertainment',
        ),
      ];
}
