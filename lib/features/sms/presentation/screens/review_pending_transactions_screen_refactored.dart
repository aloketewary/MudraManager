import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/approve_transaction_sheet.dart';
import 'package:mudra_manager/shared/widgets/pending_transaction_card.dart';
import 'package:mudra_manager/shared/widgets/transaction_filter_sheet.dart';

class ReviewPendingTransactionsScreen extends ConsumerStatefulWidget {
  const ReviewPendingTransactionsScreen({super.key});

  @override
  ConsumerState<ReviewPendingTransactionsScreen> createState() =>
      _ReviewPendingTransactionsScreenState();
}

class _ReviewPendingTransactionsScreenState
    extends ConsumerState<ReviewPendingTransactionsScreen>
    with TickerProviderStateMixin {
  bool _isAutoProcessing = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _filterIncome;
  String _searchQuery = '';
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingTransactionProvider = ref.watch(pendingTxnDataProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.pendingTranx_reviewPendingTransactionsScreenTitle),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _showFilterBottomSheet,
            icon: const Icon(Icons.filter_list),
          ),
          if (_isAutoProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: ctxt.sms_autoAddTooltip,
              onPressed: _autoProcessTransactions,
              icon: const Icon(Icons.auto_awesome),
            ),
            IconButton(
              tooltip: ctxt.sms_clearAllTooltip,
              onPressed: _clearAllTransactions,
              icon: const Icon(Icons.clear_all),
            ),
          ],
        ],
      ),
      body: pendingTransactionProvider.when(
        data: (pendingTrans) =>
            _buildTransactionList(pendingTrans, color, textTheme, ctxt),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTransactionList(
    List<PendingTransaction?> pendingTrans,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
  ) {
    final filtered = _applyFilters(pendingTrans);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: color.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              ctxt.sms_noPendingTransactions,
              style: textTheme.titleLarge?.copyWith(
                color: color.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
        ),
      );
    }

    _setupAnimations(filtered.length);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final tx = filtered[index];
        return SlideTransition(
          position: _animations[index],
          child: FadeTransition(
            opacity: _controllers[index],
            child: Dismissible(
              key: Key('pending_${tx?.date.millisecondsSinceEpoch}_$index'),
              confirmDismiss: (direction) =>
                  _handleDismiss(direction, tx, ctxt),
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _removePendingTransaction(tx, false, ctxt);
                }
              },
              background: _buildSwipeBackground(color, ctxt, isLeft: true),
              secondaryBackground: _buildSwipeBackground(
                color,
                ctxt,
                isLeft: false,
              ),
              child: PendingTransactionCard(
                transaction: tx!,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showApproveBottomSheet(context, tx);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<PendingTransaction?> _applyFilters(
    List<PendingTransaction?> transactions,
  ) {
    return transactions.where((tx) {
      if (tx == null) return false;
      if (_startDate != null && tx.date.isBefore(_startDate!)) return false;
      if (_endDate != null && tx.date.isAfter(_endDate!)) return false;
      if (_filterIncome != null && tx.isIncome != _filterIncome) return false;
      if (_searchQuery.isNotEmpty &&
          !(tx.sender.toLowerCase().contains(_searchQuery.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
  }

  void _setupAnimations(int count) {
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers = List.generate(
      count,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
    _runStaggeredAnimations();
  }

  void _runStaggeredAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (_isDisposed || i >= _controllers.length) return;
      _controllers[i].forward();
    }
  }

  Widget _buildSwipeBackground(
    ColorScheme color,
    AppLocalizations ctxt, {
    required bool isLeft,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isLeft ? color.primary : color.error,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: isLeft ? 24 : 0, right: isLeft ? 0 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeft ? Icons.check_circle : Icons.delete,
            color: isLeft ? color.onPrimary : color.onError,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            isLeft ? ctxt.sms_approveLabel : ctxt.common_deleteLabel,
            style: TextStyle(
              color: isLeft ? color.onPrimary : color.onError,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Future<bool?> _handleDismiss(
    DismissDirection direction,
    PendingTransaction tx,
    AppLocalizations ctxt,
  ) async {
    if (direction == DismissDirection.endToStart) {
      HapticFeedback.mediumImpact();
      return await DialogUtils.showDeleteConfirmation(
        context,
        title: ctxt.transaction_deleteAlertTitleText,
        message: ctxt.transaction_deleteAlertBodyText,
      );
    } else if (direction == DismissDirection.startToEnd) {
      HapticFeedback.mediumImpact();
      _showApproveBottomSheet(context, tx);
      return false;
    }
    return false;
  }

  void _removePendingTransaction(
    PendingTransaction pendingTx,
    bool isApproved,
    AppLocalizations ctxt,
  ) async {
    await ref.read(pendingTxnServiceProvider).remove(pendingTx);
    ref.invalidate(pendingTxnServiceProvider);
    ref.invalidate(pendingTxnDataProvider);
    if (!isApproved && mounted) {
      SnackbarService.success('Removed ${pendingTx.sender}');
    }
  }

  void _approveTransaction(
    PendingTransaction pendingTx,
    Account account,
    Category category,
    DateTime date,
    double amount,
    AppLocalizations ctxt,
  ) async {
    final log = AppLog(ref.read(loggerProvider), 'PendingTxnApprove');
    log.i('Starting transaction approval for ${pendingTx.sender}');
    log.d('Date parameter received: $date');

    if (!mounted) {
      log.w('Widget not mounted, aborting');
      return;
    }

    final transactionService = ref.read(transactionProvider);
    final pendingService = ref.read(pendingTxnServiceProvider);
    log.d('Services obtained');

    final txn = Transaction()
      ..date = date
      ..amount = amount
      ..isExpense = pendingTx.isIncome == false
      ..description = pendingTx.body
      ..isTransfer = false;
    log.d('After setting date field: ${txn.date}');
    txn.account.value = account;
    txn.category.value = category;
    log.d(
      'Transaction object before save - date: ${txn.date}, amount: ${txn.amount}, isExpense: ${txn.isExpense}',
    );

    await transactionService.addTransaction(txn);
    log.i('Transaction added to database');

    // Track SMS approval
    final gamificationService = await ref.read(gamificationServiceInitProvider.future);
    await gamificationService.track(GamificationEvent.smsTransactionApproved);

    if (!mounted) {
      log.w('Widget disposed after addTransaction');
      return;
    }

    await pendingService.remove(pendingTx);
    log.i('Pending transaction removed');

    if (!mounted) {
      log.w('Widget disposed after remove');
      return;
    }

    ref.invalidate(transactionProvider);
    ref.invalidate(pendingTxnServiceProvider);
    ref.invalidate(pendingTxnDataProvider);
    log.d('Providers invalidated');

    await Future.delayed(const Duration(milliseconds: 500));
    log.d('Waited 500ms for Isar sync');

    await WidgetService.updateWidget(ref);
    log.d('Widget updated');

    if (mounted) {
      SnackbarService.success('Approved ${pendingTx.sender}');
      log.i('Approval complete');
    }
  }

  void _approveTransfer(
    PendingTransaction pendingTx,
    Account fromAccount,
    Account toAccount,
    AppLocalizations ctxt,
  ) async {
    final log = AppLog(ref.read(loggerProvider), 'PendingTxnTransfer');
    log.i('Starting transfer approval for ${pendingTx.sender}');

    if (!mounted) {
      log.w('Widget not mounted, aborting');
      return;
    }

    final transactionService = ref.read(transactionProvider);
    final pendingService = ref.read(pendingTxnServiceProvider);
    log.d('Services obtained');

    await transactionService.transfer(
      from: fromAccount,
      to: toAccount,
      amount: pendingTx.amount ?? 0.0,
      date: pendingTx.date,
      note: pendingTx.body,
    );
    log.i(
      'Transfer completed: ${fromAccount.name} -> ${toAccount.name}, amount: ${pendingTx.amount}',
    );

    if (!mounted) {
      log.w('Widget disposed after transfer');
      return;
    }

    await pendingService.remove(pendingTx);
    log.i('Pending transaction removed');

    if (!mounted) {
      log.w('Widget disposed after remove');
      return;
    }

    ref.invalidate(transactionProvider);
    ref.invalidate(pendingTxnServiceProvider);
    ref.invalidate(pendingTxnDataProvider);
    log.d('Providers invalidated');

    await Future.delayed(const Duration(milliseconds: 500));
    log.d('Waited 500ms for Isar sync');

    await WidgetService.updateWidget(ref);
    log.d('Widget updated');

    if (mounted) {
      SnackbarService.success('Transfer approved: ${pendingTx.sender}');
      log.i('Transfer approval complete');
    }
  }

  void _autoProcessTransactions() async {
    setState(() => _isAutoProcessing = true);
    try {
      final accounts = await ref.read(accountsProvider.future);
      final categories = await ref.read(categoryListProvider.future);
      final count = await ref
          .read(pendingTxnServiceProvider)
          .autoProcessAll(accounts: accounts, categories: categories);
      ref.invalidate(pendingTxnDataProvider);
      ref.invalidate(transactionProvider);
      if (mounted) {
        SnackbarService.success('Auto-added $count transactions!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.error('Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isAutoProcessing = false);
    }
  }

  void _clearAllTransactions() async {
    HapticFeedback.mediumImpact();
    final ctxt = AppLocalizations.of(context)!;
    final confirm = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Clear All Pending Transactions?',
      message:
          'This will remove all pending transactions. This action cannot be undone.',
    );
    if (confirm == true) {
      await ref.read(pendingTxnServiceProvider).clearAll();
      ref.invalidate(pendingTxnServiceProvider);
      ref.invalidate(pendingTxnDataProvider);
      if (mounted) SnackbarService.success('All pending transactions cleared');
    }
  }

  void _showApproveBottomSheet(
    BuildContext context,
    PendingTransaction pendingTx,
  ) async {
    final ctxt = AppLocalizations.of(context)!;
    final categories = await ref.read(categoryListProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    final matchedAccount =
        pendingTx.account != null && pendingTx.account!.isNotEmpty
        ? accounts
              .where(
                (a) => a.accountNumber?.contains(pendingTx.account!) == true,
              )
              .firstOrNull
        : null;

    final matchedToAccount =
        pendingTx.toAccount != null && pendingTx.toAccount!.isNotEmpty
        ? accounts
              .where(
                (a) => a.accountNumber?.contains(pendingTx.toAccount!) == true,
              )
              .firstOrNull
        : null;

    final relevantCategories = categories
        .where(
          (c) =>
              (pendingTx.isIncome == true &&
                  c.categoryType == CategoryType.income) ||
              (pendingTx.isIncome == false &&
                  c.categoryType == CategoryType.expense),
        )
        .toList();
    final suggestedCategory = CategoryMatcher.matchByKeywords(
      pendingTx.body,
      relevantCategories,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ApproveTransactionSheet(
        transaction: pendingTx,
        matchedAccount: matchedAccount,
        matchedToAccount: matchedToAccount,
        suggestedCategory: suggestedCategory,
        onApprove: (account, category, date, amount) => _approveTransaction(
          pendingTx,
          account,
          category,
          date,
          amount,
          ctxt,
        ),
        onApproveTransfer: (fromAccount, toAccount) =>
            _approveTransfer(pendingTx, fromAccount, toAccount, ctxt),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TransactionFilterSheet(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialFilterIncome: _filterIncome,
        initialSearchQuery: _searchQuery,
        onApply: (startDate, endDate, filterIncome, searchQuery) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _filterIncome = filterIncome;
            _searchQuery = searchQuery;
          });
        },
      ),
    );
  }
}
