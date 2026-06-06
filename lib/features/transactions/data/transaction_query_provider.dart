import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/collection_watchers.dart';
import 'package:mudra_manager/features/transactions/data/filter_state_provider.dart';
import 'package:mudra_manager/features/transactions/data/view_mode_provider.dart';
import 'package:mudra_manager/features/transactions/domain/filter_state.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_list_transformer.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_query.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_query_mapper.dart';
import 'package:mudra_manager/features/transactions/domain/transaction_view_mode.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/transaction_group.dart';

/// The single query provider that the transaction list screen watches.
///
/// Pipeline:
///   viewModeProvider + filterStateProvider
///     -> createTransactionQuery()
///     -> repository.query()
///     -> toTransactionListEntries()
///     -> `List<TxListEntry>`
///
/// The screen just renders entries. No query logic, no grouping, no provider selection.
final transactionQueryProvider =
    FutureProvider.autoDispose<List<TxListEntry>>((ref) async {
  // React to DB changes
  ref.watch(transactionChangeProvider);

  // Watch query state
  final mode = ref.watch(viewModeProvider);
  final filters = ref.watch(filterStateProvider);

  // Map to repository contract
  final query = createTransactionQuery(mode, filters);

  // Execute query
  final service = ref.watch(transactionProvider);
  final transactions = await _executeQuery(service, query, mode);

  // Transform to presentation model
  return toTransactionListEntries(transactions);
});

/// Executes a [TransactionQuery] against the [TransactionService].
///
/// For [InfiniteView], applies a 180-day recency window as a performance
/// optimization. This is an implementation detail of the repository layer,
/// NOT a semantic property of InfiniteView.
Future<List<Transaction>> _executeQuery(
  TransactionService service,
  TransactionQuery query,
  TransactionViewMode mode,
) async {
  // Tag queries need special handling (Isar link-based query)
  if (query.tagId != null) {
    final results = await service.getByTagAndType(
      tagId: query.tagId!,
      type: _typeToString(query.type),
    );
    return _applySearchFilter(results, query.searchQuery);
  }

  // Category queries use DB-level filter
  if (query.categoryId != null) {
    final results = await service.getByCategoryAndType(
      categoryId: query.categoryId!,
      type: _typeToString(query.type),
    );
    return _applySearchFilter(results, query.searchQuery);
  }

  // Date-bounded queries
  if (query.startDate != null && query.endDate != null) {
    final results = query.type == TransactionTypeFilter.all
        ? await service.getByDateRange(query.startDate!, query.endDate!)
        : await service.getByTypeAndDateRange(
            isExpense: query.type == TransactionTypeFilter.expense,
            start: query.startDate!,
            end: query.endDate!,
          );
    return _applySearchFilter(results, query.searchQuery);
  }

  // InfiniteView: apply performance window
  if (mode is InfiniteView) {
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final results = query.type == TransactionTypeFilter.all
        ? await service.getByDateRange(cutoff, DateTime.now())
        : await service.getByTypeAndDateRange(
            isExpense: query.type == TransactionTypeFilter.expense,
            start: cutoff,
            end: DateTime.now(),
          );
    return _applySearchFilter(results, query.searchQuery);
  }

  // Fallback: all transactions filtered by type
  final results = query.type == TransactionTypeFilter.all
      ? await service.getAll()
      : await service.getByType(
          isExpense: query.type == TransactionTypeFilter.expense,
        );
  return _applySearchFilter(results, query.searchQuery);
}

/// Applies text search in memory (can't index text search efficiently in Isar).
List<Transaction> _applySearchFilter(
  List<Transaction> transactions,
  String query,
) {
  if (query.isEmpty) return transactions;
  final lowerQuery = query.toLowerCase();
  return transactions
      .where(
          (tx) => tx.description?.toLowerCase().contains(lowerQuery) ?? false)
      .toList();
}

/// Converts [TransactionTypeFilter] to the string format the service expects.
String _typeToString(TransactionTypeFilter type) {
  switch (type) {
    case TransactionTypeFilter.all:
      return 'all';
    case TransactionTypeFilter.income:
      return 'income';
    case TransactionTypeFilter.expense:
      return 'expense';
  }
}
