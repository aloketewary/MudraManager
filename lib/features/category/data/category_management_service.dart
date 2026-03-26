import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/plugins/category_packs/category_pack.dart';

class CategoryManagementService {
  /// Install a single pack by ID.
  static Future<void> installPack(String packId) async {
    final pack = CategoryPackRegistry.get(packId);
    if (pack == null) return;

    final isar = Isar.getInstance();
    if (isar == null) return;

    // Install dependencies first
    for (final depId in pack.extendsPackIds) {
      await installPack(depId);
    }

    final existingNames =
        (await isar.categorys.where().nameProperty().findAll()).toSet();
    final allExisting = await isar.categorys.where().findAll();
    final nameToCategory = {for (final c in allExisting) c.name: c};

    final parents = pack.categories.where((c) => c.parent == null).toList();
    final children = pack.categories.where((c) => c.parent != null).toList();

    await isar.writeTxn(() async {
      for (final def in parents) {
        if (existingNames.contains(def.name)) continue;
        final cat = def.toCategory()..packId = packId;
        await isar.categorys.put(cat);
        existingNames.add(def.name);
        nameToCategory[def.name] = cat;
      }

      for (final def in children) {
        if (existingNames.contains(def.name)) continue;
        final cat = def.toCategory()..packId = packId;
        final parentCat = nameToCategory[def.parent];
        final hasParent = parentCat != null;

        if (hasParent) {
          cat.parentCategory.value = parentCat;
        }

        await isar.categorys.put(cat);
        if (hasParent) {
          await cat.parentCategory.save();
        }
        existingNames.add(def.name);
        nameToCategory[def.name] = cat;
      }
    });
  }

  /// Remove categories owned by a pack.
  /// Only removes categories that are NOT shared with other enabled packs.
  static Future<void> removePack(
    String packId,
    Set<String> enabledPackIds,
  ) async {
    final pack = CategoryPackRegistry.get(packId);
    if (pack == null) return;

    final isar = Isar.getInstance();
    if (isar == null) return;

    // Collect names owned by other enabled packs (don't delete shared ones)
    final protectedNames = <String>{};
    for (final otherId in enabledPackIds) {
      if (otherId == packId) continue;
      final other = CategoryPackRegistry.get(otherId);
      if (other != null) protectedNames.addAll(other.allCategoryNames);
    }

    final toRemove = pack.allCategoryNames
        .where((n) => !protectedNames.contains(n))
        .toList();
    if (toRemove.isEmpty) return;

    await isar.writeTxn(() async {
      final cats = await isar.categorys
          .filter()
          .anyOf(toRemove, (q, name) => q.nameEqualTo(name))
          .findAll();
      if (cats.isNotEmpty) {
        await isar.categorys.deleteAll(cats.map((c) => c.id).toList());
      }
    });
  }

  /// Install multiple packs at once (used during onboarding).
  static Future<void> installPacks(List<String> packIds) async {
    for (final id in packIds) {
      await installPack(id);
    }
  }

  /// Remove all categories when no packs are enabled.
  static Future<void> clearAll() async {
    final isar = Isar.getInstance();
    if (isar == null) return;

    await isar.writeTxn(() async {
      await isar.categorys.clear();
    });
  }
}

final categoryManagementServiceProvider =
    Provider.autoDispose<CategoryManagementService>((ref) {
  return CategoryManagementService();
});
