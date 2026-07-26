import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class GamerPack extends CategoryPack {
  static final instance = GamerPack._();
  GamerPack._();

  @override
  String get id => 'com.mudra.pack.gamer';
  @override
  String get name => 'Gamer';
  @override
  String get description => 'Games, subscriptions, hardware & in-app purchases';
  @override
  String get icon => 'gaming_console';
  @override
  int get color => 0xFF7C4DFF;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(name: 'Gaming', icon: 'gaming_console', color: 0xFF7C4DFF),
        CategoryDef(name: 'Game Purchases', icon: 'shopping_cart', color: 0xFF536DFE, parent: 'Gaming'),
        CategoryDef(name: 'In-App Purchases', icon: 'shopping_bag', color: 0xFFFF9800, parent: 'Gaming'),
        CategoryDef(name: 'Gaming Subscription', icon: 'receipt', color: 0xFF4CAF50, parent: 'Gaming'),
        CategoryDef(name: 'Hardware & Peripherals', icon: 'electronics', color: 0xFF455A64, parent: 'Gaming'),
        CategoryDef(name: 'Internet / Server', icon: 'wifi', color: 0xFF00BCD4, parent: 'Gaming'),
        CategoryDef(name: 'Tournament / Event', icon: 'trophy', color: 0xFFFFD600, parent: 'Gaming'),

        // Income
        CategoryDef(name: 'Streaming Income', icon: 'gaming_console', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Tournament Winnings', icon: 'trophy', color: 0xFFFFD600, type: CategoryType.income),
      ];
}
