import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/constants/app_constants.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';

class PaginatedTransactionState {
  final List<Transaction> transactions;
  final bool hasMore;
  final bool isLoading;
  final int currentPage;

  PaginatedTransactionState({
    required this.transactions,
    required this.hasMore,
    required this.isLoading,
    required this.currentPage,
  });

  PaginatedTransactionState copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    bool? isLoading,
    int? currentPage,
  }) {
    return PaginatedTransactionState(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Paginated transaction provider using family for filter params.
///
/// Usage:
/// ```dart
/// final state = ref.watch(paginatedTransactionsProvider({'categoryId': 5}));
/// ref.read(paginatedTransactionsProvider({'categoryId': 5}).notifier).loadMore();
/// ```
final paginatedTransactionsProvider = FutureProvider.autoDispose
    .family<PaginatedTransactionState, Map<String, dynamic>>((ref, params) async {
  final categoryId = params['categoryId'] as int?;
  final accountId = params['accountId'] as int?;
  final startDate = params['startDate'] as DateTime?;
  final endDate = params['endDate'] as DateTime?;
  final page = params['page'] as int? ?? 0;

  final isar = await IsarService().getInstance();

  dynamic query = isar.transactions.filter();

  if (categoryId != null) {
    query = query.category((q) => q.idEqualTo(categoryId));
  }
  if (accountId != null) {
    query = query.account((q) => q.idEqualTo(accountId));
  }
  if (startDate != null) {
    query = query.dateGreaterThan(startDate);
  }
  if (endDate != null) {
    query = query.dateLessThan(endDate);
  }

  final transactions = await query
      .sortByDateDesc()
      .offset(page * AppConstants.transactionPageSize)
      .limit(AppConstants.transactionPageSize)
      .findAll();

  return PaginatedTransactionState(
    transactions: transactions,
    hasMore: transactions.length == AppConstants.transactionPageSize,
    isLoading: false,
    currentPage: page,
  );
});
