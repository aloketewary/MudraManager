import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/isar_service.dart' show IsarService;
import 'package:mudra_manager/db/models/pending_transaction.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' as db_category
    show Category, CategoryType;
import 'package:mudra_manager/db/models/transaction.dart'
    show GetTransactionCollection, Transaction;
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/util/transaction_msg_util.dart';
import 'package:mudra_manager/util/category_matcher.dart';
import 'package:mudra_manager/util/app_logger.dart';

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

  Future<void> clearAll() async {
    var isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.pendingTransactions.clear();
    });
  }

  Future<bool> processTransaction({
    required PendingTransaction pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) async {
    var isar = await isarService.getInstance();
    return await isar.writeTxn(() async {
      final transactionUtil = TransactionUtil();
      return await _processSingleTransactionInternal(isar, pending, accounts, categories, transactionUtil);
    });
  }

  Future<int> autoProcessAll({
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) async {
    AppLogger.info('Starting auto-process for pending transactions');
    var isar = await isarService.getInstance();
    final pendingTxns = await getAllPendingTransaction();
    if (pendingTxns.isEmpty) {
      AppLogger.info('No pending transactions to process');
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

    AppLogger.info('Auto-processed $successCount transactions');
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

    final match = matchTransaction(
      pending: pending,
      accounts: accounts,
      categories: categories,
    );

    if (match != null) {
      final txn = Transaction.create(
        date: pending.date,
        amount: pending.amount ?? 0.0,
        isExpense: pending.isIncome == false,
        description: "Auto-imported: ${pending.sender}",
      );
      txn.account.value = match.account;
      txn.category.value = match.category;

      await isar.transactions.put(txn);
      await txn.account.save();
      await txn.category.save();

      await isar.pendingTransactions.delete(pending.id);

      AppLogger.logAction('transaction_auto_added', parameters: {
        'sender': pending.sender,
        'amount': pending.amount,
        'category': match.category.name,
        'account': match.account.name,
      });
      return true;
    } else {
      AppLogger.warning(
        "No match for pending ${pending.id} (Acc: ${pending.account}, Sender: ${pending.sender})",
      );
      return false;
    }
  }

  static MatchingResult? matchTransaction({
    required PendingTransaction pending,
    required List<Account> accounts,
    required List<db_category.Category> categories,
  }) {
    if (pending.account == null || pending.account!.isEmpty) return null;

    // 1. Try to find a matching account (match last 4 digits)
    Account? matchedAccount;
    final pendingAccTrimmed = pending.account!.trim();
    for (var acc in accounts) {
      final dbAccNo = acc.accountNumber?.trim();
      if (dbAccNo != null && dbAccNo.endsWith(pendingAccTrimmed)) {
        matchedAccount = acc;
        break;
      }
    }

    if (matchedAccount == null) return null;

    // 2. Filter categories by type (income/expense)
    final relevantCategories =
        categories
            .where(
              (c) =>
                  (pending.isIncome == true &&
                      c.categoryType == db_category.CategoryType.income) ||
                  (pending.isIncome == false &&
                      c.categoryType == db_category.CategoryType.expense),
            )
            .toList();

    if (relevantCategories.isEmpty) return null;

    // 3. Try keyword-based matching (NEW)
    db_category.Category? matchedCategory = CategoryMatcher.matchByKeywords(
      pending.body,
      relevantCategories,
    );

    // 4. Fallback with smart logic based on amount
    matchedCategory ??= CategoryMatcher.getFallbackCategory(
        relevantCategories,
        pending.amount,
      );

    // 5. Debug logging
    if (matchedCategory == null) {
      debugPrint(
        'No category match for: ${pending.body.substring(0, pending.body.length > 50 ? 50 : pending.body.length)}... '
        '(Amount: ${pending.amount}, Sender: ${pending.sender})',
      );
    }

    if (matchedCategory != null) {
      return MatchingResult(account: matchedAccount, category: matchedCategory);
    }

    return null;
  }
}

class MatchingResult {
  final Account account;
  final db_category.Category category;
  MatchingResult({required this.account, required this.category});
}
