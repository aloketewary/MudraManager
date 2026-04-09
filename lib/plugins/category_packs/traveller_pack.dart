import 'category_pack.dart';

class TravellerPack extends CategoryPack {
  static final instance = TravellerPack._();
  TravellerPack._();

  @override
  String get id => 'com.mudra.pack.traveller';
  @override
  String get name => 'Traveller';
  @override
  String get description => 'Flights, hotels & adventures';
  @override
  String get icon => 'flight';
  @override
  int get color => 0xFF2196F3;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Flights',
          icon: 'flight',
          color: 0xFF1E88E5,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Hotels',
          icon: 'hotel',
          color: 0xFF1565C0,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Visa & Passport',
          icon: 'passport',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Travel Insurance',
          icon: 'insurance',
          color: 0xFFFF9800,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Sightseeing',
          icon: 'photography',
          color: 0xFF4CAF50,
          parent: 'Entertainment',
        ),
        CategoryDef(
          name: 'Souvenirs',
          icon: 'gift',
          color: 0xFF9C27B0,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Airport Transfer',
          icon: 'taxi',
          color: 0xFFFFEB3B,
          parent: 'Transport',
        ),
        CategoryDef(
          name: 'Luggage & Gear',
          icon: 'luggage',
          color: 0xFF795548,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Travel Food',
          icon: 'restaurant',
          color: 0xFFFF9800,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Currency Exchange',
          icon: 'neft',
          color: 0xFF009688,
          parent: 'Bills',
        ),
      ];
}
