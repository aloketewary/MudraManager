import 'category_pack.dart';

class FreelancerPack extends CategoryPack {
  static final instance = FreelancerPack._();
  FreelancerPack._();

  @override
  String get id => 'com.mudra.pack.freelancer';
  @override
  String get name => 'Freelancer';
  @override
  String get description => 'Gig economy, WFH & self-employed';
  @override
  String get icon => 'computer';
  @override
  int get color => 0xFF9C27B0;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        CategoryDef(
          name: 'Coworking Space',
          icon: 'coworking',
          color: 0xFF2196F3,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Client Meetings',
          icon: 'coffee',
          color: 0xFF795548,
          parent: 'Food',
        ),
        CategoryDef(
          name: 'Software Tools',
          icon: 'coding',
          color: 0xFF9C27B0,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Internet/Data',
          icon: 'wifi',
          color: 0xFF00BCD4,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Tax (GST)',
          icon: 'gst',
          color: 0xFFF44336,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Invoice Payment',
          icon: 'invoice',
          color: 0xFF4CAF50,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Domain & Hosting',
          icon: 'broadband',
          color: 0xFF607D8B,
          parent: 'Bills',
        ),
        CategoryDef(
          name: 'Portfolio/Website',
          icon: 'freelance',
          color: 0xFF3F51B5,
          parent: 'Bills',
        ),
      ];
}
