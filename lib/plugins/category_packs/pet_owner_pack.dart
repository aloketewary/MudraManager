import 'category_pack.dart';

class PetOwnerPack extends CategoryPack {
  static final instance = PetOwnerPack._();
  PetOwnerPack._();

  @override
  String get id => 'com.mudra.pack.pet_owner';
  @override
  String get name => 'Pet Owner';
  @override
  String get description => 'Vet, food & care for your pets';
  @override
  String get icon => 'pets';
  @override
  int get color => 0xFFFF9800;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Pet Food',
          icon: 'restaurant',
          color: 0xFFFF9800,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Vet Visits',
          icon: 'medical',
          color: 0xFF4CAF50,
          parent: 'Healthcare',
        ),
        CategoryDef(
          name: 'Pet Grooming',
          icon: 'haircut',
          color: 0xFFE91E63,
          parent: 'Personal Care',
        ),
        CategoryDef(
          name: 'Pet Accessories',
          icon: 'shopping_bag',
          color: 0xFF9C27B0,
          parent: 'Shopping',
        ),
        CategoryDef(
          name: 'Pet Insurance',
          icon: 'insurance',
          color: 0xFF2196F3,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Pet Boarding',
          icon: 'camping',
          color: 0xFF795548,
          parent: 'Bills',
        ),
      ];
}
