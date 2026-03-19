import 'category_pack.dart';

class IndianCommonPack extends CategoryPack {
  static final instance = IndianCommonPack._();
  IndianCommonPack._();

  @override
  String get id => 'com.mudra.pack.indian_common';
  @override
  String get name => 'Indian Common';
  @override
  String get description => 'Shared Indian lifestyle categories';
  @override
  String get icon => 'map';
  @override
  int get color => 0xFFFF9800;
  @override
  bool get hidden => true;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        // Food
        CategoryDef(
          name: 'Street Food',
          icon: 'fastfood',
          color: 0xFFFF5722,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Sweets & Mithai',
          icon: 'cake',
          color: 0xFFE91E63,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Tea & Chai',
          icon: 'coffee',
          color: 0xFF795548,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Tiffin Service',
          icon: 'restaurant',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        // Transport
        CategoryDef(
          name: 'Auto Rickshaw',
          icon: 'taxi',
          color: 0xFFFFEB3B,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Local Train',
          icon: 'train',
          color: 0xFF2196F3,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Bus Travel',
          icon: 'bus',
          color: 0xFF9C27B0,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Metro',
          icon: 'subway',
          color: 0xFF00BCD4,
          parent: 'Transport',
        ),
        // Shopping
        CategoryDef(
          name: 'Kirana Store',
          icon: 'groceries',
          color: 0xFF4CAF50,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Vegetable Market',
          icon: 'basket',
          color: 0xFF8BC34A,
          parent: 'Shopping',
        ),
        // Bills
        CategoryDef(
          name: 'LPG Cylinder',
          icon: 'gas_bill',
          color: 0xFFF44336,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'DTH/Cable TV',
          icon: 'tv',
          color: 0xFF3F51B5,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Newspaper',
          icon: 'newspaper',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'RO Water Service',
          icon: 'water',
          color: 0xFF03A9F4,
          parent: 'Bills',
        ),
        // Personal Care / Services
        CategoryDef(
          name: 'Domestic Help',
          icon: 'cleaning',
          color: 0xFF8BC34A,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Laundry/Dhobi',
          icon: 'laundry',
          color: 0xFF03A9F4,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Barber/Salon',
          icon: 'haircut',
          color: 0xFFFF9800,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Milk Delivery',
          icon: 'milk',
          color: 0xFFFFFFFF,
          parent: 'Food',
        ),
      ];
}
