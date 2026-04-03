import 'package:mudra_manager/core/db/models/category.dart';
import 'category_pack.dart';

class WeddingPlannerPack extends CategoryPack {
  static final instance = WeddingPlannerPack._();
  WeddingPlannerPack._();

  @override
  String get id => 'com.mudra.pack.wedding_planner';
  @override
  String get name => 'Wedding Planner';
  @override
  String get description => 'Venue, catering, outfits, jewellery & all shaadi expenses';
  @override
  String get icon => 'gift';
  @override
  int get color => 0xFFD4AF37;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(name: 'Wedding', icon: 'gift', color: 0xFFD4AF37),
        CategoryDef(name: 'Venue & Banquet', icon: 'home', color: 0xFF8D6E63, parent: 'Wedding'),
        CategoryDef(name: 'Catering', icon: 'restaurant', color: 0xFFFF9800, parent: 'Wedding'),
        CategoryDef(name: 'Decoration & Flowers', icon: 'gift', color: 0xFFE91E63, parent: 'Wedding'),
        CategoryDef(name: 'Photography & Video', icon: 'photography', color: 0xFF2196F3, parent: 'Wedding'),
        CategoryDef(name: 'Outfits & Tailoring', icon: 'shopping_bag', color: 0xFF9C27B0, parent: 'Wedding'),
        CategoryDef(name: 'Wedding Jewellery', icon: 'gift', color: 0xFFFFD600, parent: 'Wedding'),
        CategoryDef(name: 'Invitations & Cards', icon: 'receipt', color: 0xFF607D8B, parent: 'Wedding'),
        CategoryDef(name: 'Mehendi & Makeup', icon: 'spa', color: 0xFF4CAF50, parent: 'Wedding'),
        CategoryDef(name: 'DJ / Band / Sangeet', icon: 'concert', color: 0xFF3F51B5, parent: 'Wedding'),
        CategoryDef(name: 'Pandit / Rituals', icon: 'temple', color: 0xFFFF5722, parent: 'Wedding'),
        CategoryDef(name: 'Guest Travel & Stay', icon: 'hotel', color: 0xFF00BCD4, parent: 'Wedding'),
        CategoryDef(name: 'Gifts & Trousseau', icon: 'gift', color: 0xFFF44336, parent: 'Wedding'),
        CategoryDef(name: 'Honeymoon', icon: 'flight', color: 0xFF03A9F4, parent: 'Wedding'),

        // Income
        CategoryDef(name: 'Wedding Gifts Received', icon: 'gift', color: 0xFF4CAF50, type: CategoryType.income),
        CategoryDef(name: 'Shagun / Cash Gifts', icon: 'wallet', color: 0xFFFF9800, type: CategoryType.income),
      ];
}
