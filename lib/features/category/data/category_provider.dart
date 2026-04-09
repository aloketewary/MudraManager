import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
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
  // Hide system categories from user management
  return categories.where((c) => !c.isSystem).toList();
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
      .isSystemEqualTo(false)
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
      .isSystemEqualTo(false)
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
      await isar.categorys.filter().categoryTypeEqualTo(type).isSystemEqualTo(false).findAll();

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

  /// Returns the number of transactions linked to this category.
  /// Use this to show a confirmation alert before deletion.
  Future<int> getLinkedTransactionCount(int id) async {
    final isar = await isarService.getInstance();
    return await isar.transactions
        .filter()
        .category((q) => q.idEqualTo(id))
        .count();
  }

  Future<int> getLinkedBudgetCount(int categoryId) async {
    final isar = await isarService.getInstance();
    return await isar.budgetCategoryAllocations
        .filter()
        .category((q) => q.idEqualTo(categoryId))
        .count();
  }

  /// Deletes category, unlinks transactions, and cleans up budget allocations.
  /// Call [getLinkedTransactionCount] and [getLinkedBudgetCount] first for UI.
  Future<void> deleteCategory(int id) async {
    final isar = await isarService.getInstance();
    int txCount = 0;
    int allocCount = 0;
    await isar.writeTxn(() async {
      // Unlink transactions
      final linked = await isar.transactions
          .filter()
          .category((q) => q.idEqualTo(id))
          .findAll();
      txCount = linked.length;
      for (final tx in linked) {
        tx.category.value = null;
        await tx.category.save();
      }
      // Remove budget allocations for this category
      final allocs = await isar.budgetCategoryAllocations
          .filter()
          .category((q) => q.idEqualTo(id))
          .findAll();
      allocCount = allocs.length;
      for (final alloc in allocs) {
        await alloc.budget.load();
        final budget = alloc.budget.value;
        if (budget != null) {
          budget.allocations.remove(alloc);
          budget.categories.removeWhere((c) => c.id == id);
          await budget.allocations.save();
          await budget.categories.save();
        }
        await isar.budgetCategoryAllocations.delete(alloc.id);
      }
      await isar.categorys.delete(id);
    });
    log.i('Category $id deleted, $txCount txns unlinked, $allocCount budget allocs removed');
  }

  Future<List<Category>> getAllCategories() async {
    final isar = await isarService.getInstance();
    return await isar.categorys.where().findAll();
  }
}
