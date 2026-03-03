import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';

final categoryListProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final categories = await isar.categorys.where().findAll();
  for (final category in categories) {
    await category.parentCategory.load();
  }
  return categories;
});

final incomeCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
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

final expenseCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
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
