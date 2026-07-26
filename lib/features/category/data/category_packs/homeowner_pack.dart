import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class HomeownerPack extends CategoryPack {
  static final instance = HomeownerPack._();
  HomeownerPack._();

  @override
  String get id => 'com.mudra.pack.homeowner';
  @override
  String get name => 'Homeowner';
  @override
  String get description => 'EMI, maintenance, bills & home upkeep';
  @override
  String get icon => 'home';
  @override
  int get color => 0xFF5D4037;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(name: 'Home', icon: 'home', color: 0xFF5D4037),
        CategoryDef(name: 'Home Loan EMI', icon: 'receipt', color: 0xFFF44336, parent: 'Home'),
        CategoryDef(name: 'Society Charges', icon: 'home', color: 0xFF795548, parent: 'Home'),
        CategoryDef(name: 'Property Tax', icon: 'receipt', color: 0xFF607D8B, parent: 'Home'),
        CategoryDef(name: 'Home Insurance', icon: 'insurance', color: 0xFF673AB7, parent: 'Home'),
        CategoryDef(name: 'Repairs & Maintenance', icon: 'repair', color: 0xFF2196F3, parent: 'Home'),
        CategoryDef(name: 'Plumber / Electrician', icon: 'repair', color: 0xFF00BCD4, parent: 'Home'),
        CategoryDef(name: 'Maid / Cook', icon: 'home', color: 0xFFFF9800, parent: 'Home'),
        CategoryDef(name: 'Interior & Furniture', icon: 'home', color: 0xFF8D6E63, parent: 'Home'),
        CategoryDef(name: 'Painting & Renovation', icon: 'home', color: 0xFFE91E63, parent: 'Home'),
        CategoryDef(name: 'Security / CCTV', icon: 'home', color: 0xFF455A64, parent: 'Home'),
        CategoryDef(name: 'Pest Control', icon: 'cleaning', color: 0xFF4CAF50, parent: 'Home'),
        CategoryDef(name: 'Water Tanker', icon: 'home', color: 0xFF03A9F4, parent: 'Home'),
        CategoryDef(name: 'Gas Cylinder', icon: 'gas', color: 0xFFFF5722, parent: 'Home'),

        // Income
        CategoryDef(name: 'Rental Income', icon: 'home', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Property Sale', icon: 'home', color: 0xFF2196F3, type: CategoryType.income),
      ];
}
