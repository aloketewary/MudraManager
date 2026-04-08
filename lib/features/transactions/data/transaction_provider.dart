import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/trip.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/plugin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/services/gamification_service.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

final transactionProvider = Provider<TransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('TransactionService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return TransactionService(isarService, log, gamificationService);
});

final filteredTransactionProvider = FutureProvider.autoDispose
    .family<List<Transaction>, String>((ref, type) async {
  final service = ref.watch(transactionProvider);

  if (type == 'income') {
    return await service.getByType(isExpense: false);
  } else if (type == 'expense') {
    return await service.getByType(isExpense: true);
  } else {
    return await service.getAll();
  }
});

final transactionsByMonthProvider = FutureProvider.autoDispose
    .family<List<Transaction>, DateTime>((ref, monthDate) async {
  final service = ref.watch(transactionProvider);

  final start = DateTime(monthDate.year, monthDate.month);
  final end = DateTime(monthDate.year, monthDate.month + 1);

  return await service.getByDateRange(start, end);
});

final transactionsByMonthAndTypeProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ({DateTime month, String type})>((
  ref,
  arg,
) async {
  final service = ref.watch(transactionProvider);
  final start = DateTime(arg.month.year, arg.month.month, 1);
  final end = DateTime(
    arg.month.year,
    arg.month.month + 1,
    1,
  ).subtract(const Duration(microseconds: 1));

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

final transactionsByDateRangeProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ({DateTime start, DateTime end, String type})>(
        (ref, arg) async {
  final service = ref.watch(transactionProvider);
  if (arg.type == 'all') {
    return service.getByDateRange(arg.start, arg.end);
  } else {
    return service.getByTypeAndDateRange(
      isExpense: arg.type == 'expense',
      start: arg.start,
      end: arg.end,
    );
  }
});

final sectionedTransactionsProvider = FutureProvider.autoDispose
    .family<List<TxListEntry>, ({DateTime month, String type})>((
  ref,
  arg,
) async {
  ref.watch(transactionChangeProvider);
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

final sectionedTransactionsByDateRangeProvider = FutureProvider.autoDispose
    .family<List<TxListEntry>, ({DateTime start, DateTime end, String type})>(
        (ref, arg) async {
  ref.watch(transactionChangeProvider);
  final startDate = DateTime(
    arg.start.year,
    arg.start.month,
    arg.start.day,
  );
  final endDate = DateTime(
    arg.end.year,
    arg.end.month,
    arg.end.day,
    23,
    59,
    59,
  );

  final transactions = await ref.watch(
    transactionsByDateRangeProvider(
      (
        start: startDate,
        end: endDate,
        type: arg.type,
      ),
    ).future,
  );

  if (transactions.isEmpty) return [];

  final List<TxListEntry> sectioned = [];
  DateTime? currentDate;

  for (var tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (currentDate == null ||
        currentDate.year != txDate.year ||
        currentDate.month != txDate.month ||
        currentDate.day != txDate.day) {
      currentDate = txDate;
      sectioned.add(TxHeader(txDate));
    }
    sectioned.add(TxItem(tx));
  }

  return sectioned;
});

final allSectionedTransactionsProvider = FutureProvider.autoDispose
    .family<List<TxListEntry>, String>((ref, type) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(transactionProvider);

  List<Transaction> transactions;
  if (type == 'income') {
    transactions = await service.getByType(isExpense: false);
  } else if (type == 'expense') {
    transactions = await service.getByType(isExpense: true);
  } else {
    transactions = await service.getAll();
  }

  if (transactions.isEmpty) return [];

  final List<TxListEntry> sectioned = [];
  DateTime? currentDate;

  for (var tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (currentDate == null ||
        currentDate.year != txDate.year ||
        currentDate.month != txDate.month ||
        currentDate.day != txDate.day) {
      currentDate = txDate;
      sectioned.add(TxHeader(txDate));
    }
    sectioned.add(TxItem(tx));
  }

  return sectioned;
});

// OPTIMIZED: Filter at database level
final filteredSectionedTransactionsProvider = FutureProvider.autoDispose.family<
    List<TxListEntry>,
    ({String type, int? categoryId, int? tagId, String? searchQuery})>((ref, arg) async {
  final service = ref.watch(transactionProvider);

  List<Transaction> transactions;
  if (arg.tagId != null) {
    transactions = await service.getByTagAndType(
      tagId: arg.tagId!,
      type: arg.type,
    );
  } else if (arg.categoryId != null) {
    transactions = await service.getByCategoryAndType(
      categoryId: arg.categoryId!,
      type: arg.type,
    );
  } else if (arg.type == 'income') {
    transactions = await service.getByType(isExpense: false);
  } else if (arg.type == 'expense') {
    transactions = await service.getByType(isExpense: true);
  } else {
    transactions = await service.getAll();
  }

  // Apply search filter in memory (can't index text search efficiently)
  if (arg.searchQuery != null && arg.searchQuery!.isNotEmpty) {
    final query = arg.searchQuery!.toLowerCase();
    transactions = transactions
        .where((tx) => tx.description?.toLowerCase().contains(query) ?? false)
        .toList();
  }

  if (transactions.isEmpty) return [];

  final List<TxListEntry> sectioned = [];
  DateTime? currentDate;

  for (var tx in transactions) {
    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (currentDate == null ||
        currentDate.year != txDate.year ||
        currentDate.month != txDate.month ||
        currentDate.day != txDate.day) {
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
  final categories = await isar?.categorys
      .where()
      .findAll(); // your actual category collection name

  for (final cat in categories ?? []) {
    final count = await isar?.transactions
        .filter()
        .category((q) => q.idEqualTo(cat.id))
        .count();
    counts[cat.id] = count ?? 0;
  }

  return counts;
});

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

  Future<List<Transaction>> getAll() async {
    final isar = await isarService.getInstance();
    final allTransactions =
        await isar.transactions.where().sortByDateDesc().findAll();

    final filteredTransactions = allTransactions.where((tx) {
      if (tx.isTransfer) {
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
        return DateTime(current.year, current.month - 1, current.day);
      case Frequency.yearly:
        return DateTime(current.year - 1, current.month, current.day);
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
      final rate = await isar.exchangeRates
          .filter()
          .currencyCodeEqualTo(fromCur)
          .findFirst();
      if (rate != null) {
        debitConverted = amount * rate.rateToBase;
        debitRate = rate.rateToBase;
      }
    }

    // Snapshot conversion for credit side
    final effectiveCreditAmount = creditAmount ?? amount;
    double? creditConverted;
    double? creditRate;
    if (toCur != null) {
      final rate = await isar.exchangeRates
          .filter()
          .currencyCodeEqualTo(toCur)
          .findFirst();
      if (rate != null) {
        creditConverted = effectiveCreditAmount * rate.rateToBase;
        creditRate = rate.rateToBase;
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

    return await query.sortByDateDesc().findAll();
  }
}

final quickAmountsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final service = ref.watch(transactionProvider);
  final transactions = await service.getByType(isExpense: true);

  if (transactions.length < 5) return [100, 500, 1000, 2000, 5000];

  // Round to nearest "clean" number and count frequency
  final freq = <int, int>{};
  for (final tx in transactions.take(200)) {
    final rounded = _roundToClean(tx.amount);
    if (rounded > 0) freq[rounded] = (freq[rounded] ?? 0) + 1;
  }

  final sorted = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = sorted.take(5).map((e) => e.key).toList()..sort();
  return top.isEmpty ? [100, 500, 1000, 2000, 5000] : top;
});

int _roundToClean(double amount) {
  if (amount <= 0) return 0;
  if (amount <= 50) return (amount / 10).round() * 10;
  if (amount <= 500) return (amount / 50).round() * 50;
  if (amount <= 5000) return (amount / 100).round() * 100;
  return (amount / 500).round() * 500;
}
