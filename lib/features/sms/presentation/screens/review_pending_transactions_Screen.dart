import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/category_matcher.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/pending_transaction_prodiver.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';

class ReviewPendingTransactionsScreen extends ConsumerStatefulWidget {
  const ReviewPendingTransactionsScreen({super.key});

  @override
  ConsumerState<ReviewPendingTransactionsScreen> createState() =>
      _ReviewPendingTransactionsScreenState();
}

class _ReviewPendingTransactionsScreenState
    extends ConsumerState<ReviewPendingTransactionsScreen>
    with TickerProviderStateMixin {
  Map<int, double> _balanceMap = {};
  bool _initialized = false;
  bool _isAutoProcessing = false;
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];
  bool _isDisposed = false;

  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _filterIncome; // null = all, true = income, false = expense
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.watch(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) setState(() => _balanceMap = val);
      });
      _initialized = true;
    }
  }

  void _runStaggeredAnimations() async {
    if (_controllers.isNotEmpty) {
      for (int i = 0; i < _controllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (_isDisposed || i >= _controllers.length) return;
        _controllers[i].forward();
      }
    }
  }

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
    final pendingTransactionService = ref.watch(pendingTxnServiceProvider);
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
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final confirm = await DialogUtils.showDeleteConfirmation(
                  context,
                  title: 'Clear All Pending Transactions?',
                  message:
                      'This will remove all pending transactions. This action cannot be undone.',
                );
                if (confirm == true) {
                  await pendingTransactionService.clearAll();
                  ref.invalidate(pendingTxnServiceProvider);
                  ref.invalidate(pendingTxnDataProvider);
                  if (mounted) {
                    SnackbarService.success('All pending transactions cleared');
                  }
                }
              },
              icon: const Icon(Icons.clear_all),
            ),
          ],
        ],
      ),
      body: pendingTransactionProvider.when(
        data: (pendingTrans) {
          // Apply filters
          final filtered = pendingTrans.where((tx) {
            if (tx == null) return false;

            // Date filter
            if (_startDate != null && tx.date.isBefore(_startDate!)) {
              return false;
            }
            if (_endDate != null && tx.date.isAfter(_endDate!)) {
              return false;
            }

            // Income/Expense filter
            if (_filterIncome != null && tx.isIncome != _filterIncome) {
              return false;
            }

            // Sender search
            if (_searchQuery.isNotEmpty &&
                !(tx.sender.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ))) {
              return false;
            }

            return true;
          }).toList();

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

          for (var c in _controllers) {
            c.dispose();
          }
          _controllers = List.generate(
            filtered.length,
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              final isIncome = (tx?.amount ?? 0) > 0;

              return SlideTransition(
                position: _animations[index],
                child: FadeTransition(
                  opacity: _controllers[index],
                  child: Dismissible(
                    key: Key(
                      'pending_${tx?.date.millisecondsSinceEpoch}_$index',
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        HapticFeedback.mediumImpact();
                        return await DialogUtils.showDeleteConfirmation(
                          context,
                          title: ctxt.transaction_deleteAlertTitleText,
                          message: ctxt.transaction_deleteAlertBodyText,
                        );
                      } else if (direction == DismissDirection.startToEnd) {
                        HapticFeedback.mediumImpact();
                        _showApproveBottomSheet(context, tx!);
                        return false;
                      }
                      return false;
                    },

                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _removePendingTransaction(tx!, false, ctxt);
                      }
                    },
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color.onPrimary,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ctxt.sms_approveLabel,
                            style: TextStyle(
                              color: color.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: color.onError, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            ctxt.common_deleteLabel,
                            style: TextStyle(
                              color: color.onError,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showApproveBottomSheet(context, tx!);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      (isIncome ? color.primary : color.error)
                                          .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: isIncome ? color.primary : color.error,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx?.sender ?? 'Unknown',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'EEE, dd MMM',
                                        ctxt.localeName,
                                      ).format(tx?.date ?? DateTime.now()),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'} ${ctxt.formatCurrencyWithSign(2, (tx?.amount ?? 0.0).abs())}',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isIncome ? color.primary : color.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _removePendingTransaction(
    PendingTransaction pendingTx,
    bool isApproved,
    AppLocalizations ctxt,
  ) async {
    final confirm = await DialogUtils.showDeleteConfirmation(
      context,
      title: ctxt.transaction_deleteAlertTitleText,
      message: ctxt.transaction_deleteAlertBodyText,
    );

    if (confirm == true) {
      await ref.read(pendingTxnServiceProvider).remove(pendingTx);
      ref.invalidate(pendingTxnServiceProvider);
      if (!isApproved && mounted) {
        SnackbarService.success('Removed ${pendingTx.sender}');
      }
    }
  }

  void _approveTransaction(
    PendingTransaction pendingTx,
    Account account,
    Category category,
    AppLocalizations ctxt,
  ) async {
    final txn = Transaction.create(
      date: pendingTx.date,
      amount: pendingTx.amount ?? 0.0,
      isExpense: pendingTx.isIncome == false,
      description: pendingTx.body,
    );
    txn.account.value = account;
    txn.category.value = category;
    await ref.read(transactionProvider).addTransaction(txn);
    await WidgetService.updateWidget(ref);
    ref.invalidate(transactionProvider);
    _removePendingTransaction(pendingTx, true, ctxt);
    if (mounted) {
      SnackbarService.success('Approved ${pendingTx.sender}');
      context.pop();
    }
  }

  void _approveTransfer(
    PendingTransaction pendingTx,
    Account fromAccount,
    Account toAccount,
    AppLocalizations ctxt,
  ) async {
    await ref
        .read(transactionProvider)
        .transfer(
          from: fromAccount,
          to: toAccount,
          amount: pendingTx.amount ?? 0.0,
          date: pendingTx.date,
          note: pendingTx.body,
        );
    await WidgetService.updateWidget(ref);
    ref.invalidate(transactionProvider);
    _removePendingTransaction(pendingTx, true, ctxt);
    if (mounted) {
      SnackbarService.success('Transfer approved: ${pendingTx.sender}');
      context.pop();
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

  void _showApproveBottomSheet(
    BuildContext context,
    PendingTransaction pendingTx,
  ) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    // Check if this is a transfer transaction
    final isTransfer =
        pendingTx.type?.toLowerCase().contains('transfer') == true ||
        (pendingTx.fromBank != null && pendingTx.toAccount != null);

    // Pre-select suggested category
    final categories = await ref.read(categoryListProvider.future);
    final accounts = await ref.read(accountsProvider.future);

    // Try to match account
    Account? matchedAccount;
    Account? selectedAccount;
    if (pendingTx.account != null && pendingTx.account!.isNotEmpty) {
      matchedAccount = accounts
          .where((a) => a.accountNumber?.contains(pendingTx.account!) == true)
          .firstOrNull;
      selectedAccount = matchedAccount;
    }

    // For transfers, try to match destination account
    Account? matchedToAccount;
    Account? selectedToAccount;
    if (isTransfer &&
        pendingTx.toAccount != null &&
        pendingTx.toAccount!.isNotEmpty) {
      matchedToAccount = accounts
          .where((a) => a.accountNumber?.contains(pendingTx.toAccount!) == true)
          .firstOrNull;
      selectedToAccount = matchedToAccount;
    }

    final relevantCategories = categories
        .where(
          (c) =>
              (pendingTx.isIncome == true &&
                  c.categoryType == CategoryType.income) ||
              (pendingTx.isIncome == false &&
                  c.categoryType == CategoryType.expense),
        )
        .toList();
    Category? selectedCategory = CategoryMatcher.matchByKeywords(
      pendingTx.body,
      relevantCategories,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ctxt.sms_approveTransactionTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sms_outlined, size: 20, color: color.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pendingTx.body,
                          style: textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Account', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) => ref
                      .watch(accountsProvider)
                      .when(
                        data: (accounts) => SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                accounts.length +
                                (pendingTx.account != null &&
                                        matchedAccount == null
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              // Show "Add Account" button if account not found
                              if (index == accounts.length &&
                                  pendingTx.account != null &&
                                  matchedAccount == null) {
                                return GestureDetector(
                                  onTap: () => context.push(
                                    '/manage-accounts/add',
                                    extra: {
                                      'accountNumber': pendingTx.account,
                                      'bankName': pendingTx.fromBank,
                                    },
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.error,
                                        width: 2,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                          color: color.error,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pendingTx.fromBank != null &&
                                                  pendingTx.fromBank!.isNotEmpty
                                              ? '${pendingTx.fromBank}\n****${pendingTx.account}'
                                              : '****${pendingTx.account}',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: color.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final account = accounts[index];
                              final isSelected =
                                  selectedAccount?.id == account.id;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => selectedAccount = account);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.primaryContainer
                                        : color.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: color.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getIconForAccountType(
                                          account.accountType,
                                        ),
                                        size: 20,
                                        color: isSelected
                                            ? color.onPrimaryContainer
                                            : color.onSurface,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        account.name,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: isSelected
                                              ? color.onPrimaryContainer
                                              : color.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 60,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox(
                          height: 60,
                          child: Text('Error loading accounts'),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                if (isTransfer) ...[
                  Text('To Account', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) => ref
                        .watch(accountsProvider)
                        .when(
                          data: (accounts) => SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  accounts.length +
                                  (pendingTx.toAccount != null &&
                                          matchedToAccount == null
                                      ? 1
                                      : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == accounts.length &&
                                    pendingTx.toAccount != null &&
                                    matchedToAccount == null) {
                                  return GestureDetector(
                                    onTap: () => context.push(
                                      '/manage-accounts/add',
                                      extra: {
                                        'accountNumber': pendingTx.toAccount,
                                        'bankName': pendingTx.fromBank,
                                      },
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: color.error,
                                          width: 2,
                                          strokeAlign:
                                              BorderSide.strokeAlignInside,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                            color: color.error,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '****${pendingTx.toAccount}',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  color: color.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final account = accounts[index];
                                final isSelected =
                                    selectedToAccount?.id == account.id;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    setState(() => selectedToAccount = account);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.primaryContainer
                                          : color.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: color.primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getIconForAccountType(
                                            account.accountType,
                                          ),
                                          size: 20,
                                          color: isSelected
                                              ? color.onPrimaryContainer
                                              : color.onSurface,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          account.name,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: isSelected
                                                ? color.onPrimaryContainer
                                                : color.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 60,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox(
                            height: 60,
                            child: Text('Error loading accounts'),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!isTransfer) ...[
                  Text('Category', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) => ref
                        .watch(categoryListProvider)
                        .when(
                          data: (categories) {
                            final filtered = categories
                                .where(
                                  (c) =>
                                      ((pendingTx.isIncome == true
                                          ? c.categoryType ==
                                                CategoryType.income
                                          : c.categoryType ==
                                                CategoryType.expense)) &&
                                      c.parentCategory.value == null,
                                )
                                .toList();
                            return SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length + 1,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  if (index < filtered.length) {
                                    final cat = filtered[index];
                                    final isParentSelected =
                                        selectedCategory?.id == cat.id;
                                    final isChildSelected =
                                        selectedCategory
                                            ?.parentCategory
                                            .value
                                            ?.id ==
                                        cat.id;
                                    final isSelected =
                                        isParentSelected || isChildSelected;
                                    final hasSubcategories = categories.any(
                                      (c) =>
                                          c.parentCategory.value?.id == cat.id,
                                    );

                                    return GestureDetector(
                                      onTap: () async {
                                        if (hasSubcategories) {
                                          final subcategories = categories
                                              .where(
                                                (c) =>
                                                    c
                                                        .parentCategory
                                                        .value
                                                        ?.id ==
                                                    cat.id,
                                              )
                                              .toList();
                                          final selected =
                                              await showModalBottomSheet<
                                                Category
                                              >(
                                                context: context,
                                                builder: (_) =>
                                                    _SubcategoryPicker(
                                                      parent: cat,
                                                      subcategories:
                                                          subcategories,
                                                      selected:
                                                          selectedCategory,
                                                    ),
                                              );
                                          if (selected != null) {
                                            setState(
                                              () => selectedCategory = selected,
                                            );
                                          }
                                        } else {
                                          HapticFeedback.mediumImpact();
                                          setState(
                                            () => selectedCategory = cat,
                                          );
                                        }
                                      },
                                      onLongPress: hasSubcategories
                                          ? () {
                                              HapticFeedback.mediumImpact();
                                              setState(
                                                () => selectedCategory = cat,
                                              );
                                            }
                                          : null,
                                      child: Card(
                                        elevation: isSelected ? 4 : 0,
                                        shadowColor: isSelected
                                            ? color.primary.withValues(
                                                alpha: 0.3,
                                              )
                                            : null,
                                        color: isSelected
                                            ? color.primaryContainer
                                            : color.surfaceContainerHighest,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          side: isSelected
                                              ? BorderSide(
                                                  color: color.primary,
                                                  width: 2,
                                                )
                                              : BorderSide.none,
                                        ),
                                        child: Container(
                                          width: 120,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                height: 40,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          cat.colorValue ??
                                                              color.primary
                                                                  .toARGB32(),
                                                        ).withValues(alpha: 0.15),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        IconHelper.iconFromName(
                                                          cat.iconName ??
                                                              'category',
                                                        ),
                                                        color: Color(
                                                          cat.colorValue ??
                                                              color.primary
                                                                  .toARGB32(),
                                                        ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    if (isChildSelected &&
                                                        selectedCategory !=
                                                            null)
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Color(
                                                              selectedCategory!
                                                                      .colorValue ??
                                                                  color.primary
                                                                      .toARGB32(),
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  color.surface,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            IconHelper.iconFromName(
                                                              selectedCategory!
                                                                      .iconName ??
                                                                  'category',
                                                            ),
                                                            color: Colors.white,
                                                            size: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    if (hasSubcategories &&
                                                        !isChildSelected)
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                2,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: color
                                                                    .primary,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: Icon(
                                                            Icons.chevron_right,
                                                            size: 12,
                                                            color:
                                                                color.onPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isChildSelected &&
                                                            selectedCategory !=
                                                                null
                                                        ? selectedCategory!.name
                                                        : cat.name,
                                                    style: textTheme.labelLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isSelected
                                                              ? color
                                                                    .onPrimaryContainer
                                                              : color.onSurface,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (isChildSelected &&
                                                      selectedCategory != null)
                                                    Text(
                                                      cat.name,
                                                      style: textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: isSelected
                                                                ? color
                                                                      .onPrimaryContainer
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      )
                                                                : color
                                                                      .onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return GestureDetector(
                                      onTap: () =>
                                          context.push('/add-category'),
                                      child: Card(
                                        elevation: 0,
                                        color: color.surfaceContainerHigh,
                                        child: SizedBox(
                                          width: 80,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                color: color.onSurfaceVariant,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ctxt.common_addLabel,
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: color
                                                          .onSurfaceVariant,
                                                    ),
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox(
                            height: 120,
                            child: Text('Error loading categories'),
                          ),
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (isTransfer) {
                      if (selectedAccount != null &&
                          selectedToAccount != null) {
                        _approveTransfer(
                          pendingTx,
                          selectedAccount!,
                          selectedToAccount!,
                          ctxt,
                        );
                      } else {
                        SnackbarService.warning(
                          'Select both accounts for transfer',
                        );
                      }
                    } else {
                      if (selectedCategory != null && selectedAccount != null) {
                        _approveTransaction(
                          pendingTx,
                          selectedAccount!,
                          selectedCategory!,
                          ctxt,
                        );
                      } else {
                        SnackbarService.warning('Select Account & Category');
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isTransfer ? 'Approve Transfer' : 'Approve Transaction',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.eWallet:
        return Icons.account_balance_wallet;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.attach_money;
    }
  }

  void _showFilterBottomSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: color.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setModalState) => Container(
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: color.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Transactions',
                    style: textTheme.titleLarge?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by sender',
                      prefixIcon: Icon(Icons.search, color: color.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: color.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: color.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    onChanged: (value) =>
                        setModalState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Type',
                    style: textTheme.titleMedium?.copyWith(
                      color: color.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool?>(
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text('All'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_filterIncome},
                    onSelectionChanged: (Set<bool?> selected) {
                      setModalState(() => _filterIncome = selected.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => _startDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate == null
                                ? 'Start Date'
                                : DateFormat('dd MMM').format(_startDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setModalState(() => _endDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _endDate == null
                                ? 'End Date'
                                : DateFormat('dd MMM').format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _startDate = null;
                              _endDate = null;
                              _filterIncome = null;
                              _searchQuery = '';
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: color.primary,
                            foregroundColor: color.onPrimary,
                          ),
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryPicker extends StatelessWidget {
  final Category parent;
  final List<Category> subcategories;
  final Category? selected;

  const _SubcategoryPicker({
    required this.parent,
    required this.subcategories,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parent.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select subcategory or tap parent',
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              IconHelper.iconFromName(parent.iconName ?? 'category'),
              color: Color(parent.colorValue ?? 0xFF000000),
            ),
            title: Text('${parent.name} (Parent)'),
            selected: selected?.id == parent.id,
            onTap: () => Navigator.pop(context, parent),
          ),
          const Divider(),
          ...subcategories.map(
            (sub) => ListTile(
              leading: Icon(
                IconHelper.iconFromName(sub.iconName ?? 'category'),
                color: Color(sub.colorValue ?? 0xFF000000),
              ),
              title: Text(sub.name),
              selected: selected?.id == sub.id,
              onTap: () => Navigator.pop(context, sub),
            ),
          ),
        ],
      ),
    );
  }
}
