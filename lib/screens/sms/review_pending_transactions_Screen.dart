import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account, AccountType;
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType;
import 'package:mudra_manager/db/models/pending_transaction.dart'
    show PendingTransaction;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart'
    show AddEditCategoryScreen;
import 'package:mudra_manager/screens/reusable/account_display_card.dart'
    show AccountDisplayCard;
import 'package:mudra_manager/screens/reusable/category_card.dart'
    show CategoryCard;

import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:mudra_manager/util/category_matcher.dart';

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
        await Future.delayed(Duration(milliseconds: 80));
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
    var pendingTransactionProvider = ref.watch(pendingTxnDataProvider);
    var pendingTransactionService = ref.watch(pendingTxnServiceProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.pendingTranx_reviewPendingTransactionsScreenTitle),
        actions: [
          IconButton(
            tooltip: "Filter",
            onPressed: _showFilterBottomSheet,
            icon: Icon(Icons.filter_list),
          ),
          if (_isAutoProcessing)
            Padding(
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
              icon: Icon(Icons.auto_awesome),
            ),
            IconButton(
              tooltip: ctxt.sms_clearAllTooltip,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await pendingTransactionService.clearAll();
                ref.invalidate(pendingTxnServiceProvider);
                ref.invalidate(pendingTxnDataProvider);
              },
              icon: Icon(Icons.clear_all),
            ),
          ],
        ],
      ),
      body: pendingTransactionProvider.when(
        data: (pendingTrans) {
          // Apply filters
          var filtered =
              pendingTrans.where((tx) {
                if (tx == null) return false;

                // Date filter
                if (_startDate != null && tx.date.isBefore(_startDate!))
                  return false;
                if (_endDate != null && tx.date.isAfter(_endDate!))
                  return false;

                // Income/Expense filter
                if (_filterIncome != null && tx.isIncome != _filterIncome)
                  return false;

                // Sender search
                if (_searchQuery.isNotEmpty &&
                    !(tx.sender?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false)) {
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
                    color: color.primary.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
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
              duration: Duration(milliseconds: 400),
            ),
          );
          _animations =
              _controllers
                  .map(
                    (c) => Tween<Offset>(
                      begin: Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: c, curve: Curves.easeOut),
                    ),
                  )
                  .toList();
          _runStaggeredAnimations();

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
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
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color.onPrimary,
                            size: 32,
                          ),
                          SizedBox(height: 4),
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
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: color.onError, size: 32),
                          SizedBox(height: 4),
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
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showApproveBottomSheet(context, tx!);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isIncome
                                          ? color.primary
                                          : color.error)
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: isIncome ? color.primary : color.error,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
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
                                    SizedBox(height: 4),
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
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _removePendingTransaction(
    PendingTransaction pendingTx,
    bool isApproved,
    AppLocalizations ctxt
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
      description: ctxt.sms_importedFromSmsDescription,
    );
    txn.account.value = account;
    txn.category.value = category;
    await ref.read(transactionProvider).addTransaction(txn);
    ref.invalidate(transactionProvider);
    _removePendingTransaction(pendingTx, true, ctxt);
    if (mounted) {
      SnackbarService.success('Approved ${pendingTx.sender}');
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
    Account? selectedAccount;
    Category? selectedCategory;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    // Pre-select suggested category
    final categories = await ref.read(categoryListProvider.future);
    final relevantCategories =
        categories
            .where(
              (c) =>
                  (pendingTx.isIncome == true &&
                      c.categoryType == CategoryType.income) ||
                  (pendingTx.isIncome == false &&
                      c.categoryType == CategoryType.expense),
            )
            .toList();
    selectedCategory = CategoryMatcher.matchByKeywords(
      pendingTx.body,
      relevantCategories,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      showDragHandle: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (_, controller) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: StatefulBuilder(
                    builder:
                        (context, setState) => SingleChildScrollView(
                          controller: controller,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ctxt.sms_approveTransactionTitle,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sms_outlined,
                                          size: 20,
                                          color: color.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'SMS Details',
                                          style: textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      pendingTx.body,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                                Text(
                                'Select Account',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 16),
                              Consumer(
                                builder:
                                    (context, ref, _) => ref
                                        .watch(accountsProvider)
                                        .when(
                                          data:
                                              (accounts) => SizedBox(
                                                height: 150,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: accounts.length,
                                                  separatorBuilder:
                                                      (_, __) =>
                                                          SizedBox(width: 12),
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    final account =
                                                        accounts[index];
                                                    final isSelected =
                                                        selectedAccount?.id ==
                                                        account.id;
                                                    final balance =
                                                        _balanceMap[account
                                                            .id] ??
                                                        account.initialBalance;

                                                    return GestureDetector(
                                                      onTap: () {
                                                        HapticFeedback.mediumImpact();
                                                        setState(
                                                          () =>
                                                              selectedAccount =
                                                                  account,
                                                        );
                                                      },
                                                      child: AnimatedContainer(
                                                        duration: Duration(
                                                          milliseconds: 200,
                                                        ),
                                                        width: 140,
                                                        margin:
                                                            EdgeInsets.symmetric(
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                24,
                                                              ),
                                                          gradient:
                                                              isSelected
                                                                  ? LinearGradient(
                                                                    begin:
                                                                        Alignment
                                                                            .topLeft,
                                                                    end:
                                                                        Alignment
                                                                            .bottomRight,
                                                                    colors: [
                                                                      Color(
                                                                        account.colorValue ??
                                                                            0xFF000000,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                                      Color(
                                                                        account.colorValue ??
                                                                            0xFF000000,
                                                                      ),
                                                                    ],
                                                                  )
                                                                  : LinearGradient(
                                                                    begin:
                                                                        Alignment
                                                                            .topLeft,
                                                                    end:
                                                                        Alignment
                                                                            .bottomRight,
                                                                    colors: [
                                                                      color
                                                                          .surfaceContainerHighest
                                                                          .withValues(
                                                                            alpha:
                                                                                0.6,
                                                                          ),
                                                                      color
                                                                          .surfaceContainerHighest
                                                                          .withValues(
                                                                            alpha:
                                                                                0.3,
                                                                          ),
                                                                    ],
                                                                  ),
                                                          boxShadow:
                                                              isSelected
                                                                  ? [
                                                                    BoxShadow(
                                                                      color: Color(
                                                                        account.colorValue ??
                                                                            0xFF000000,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                                      blurRadius:
                                                                          8,
                                                                      offset:
                                                                          Offset(
                                                                            0,
                                                                            4,
                                                                          ),
                                                                    ),
                                                                  ]
                                                                  : [],
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                24,
                                                              ),
                                                          child: Stack(
                                                            children: [
                                                              Positioned(
                                                                right: -15,
                                                                bottom: -15,
                                                                child: Transform.rotate(
                                                                  angle: -0.2,
                                                                  child: Icon(
                                                                    _getIconForAccountType(
                                                                      account
                                                                          .accountType,
                                                                    ),
                                                                    size: 80,
                                                                    color: Colors
                                                                        .white
                                                                        .withValues(
                                                                          alpha:
                                                                              0.15,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      16,
                                                                    ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isSelected
                                                                                ? Colors.white.withValues(
                                                                                  alpha:
                                                                                      0.2,
                                                                                )
                                                                                : color.surface,
                                                                        shape:
                                                                            BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        _getIconForAccountType(
                                                                          account
                                                                              .accountType,
                                                                        ),
                                                                        color:
                                                                            isSelected
                                                                                ? Colors.white
                                                                                : color.onSurfaceVariant,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          account
                                                                              .name,
                                                                          style: textTheme.labelMedium?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                isSelected
                                                                                    ? Colors.white
                                                                                    : color.onSurfaceVariant,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              2,
                                                                        ),
                                                                        Text(
                                                                          ctxt.formatCurrencyWithSign(2, balance),
                                                                          style: textTheme.labelLarge?.copyWith(
                                                                            color:
                                                                                isSelected
                                                                                    ? Colors.white.withValues(
                                                                                      alpha:
                                                                                          0.8,
                                                                                    )
                                                                                    : color.onSurfaceVariant.withValues(
                                                                                      alpha:
                                                                                          0.7,
                                                                                    ),
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                          loading: () => SizedBox(height: 120),
                                          error: (_, __) => SizedBox(),
                                        ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Select Category',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 16),
                              Consumer(
                                builder:
                                    (context, ref, _) => ref
                                        .watch(categoryListProvider)
                                        .when(
                                          data:
                                              (categories) => SizedBox(
                                                height: 120,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      categories.length + 1,
                                                  separatorBuilder:
                                                      (_, __) =>
                                                          SizedBox(width: 12),
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    if (index <
                                                        categories.length) {
                                                      final cat =
                                                          categories[index];
                                                      final isSelected =
                                                          selectedCategory
                                                              ?.id ==
                                                          cat.id;
                                                      return GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.mediumImpact();
                                                          setState(
                                                            () =>
                                                                selectedCategory =
                                                                    cat,
                                                          );
                                                        },
                                                        child: AnimatedContainer(
                                                          duration: Duration(
                                                            milliseconds: 200,
                                                          ),
                                                          width: 120,
                                                          margin:
                                                              EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  24,
                                                                ),
                                                            gradient:
                                                                isSelected
                                                                    ? LinearGradient(
                                                                      begin:
                                                                          Alignment
                                                                              .topLeft,
                                                                      end:
                                                                          Alignment
                                                                              .bottomRight,
                                                                      colors: [
                                                                        Color(
                                                                          cat.colorValue ??
                                                                              0xFF000000,
                                                                        ).withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                        Color(
                                                                          cat.colorValue ??
                                                                              0xFF000000,
                                                                        ),
                                                                      ],
                                                                    )
                                                                    : LinearGradient(
                                                                      begin:
                                                                          Alignment
                                                                              .topLeft,
                                                                      end:
                                                                          Alignment
                                                                              .bottomRight,
                                                                      colors: [
                                                                        color.surfaceContainerHighest.withValues(
                                                                          alpha:
                                                                              0.6,
                                                                        ),
                                                                        color.surfaceContainerHighest.withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                      ],
                                                                    ),
                                                            boxShadow:
                                                                isSelected
                                                                    ? [
                                                                      BoxShadow(
                                                                        color: Color(
                                                                          cat.colorValue ??
                                                                              0xFF000000,
                                                                        ).withValues(
                                                                          alpha:
                                                                              0.3,
                                                                        ),
                                                                        blurRadius:
                                                                            8,
                                                                        offset:
                                                                            Offset(
                                                                              0,
                                                                              4,
                                                                            ),
                                                                      ),
                                                                    ]
                                                                    : [],
                                                            border: Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  24,
                                                                ),
                                                            child: Stack(
                                                              children: [
                                                                if (isSelected)
                                                                  Positioned(
                                                                    right: -15,
                                                                    bottom: -15,
                                                                    child: Transform.rotate(
                                                                      angle:
                                                                          -0.2,
                                                                      child: Icon(
                                                                        IconHelper.iconFromName(
                                                                          cat.iconName ??
                                                                              'category',
                                                                        ),
                                                                        size:
                                                                            70,
                                                                        color: Colors.white.withValues(
                                                                          alpha:
                                                                              0.15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                        16,
                                                                      ),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.all(
                                                                              8,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              isSelected
                                                                                  ? Colors.white.withValues(
                                                                                    alpha:
                                                                                        0.2,
                                                                                  )
                                                                                  : color.surface,
                                                                          shape:
                                                                              BoxShape.circle,
                                                                        ),
                                                                        child: Icon(
                                                                          IconHelper.iconFromName(
                                                                            cat.iconName ??
                                                                                'category',
                                                                          ),
                                                                          color:
                                                                              isSelected
                                                                                  ? Colors.white
                                                                                  : color.onSurfaceVariant,
                                                                          size:
                                                                              20,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        cat.name,
                                                                        style: textTheme.labelMedium?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              isSelected
                                                                                  ? Colors.white
                                                                                  : color.onSurfaceVariant,
                                                                        ),
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.mediumImpact();
                                                          context.push(
                                                            '/add-category',
                                                          );
                                                        },
                                                        child: Container(
                                                          width: 80,
                                                          margin:
                                                              EdgeInsets.symmetric(
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  24,
                                                                ),
                                                            color: color
                                                                .surfaceContainerHighest
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            border: Border.all(
                                                              color: color
                                                                  .outline
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons.add,
                                                                color:
                                                                    color
                                                                        .onSurfaceVariant,
                                                              ),
                                                              SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                ctxt.common_addLabel,
                                                                style: textTheme
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                      color:
                                                                          color
                                                                              .onSurfaceVariant,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                          loading: () => SizedBox(height: 120),
                                          error: (_, __) => SizedBox(),
                                        ),
                              ),
                              SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: color.primary,
                                    foregroundColor: color.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    if (selectedCategory != null &&
                                        selectedAccount != null) {
                                      _approveTransaction(
                                        pendingTx,
                                        selectedAccount!,
                                        selectedCategory!,
                                        ctxt,
                                      );
                                    } else {
                                      SnackbarService.warning(
                                        'Select Account & Category',
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'APPROVE TRANSACTION',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: color.surface,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder:
                    (context, setModalState) => Container(
                      decoration: BoxDecoration(
                        color: color.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: color.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      padding: EdgeInsets.all(16),
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
                          SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Search by sender',
                              prefixIcon: Icon(
                                Icons.search,
                                color: color.primary,
                              ),
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
                            onChanged:
                                (value) =>
                                    setModalState(() => _searchQuery = value),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Type',
                            style: textTheme.titleMedium?.copyWith(
                              color: color.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          SegmentedButton<bool?>(
                            segments: [
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
                              setModalState(
                                () => _filterIncome = selected.first,
                              );
                            },
                          ),
                          SizedBox(height: 16),
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
                                    if (date != null)
                                      setModalState(() => _startDate = date);
                                  },
                                  icon: Icon(Icons.calendar_today),
                                  label: Text(
                                    _startDate == null
                                        ? 'Start Date'
                                        : DateFormat(
                                          'dd MMM',
                                        ).format(_startDate!),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null)
                                      setModalState(() => _endDate = date);
                                  },
                                  icon: Icon(Icons.calendar_today),
                                  label: Text(
                                    _endDate == null
                                        ? 'End Date'
                                        : DateFormat(
                                          'dd MMM',
                                        ).format(_endDate!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
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
                                  child: Text('Clear'),
                                ),
                              ),
                              SizedBox(width: 8),
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
                                  child: Text('Apply'),
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
