import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('BudgetService');
  return BudgetService(isarService, log);
});

final budgetStreamProvider = StreamProvider<List<Budget>>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return service.watchAllBudgets();
});

final budgetWithProgressProvider =
    StreamProvider<List<(Budget, double, DateTime, DateTime)>>((ref) async* {
      final budgetService = ref.watch(budgetServiceProvider);
      final isar = await ref.read(isarServiceProvider).getInstance();

      await for (final budgets
          in isar.budgets
              .where()
              .isArchivedEqualTo(false)
              .watch(fireImmediately: true)) {
        final List<(Budget, double, DateTime, DateTime)> result = [];
        final now = DateTime.now();
        for (final budget in budgets) {
          // Filter out expired one-time budgets
          if (budget.recurrence == BudgetRecurrence.none &&
              budget.endDate.isBefore(
                DateTime(now.year, now.month, now.day, 23, 59, 59),
              )) {
            continue;
          }

          final (s, e) = budget.getCurrentPeriodRange(now);
          final spent = await budgetService.calculateSpentAmount(
            budget,
            start: s,
            end: e,
          );
          result.add((budget, spent, s, e));
        }
        yield result;
      }
    });

final budgetsWithProgressProvider =
    StreamProvider.autoDispose<List<BudgetWithProgress>>((ref) {
      return ref.watch(budgetServiceProvider).watchBudgetsWithProgress();
    });

class BudgetService {
  final IsarService isarService;
  final AppLog log;

  BudgetService(this.isarService, this.log);

  Stream<List<Budget>> watchAllBudgets() async* {
    final isar = await isarService.getInstance();
    yield* isar.budgets
        .where()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Future<double> calculateSpentAmount(
    Budget budget, {
    DateTime? start,
    DateTime? end,
  }) async {
    final isar = await isarService.getInstance();
    final s = start ?? budget.startDate;
    final e = end ?? budget.endDate;

    final categoryIds = budget.categories.map((c) => c.id).toList();

    final transactions = await isar.transactions
        .filter()
        .isExpenseEqualTo(true)
        .dateBetween(s, e)
        .findAll();

    final spent = transactions
        .where(
          (t) =>
              t.category.value != null &&
              categoryIds.contains(t.category.value!.id),
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return spent;
  }

  Stream<List<BudgetWithProgress>> watchBudgetsWithProgress() async* {
    final isar = await isarService.getInstance();
    await for (final budgets
        in isar.budgets
            .where()
            .isArchivedEqualTo(false)
            .watch(fireImmediately: true)) {
      final List<BudgetWithProgress> list = [];
      final now = DateTime.now();
      for (final budget in budgets) {
        // Calculate current range
        final (s, e) = budget.getCurrentPeriodRange(now);

        // 1) load linked categories & allocations
        await budget.categories.load();
        await budget.allocations.load();

        // 2) total spent across all linked categories
        double totalSpent = 0;
        final catSpendings = <CategorySpending>[];
        for (final alloc in budget.allocations) {
          await alloc.category.load();
          final cat = alloc.category.value!;
          final spent = await isar.transactions
              .filter()
              .isExpenseEqualTo(true)
              .dateBetween(s, e)
              .category((q) => q.idEqualTo(cat.id))
              .amountProperty()
              .sum();
          totalSpent += spent;
          catSpendings.add(
            CategorySpending(
              category: cat,
              allocated: alloc.amount,
              spent: spent,
            ),
          );
        }

        list.add(
          BudgetWithProgress(
            budget: budget,
            spent: totalSpent,
            categorySpendings: catSpendings,
            startDate: s,
            endDate: e,
          ),
        );
      }
      yield list;
    }
  }

  Future<void> save(Budget bud) async {
    final isar = await isarService.getInstance();
    await isar.writeTxnSync(() async {
      // 1) Put budget and save its category & allocation links in one go:
      isar.budgets.putSync(bud, saveLinks: true);

      // 2) Put each allocation (and save its own links):
      for (final alloc in bud.allocations) {
        isar.budgetCategoryAllocations.putSync(alloc, saveLinks: true);
      }
    });
    log.i('Budget saved: ${bud.name}');
  }

  /// Delete a budget and all its allocations
  Future<void> deleteBudget(int budgetId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      // Remove allocations
      final allocs = await isar.budgetCategoryAllocations
          .filter()
          .budget((q) => q.idEqualTo(budgetId))
          .findAll();
      for (final a in allocs) {
        await isar.budgetCategoryAllocations.delete(a.id);
      }
      // Remove budget itself
      await isar.budgets.delete(budgetId);
    });
    log.i('Budget deleted: $budgetId');
  }

  /// Fetch a single budget by ID
  Future<Budget?> getBudget(int budgetId) async {
    final isar = await isarService.getInstance();
    return await isar.budgets.get(budgetId);
  }

  // Archiving
  Future<void> archiveBudget(int id) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final b = await isar.budgets.get(id);
      if (b != null) {
        b.isArchived = true;
        await isar.budgets.put(b);
      }
    });
  }

  Future<List<Budget>> getFilterBudget(DateTime now) async {
    final isar = await isarService.getInstance();
    final budgets = await isar.budgets
        .filter()
        .startDateLessThan(now)
        .and()
        .endDateGreaterThan(now)
        .findAll();
    return budgets;
  }

  Future<void> deleteAllocation(
    List<BudgetCategoryAllocation> allocList,
  ) async {
    final isar = await isarService.getInstance();
    final allocIds = allocList.map((elem) => elem.id).toList();
    await isar.writeTxn(() async {
      await isar.budgetCategoryAllocations.deleteAll(allocIds);
    });
  }
}

class CategorySpending {
  final Category category;
  final double allocated;
  final double spent;

  CategorySpending({
    required this.category,
    required this.allocated,
    required this.spent,
  });
}

class BudgetWithProgress {
  final Budget budget;
  final double spent;
  final List<CategorySpending> categorySpendings;
  final DateTime startDate;
  final DateTime endDate;

  BudgetWithProgress({
    required this.budget,
    required this.spent,
    required this.categorySpendings,
    required this.startDate,
    required this.endDate,
  });
}
