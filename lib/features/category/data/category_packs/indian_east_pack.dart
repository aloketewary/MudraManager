import 'category_pack.dart';

class IndianEastPack extends CategoryPack {
  static final instance = IndianEastPack._();
  IndianEastPack._();

  @override
  String get id => 'com.mudra.pack.indian_east';
  @override
  String get name => 'Indian (East)';
  @override
  String get description => 'East India sweets, festivals & transport';
  @override
  String get icon => 'map';
  @override
  int get color => 0xFF03A9F4;
  @override
  List<String> get extendsPackIds =>
      ['com.mudra.pack.default', 'com.mudra.pack.indian_common'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Mishti & Rosogolla',
          icon: 'cake',
          color: 0xFFE91E63,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Cycle Rickshaw',
          icon: 'taxi',
          color: 0xFF8BC34A,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Ferry/Boat',
          icon: 'boat',
          color: 0xFF03A9F4,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Durga Puja',
          icon: 'celebration',
          color: 0xFFFF5722,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Handloom',
          icon: 'clothing',
          color: 0xFF9C27B0,
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
