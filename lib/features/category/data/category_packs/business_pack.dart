import 'category_pack.dart';

class BusinessPack extends CategoryPack {
  static final instance = BusinessPack._();
  BusinessPack._();

  @override
  String get id => 'com.mudra.pack.business';
  @override
  String get name => 'Business';
  @override
  String get description => 'Business accounting & professional expenses';
  @override
  String get icon => 'briefcase';
  @override
  int get color => 0xFF607D8B;
  @override
  List<String> get extendsPackIds => ['com.mudra.pack.default'];

  @override
  List<CategoryDef> get categories => const [
        // Own parents
        CategoryDef(name: 'Office Rent', icon: 'business', color: 0xFF2196F3),
        CategoryDef(
          name: 'Office Supplies',
          icon: 'stationery',
          color: 0xFF4CAF50,
        ),
        CategoryDef(name: 'Equipment', icon: 'computer', color: 0xFF9C27B0),
        CategoryDef(
          name: 'Software & Licenses',
          icon: 'devices',
          color: 0xFF00BCD4,
        ),
        CategoryDef(name: 'Marketing', icon: 'presentation', color: 0xFFFF5722),
        CategoryDef(name: 'Advertising', icon: 'tv', color: 0xFFE91E63),
        CategoryDef(
            name: 'Website & Domain', icon: 'broadband', color: 0xFF3F51B5,),
        CategoryDef(name: 'Legal Fees', icon: 'work', color: 0xFF607D8B),
        CategoryDef(
          name: 'Accounting',
          icon: 'receipt_long',
          color: 0xFF8BC34A,
        ),
        CategoryDef(name: 'Insurance', icon: 'insurance', color: 0xFFFF9800),
        CategoryDef(name: 'Business Travel', icon: 'flight', color: 0xFF2196F3),
        CategoryDef(name: 'Fuel & Vehicle', icon: 'gas', color: 0xFFF44336),
        // Children
        CategoryDef(
          name: 'Monthly Rent',
          icon: 'home',
          color: 0xFF1E88E5,
          parent: 'Office Rent',
        ),
        CategoryDef(
          name: 'Security Deposit',
          icon: 'bank',
          color: 0xFF1565C0,
          parent: 'Office Rent',
        ),
        CategoryDef(
          name: 'Maintenance',
          icon: 'repair',
          color: 0xFF42A5F5,
          parent: 'Office Rent',
        ),
        CategoryDef(
          name: 'Stationery',
          icon: 'stationery',
          color: 0xFF43A047,
          parent: 'Office Supplies',
        ),
        CategoryDef(
          name: 'Printer Supplies',
          icon: 'print',
          color: 0xFF388E3C,
          parent: 'Office Supplies',
        ),
        CategoryDef(
          name: 'Furniture',
          icon: 'furniture',
          color: 0xFF66BB6A,
          parent: 'Office Supplies',
        ),
        CategoryDef(
          name: 'Computers',
          icon: 'computer',
          color: 0xFF8E24AA,
          parent: 'Equipment',
        ),
        CategoryDef(
          name: 'Phones',
          icon: 'phone',
          color: 0xFF7B1FA2,
          parent: 'Equipment',
        ),
        CategoryDef(
          name: 'Machinery',
          icon: 'tools',
          color: 0xFFAB47BC,
          parent: 'Equipment',
        ),
        CategoryDef(
          name: 'Software Licenses',
          icon: 'devices',
          color: 0xFF00ACC1,
          parent: 'Software & Licenses',
        ),
        CategoryDef(
          name: 'Subscriptions',
          icon: 'repeat',
          color: 0xFF0097A7,
          parent: 'Software & Licenses',
        ),
        CategoryDef(
          name: 'Cloud Services',
          icon: 'broadband',
          color: 0xFF26C6DA,
          parent: 'Software & Licenses',
        ),
        CategoryDef(
          name: 'Digital Marketing',
          icon: 'networking',
          color: 0xFFF4511E,
          parent: 'Marketing',
        ),
        CategoryDef(
          name: 'Print Ads',
          icon: 'print',
          color: 0xFFE64A19,
          parent: 'Marketing',
        ),
        CategoryDef(
          name: 'Events',
          icon: 'celebration',
          color: 0xFFFF7043,
          parent: 'Marketing',
        ),
        CategoryDef(
          name: 'Online Ads',
          icon: 'scan_pay',
          color: 0xFFD81B60,
          parent: 'Advertising',
        ),
        CategoryDef(
          name: 'TV/Radio',
          icon: 'tv',
          color: 0xFFC2185B,
          parent: 'Advertising',
        ),
        CategoryDef(
          name: 'Outdoor',
          icon: 'photo',
          color: 0xFFEC407A,
          parent: 'Advertising',
        ),
        CategoryDef(
          name: 'Domain',
          icon: 'broadband',
          color: 0xFF3949AB,
          parent: 'Website & Domain',
        ),
        CategoryDef(
          name: 'Hosting',
          icon: 'freelance',
          color: 0xFF303F9F,
          parent: 'Website & Domain',
        ),
        CategoryDef(
          name: 'Development',
          icon: 'coding',
          color: 0xFF5C6BC0,
          parent: 'Website & Domain',
        ),
        CategoryDef(
          name: 'Consultation',
          icon: 'work',
          color: 0xFF546E7A,
          parent: 'Legal Fees',
        ),
        CategoryDef(
          name: 'Documentation',
          icon: 'patent',
          color: 0xFF455A64,
          parent: 'Legal Fees',
        ),
        CategoryDef(
          name: 'Court Fees',
          icon: 'bank',
          color: 0xFF78909C,
          parent: 'Legal Fees',
        ),
        CategoryDef(
          name: 'CA Fees',
          icon: 'receipt_long',
          color: 0xFF7CB342,
          parent: 'Accounting',
        ),
        CategoryDef(
          name: 'Audit',
          icon: 'exam',
          color: 0xFF689F38,
          parent: 'Accounting',
        ),
        CategoryDef(
          name: 'Tax Filing',
          icon: 'tax',
          color: 0xFF9CCC65,
          parent: 'Accounting',
        ),
        CategoryDef(
          name: 'Business Insurance',
          icon: 'insurance',
          color: 0xFFFB8C00,
          parent: 'Insurance',
        ),
        CategoryDef(
          name: 'Health Insurance',
          icon: 'health_insurance',
          color: 0xFFF57C00,
          parent: 'Insurance',
        ),
        CategoryDef(
          name: 'Vehicle Insurance',
          icon: 'directions_car',
          color: 0xFFFFA726,
          parent: 'Insurance',
        ),
        CategoryDef(
          name: 'Flight',
          icon: 'flight',
          color: 0xFF1E88E5,
          parent: 'Business Travel',
        ),
        CategoryDef(
          name: 'Hotel',
          icon: 'hotel',
          color: 0xFF1565C0,
          parent: 'Business Travel',
        ),
        CategoryDef(
          name: 'Local Transport',
          icon: 'taxi',
          color: 0xFF42A5F5,
          parent: 'Business Travel',
        ),
        CategoryDef(
          name: 'Petrol/Diesel',
          icon: 'gas',
          color: 0xFFE53935,
          parent: 'Fuel & Vehicle',
        ),
        CategoryDef(
          name: 'Vehicle Maintenance',
          icon: 'repair',
          color: 0xFFC62828,
          parent: 'Fuel & Vehicle',
        ),
        CategoryDef(
          name: 'Parking',
          icon: 'parking',
          color: 0xFFEF5350,
          parent: 'Fuel & Vehicle',
        ),
      ];
}
