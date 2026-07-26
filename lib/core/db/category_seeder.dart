import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';
import 'package:mudra_manager/features/category/data/category_packs/category_pack.dart';

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

    // Keys MUST match real seeded category names exactly (see
    // default_pack.dart / indian_common_pack.dart) — matching is exact,
    // case-insensitive, not substring. A previous version used
    // `.contains()` with keys like 'Food & Dining'/'Transportation'/
    // 'Utilities' that don't exist as actual category names (the real
    // ones are 'Food'/'Transport'/'Bills'), so almost none of the default
    // categories ever received keywords and auto-categorization silently
    // fell back to weak heuristics for most transactions.
    final keywordMap = {
      // ── Food (parent + children) ──
      'Food': [
        'swiggy',
        'zomato',
        'food',
        'dining',
        'cafe',
        'kfc',
        'mcdonalds',
        'dominos',
        'subway',
        'starbucks',
        'ccd',
        'dunkin',
        'canteen',
        'mess',
        'tiffin',
        'fastfood',
      ],
      'Groceries': [
        'bigbasket',
        'blinkit',
        'zepto',
        'grocery',
        'supermarket',
        'dmart',
        'reliance fresh',
        'more',
        'easyday',
        'spencer',
        'vegetables',
        'fruits',
        'milk',
        'bread',
        'rice',
        'dal',
        'flour',
      ],
      'Restaurant': [
        'restaurant',
        'pizza',
        'burger',
        'bakery',
        'biryani',
        'chinese',
        'italian',
        'diner',
        'eatery',
      ],

      // ── Transport (parent + children) ──
      'Transport': [
        'uber',
        'ola',
        'rapido',
        'taxi',
        'cab',
        'auto',
        'rickshaw',
        'transport',
        'commute',
      ],
      'Fuel': [
        'petrol',
        'diesel',
        'cng',
        'fuel',
        'gas station',
        'pump',
        'indianoil',
        'hpcl',
        'bpcl',
        'shell',
      ],
      'Public Transport': [
        'metro',
        'bus',
        'train',
        'railway',
        'irctc',
        'parking',
        'toll',
      ],

      // ── Shopping (parent + children) ──
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
        'accessories',
        'jewellery',
      ],
      'Clothing': [
        'clothes',
        'shoes',
        'fashion',
        'apparel',
        'footwear',
      ],
      'Electronics': [
        'electronics',
        'mobile phone',
        'laptop',
        'gadget',
        'croma',
        'reliance digital',
        'vijay sales',
      ],

      // ── Bills (parent + children) ──
      'Bills': [
        'bill',
        'maintenance',
        'society',
        'apartment',
      ],
      'Electricity': [
        'electricity',
        'power bill',
        'discom',
        'electricity board',
      ],
      'Internet': [
        'internet',
        'broadband',
        'wifi',
        'airtel',
        'jio fiber',
        'act fibernet',
        'excitel',
      ],
      'Rent': [
        'house rent',
        'rent paid',
        'landlord',
        'monthly rent',
      ],
      'Phone Recharge': [
        'recharge',
        'airtel',
        'jio',
        'vi ',
        'bsnl',
        'postpaid',
        'prepaid',
      ],

      // ── Entertainment (parent + children) ──
      'Entertainment': [
        'bookmyshow',
        'games',
        'concert',
        'show',
        'theatre',
        'music',
      ],
      'Movies & Cinema': [
        'movie',
        'cinema',
        'pvr',
        'inox',
        'multiplex',
      ],
      'Streaming/OTT': [
        'netflix',
        'prime video',
        'hotstar',
        'spotify',
        'youtube premium',
        'disney',
        'zee5',
        'sonyliv',
        'voot',
        'jiocinema',
        'streaming',
      ],

      // ── Healthcare (parent + children) ──
      'Healthcare': [
        'hospital',
        'clinic',
        'dental',
        'eye',
        'checkup',
        'consultation',
        'lab',
        'test',
        'surgery',
        'treatment',
        'apollo',
      ],
      'Doctor Visit': [
        'doctor',
        'physician',
        'consultation fee',
        'opd',
      ],
      'Medicines': [
        'pharmacy',
        'medicine',
        'medplus',
        'netmeds',
        '1mg',
        'pharmeasy',
        'chemist',
      ],

      // ── Education (parent + children) ──
      'Education': [
        'school',
        'college',
        'university',
        'course',
        'exam',
        'coaching',
        'udemy',
        'coursera',
        'byju',
        'unacademy',
        'vedantu',
        'library',
      ],
      'Tuition/Fees': [
        'tuition',
        'fees',
        'admission fee',
      ],
      'Books': [
        'books',
        'stationery',
        'bookstore',
      ],

      // ── Personal Care (parent + children) ──
      'Personal Care': [
        'spa',
        'parlour',
        'facial',
        'massage',
        'beauty',
        'cosmetics',
        'skincare',
        'grooming',
      ],
      'Salon/Barber': [
        'salon',
        'barber',
        'haircut',
      ],
      'Gym/Fitness': [
        'gym',
        'fitness',
        'yoga',
        'cult.fit',
        'workout',
      ],

      // ── Religious & Spiritual (parent + children) ──
      'Religious & Spiritual': [
        'temple',
        'church',
        'mosque',
        'gurudwara',
      ],
      'Puja & Rituals': [
        'puja',
        'pooja',
        'ritual',
        'pandit',
      ],
      'Donations': [
        'donation',
        'charity',
        'dakshina',
      ],

      // ── Gifts & Social (parent + children) ──
      'Gifts & Social': [
        'present',
        'festival',
        'birthday',
        'anniversary',
      ],
      'Gifts': [
        'gift',
      ],
      'Weddings': [
        'wedding',
        'marriage',
        'shaadi',
      ],

      // ── Income ──
      'Salary': [
        'salary',
        'wages',
        'payroll',
        'payment received',
        'bonus',
        'incentive',
        'allowance',
      ],
      'Business Income': [
        'business income',
        'consulting',
        'freelance',
        'commission',
        'invoice paid',
      ],
      'Investment': [
        'mutual fund',
        'stock',
        'sip',
        'dividend',
        'interest credited',
        'zerodha',
        'groww',
        'upstox',
        'shares',
        'equity',
        'fd matured',
        'rd matured',
      ],
    };

    final keywordMapLower = {
      for (final entry in keywordMap.entries) entry.key.toLowerCase(): entry.value,
    };

    await isar.writeTxn(() async {
      for (final category in categories) {
        if (category.keywords == null || category.keywords!.isEmpty) {
          final keywords = keywordMapLower[category.name.toLowerCase()];
          if (keywords != null) {
            category.keywords = keywords;
            await isar.categorys.put(category);
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
