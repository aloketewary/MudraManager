import 'category_pack.dart';

class HealthPack extends CategoryPack {
  static final instance = HealthPack._();
  HealthPack._();

  @override
  String get id => 'com.mudra.pack.health';
  @override
  String get name => 'Health & Wellness';
  @override
  String get description => 'Fitness, diet & medical tracking';
  @override
  String get icon => 'fitness';
  @override
  int get color => 0xFF4CAF50;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Gym Membership',
          icon: 'fitness',
          color: 0xFFFF5722,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Yoga/Meditation',
          icon: 'yoga',
          color: 0xFF9C27B0,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Supplements',
          icon: 'pharmacy',
          color: 0xFF8BC34A,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Diet Food',
          icon: 'salad',
          color: 0xFF4CAF50,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Sports Equipment',
          icon: 'sports',
          color: 0xFF2196F3,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Health Checkup',
          icon: 'heartbeat',
          color: 0xFF00BCD4,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Therapy/Counselling',
          icon: 'therapy',
          color: 0xFF009688,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Ayurveda/Homeopathy',
          icon: 'ayurveda',
          color: 0xFF795548,
          parent: 'Healthcare',
        ),
      ];
}
