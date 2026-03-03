import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';

class BusinessCategoriesPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.business_categories';

  @override
  String get name => 'Business Categories';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Industry-specific business expense categories';

  @override
  String get author => 'Mudra Team';

  @override
  void onLoad() {
    // Plugin loaded
  }

  @override
  void onStart() {
    // Plugin started
  }

  static const List<Map<String, dynamic>> businessCategories = [
    // Office & Operations
    {
      'name': 'Office Rent',
      'icon': 'business',
      'color': 0xFF2196F3,
      'subcategories': ['Monthly Rent', 'Security Deposit', 'Maintenance'],
    },
    {
      'name': 'Office Supplies',
      'icon': 'receipt',
      'color': 0xFF4CAF50,
      'subcategories': ['Stationery', 'Printer Supplies', 'Furniture'],
    },
    {
      'name': 'Equipment',
      'icon': 'computer',
      'color': 0xFF9C27B0,
      'subcategories': ['Computers', 'Phones', 'Machinery'],
    },
    {
      'name': 'Software & Licenses',
      'icon': 'devices',
      'color': 0xFF00BCD4,
      'subcategories': ['Software Licenses', 'Subscriptions', 'Cloud Services'],
    },

    // Marketing & Sales
    {
      'name': 'Marketing',
      'icon': 'trending_up',
      'color': 0xFFFF5722,
      'subcategories': ['Digital Marketing', 'Print Ads', 'Events'],
    },
    {
      'name': 'Advertising',
      'icon': 'tv',
      'color': 0xFFE91E63,
      'subcategories': ['Online Ads', 'TV/Radio', 'Outdoor'],
    },
    {
      'name': 'Website & Domain',
      'icon': 'wifi',
      'color': 0xFF3F51B5,
      'subcategories': ['Domain', 'Hosting', 'Development'],
    },

    // Professional Services
    {
      'name': 'Legal Fees',
      'icon': 'work',
      'color': 0xFF607D8B,
      'subcategories': ['Consultation', 'Documentation', 'Court Fees'],
    },
    {
      'name': 'Accounting',
      'icon': 'receipt_long',
      'color': 0xFF8BC34A,
      'subcategories': ['CA Fees', 'Audit', 'Tax Filing'],
    },
    {
      'name': 'Insurance',
      'icon': 'insurance',
      'color': 0xFFFF9800,
      'subcategories': [
        'Business Insurance',
        'Health Insurance',
        'Vehicle Insurance',
      ],
    },

    // Travel & Transport
    {
      'name': 'Business Travel',
      'icon': 'flight',
      'color': 0xFF2196F3,
      'subcategories': ['Flight', 'Hotel', 'Local Transport'],
    },
    {
      'name': 'Fuel & Vehicle',
      'icon': 'gas',
      'color': 0xFFF44336,
      'subcategories': ['Petrol/Diesel', 'Vehicle Maintenance', 'Parking'],
    },
  ];

  @override
  Future<void> initialize() async {
    // Categories will be added when plugin is enabled
  }

  @override
  Future<void> dispose() async {
    // Categories remain even after plugin is disabled
  }

  static List<Category> getBusinessCategories() {
    final allCategories = <Category>[];

    for (final cat in businessCategories) {
      // Create parent category
      final parentCategory = Category.create(
        name: cat['name'],
        categoryType: CategoryType.expense,
      )
        ..iconName = cat['icon']
        ..colorValue = cat['color'];

      allCategories.add(parentCategory);

      // Create subcategories if they exist
      if (cat['subcategories'] != null) {
        final subcats = (cat['subcategories'] as List<String>).map((subName) {
          final subCategory = Category.create(
            name: subName,
            categoryType: CategoryType.expense,
          )
            ..iconName = cat['icon']
            ..colorValue = cat['color'];

          // Link to parent category
          subCategory.parentCategory.value = parentCategory;
          return subCategory;
        }).toList();

        allCategories.addAll(subcats);
      }
    }

    return allCategories;
  }
}
