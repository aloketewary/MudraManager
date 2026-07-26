import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_service.dart';
export 'package:mudra_manager/features/transactions/data/transaction_service.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

final transactionProvider = Provider<TransactionService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final log = ref.getLogger('TransactionService');
  final gamificationService = ref.watch(gamificationServiceProvider);
  return TransactionService(isarService, log, gamificationService);
});

final filteredTransactionProvider = FutureProvider.autoDispose
    .family<List<Transaction>, String>((ref, type) async {
  ref.watch(transactionChangeProvider);
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
  ref.watch(transactionChangeProvider);
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
  ref.watch(transactionChangeProvider);
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
  ref.watch(transactionChangeProvider);
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

  return buildSectionedList(transactions);
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

  return buildSectionedList(transactions);
});

final allSectionedTransactionsProvider = FutureProvider.autoDispose
    .family<List<TxListEntry>, String>((ref, type) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(transactionProvider);

  // Load last 6 months for performance — user can switch to month view for older
  final cutoff = DateTime.now().subtract(const Duration(days: 180));
  List<Transaction> transactions;
  if (type == 'income') {
    transactions = await service.getByTypeAndDateRange(
      isExpense: false,
      start: cutoff,
      end: DateTime.now(),
    );
  } else if (type == 'expense') {
    transactions = await service.getByTypeAndDateRange(
      isExpense: true,
      start: cutoff,
      end: DateTime.now(),
    );
  } else {
    transactions = await service.getByDateRange(cutoff, DateTime.now());
  }

  if (transactions.isEmpty) return [];

  return buildSectionedList(transactions);
});

// OPTIMIZED: Filter at database level
final filteredSectionedTransactionsProvider = FutureProvider.autoDispose.family<
    List<TxListEntry>,
    ({String type, int? categoryId, int? tagId, String? searchQuery})>((ref, arg) async {
  ref.watch(transactionChangeProvider);
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

  return buildSectionedList(transactions);
});

final transactionCountsProvider = FutureProvider.autoDispose<Map<Id, int>>((
  ref,
) async {
  ref.watch(transactionChangeProvider);
  final isar = await ref.watch(isarServiceProvider).getInstance();
  final counts = <Id, int>{};
  final categories = await isar.categorys.where().findAll();

  for (final cat in categories) {
    final count = await isar.transactions
        .filter()
        .category((q) => q.idEqualTo(cat.id))
        .count();
    counts[cat.id] = count;
  }

  return counts;
});


final quickAmountsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  ref.watch(transactionChangeProvider);
  final service = ref.watch(transactionProvider);
  final transactions = await service.getByType(isExpense: true);

  if (transactions.length < 5) return [100, 500, 1000, 2000, 5000];

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
