import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class NewParentPack extends CategoryPack {
  static final instance = NewParentPack._();
  NewParentPack._();

  @override
  String get id => 'com.mudra.pack.new_parent';
  @override
  String get name => 'New Parent';
  @override
  String get description => 'Diapers, doctor visits, daycare & baby essentials';
  @override
  String get icon => 'baby';
  @override
  int get color => 0xFFE91E63;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(name: 'Baby', icon: 'baby', color: 0xFFE91E63),
        CategoryDef(name: 'Diapers & Wipes', icon: 'shopping_bag', color: 0xFF9C27B0, parent: 'Baby'),
        CategoryDef(name: 'Baby Food & Formula', icon: 'restaurant', color: 0xFFFF9800, parent: 'Baby'),
        CategoryDef(name: 'Pediatrician', icon: 'medical', color: 0xFF4CAF50, parent: 'Baby'),
        CategoryDef(name: 'Vaccination', icon: 'medical', color: 0xFF2196F3, parent: 'Baby'),
        CategoryDef(name: 'Daycare / Crèche', icon: 'daycare', color: 0xFFFF5722, parent: 'Baby'),
        CategoryDef(name: 'Baby Clothes', icon: 'shopping_bag', color: 0xFFF06292, parent: 'Baby'),
        CategoryDef(name: 'Toys', icon: 'gift', color: 0xFFFFEB3B, parent: 'Baby'),
        CategoryDef(name: 'Baby Gear', icon: 'shopping_cart', color: 0xFF795548, parent: 'Baby'),
        CategoryDef(name: 'Maternity Care', icon: 'medical', color: 0xFFAD1457, parent: 'Baby'),

        // Income
        CategoryDef(name: 'Baby Shower Gifts', icon: 'gift', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Govt. Benefits / Subsidy', icon: 'wallet', color: 0xFF2196F3, type: CategoryType.income),
      ];
}
