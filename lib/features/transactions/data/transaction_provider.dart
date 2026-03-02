import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

final transactionProvider = Provider<TransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('TransactionService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return TransactionService(isarService, log, gamificationService);
});

final filteredTransactionProvider =
    FutureProvider.autoDispose.family<List<Transaction>, String>((ref, type) async {
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
    FutureProvider.autoDispose.family<List<Transaction>, DateTime>((ref, monthDate) async {
      final service = ref.watch(transactionProvider);

      final start = DateTime(monthDate.year, monthDate.month);
      final end = DateTime(monthDate.year, monthDate.month + 1);

      return await service.getByDateRange(start, end);
    });

final transactionsByMonthAndTypeProvider =
    FutureProvider.autoDispose.family<List<Transaction>, ({DateTime month, String type})>((
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

final transactionsByDateRangeProvider =
    FutureProvider.autoDispose.family<
      List<Transaction>,
      ({DateTime start, DateTime end, String type})
    >((ref, arg) async {
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

final sectionedTransactionsProvider =
    FutureProvider.autoDispose.family<List<TxListEntry>, ({DateTime month, String type})>((
      ref,
      arg,
    ) async {
      final transactions = await ref.watch(
        transactionsByMonthAndTypeProvider(arg).future,
      );

      // Get pending SMS activities for this month
      final service = ref.watch(transactionProvider);
      final isar = await service.isarService.getInstance();
      final start = DateTime(arg.month.year, arg.month.month, 1);
      final end = DateTime(arg.month.year, arg.month.month + 1, 1);
      
      final pendingActivities = await isar.smsActivitys
          .filter()
          .dateBetween(start, end)
          .and()
          .not()
          .statusEqualTo(ActivityStatus.approved)
          .and()
          .not()
          .statusEqualTo(ActivityStatus.rejected)
          .sortByDateDesc()
          .findAll();

      // Combine
      final combined = <dynamic>[
        ...transactions,
        ...pendingActivities,
      ];

      combined.sort((a, b) {
        final dateA = a is Transaction ? a.date : (a as SmsActivity).date;
        final dateB = b is Transaction ? b.date : (b as SmsActivity).date;
        return dateB.compareTo(dateA);
      });

      if (combined.isEmpty) return [];

      final List<TxListEntry> sectioned = [];
      DateTime? currentDate;

      for (var item in combined) {
        final date = item is Transaction ? item.date : (item as SmsActivity).date;
        final txDate = DateTime(date.year, date.month, date.day);
        if (currentDate == null || txDate != currentDate) {
          currentDate = txDate;
          sectioned.add(TxHeader(txDate));
        }
        if (item is Transaction) {
          sectioned.add(TxItem(item));
        } else {
          sectioned.add(SmsActivityItem(item as SmsActivity));
        }
      }

      return sectioned;
    });

final sectionedTransactionsByDateRangeProvider =
    FutureProvider.autoDispose.family<
      List<TxListEntry>,
      ({DateTime start, DateTime end, String type})
    >((ref, arg) async {
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
        transactionsByDateRangeProvider((
          start: startDate,
          end: endDate,
          type: arg.type,
        )).future,
      );

      // Get pending SMS activities for this date range
      final service = ref.watch(transactionProvider);
      final isar = await service.isarService.getInstance();
      
      final pendingActivities = await isar.smsActivitys
          .filter()
          .dateBetween(startDate, endDate)
          .and()
          .not()
          .statusEqualTo(ActivityStatus.approved)
          .and()
          .not()
          .statusEqualTo(ActivityStatus.rejected)
          .sortByDateDesc()
          .findAll();

      // Combine
      final combined = <dynamic>[
        ...transactions,
        ...pendingActivities,
      ];

      combined.sort((a, b) {
        final dateA = a is Transaction ? a.date : (a as SmsActivity).date;
        final dateB = b is Transaction ? b.date : (b as SmsActivity).date;
        return dateB.compareTo(dateA);
      });

      if (combined.isEmpty) return [];

      final List<TxListEntry> sectioned = [];
      DateTime? currentDate;

      for (var item in combined) {
        final date = item is Transaction ? item.date : (item as SmsActivity).date;
        final txDate = DateTime(date.year, date.month, date.day);
        if (currentDate == null ||
            currentDate.year != txDate.year ||
            currentDate.month != txDate.month ||
            currentDate.day != txDate.day) {
          currentDate = txDate;
          sectioned.add(TxHeader(txDate));
        }
        if (item is Transaction) {
          sectioned.add(TxItem(item));
        } else {
          sectioned.add(SmsActivityItem(item as SmsActivity));
        }
      }

      return sectioned;
    });

final allSectionedTransactionsProvider =
    FutureProvider.autoDispose.family<List<TxListEntry>, String>((ref, type) async {
      final service = ref.watch(transactionProvider);

      // Handle needsReview filter - only show SMS activities
      if (type == 'needsReview') {
        final isar = await service.isarService.getInstance();
        final needsReviewActivities = await isar.smsActivitys
            .filter()
            .statusEqualTo(ActivityStatus.needsReview)
            .or()
            .statusEqualTo(ActivityStatus.pending)
            .or()
            .statusEqualTo(ActivityStatus.duplicate)
            .sortByDateDesc()
            .findAll();

        if (needsReviewActivities.isEmpty) return [];

        final List<TxListEntry> sectioned = [];
        DateTime? currentDate;

        for (var activity in needsReviewActivities) {
          final txDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
          if (currentDate == null ||
              currentDate.year != txDate.year ||
              currentDate.month != txDate.month ||
              currentDate.day != txDate.day) {
            currentDate = txDate;
            sectioned.add(TxHeader(txDate));
          }
          sectioned.add(SmsActivityItem(activity));
        }

        return sectioned;
      }

      List<Transaction> transactions;
      if (type == 'income') {
        transactions = await service.getByType(isExpense: false);
      } else if (type == 'expense') {
        transactions = await service.getByType(isExpense: true);
      } else {
        transactions = await service.getAll();
      }

      // Get pending SMS activities
      final isar = await service.isarService.getInstance();
      final pendingActivities = await isar.smsActivitys
          .filter()
          .not()
          .statusEqualTo(ActivityStatus.approved)
          .and()
          .not()
          .statusEqualTo(ActivityStatus.rejected)
          .sortByDateDesc()
          .findAll();

      // Combine transactions and activities
      final combined = <dynamic>[
        ...transactions,
        ...pendingActivities,
      ];

      // Sort by date
      combined.sort((a, b) {
        final dateA = a is Transaction ? a.date : (a as SmsActivity).date;
        final dateB = b is Transaction ? b.date : (b as SmsActivity).date;
        return dateB.compareTo(dateA);
      });

      if (combined.isEmpty) return [];

      final List<TxListEntry> sectioned = [];
      DateTime? currentDate;

      for (var item in combined) {
        final date = item is Transaction ? item.date : (item as SmsActivity).date;
        final txDate = DateTime(date.year, date.month, date.day);
        if (currentDate == null ||
            currentDate.year != txDate.year ||
            currentDate.month != txDate.month ||
            currentDate.day != txDate.day) {
          currentDate = txDate;
          sectioned.add(TxHeader(txDate));
        }
        if (item is Transaction) {
          sectioned.add(TxItem(item));
        } else {
          sectioned.add(SmsActivityItem(item as SmsActivity));
        }
      }

      return sectioned;
    });

// OPTIMIZED: Filter at database level
final filteredSectionedTransactionsProvider =
    FutureProvider.autoDispose.family<
      List<TxListEntry>,
      ({String type, int? categoryId, String? searchQuery})
    >((ref, arg) async {
      final service = ref.watch(transactionProvider);

      List<Transaction> transactions;
      if (arg.categoryId != null) {
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
  final gamificationService;

  TransactionService(this.isarService, this.log, this.gamificationService);

  Future<void> addTransaction(Transaction txn) async {
    log.d('Adding transaction: ${txn.isExpense ? "Expense" : "Income"} of ₹${txn.amount}');
    log.d('Transaction date: ${txn.date}');
    log.d('Transaction account: ${txn.account.value?.name}');
    log.d('Transaction category: ${txn.category.value?.name}');
    
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      final id = await isar.transactions.put(txn);
      log.d('Transaction put returned ID: $id');
      await txn.category.save();
      await txn.account.save();
      await txn.tags.save();
    });
    log.i('Transaction saved successfully with ID: ${txn.id}');
    
    // Verify the transaction was saved
    final saved = await isar.transactions.get(txn.id);
    if (saved != null) {
      log.d('Verified: Transaction ${txn.id} exists in DB with date: ${saved.date}');
    } else {
      log.e('ERROR: Transaction ${txn.id} not found in DB after save!');
    }
    
    // Track gamification
    await gamificationService.track(GamificationEvent.transactionAdded);
    if (txn.isTransfer) {
      await gamificationService.track(GamificationEvent.transferCompleted);
    }
    if (txn.tags.isNotEmpty) {
      await gamificationService.track(GamificationEvent.tagUsed);
    }
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
    log.d('Deleting transaction ID: $transactionId');
    final isar = await isarService.getInstance();
    await isar.writeTxn(() async {
      await isar.transactions.delete(transactionId);
    });
    log.i('Transaction deleted successfully');
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
    log.d('Transfer: ₹$amount from ${from.name} to ${to.name}');
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
      debit.related.value = credit;
      credit.related.value = debit;
      isar.transactions.putSync(debit, saveLinks: true);
      isar.transactions.putSync(credit, saveLinks: true);
      await debit.category.save();
      await debit.account.save();
      await credit.category.save();
      await credit.account.save();
    });
    log.i('Transfer completed successfully');
    
    // Track gamification
    await gamificationService.track(GamificationEvent.transferCompleted);
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

  // OPTIMIZED: Filter by category at database level
  Future<List<Transaction>> getByCategoryAndType({
    required int categoryId,
    required String type,
  }) async {
    final isar = await isarService.getInstance();
    
    var query = isar.transactions
        .filter()
        .category((q) => q.idEqualTo(categoryId));
    
    if (type == 'income') {
      query = query.isExpenseEqualTo(false).isTransferEqualTo(false);
    } else if (type == 'expense') {
      query = query.isExpenseEqualTo(true).isTransferEqualTo(false);
    }
    
    return await query.sortByDateDesc().findAll();
  }
}
