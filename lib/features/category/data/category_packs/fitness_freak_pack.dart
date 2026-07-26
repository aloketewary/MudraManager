import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class FitnessFreakPack extends CategoryPack {
  static final instance = FitnessFreakPack._();
  FitnessFreakPack._();

  @override
  String get id => 'com.mudra.pack.fitness_freak';
  @override
  String get name => 'Fitness Freak';
  @override
  String get description => 'Gym, supplements, gear & event fees';
  @override
  String get icon => 'fitness';
  @override
  int get color => 0xFFFF6D00;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(name: 'Fitness', icon: 'fitness', color: 0xFFFF6D00),
        CategoryDef(name: 'Gym Membership', icon: 'fitness', color: 0xFFF44336, parent: 'Fitness'),
        CategoryDef(name: 'Supplements & Protein', icon: 'restaurant', color: 0xFF4CAF50, parent: 'Fitness'),
        CategoryDef(name: 'Sportswear', icon: 'shopping_bag', color: 0xFF2196F3, parent: 'Fitness'),
        CategoryDef(name: 'Fitness Equipment', icon: 'fitness', color: 0xFF455A64, parent: 'Fitness'),
        CategoryDef(name: 'Marathon / Event Fee', icon: 'trophy', color: 0xFFFFD600, parent: 'Fitness'),
        CategoryDef(name: 'Sports Coaching', icon: 'school', color: 0xFF9C27B0, parent: 'Fitness'),
        CategoryDef(name: 'Yoga / Pilates', icon: 'spa', color: 0xFF00BCD4, parent: 'Fitness'),
        CategoryDef(name: 'Diet & Meal Plan', icon: 'restaurant', color: 0xFFFF9800, parent: 'Fitness'),

        // Income
        CategoryDef(name: 'Coaching Income', icon: 'fitness', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Prize Money', icon: 'trophy', color: 0xFFFFD600, type: CategoryType.income),
      ];
}
