import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/plugins/category_packs/category_pack.dart';

class CategorySeeder {
  /// Sync icon & color from enabled pack definitions → DB categories.
  /// Runs on every app start so pack updates are always reflected.
  static Future<void> seedCategoryIcons(Isar isar) async {
    final marketplace = MarketplaceService();
    final allCategories = await isar.categorys.where().findAll();
    if (allCategories.isEmpty) return;

    final nameToCategory = {for (final c in allCategories) c.name: c};

    // Build definitive icon/color map from all enabled packs
    final defMap = <String, CategoryDef>{};
    for (final pack in CategoryPackRegistry.all) {
      if (!marketplace.isPluginEnabledSync(pack.id)) continue;
      for (final def in pack.categories) {
        defMap[def.name] = def;
      }
    }

    final toUpdate = <Category>[];
    for (final entry in defMap.entries) {
      final cat = nameToCategory[entry.key];
      if (cat == null) continue;
      final def = entry.value;
      if (cat.iconName == def.icon && cat.colorValue == def.color) continue;
      cat.iconName = def.icon;
      cat.colorValue = def.color;
      toUpdate.add(cat);
    }

    if (toUpdate.isEmpty) return;

    await isar.writeTxn(() async {
      await isar.categorys.putAll(toUpdate);
    });
  }

  static Future<void> seedDefaultKeywords(Isar isar) async {
    final categories = await isar.categorys.where().findAll();

    final keywordMap = {
      'Food & Dining': [
        'swiggy',
        'zomato',
        'restaurant',
        'food',
        'dining',
        'cafe',
        'pizza',
        'burger',
        'kfc',
        'mcdonalds',
        'dominos',
        'subway',
        'starbucks',
        'ccd',
        'dunkin',
        'bakery',
        'canteen',
        'mess',
        'tiffin',
        'biryani',
        'chinese',
        'italian',
        'fastfood',
      ],
      'Groceries': [
        'bigbasket',
        'blinkit',
        'zepto',
        'grocery',
        'supermarket',
        'dmart',
        'reliance',
        'fresh',
        'more',
        'easyday',
        'spencer',
        'nature',
        'basket',
        'vegetables',
        'fruits',
        'milk',
        'bread',
        'rice',
        'dal',
        'oil',
        'sugar',
        'flour',
      ],
      'Transportation': [
        'uber',
        'ola',
        'rapido',
        'taxi',
        'cab',
        'metro',
        'bus',
        'petrol',
        'fuel',
        'auto',
        'rickshaw',
        'train',
        'flight',
        'parking',
        'toll',
        'diesel',
        'cng',
        'bike',
        'car',
        'transport',
        'travel',
        'commute',
      ],
      'Shopping': [
        'amazon',
        'flipkart',
        'myntra',
        'shopping',
        'mall',
        'store',
        'ajio',
        'nykaa',
        'jabong',
        'snapdeal',
        'paytm mall',
        'clothes',
        'shoes',
        'electronics',
        'mobile',
        'laptop',
        'fashion',
        'accessories',
        'jewellery',
      ],
      'Entertainment': [
        'netflix',
        'prime',
        'hotstar',
        'spotify',
        'bookmyshow',
        'movie',
        'cinema',
        'youtube',
        'disney',
        'zee5',
        'sonyliv',
        'voot',
        'jiocinema',
        'games',
        'concert',
        'show',
        'theatre',
        'music',
        'streaming',
      ],
      'Utilities': [
        'electricity',
        'water',
        'gas',
        'internet',
        'broadband',
        'mobile',
        'recharge',
        'airtel',
        'jio',
        'vi',
        'bsnl',
        'wifi',
        'postpaid',
        'prepaid',
        'bill',
        'maintenance',
        'society',
        'apartment',
      ],
      'Healthcare': [
        'hospital',
        'doctor',
        'pharmacy',
        'medicine',
        'clinic',
        'apollo',
        'medplus',
        'netmeds',
        '1mg',
        'pharmeasy',
        'dental',
        'eye',
        'checkup',
        'consultation',
        'lab',
        'test',
        'surgery',
        'treatment',
      ],
      'Education': [
        'school',
        'college',
        'university',
        'course',
        'tuition',
        'books',
        'fees',
        'exam',
        'coaching',
        'online',
        'udemy',
        'coursera',
        'byju',
        'unacademy',
        'vedantu',
        'library',
        'stationery',
      ],
      'Travel': [
        'flight',
        'hotel',
        'booking',
        'makemytrip',
        'goibibo',
        'airbnb',
        'oyo',
        'treebo',
        'fab',
        'yatra',
        'cleartrip',
        'ixigo',
        'vacation',
        'trip',
        'tour',
        'visa',
        'passport',
      ],
      'Salary': [
        'salary',
        'wages',
        'income',
        'payment received',
        'bonus',
        'incentive',
        'commission',
        'freelance',
        'consulting',
        'part time',
        'overtime',
        'allowance',
      ],
      'Investment': [
        'mutual fund',
        'stock',
        'sip',
        'dividend',
        'interest',
        'zerodha',
        'groww',
        'upstox',
        'angel',
        'icicidirect',
        'hdfc sec',
        'kotak sec',
        'shares',
        'equity',
        'debt',
        'gold',
        'fd',
        'rd',
      ],
      'Insurance': [
        'lic',
        'hdfc life',
        'icici pru',
        'sbi life',
        'bajaj',
        'star health',
        'care',
        'religare',
        'premium',
        'policy',
        'claim',
        'health',
        'life',
        'motor',
        'term',
      ],
      'Personal Care': [
        'salon',
        'spa',
        'parlour',
        'haircut',
        'facial',
        'massage',
        'gym',
        'fitness',
        'yoga',
        'beauty',
        'cosmetics',
        'skincare',
        'grooming',
      ],
      'Home & Garden': [
        'furniture',
        'decor',
        'appliances',
        'repair',
        'maintenance',
        'cleaning',
        'gardening',
        'plants',
        'tools',
        'paint',
        'renovation',
        'interior',
      ],
      'Gifts & Donations': [
        'gift',
        'present',
        'donation',
        'charity',
        'temple',
        'church',
        'mosque',
        'gurudwara',
        'festival',
        'birthday',
        'anniversary',
        'wedding',
      ],
      'Business': [
        'office',
        'supplies',
        'equipment',
        'software',
        'license',
        'subscription',
        'marketing',
        'advertising',
        'printing',
        'courier',
        'legal',
        'accounting',
      ],
      'Miscellaneous': [
        'other',
        'misc',
        'general',
        'cash',
        'atm',
        'withdrawal',
        'transfer',
        'fees',
        'charges',
        'penalty',
        'fine',
        'tax',
        'gst',
      ],
    };

    await isar.writeTxn(() async {
      for (final category in categories) {
        if (category.keywords == null || category.keywords!.isEmpty) {
          for (final entry in keywordMap.entries) {
            if (category.name.toLowerCase().contains(entry.key.toLowerCase())) {
              category.keywords = entry.value;
              await isar.categorys.put(category);
              break;
            }
          }
        }
      }
    });
  }

  /// System categories for trip/split/settlement.
  /// Created once, hidden from user management.
  static const _systemCategories = [
    (
      name: 'Shared Expense',
      icon: 'split_bill',
      color: 0xFF3B82F6,
      type: CategoryType.expense,
    ),
    (
      name: 'Trip Expense',
      icon: 'card_travel',
      color: 0xFF8B5CF6,
      type: CategoryType.expense,
    ),
    (
      name: 'Settlement',
      icon: 'settlement',
      color: 0xFF10B981,
      type: CategoryType.expense,
    ),
    (
      name: 'Settlement Received',
      icon: 'settlement',
      color: 0xFF10B981,
      type: CategoryType.income,
    ),
  ];

  /// Seeds system categories if they don't exist.
  /// Safe to call on every app start — no-op if already seeded.
  static Future<void> seedSystemCategories(Isar isar) async {
    final existing = await isar.categorys.where().findAll();
    final existingByName = {for (final c in existing) c.name: c};

    final toCreate = <Category>[];
    final toUpdate = <Category>[];
    for (final def in _systemCategories) {
      final match = existingByName[def.name];
      if (match != null) {
        if (!match.isSystem) {
          match.isSystem = true;
          toUpdate.add(match);
        }
        continue;
      }
      toCreate.add(
        Category.create(name: def.name, categoryType: def.type)
          ..iconName = def.icon
          ..colorValue = def.color
          ..isSystem = true,
      );
    }

    if (toCreate.isEmpty && toUpdate.isEmpty) return;

    await isar.writeTxn(() async {
      if (toCreate.isNotEmpty) await isar.categorys.putAll(toCreate);
      if (toUpdate.isNotEmpty) await isar.categorys.putAll(toUpdate);
    });
  }

  /// Looks up a system category by name. Returns null if not found.
  static Future<Category?> getSystemCategory(
    Isar isar,
    String name,
  ) async {
    return isar.categorys
        .filter()
        .isSystemEqualTo(true)
        .nameEqualTo(name)
        .findFirst();
  }
}
