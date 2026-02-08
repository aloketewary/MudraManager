import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/transaction.dart'
    show
        GetTransactionCollection,
        Transaction,
        TransactionQueryFilter,
        TransactionQueryLinks,
        TransactionQuerySortBy,
        TransactionQueryWhere;
import 'package:mudra_manager/providers/isar_provider.dart';

import 'package:mudra_manager/screens/transaction/transaction_group.dart'
    show TxListEntry, TxHeader, TxItem;

final transactionProvider = Provider<TransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TransactionService(isarService);
});

final filteredTransactionProvider =
    FutureProvider.family<List<Transaction>, String>((ref, type) async {
      final service = ref.watch(transactionProvider);

      if (type == 'income') {
        return await service.getByType(isExpense: false);
      } else if (type == 'expense') {
        return await service.getByType(isExpense: true);
      } else {
        return await service.getAll();
      }
    });

final transactionsByMonthProvider =
    FutureProvider.family<List<Transaction>, DateTime>((ref, monthDate) async {
      final service = ref.watch(transactionProvider);

      final start = DateTime(monthDate.year, monthDate.month);
      final end = DateTime(monthDate.year, monthDate.month + 1);

      return await service.getByDateRange(start, end);
    });

final transactionsByMonthAndTypeProvider =
    FutureProvider.family<List<Transaction>, ({DateTime month, String type})>((
      ref,
      arg,
    ) async {
      final service = ref.watch(transactionProvider);
      final start = DateTime(arg.month.year, arg.month.month, 1);
      final end = DateTime(arg.month.year, arg.month.month + 1, 0, 23, 59, 59);

      if (arg.type == 'all') {
        return service.getByDateRange(start, end);
      } else {
        return service.getByTypeAndDateRange(
          isExpense: arg.type == 'expense',
          start: start,
          end: end,
        );
      }
    });

final sectionedTransactionsProvider =
    FutureProvider.family<List<TxListEntry>, ({DateTime month, String type})>((
      ref,
      arg,
    ) async {
      final transactions = await ref.watch(
        transactionsByMonthAndTypeProvider(arg).future,
      );

      if (transactions.isEmpty) return [];

      final List<TxListEntry> sectioned = [];
      DateTime? currentDate;

      for (var tx in transactions) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (currentDate == null || txDate != currentDate) {
          currentDate = txDate;
          sectioned.add(TxHeader(txDate));
        }
        sectioned.add(TxItem(tx));
      }

      return sectioned;
    });

final transactionCountsProvider = FutureProvider.autoDispose<Map<Id, int>>((
  ref,
) async {
  final isar = Isar.getInstance(); // or inject
  final counts = <Id, int>{};
  final categories =
      await isar?.categorys
          .where()
          .findAll(); // your actual category collection name

  for (final cat in categories ?? []) {
    final count =
        await isar?.transactions
            .filter()
            .category((q) => q.idEqualTo(cat.id))
            .count();
    counts[cat.id] = count ?? 0;
  }

  return counts;
});

class TransactionService {
  final IsarService isarService;

  TransactionService(this.isarService);

  Future<void> addTransaction(Transaction txn) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.transactions.put(txn);
      await txn.category.save();
      await txn.account.save();
      await txn.tags.save();
    });
  }

  Future<List<Transaction>> getAll() async {
    final isar = await isarService.getInstance();
    final allTransactions =
        await isar.transactions.where().sortByDateDesc().findAll();

    final filteredTransactions =
        allTransactions.where((tx) {
          if (tx.isTransfer) {
            // Only show the 'source' transaction, not the linked one
            return !tx.isExpense;
          }
          return true;
        }).toList();
    return filteredTransactions;
  }

  Future<List<Transaction>> getAllForDashBoard() async {
    final isar = await isarService.getInstance();
    final allTransactions =
        await isar.transactions
            .where()
            .isTransferEqualTo(false)
            .sortByDateDesc()
            .findAll();

    return allTransactions;
  }

  Future<List<Transaction>> getByType({required bool isExpense}) async {
    final isar = await isarService.getInstance();
    return await isar.transactions
        .where()
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .findAll();
  }

  Stream<List<Transaction>> watchAll() async* {
    final isar = await isarService.getInstance();
    yield* isar.transactions.where().sortByDateDesc().watch(
      fireImmediately: true,
    );
  }

  Stream<List<Transaction>> watchByType({required bool isExpense}) async* {
    final isar = await isarService.getInstance();
    yield* isar.transactions
        .where()
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<int> getTransactionCountForCategory(int categoryId) async {
    final isar = await isarService.getInstance();
    return await isar.transactions
        .filter()
        .category((cat) => cat.idEqualTo(categoryId))
        .count();
  }

  Future<void> deleteTransaction(int transactionId) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.transactions.delete(transactionId);
    });
  }

  /// Perform a transfer between two accounts
  Future<void> transfer({
    required Account from,
    required Account to,
    required double amount,
    required DateTime date,
    String? note,
    int? fromId,
    int? toId,
  }) async {
    final isar = await isarService.getInstance();
    final debit =
        Transaction.create(
            date: date,
            amount: amount,
            isExpense: true,
            description: note,
          )
          ..isTransfer = true
          ..account.value = from;
    if (fromId != null) debit.id = fromId;
    final credit =
        Transaction.create(
            date: date,
            amount: amount,
            isExpense: false,
            description: note,
          )
          ..isTransfer = true
          ..account.value = to;
    if (toId != null) credit.id = toId;
    await isar.writeTxnSync(() async {
      // 1) Save both
      debit.related.value = credit;
      credit.related.value = debit;
      isar.transactions.putSync(debit, saveLinks: true);
      isar.transactions.putSync(credit, saveLinks: true);
      await debit.category.save();
      await debit.account.save();
      await credit.category.save();
      await credit.account.save();
    });
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final isar = await isarService.getInstance();
    // OPTIMIZATION: Use where() for indexed date range
    final allTransactions =
        await isar.transactions
            .where()
            .dateBetween(start, end)
            .sortByDateDesc()
            .findAll();

    final filteredTransactions =
        allTransactions.where((tx) {
          if (tx.isTransfer) {
            return !tx.isExpense;
          }
          return true;
        }).toList();
    return filteredTransactions;
  }

  Future<List<Transaction>> getByTypeAndDateRange({
    required bool isExpense,
    required DateTime start,
    required DateTime end,
  }) async {
    final isar = await isarService.getInstance();
    // OPTIMIZATION: Use composite-like filter starting with indexed date
    return await isar.transactions
        .where()
        .dateBetween(start, end)
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .findAll();
  }
}
