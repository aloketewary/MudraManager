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

class PaginatedTransactionNotifier
    extends StateNotifier<PaginatedTransactionState> {
  final Ref ref;
  final int? categoryId;
  final int? accountId;
  final DateTime? startDate;
  final DateTime? endDate;

  PaginatedTransactionNotifier(
    this.ref, {
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
  }) : super(
         PaginatedTransactionState(
           transactions: [],
           hasMore: true,
           isLoading: false,
           currentPage: 0,
         ),
       ) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final isar = await IsarService().getInstance();

      // Start with base query - use dynamic to avoid type issues
      dynamic query = isar.transactions.filter();

      if (categoryId != null) {
        query = query.category((q) => q.idEqualTo(categoryId!));
      }
      if (accountId != null) {
        query = query.account((q) => q.idEqualTo(accountId!));
      }
      if (startDate != null) {
        query = query.dateGreaterThan(startDate!);
      }
      if (endDate != null) {
        query = query.dateLessThan(endDate!);
      }

      // Execute query with sorting
      final newTransactions = await query
          .sortByDateDesc()
          .offset(state.currentPage * AppConstants.transactionPageSize)
          .limit(AppConstants.transactionPageSize)
          .findAll();

      final hasMore =
          newTransactions.length == AppConstants.transactionPageSize;

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        hasMore: hasMore,
        isLoading: false,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void reset() {
    state = PaginatedTransactionState(
      transactions: [],
      hasMore: true,
      isLoading: false,
      currentPage: 0,
    );
    loadMore();
  }
}

final paginatedTransactionsProvider = StateNotifierProvider.autoDispose
    .family<
      PaginatedTransactionNotifier,
      PaginatedTransactionState,
      Map<String, dynamic>
    >((ref, params) {
      return PaginatedTransactionNotifier(
        ref,
        categoryId: params['categoryId'] as int?,
        accountId: params['accountId'] as int?,
        startDate: params['startDate'] as DateTime?,
        endDate: params['endDate'] as DateTime?,
      );
    });
