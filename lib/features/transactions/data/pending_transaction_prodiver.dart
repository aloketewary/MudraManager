import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart' as db_category;
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/utils/transaction_msg_util.dart';
import 'package:mudra_manager/features/transactions/data/transaction_matching_service.dart';

final pendingTxnServiceProvider = Provider<PendingTransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('PendingTxnService');
  return PendingTransactionService(isarService, log);
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
  final AppLog log;

  PendingTransactionService(this.isarService, this.log);

  Future<int> countPendingTransaction() async {
    final isar = await isarService.getInstance();
    return isar.pendingTransactions.count();
  }

  Future<List<PendingTransaction>> saveAll(
    List<PendingTransaction> pendingTransactionList,
  ) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.putAll(pendingTransactionList);
    });
    return pendingTransactionList;
  }

  Future<PendingTransaction> save(PendingTransaction pendingTransaction) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.put(pendingTransaction);
    });
    return pendingTransaction;
  }

  Future<List<PendingTransaction?>> getAllPendingTransaction() async {
    final isar = await isarService.getInstance();
    return isar.pendingTransactions.where().sortByDate().findAll();
  }

  Future<void> remove(PendingTransaction pendingTx) async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.delete(pendingTx.id);
    });
  }

  Future<void> clearAll() async {
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.clear();
    });
  }

  Future<bool> processTransaction({
    required PendingTransaction pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) async {
    final isar = await isarService.getInstance();
    return await isar.writeTxn(() async {
      final transactionUtil = TransactionUtil();
      return await _processSingleTransactionInternal(
        isar,
        pending,
        accounts,
        categories,
        transactionUtil,
      );
    });
  }

  Future<int> autoProcessAll({
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) async {
    log.i('Starting auto-process for pending transactions');
    final isar = await isarService.getInstance();
    final pendingTxns = await getAllPendingTransaction();
    if (pendingTxns.isEmpty) {
      log.i('No pending transactions to process');
      return 0;
    }

    int successCount = 0;

    await isar.writeTxn(() async {
      final transactionUtil = TransactionUtil();
      for (var pending in pendingTxns) {
        if (pending == null) continue;
        if (await _processSingleTransactionInternal(
          isar,
          pending,
          accounts,
          categories,
          transactionUtil,
        )) {
          successCount++;
        }
      }
    });

    log.i('Auto-processed $successCount transactions');
    return successCount;
  }

  Future<bool> _processSingleTransactionInternal(
    Isar isar,
    PendingTransaction pending,
    List<Account> accounts,
    List<db_category.Category> categories,
    TransactionUtil transactionUtil,
  ) async {
    // HEAL: If account is missing, try to re-parse it from the body
    if (pending.account == null || pending.account!.isEmpty) {
      final info = transactionUtil.getTransactionInfo(
        pending.body,
        pending.sender,
        pending.sender,
        '',
      );
      if (info.account?.no != null && info.account!.no!.isNotEmpty) {
        pending.account = info.account!.no;
        pending.amount ??= double.tryParse(info.money ?? '');
        pending.isIncome ??= info.typeOfTransaction == TransactionType.credited;
        // Optionally update the DB record so it stays healed
        await isar.pendingTransactions.put(pending);
      }
    }

    final match = TransactionMatchingService.matchTransaction(
      pending: pending,
      accounts: accounts,
      categories: categories,
    );

    if (match != null) {
      final txn = Transaction.create(
        date: pending.date,
        amount: pending.amount ?? 0.0,
        isExpense: pending.isIncome == false,
        description: 'Auto-imported: ${pending.sender}',
      );
      txn.account.value = match.account;
      txn.category.value = match.category;

      await isar.transactions.put(txn);
      await txn.account.save();
      await txn.category.save();

      await isar.pendingTransactions.delete(pending.id);
      log.i('Transaction auto-enabled: ${pending.sender} ${BaseCurrency.symbol}${pending.amount} -> ${match.category.name} (${match.account.name})');

      return true;
    } else {
      log.w('No match for pending ${pending.id} (Acc: ${pending.account}, Sender: ${pending.sender})');
      return false;
    }
  }
}
