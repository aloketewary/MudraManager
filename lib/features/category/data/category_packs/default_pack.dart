import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class DefaultPack extends CategoryPack {
  static final instance = DefaultPack._();
  DefaultPack._();

  @override
  String get id => 'com.mudra.pack.default';
  @override
  String get name => 'Default';
  @override
  String get description => 'Essential categories for everyday tracking';
  @override
  String get icon => 'grid';
  @override
  int get color => 0xFF2196F3;
  @override
  List<String> get extendsPackIds => [];

  @override
  List<CategoryDef> get categories => const [
        // ── Income parents ──
        CategoryDef(
          name: 'Salary',
          icon: 'attach_money',
          color: 0xFF4CAF50,
          type: CategoryType.income,
        ),
        CategoryDef(
          name: 'Business Income',
          icon: 'coworking',
          color: 0xFF009688,
          type: CategoryType.income,
        ),
        CategoryDef(
          name: 'Investment',
          icon: 'trending_up',
          color: 0xFF2196F3,
          type: CategoryType.income,
        ),
        CategoryDef(
          name: 'Other Income',
          icon: 'pocket_money',
          color: 0xFF8BC34A,
          type: CategoryType.income,
        ),

        // ── Expense parents ──
        CategoryDef(name: 'Food', icon: 'restaurant', color: 0xFFFF9800),
        CategoryDef(
          name: 'Transport',
          icon: 'directions_car',
          color: 0xFF9C27B0,
        ),
        CategoryDef(name: 'Shopping', icon: 'shopping_bag', color: 0xFFF44336),
        CategoryDef(name: 'Bills', icon: 'receipt', color: 0xFF795548),
        CategoryDef(name: 'Entertainment', icon: 'movie', color: 0xFF3F51B5),
        CategoryDef(
          name: 'Healthcare',
          icon: 'local_hospital',
          color: 0xFF00BCD4,
        ),
        CategoryDef(name: 'Education', icon: 'school', color: 0xFFCDDC39),
        CategoryDef(name: 'Personal Care', icon: 'spa', color: 0xFFE91E63),
        CategoryDef(
          name: 'Religious & Spiritual',
          icon: 'tithe',
          color: 0xFFFF5722,
        ),
        CategoryDef(name: 'Gifts & Social', icon: 'gift', color: 0xFF9C27B0),

        // ── Children ──
        CategoryDef(
          name: 'Groceries',
          icon: 'basket',
          color: 0xFFFF5722,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Restaurant',
          icon: 'fastfood',
          color: 0xFFFFAB40,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Fuel',
          icon: 'local_gas_station',
          color: 0xFF7B1FA2,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Public Transport',
          icon: 'directions_bus',
          color: 0xFFEA80FC,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Clothing',
          icon: 'checkroom',
          color: 0xFFFF5252,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Electronics',
          icon: 'devices',
          color: 0xFFE91E63,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Electricity',
          icon: 'bolt',
          color: 0xFFFFC107,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Internet',
          icon: 'wifi',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Rent',
          icon: 'home',
          color: 0xFF795548,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Phone Recharge',
          icon: 'recharge',
          color: 0xFF546E7A,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Movies & Cinema',
          icon: 'movie',
          color: 0xFF3949AB,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Streaming/OTT',
          icon: 'streaming',
          color: 0xFF7B1FA2,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Doctor Visit',
          icon: 'medical',
          color: 0xFF0097A7,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Medicines',
          icon: 'pharmacy',
          color: 0xFF43A047,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Tuition/Fees',
          icon: 'school',
          color: 0xFF0097A7,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Books',
          icon: 'book',
          color: 0xFF303F9F,
          parent: 'Education',
        ),
        CategoryDef(
          name: 'Salon/Barber',
          icon: 'haircut',
          color: 0xFFFF9800,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Gym/Fitness',
          icon: 'fitness',
          color: 0xFFFF5722,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Puja & Rituals',
          icon: 'temple',
          color: 0xFFFF9800,
          parent: 'Religious & Spiritual',
        ),
        CategoryDef(
          name: 'Donations',
          icon: 'donation',
          color: 0xFF795548,
          parent: 'Religious & Spiritual',
        ),
        CategoryDef(
          name: 'Gifts',
          icon: 'gift',
          color: 0xFF7B1FA2,
          parent: 'Gifts & Social',
        ),
        CategoryDef(
          name: 'Weddings',
          icon: 'celebration',
          color: 0xFFD81B60,
          parent: 'Gifts & Social',
        ),
      ];
}
