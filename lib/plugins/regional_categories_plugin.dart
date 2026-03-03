import 'package:mudra_plugin_sdk/mudra_plugin_sdk.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';

class RegionalCategoriesPlugin extends MudraPlugin {
  @override
  String get id => 'com.mudra.regional_categories';

  @override
  String get name => 'Regional Categories';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'India-specific regional expense categories';

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

  static const List<Map<String, dynamic>> regionalCategories = [
    // Indian Food & Dining
    {'name': 'Street Food', 'icon': 'fastfood', 'color': 0xFFFF5722},
    {'name': 'Sweets & Mithai', 'icon': 'cake', 'color': 0xFFE91E63},
    {'name': 'Tea & Chai', 'icon': 'coffee', 'color': 0xFF795548},
    {'name': 'Tiffin Service', 'icon': 'restaurant', 'color': 0xFF4CAF50},

    // Transportation
    {'name': 'Auto Rickshaw', 'icon': 'taxi', 'color': 0xFFFFEB3B},
    {'name': 'Local Train', 'icon': 'train', 'color': 0xFF2196F3},
    {'name': 'Bus Travel', 'icon': 'bus', 'color': 0xFF9C27B0},
    {'name': 'Metro', 'icon': 'subway', 'color': 0xFF00BCD4},

    // Indian Services
    {'name': 'Domestic Help', 'icon': 'cleaning', 'color': 0xFF8BC34A},
    {'name': 'Laundry/Dhobi', 'icon': 'laundry', 'color': 0xFF03A9F4},
    {'name': 'Barber/Salon', 'icon': 'beauty', 'color': 0xFFFF9800},
    {'name': 'Milk Delivery', 'icon': 'delivery', 'color': 0xFFFFFFFF},

    // Festivals & Occasions
    {'name': 'Festival Expenses', 'icon': 'celebration', 'color': 0xFFE91E63},
    {'name': 'Puja Items', 'icon': 'spa', 'color': 0xFFFF9800},
    {'name': 'Wedding Gifts', 'icon': 'gift', 'color': 0xFF9C27B0},
    {'name': 'Religious Donations', 'icon': 'donation', 'color': 0xFF795548},

    // Indian Shopping
    {'name': 'Kirana Store', 'icon': 'groceries', 'color': 0xFF4CAF50},
    {'name': 'Vegetable Market', 'icon': 'groceries', 'color': 0xFF8BC34A},
    {'name': 'Clothing/Textile', 'icon': 'clothing', 'color': 0xFFE91E63},
    {'name': 'Jewelry', 'icon': 'gift', 'color': 0xFFFFEB3B},

    // Utilities & Services
    {'name': 'LPG Cylinder', 'icon': 'gas', 'color': 0xFFF44336},
    {'name': 'DTH/Cable TV', 'icon': 'tv', 'color': 0xFF3F51B5},
    {'name': 'Newspaper', 'icon': 'mail', 'color': 0xFF607D8B},
    {'name': 'RO Water Service', 'icon': 'water', 'color': 0xFF03A9F4},
  ];

  @override
  Future<void> initialize() async {
    // Categories will be added when plugin is enabled
  }

  @override
  Future<void> dispose() async {
    // Categories remain even after plugin is disabled
  }

  static List<Category> getRegionalCategories() {
    return regionalCategories
        .map((cat) => Category.create(
              name: cat['name'],
              categoryType: CategoryType.expense,
            )
              ..iconName = cat['icon']
              ..colorValue = cat['color'],)
        .toList();
  }
}
