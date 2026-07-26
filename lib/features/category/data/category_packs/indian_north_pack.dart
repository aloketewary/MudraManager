import 'category_pack.dart';

class IndianNorthPack extends CategoryPack {
  static final instance = IndianNorthPack._();
  IndianNorthPack._();

  @override
  String get id => 'com.mudra.pack.indian_north';
  @override
  String get name => 'Indian (North)';
  @override
  String get description => 'North India lifestyle & festivals';
  @override
  String get icon => 'map';
  @override
  int get color => 0xFFFF5722;
  @override
  List<String> get extendsPackIds =>
      ['com.mudra.pack.default', 'com.mudra.pack.indian_common'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Festival Expenses',
          icon: 'celebration',
          color: 0xFFE91E63,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Puja Items',
          icon: 'spa',
          color: 0xFFFF9800,
          parent: 'Religious & Spiritual',
        ),
        CategoryDef(
          name: 'Wedding Gifts',
          icon: 'gift',
          color: 0xFF9C27B0,
          parent: 'Gifts & Social',
        ),
        CategoryDef(
          name: 'Religious Donations',
          icon: 'donation',
          color: 0xFF795548,
          parent: 'Religious & Spiritual',
        ),
        CategoryDef(
          name: 'Clothing/Textile',
          icon: 'clothing',
          color: 0xFFE91E63,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Jewelry',
          icon: 'gem',
          color: 0xFFFFEB3B,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Temple/Church',
          icon: 'spa',
          color: 0xFFFF5722,
          parent: 'Religious & Spiritual',
        ),
      ];
}
