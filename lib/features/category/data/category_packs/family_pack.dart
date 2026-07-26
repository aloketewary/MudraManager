import 'category_pack.dart';

class FamilyPack extends CategoryPack {
  static final instance = FamilyPack._();
  FamilyPack._();

  @override
  String get id => 'com.mudra.pack.family';
  @override
  String get name => 'Family';
  @override
  String get description => 'Household, kids & elder care';
  @override
  String get icon => 'home';
  @override
  int get color => 0xFF4CAF50;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'School Fees',
          icon: 'school',
          color: 0xFF2196F3,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Baby Products',
          icon: 'baby',
          color: 0xFFE91E63,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Kids Clothing',
          icon: 'clothing',
          color: 0xFF9C27B0,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Toys & Games',
          icon: 'toys',
          color: 0xFFFF9800,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Family Outing',
          icon: 'park',
          color: 0xFF4CAF50,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Elder Care',
          icon: 'medical',
          color: 0xFF00BCD4,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Vitamins & Supplements',
          icon: 'vaccination',
          color: 0xFF8BC34A,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Home Maintenance',
          icon: 'renovation',
          color: 0xFF795548,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Society Maintenance',
          icon: 'maintenance',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Maid/Cook',
          icon: 'cleaning',
          color: 0xFFFF5722,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Diapers & Formula',
          icon: 'baby',
          color: 0xFFE91E63,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'School Supplies',
          icon: 'stationery',
          color: 0xFF2196F3,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Family Doctor',
          icon: 'heartbeat',
          color: 0xFF009688,
          parent: 'Healthcare',
        ),
      ];
}
