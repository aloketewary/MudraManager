import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
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
    final allTransactions = await isar.transactions
        .where()
        .sortByDateDesc()
        .findAll();

    final filteredTransactions = allTransactions.where((tx) {
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
    final allTransactions = await isar.transactions
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

    final credit =
        Transaction.create(
            date: date,
            amount: amount,
            isExpense: false,
            description: note,
          )
          ..isTransfer = true
          ..account.value = to;

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
}
