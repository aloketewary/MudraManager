import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/features/marketplace/services/marketplace_service.dart';

final categoryListProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  ref.watch(categoryChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final categories = await isar.categorys.where().findAll();
  for (final category in categories) {
    await category.parentCategory.load();
  }
  return categories;
});

final selectableCategoriesProvider = FutureProvider.autoDispose
    .family<List<Category>, CategoryType>((ref, type) async {
  final all = await ref.watch(frequencySortedCategoriesProvider(type).future);
  final hasAccess = await ref.watch(hasFullAccessProvider.future);
  if (hasAccess) return all;

  final marketplace = MarketplaceService();
  return all.where((c) {
    if (c.packId == null) return true; // user-created or default
    return marketplace.isPluginEnabledSync(c.packId!);
  }).toList();
});

final incomeCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  ref.watch(categoryChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final categories = await isar.categorys
      .filter()
      .categoryTypeEqualTo(CategoryType.income)
      .findAll();
  for (final category in categories) {
    await category.parentCategory.load();
  }
  return categories;
});

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  ref.watch(categoryChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final categories = await isar.categorys
      .filter()
      .categoryTypeEqualTo(CategoryType.expense)
      .findAll();
  for (final category in categories) {
    await category.parentCategory.load();
  }
  return categories;
});

final categoryServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  final log = ref.getLogger('CategoryService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return CategoryService(isar, log, gamificationService);
});

/// Categories sorted by usage frequency (most-used first).
/// Falls back to alphabetical for unused categories.
final frequencySortedCategoriesProvider = FutureProvider.autoDispose
    .family<List<Category>, CategoryType>((ref, type) async {
  ref.watch(categoryChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();

  final categories =
      await isar.categorys.filter().categoryTypeEqualTo(type).findAll();

  for (final cat in categories) {
    await cat.parentCategory.load();
  }

  // Count transactions per category (last 90 days for recency bias)
  final cutoff = DateTime.now().subtract(const Duration(days: 90));
  final counts = <int, int>{};
  for (final cat in categories) {
    counts[cat.id] = await isar.transactions
        .filter()
        .category((q) => q.idEqualTo(cat.id))
        .dateGreaterThan(cutoff)
        .count();
  }

  // Parents first, sorted by aggregate count (parent + children)
  final parents =
      categories.where((c) => c.parentCategory.value == null).toList();
  final children =
      categories.where((c) => c.parentCategory.value != null).toList();

  int parentScore(Category p) {
    final childIds = children
        .where((c) => c.parentCategory.value?.id == p.id)
        .map((c) => c.id);
    return (counts[p.id] ?? 0) +
        childIds.fold<int>(0, (sum, id) => sum + (counts[id] ?? 0));
  }

  parents.sort((a, b) => parentScore(b).compareTo(parentScore(a)));

  // Sort children within each parent by frequency too
  for (final parent in parents) {
    final subs = children
        .where((c) => c.parentCategory.value?.id == parent.id)
        .toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    // Replace in-place ordering isn't needed — we'll use this when building UI
  }

  // Rebuild full list: parents (freq-sorted) + their children (freq-sorted)
  final sorted = <Category>[];
  for (final p in parents) {
    sorted.add(p);
    final subs = children
        .where((c) => c.parentCategory.value?.id == p.id)
        .toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    sorted.addAll(subs);
  }

  return sorted;
});

class CategoryService {
  final IsarService isarService;
  final AppLog log;
  final GamificationService? gamificationService;

  CategoryService(this.isarService, this.log, this.gamificationService);

  Future<void> addCategory(Category category) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    log.i('Category added: ${category.name}');
    await gamificationService?.track(GamificationEvent.categoryCreated);
  }

  Future<void> deleteCategory(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
    log.i('Category deleted: $id');
  }

  Future<List<Category>> getAllCategories() async {
    final isar = await isarService.getInstance();
    return await isar.categorys.where().findAll();
  }

  Future<void> deleteCategoryWithTransactions(Id categoryId) async {
    final isar = await isarService.getInstance();
    int txCount = 0;
    await isar.writeTxn(() async {
      // Delete transactions with that category
      final related = await isar.transactions
          .filter()
          .category((q) => q.idEqualTo(categoryId))
          .findAll();
      txCount = related.length;

      await isar.transactions.deleteAll(related.map((e) => e.id).toList());

      // Then delete the category
      await isar.categorys.delete(categoryId); // adjust to your collection name
    });
    log.w('Category deleted with $txCount transactions');
  }
}
