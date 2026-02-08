import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/category.dart' show Category, CategoryQueryFilter, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/db/models/transaction.dart';

import 'isar_provider.dart';

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return await isar.categorys.where().findAll(); // You can filter if needed
});

final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return await isar.categorys
      .filter()
      .categoryTypeEqualTo(CategoryType.income)
      .findAll();
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final isar = await ref.watch(isarServiceProvider).getInstance();
  return await isar.categorys
      .filter()
      .categoryTypeEqualTo(CategoryType.expense)
      .findAll();
});


final categoryServiceProvider = Provider((ref) {
  final isar = ref.watch(isarServiceProvider);
  return CategoryService(isar);
});


class CategoryService {
  final IsarService isarService;

  CategoryService(this.isarService);

  Future<void> addCategory(Category category) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
    // Optionally invalidate the list provider
  }

  Future<void> deleteCategory(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.categorys.delete(id);
    });
  }

  Future<List<Category>> getAllCategories() async {
    final isar = await isarService.getInstance();
    return await isar.categorys.where().findAll();
  }

  Future<void> deleteCategoryWithTransactions(Id categoryId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      // Delete transactions with that category
      final related = await isar.transactions
          .filter()
          .category((q) => q.idEqualTo(categoryId))
          .findAll();

      await isar.transactions.deleteAll(related.map((e) => e.id).toList());

      // Then delete the category
      await isar.categorys.delete(categoryId); // adjust to your collection name
    });
  }

}
