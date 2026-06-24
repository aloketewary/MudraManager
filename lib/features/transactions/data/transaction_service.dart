import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/extensions/field_encryption_ext.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/utils/date_arithmetic.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
class TransactionService {
  final IsarService isarService;
  final AppLog log;
  final GamificationService? gamificationService;

  TransactionService(this.isarService, this.log, this.gamificationService);

  Future<void> addTransaction(Transaction txn) async {
    log.d(
      'Adding transaction: ${txn.isExpense ? "Expense" : "Income"} of ${BaseCurrency.symbol}${txn.amount}',
    );

    final isar = await isarService.getInstance();

    // Capture tags BEFORE entering writeTxn — toList() triggers loadSync()
    // which can't run inside a write transaction
    final tagsToSave = txn.tags.toList();

    txn.encryptFields();

    // Denormalize categoryId for efficient queries
    txn.categoryId = txn.category.value?.id;

    try {
      await isar.writeTxn(() async {
        await isar.transactions.put(txn);
        await txn.category.save();
        await txn.account.save();
        await txn.tags.reset();
        txn.tags.addAll(tagsToSave);
        await txn.tags.save();
      });
    } catch (e) {
      log.e('Failed to save transaction: ${BaseCurrency.symbol}${txn.amount}', e);
      rethrow;
    }

    log.i('Transaction saved successfully with ID: ${txn.id}');

    // Emit transaction event to plugins
    if (!txn.isTransfer) {
      if (txn.isExpense) {
        PluginService().emitExpense(
          txn.category.value?.name ?? 'Uncategorized',
          txn.amount,
          txn.date,
        );
      } else {
        PluginService().emitIncome(
          txn.category.value?.name ?? 'Income',
          txn.amount,
          txn.date,
        );
      }
    }

    // Track gamification
    await gamificationService?.track(GamificationEvent.transactionAdded);
    await gamificationService?.track(GamificationEvent.transactionTrackedToday);

    if (txn.isTransfer) {
      await gamificationService?.track(GamificationEvent.transferCompleted);
    }
    if (tagsToSave.isNotEmpty) {
      await gamificationService?.track(GamificationEvent.tagUsed);
    }
  }

  /// Loads category and account links for a list of transactions.
  Future<void> _loadLinks(List<Transaction> txns) async {
    for (final t in txns) {
      t.category.loadSync();
      t.account.loadSync();
      t.decryptFields();
    }
  }

  Future<List<Transaction>> getAll({int? limit}) async {
    final isar = await isarService.getInstance();
    final query = isar.transactions.where().sortByDateDesc();
    final allTransactions = limit != null
        ? await query.limit(limit).findAll()
        : await query.findAll();

    final filteredTransactions = allTransactions.where((tx) {
      if (tx.isTransfer) {
        return !tx.isExpense;
      }
      return true;
    }).toList();
    await _loadLinks(filteredTransactions);
    return filteredTransactions;
  }

  Future<List<Transaction>> getAllForDashBoard() async {
    final isar = await isarService.getInstance();
    // Limit to last 12 months — analytics only needs this range
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final allTransactions = await isar.transactions
        .where()
        .dateBetween(cutoff, DateTime.now())
        .filter()
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .findAll();

    for (final t in allTransactions) {
      t.category.loadSync();
      t.account.loadSync();
      t.decryptFields();
    }

    return allTransactions;
  }

  Future<List<Transaction>> getByType({required bool isExpense}) async {
    final isar = await isarService.getInstance();
    final txns = await isar.transactions
        .where()
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .findAll();
    await _loadLinks(txns);
    return txns;
  }

  Stream<List<Transaction>> watchAll() async* {
    final isar = await isarService.getInstance();
    yield* isar.transactions
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true)
        .withDecryption();
  }

  Stream<List<Transaction>> watchByType({required bool isExpense}) async* {
    final isar = await isarService.getInstance();
    yield* isar.transactions
        .where()
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true)
        .withDecryption();
  }

  Future<int> getTransactionCountForCategory(int categoryId) async {
    final isar = await isarService.getInstance();
    return await isar.transactions
        .filter()
        .category((cat) => cat.idEqualTo(categoryId))
        .count();
  }

  Future<void> deleteTransaction(int transactionId) async {
    log.d('Deleting transaction ID: $transactionId');
    final isar = await isarService.getInstance();

    final txn = await isar.transactions.get(transactionId);
    if (txn == null) return;

    // Check if linked to a recurring bill — revert due date if so
    await txn.recurringTransactionSource.load();
    final recurring = txn.recurringTransactionSource.value;
    if (recurring != null) {
      final prevDate = _calculatePreviousDueDate(
        recurring.nextDueDate, recurring.frequency,
      );
      await isar.writeTxn(() async {
        recurring.nextDueDate = prevDate;
        recurring.isActive = true;
        recurring.encryptFields();
        await isar.recurringTransactions.put(recurring);
        await _cleanupTripLink(isar, transactionId);
        await isar.transactions.delete(transactionId);
      });
      log.i('Transaction deleted + recurring due date reverted to $prevDate');
      return;
    }

    await isar.writeTxn(() async {
      await _cleanupTripLink(isar, transactionId);
      await isar.transactions.delete(transactionId);
    });
    log.i('Transaction deleted successfully');
  }

  /// Atomically deletes both legs of a transfer in a single writeTxn.
  Future<void> deleteTransferAtomic(int txnId) async {
    log.d('Deleting transfer atomically: $txnId');
    final isar = await isarService.getInstance();
    final txn = await isar.transactions.get(txnId);
    if (txn == null) return;

    await txn.related.load();
    final relatedId = txn.related.value?.id;

    await isar.writeTxn(() async {
      await _cleanupTripLink(isar, txnId);
      if (relatedId != null) {
        await _cleanupTripLink(isar, relatedId);
        await isar.transactions.delete(relatedId);
      }
      await isar.transactions.delete(txnId);
    });
    log.i('Transfer deleted atomically: $txnId + $relatedId');
  }

  /// Atomically deletes a pair of transactions (for merge-as-transfer cleanup).
  Future<void> deleteTransactionPair(int id1, int id2) async {
    log.d('Deleting transaction pair: $id1 + $id2');
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await _cleanupTripLink(isar, id1);
      await _cleanupTripLink(isar, id2);
      await isar.transactions.deleteAll([id1, id2]);
    });
    log.i('Transaction pair deleted atomically: $id1 + $id2');
  }

  /// Cleans up any TripTransaction + SplitExpense linked to this transaction.
  Future<void> _cleanupTripLink(Isar isar, int transactionId) async {
    final tripTxn = await isar.tripTransactions
        .filter()
        .transaction((q) => q.idEqualTo(transactionId))
        .findFirst();
    if (tripTxn == null) return;

    // Delete linked split expense
    await tripTxn.splitExpense.load();
    if (tripTxn.splitExpense.value != null) {
      await isar.splitExpenses.delete(tripTxn.splitExpense.value!.id);
    }

    // Remove from trip's transaction list
    final trip = await isar.trips
        .filter()
        .transactions((q) => q.idEqualTo(tripTxn.id))
        .findFirst();
    if (trip != null) {
      await trip.transactions.load();
      trip.transactions.removeWhere((t) => t.id == tripTxn.id);
      await trip.transactions.save();
    }

    await isar.tripTransactions.delete(tripTxn.id);
  }

  DateTime _calculatePreviousDueDate(DateTime current, Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return current.subtract(const Duration(days: 1));
      case Frequency.weekly:
        return current.subtract(const Duration(days: 7));
      case Frequency.monthly:
        return DateArithmetic.subtractMonths(current, 1, preferDay: current.day);
      case Frequency.yearly:
        return DateArithmetic.addYears(current, -1, preferDay: current.day);
    }
  }

  /// Perform a transfer between two accounts
  Future<void> transfer({
    required Account from,
    required Account to,
    required double amount,
    double? creditAmount,
    required DateTime date,
    String? note,
    int? fromId,
    int? toId,
  }) async {
    log.d('Transfer: $amount from ${from.name} to ${to.name}');
    final isar = await isarService.getInstance();

    final fromCur = from.currencyCode;
    final toCur = to.currencyCode;

    // Snapshot conversion for debit side
    double? debitConverted;
    double? debitRate;
    if (fromCur != null) {
      final r = CurrencyService.getCachedRate(fromCur);
      if (r != null) {
        debitConverted = amount * r;
        debitRate = r;
      }
    }

    // Snapshot conversion for credit side
    final effectiveCreditAmount = creditAmount ?? amount;
    double? creditConverted;
    double? creditRate;
    if (toCur != null) {
      final r = CurrencyService.getCachedRate(toCur);
      if (r != null) {
        creditConverted = effectiveCreditAmount * r;
        creditRate = r;
      }
    }

    final debit = Transaction.create(
      date: date,
      amount: amount,
      isExpense: true,
      description: note,
      currencyCode: fromCur,
      convertedAmount: debitConverted,
      rateUsed: debitRate,
    )
      ..isTransfer = true
      ..account.value = from;
    if (fromId != null) debit.id = fromId;
    final credit = Transaction.create(
      date: date,
      amount: effectiveCreditAmount,
      isExpense: false,
      description: note,
      currencyCode: toCur,
      convertedAmount: creditConverted,
      rateUsed: creditRate,
    )
      ..isTransfer = true
      ..account.value = to;
    if (toId != null) credit.id = toId;

    debit.encryptFields();
    credit.encryptFields();

    await isar.writeTxn(() async {
      debit.related.value = credit;
      credit.related.value = debit;
      await isar.transactions.put(debit);
      await isar.transactions.put(credit);
      await debit.related.save();
      await credit.related.save();
      await debit.category.save();
      await debit.account.save();
      await credit.category.save();
      await credit.account.save();
    });
    log.i('Transfer completed successfully');

    await gamificationService?.track(GamificationEvent.transferCompleted);

    PluginService().emitTransfer(from.name, to.name, amount, date);
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final isar = await isarService.getInstance();
    // OPTIMIZATION: Use where() for indexed date range
    final allTransactions = await isar.transactions
        .where()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();

    final filteredTransactions = allTransactions.where((tx) {
      if (tx.isTransfer) {
        return !tx.isExpense;
      }
      return true;
    }).toList();
    await _loadLinks(filteredTransactions);
    return filteredTransactions;
  }

  Future<List<Transaction>> getByTypeAndDateRange({
    required bool isExpense,
    required DateTime start,
    required DateTime end,
  }) async {
    final isar = await isarService.getInstance();
    final txns = await isar.transactions
        .where()
        .dateBetween(start, end)
        .filter()
        .isExpenseEqualTo(isExpense)
        .isTransferEqualTo(false)
        .sortByDateDesc()
        .findAll();
    await _loadLinks(txns);
    return txns;
  }

  Future<List<Transaction>> getByTagAndType({
    required int tagId,
    required String type,
  }) async {
    final isar = await isarService.getInstance();
    final tag = await isar.tags.get(tagId);
    if (tag == null) return [];

    // Query all transactions linked to this tag via backlink
    var allTxns = await isar.transactions
        .filter()
        .tags((q) => q.idEqualTo(tagId))
        .sortByDateDesc()
        .findAll();

    if (type == 'income') {
      allTxns = allTxns.where((t) => !t.isExpense && !t.isTransfer).toList();
    } else if (type == 'expense') {
      allTxns = allTxns.where((t) => t.isExpense && !t.isTransfer).toList();
    }

    for (final t in allTxns) {
      t.decryptFields();
    }
    return allTxns;
  }

  // OPTIMIZED: Filter by category at database level
  Future<List<Transaction>> getByCategoryAndType({
    required int categoryId,
    required String type,
  }) async {
    final isar = await isarService.getInstance();

    var query =
        isar.transactions.filter().category((q) => q.idEqualTo(categoryId));

    if (type == 'income') {
      query = query.isExpenseEqualTo(false).isTransferEqualTo(false);
    } else if (type == 'expense') {
      query = query.isExpenseEqualTo(true).isTransferEqualTo(false);
    }

    return await query.sortByDateDesc().findAll().withDecryption();
  }
}
