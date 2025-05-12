import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/pending_transaction.dart';
import 'package:mudra_manager/providers/isar_provider.dart';

final pendingTxnServiceProvider = Provider<PendingTransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return PendingTransactionService(isarService);
});

final pendingTxnCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(pendingTxnServiceProvider);
  return await service.countPendingTransaction();
});

final pendingTxnDataProvider =
    FutureProvider.autoDispose<List<PendingTransaction?>>((ref) async {
      final service = ref.watch(pendingTxnServiceProvider);
      return await service.getAllPendingTransaction();
    });

class PendingTransactionService {
  final IsarService isarService;

  PendingTransactionService(this.isarService);

  Future<int> countPendingTransaction() async {
    var isar = await isarService.getInstance();
    return isar.pendingTransactions.count();
  }

  Future<List<PendingTransaction>> saveAll(
    List<PendingTransaction> pendingTransactionList,
  ) async {
    var isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.putAll(pendingTransactionList);
    });
    return pendingTransactionList;
  }

  Future<PendingTransaction> save(PendingTransaction pendingTransaction) async {
    var isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.put(pendingTransaction);
    });
    return pendingTransaction;
  }

  Future<List<PendingTransaction?>> getAllPendingTransaction() async {
    var isar = await isarService.getInstance();
    return isar.pendingTransactions.where().sortByDate().findAll();
  }

  Future<void> remove(PendingTransaction pendingTx) async {
    var isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.delete(pendingTx.id);
    });
  }
}
