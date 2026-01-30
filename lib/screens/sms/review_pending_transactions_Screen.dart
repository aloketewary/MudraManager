import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category, CategoryType;
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
  bool _isCategoryExpanded = false;
  Map<int, double> _balanceMap = {};
  bool _initialized = false;
  bool _isAutoProcessing = false;
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  bool _isDisposed = false;

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
        if (_isDisposed) return;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.pendingTranx_reviewPendingTransactionsScreenTitle),
        actions: [
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
              tooltip: "Auto Add",
              onPressed: _autoProcessTransactions,
              icon: Icon(Icons.auto_awesome),
            ),
            IconButton(
              tooltip: "Clear All",
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
          if (pendingTrans.isEmpty) {
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
                    'No pending transactions',
                    style: textTheme.titleLarge?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          _controllers = List.generate(
            pendingTrans.length,
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
            itemCount: pendingTrans.length,
            itemBuilder: (context, index) {
              final tx = pendingTrans[index];
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
                          title: "Delete Transaction?",
                          message: "This action cannot be undone.",
                        );
                      } else if (direction == DismissDirection.startToEnd) {
                        HapticFeedback.lightImpact();
                        _showApproveBottomSheet(context, tx!);
                        return false;
                      }
                      return false;
                    },

                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _removePendingTransaction(tx!, false);
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
                            'Approve',
                            style: TextStyle(
                              color: color.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
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
                            'Delete',
                            style: TextStyle(
                              color: color.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.lightImpact();
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
                                    color:
                                        isIncome ? color.primary : color.error,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    color:
                                        isIncome ? color.primary : color.error,
                                  ),
                                ),
                              ],
                            ),
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
  ) async {
    final confirm = await DialogUtils.showDeleteConfirmation(
      context,
      title: "Delete Transaction?",
      message: "This action cannot be undone.",
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
  ) async {
    final txn = Transaction.create(
      date: pendingTx.date,
      amount: pendingTx.amount ?? 0.0,
      isExpense: pendingTx.isIncome == false,
      description: "Imported from SMS",
    );
    txn.account.value = account;
    txn.category.value = category;
    await ref.read(transactionProvider).addTransaction(txn);
    ref.invalidate(transactionProvider);
    _removePendingTransaction(pendingTx, true);
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

    // Pre-select suggested category
    final categories = await ref.read(categoryListProvider.future);
    final relevantCategories = categories.where(
      (c) =>
          (pendingTx.isIncome == true && c.categoryType == CategoryType.income) ||
          (pendingTx.isIncome == false && c.categoryType == CategoryType.expense),
    ).toList();
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
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: StatefulBuilder(
              builder:
                  (context, setState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Details',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pendingTx.body,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Select Account",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Consumer(
                          builder:
                              (context, ref, _) => ref
                                  .watch(accountsProvider)
                                  .when(
                                    data:
                                        (accounts) => SizedBox(
                                          height: 140,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: accounts.length,
                                            itemBuilder: (context, index) {
                                              var account = accounts[index];
                                              var balance =
                                                  _balanceMap[account.id] ?? 0;
                                              return AccountDisplayCard(
                                                title: account.name,
                                                amount:
                                                    "₹${balance.abs().toStringAsFixed(2)}",
                                                accountType:
                                                    account.accountType,
                                                startColor: color.onSecondary,
                                                endColor: Color(
                                                  account.colorValue ??
                                                      0xFF000000,
                                                ),
                                                isSelected:
                                                    selectedAccount?.id ==
                                                    account.id,
                                                accountNumber:
                                                    account.accountNumber,
                                                callbackAction:
                                                    () => setState(
                                                      () =>
                                                          selectedAccount =
                                                              account,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                    loading:
                                        () => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    error: (_, __) => Text('Error'),
                                  ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select Category",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed:
                                  () => setState(
                                    () =>
                                        _isCategoryExpanded =
                                            !_isCategoryExpanded,
                                  ),
                              icon: Icon(
                                _isCategoryExpanded
                                    ? Icons.close_fullscreen
                                    : Icons.open_in_full,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: _isCategoryExpanded ? 200 : 90,
                          child: Consumer(
                            builder:
                                (context, ref, _) => ref
                                    .watch(categoryListProvider)
                                    .when(
                                      data:
                                          (categories) =>
                                              _isCategoryExpanded
                                                  ? Wrap(
                                                    spacing: 12,
                                                    runSpacing: 12,
                                                    children: [
                                                      ...categories.map(
                                                        (cat) => SizedBox(
                                                          height: 60,
                                                          child: CategoryCard(
                                                            label: cat.name,
                                                            color: Color(
                                                              cat.colorValue ??
                                                                  0xFF000000,
                                                            ),
                                                            icon: IconHelper.iconFromName(
                                                              cat.iconName ??
                                                                  'category',
                                                            ),
                                                            isSelected:
                                                                selectedCategory
                                                                    ?.id ==
                                                                cat.id,
                                                            callbackAction:
                                                                () => setState(
                                                                  () =>
                                                                      selectedCategory =
                                                                          cat,
                                                                ),
                                                            isUnderWrap: true,
                                                          ),
                                                        ),
                                                      ),
                                                      CategoryCard(
                                                        label: "Add",
                                                        color: color.secondary,
                                                        icon: Icons.add,
                                                        isSelected: false,
                                                        isNewCard: true,
                                                        callbackAction:
                                                            () => context.push('/add-category'),
                                                        isUnderWrap: true,
                                                      ),
                                                    ],
                                                  )
                                                  : ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        categories.length + 1,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      if (index <
                                                          categories.length) {
                                                        var cat =
                                                            categories[index];
                                                        return CategoryCard(
                                                          label: cat.name,
                                                          color: Color(
                                                            cat.colorValue ??
                                                                0xFF000000,
                                                          ),
                                                          icon:
                                                              IconHelper.iconFromName(
                                                                cat.iconName ??
                                                                    'category',
                                                              ),
                                                          isSelected:
                                                              selectedCategory
                                                                  ?.id ==
                                                              cat.id,
                                                          callbackAction:
                                                              () => setState(
                                                                () =>
                                                                    selectedCategory =
                                                                        cat,
                                                              ),
                                                        );
                                                      }
                                                      return CategoryCard(
                                                        label: "Add",
                                                        color: color.secondary,
                                                        icon: Icons.add,
                                                        isSelected: false,
                                                        isNewCard: true,
                                                        callbackAction:
                                                            () => context.push('/add-category'),
                                                      );
                                                    },
                                                  ),
                                      loading:
                                          () => Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      error: (_, __) => Text('Error'),
                                    ),
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: () {
                              if (selectedCategory != null &&
                                  selectedAccount != null) {
                                _approveTransaction(
                                  pendingTx,
                                  selectedAccount!,
                                  selectedCategory!,
                                );
                              } else {
                                SnackbarService.warning('Select Account & Category');
                              }
                            },
                            icon: Icon(Icons.check_circle),
                            label: Text(
                              'APPROVE TRANSACTION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }
}
