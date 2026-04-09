import 'category_pack.dart';

class CouplePack extends CategoryPack {
  static final instance = CouplePack._();
  CouplePack._();

  @override
  String get id => 'com.mudra.pack.couple';
  @override
  String get name => 'Couple';
  @override
  String get description => 'Shared expenses, dates & household';
  @override
  String get icon => 'home';
  @override
  int get color => 0xFFE91E63;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Date Night',
          icon: 'wine',
          color: 0xFFE91E63,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Shared Groceries',
          icon: 'groceries',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Joint Bills',
          icon: 'split_bill',
          color: 0xFF795548,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Anniversary',
          icon: 'celebration',
          color: 0xFF9C27B0,
          parent: 'Gifts & Social',
        ),
        CategoryDef(
          name: 'Couple Activities',
          icon: 'comedy',
          color: 0xFF3F51B5,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Shared Subscriptions',
          icon: 'autopay',
          color: 0xFF00BCD4,
          parent: 'Bills',
        ),
      ];
}
