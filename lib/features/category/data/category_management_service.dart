import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/plugins/business_categories_plugin.dart';
import 'package:mudra_manager/plugins/regional_categories_plugin.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

class CategoryManagementService {
  static final MarketplaceService _marketplaceService = MarketplaceService();
  static final Map<String, List<Category>> _categoryCache = {}; // Cache categories

  static Future<void> installPluginCategories(String pluginId) async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final categories = _getCachedCategories(pluginId);
    if (categories.isEmpty) return;

    await isar.writeTxn(() async {
      // Batch check existing categories
      final existingNames = await isar.categorys
          .filter()
          .anyOf(categories, (q, category) => q.nameEqualTo(category.name))
          .nameProperty()
          .findAll();
      
      final existingSet = existingNames.toSet();
      final newCategories = categories.where((cat) => !existingSet.contains(cat.name)).toList();
      
      if (newCategories.isNotEmpty) {
        await isar.categorys.putAll(newCategories); // Batch insert
      }
    });
  }

  static Future<void> removePluginCategories(String pluginId) async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    final categoryNames = _getCategoryNames(pluginId);
    if (categoryNames.isEmpty) return;

    await isar.writeTxn(() async {
      // Batch delete by names
      final categoriesToDelete = await isar.categorys
          .filter()
          .anyOf(categoryNames, (q, name) => q.nameEqualTo(name))
          .findAll();
      
      if (categoriesToDelete.isNotEmpty) {
        await isar.categorys.deleteAll(categoriesToDelete.map((c) => c.id).toList());
      }
    });
  }

  static List<Category> _getCachedCategories(String pluginId) {
    if (_categoryCache.containsKey(pluginId)) {
      return _categoryCache[pluginId]!;
    }
    
    List<Category> categories = [];
    switch (pluginId) {
      case 'com.mudra.business_categories':
        categories = BusinessCategoriesPlugin.getBusinessCategories();
        break;
      case 'com.mudra.regional_categories':
        categories = RegionalCategoriesPlugin.getRegionalCategories();
        break;
    }
    
    _categoryCache[pluginId] = categories;
    return categories;
  }

  static List<String> _getCategoryNames(String pluginId) {
    switch (pluginId) {
      case 'com.mudra.business_categories':
        return BusinessCategoriesPlugin.businessCategories
            .map((cat) => cat['name'] as String)
            .toList();
      case 'com.mudra.regional_categories':
        return RegionalCategoriesPlugin.regionalCategories
            .map((cat) => cat['name'] as String)
            .toList();
      default:
        return [];
    }
  }

  static Future<List<Category>> getAvailablePluginCategories() async {
    final categories = <Category>[];

    if (await _marketplaceService
        .isPluginEnabled('com.mudra.business_categories')) {
      categories.addAll(BusinessCategoriesPlugin.getBusinessCategories());
    }

    if (await _marketplaceService
        .isPluginEnabled('com.mudra.regional_categories')) {
      categories.addAll(RegionalCategoriesPlugin.getRegionalCategories());
    }

    return categories;
  }
}

final categoryManagementServiceProvider = Provider.autoDispose<CategoryManagementService>((ref) {
  return CategoryManagementService();
});
