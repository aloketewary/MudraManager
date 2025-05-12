import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/pending_transaction.dart'
    show PendingTransaction;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
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
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;

class ReviewPendingTransactionsScreen extends ConsumerStatefulWidget {
  const ReviewPendingTransactionsScreen({super.key});

  @override
  ConsumerState<ReviewPendingTransactionsScreen> createState() =>
      _ReviewPendingTransactionsScreenState();
}

class _ReviewPendingTransactionsScreenState
    extends ConsumerState<ReviewPendingTransactionsScreen> {
  bool _isCategoryExpanded = false;
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final balanceMap =
          ref.watch(accountServiceProvider).getAccountBalanceMap();
      balanceMap.then(
        (val) => {
          setState(() {
            _balanceMap = val;
          }),
        },
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var pendingTransactionService = ref.watch(pendingTxnDataProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review Pending Transactions',
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: pendingTransactionService.when(
          data: (pendingTrans) {
            return ListView.builder(
              itemCount: pendingTrans.length,
              itemBuilder: (context, index) {
                final transaction = pendingTrans[index];
                return Card.outlined(
                  shadowColor: color.surface,
                  // color: color.primary,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(width: 1, color: color.primary),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.0),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        transaction?.sender ?? 'Unknown Sender',
                        style: textTheme.titleMedium?.copyWith(),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${transaction?.amount?.toStringAsFixed(2)}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEE, dd MMM yyyy',
                            ).format(transaction?.date ?? DateTime.now()),
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton.filled(
                              onPressed: () {
                                _removePendingTransaction(transaction!, false);
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: color.onPrimary,
                              ),
                            ),
                            IconButton.filled(
                              onPressed: () {
                                _showApproveBottomSheet(context, transaction!);
                              },
                              icon: Icon(
                                Icons.task_alt_outlined,
                                color: color.onPrimary,
                              ),
                            ),
                          ],
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
      ),
    );
  }

  void _removePendingTransaction(
    PendingTransaction pendingTx,
    bool isApproved,
  ) async {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Transaction?",
              style: textTheme.titleLarge?.copyWith(color: color.primary),
            ),
            content: Text(
              "This action cannot be undone.",
              style: textTheme.bodyLarge,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CommonButton(
                    onPressed: () => Navigator.pop(context, false),
                    text: "Cancel",
                    backGroundColor: color.secondary,
                    textColor: color.onSecondary,
                  ),
                  SizedBox(width: 8),
                  CommonButton(
                    onPressed: () => Navigator.pop(context, true),
                    text: "Delete",
                    backGroundColor: color.primary,
                    textColor: color.onPrimary,
                  ),
                ],
              ),
            ],
          ),
    );
    if (confirm == true) {
      await ref.read(pendingTxnServiceProvider).remove(pendingTx);
      ref.invalidate(pendingTxnServiceProvider);
      if (!isApproved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed ${pendingTx.sender}')));
      }
    } else {
      await ref.read(pendingTxnServiceProvider).remove(pendingTx);
      ref.invalidate(pendingTxnServiceProvider);
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
    txn.tags.clear();
    await ref.read(transactionProvider).addTransaction(txn);
    ref.invalidate(transactionProvider);
    _removePendingTransaction(pendingTx, true);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Approved ${pendingTx.sender}')));
  }

  void _showApproveBottomSheet(
    BuildContext context,
    PendingTransaction pendingTx,
  ) async {
    Account? selectedAccount;
    Category? selectedCategory;
    var accountsService = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Details',
                    style: textTheme.titleLarge?.copyWith(
                      color: color.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Transaction Message Body",
                    style: textTheme.titleMedium,
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      pendingTx.body,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Select Account",
                    style: textTheme.titleLarge?.copyWith(color: color.primary),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final accountsAsync = ref.watch(accountsProvider);
                      return accountsAsync.when(
                        data: (accounts) {
                          return SizedBox(
                            height: 180, // Adjust height as needed
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(16.0),
                              itemCount: accounts.length,
                              itemBuilder: (BuildContext context, int index) {
                                var account = accounts[index];
                                var totalBalance = _balanceMap[account.id];
                                var isNegative = (totalBalance ?? 0) < 0;
                                return AccountDisplayCard(
                                  title: account.name,
                                  amount:
                                      "${isNegative ? "-" : ""} ₹${totalBalance?.abs().toStringAsFixed(2)}",
                                  accountType: account.accountType,
                                  startColor: color.onSecondary,
                                  endColor: Color(
                                    account.colorValue ?? 0xFF000000,
                                  ),
                                  isSelected: selectedAccount?.id == account.id,
                                  accountNumber: account.accountNumber,
                                  callbackAction: () {
                                    setState(() => selectedAccount = account);
                                  },
                                );
                              },
                            ),
                          );
                        },
                        loading:
                            () => SizedBox(
                              width: 50,
                              child: const CircularProgressIndicator(),
                            ),
                        error: (err, _) => Text('Error loading accounts'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Category",
                        style: textTheme.titleLarge?.copyWith(
                          color: color.primary,
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () {
                          setState(() {
                            _isCategoryExpanded = !_isCategoryExpanded;
                          });
                        },
                        icon: Icon(
                          _isCategoryExpanded
                              ? Icons.close_fullscreen
                              : Icons.open_in_full_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: _isCategoryExpanded ? 200 : 90,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final categoriesAsync = ref.watch(categoryListProvider);
                        return categoriesAsync.when(
                          data: (categories) {
                            return SingleChildScrollView(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                child:
                                    _isCategoryExpanded
                                        ? AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: Wrap(
                                            key: const ValueKey('wrapView'),
                                            spacing: 16,
                                            runSpacing: 16,
                                            alignment:
                                                WrapAlignment.spaceEvenly,
                                            runAlignment:
                                                WrapAlignment.spaceEvenly,
                                            children: [
                                              ...categories.map((cat) {
                                                return SizedBox(
                                                  height: 60,
                                                  child: CategoryCard(
                                                    label: cat.name,
                                                    color: Color(
                                                      cat.colorValue ??
                                                          0xFF000000,
                                                    ),
                                                    icon:
                                                        IconHelper.iconFromName(
                                                          cat.iconName ??
                                                              Icons.category
                                                                  .toString(),
                                                        ),
                                                    isSelected:
                                                        selectedCategory?.id ==
                                                        cat.id,
                                                    callbackAction: () {
                                                      setState(
                                                        () =>
                                                            selectedCategory =
                                                                cat,
                                                      );
                                                    },
                                                    isUnderWrap: true,
                                                  ),
                                                );
                                              }),
                                              CategoryCard(
                                                label: "Add New \nCategory",
                                                color: color.secondary,
                                                icon: Icons.add,
                                                isSelected: false,
                                                isNewCard: true,
                                                callbackAction: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              AddEditCategoryScreen(),
                                                    ),
                                                  );
                                                },
                                                isUnderWrap: true,
                                              ),
                                            ],
                                          ),
                                        )
                                        : AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: SizedBox(
                                            key: const ValueKey('listView'),
                                            height: 90,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              itemCount: categories.length + 1,
                                              itemBuilder: (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                if (index < categories.length) {
                                                  var category =
                                                      categories[index];
                                                  return CategoryCard(
                                                    label: category.name,
                                                    color: Color(
                                                      category.colorValue ??
                                                          0xFF000000,
                                                    ),
                                                    icon:
                                                        IconHelper.iconFromName(
                                                          category.iconName ??
                                                              Icons.category
                                                                  .toString(),
                                                        ),
                                                    isSelected:
                                                        selectedCategory?.id ==
                                                        category.id,
                                                    callbackAction: () {
                                                      setState(
                                                        () =>
                                                            selectedCategory =
                                                                category,
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return CategoryCard(
                                                    label: "Add New \nCategory",
                                                    color: color.secondary,
                                                    icon: Icons.add,
                                                    isSelected: false,
                                                    isNewCard: true,
                                                    callbackAction: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  AddEditCategoryScreen(),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                              ),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Text('Error loading categories'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommonButton(
                    text: 'Approve Transaction',
                    backGroundColor: color.primary,
                    textColor: color.onPrimary,
                    onPressed: () {
                      if (selectedCategory?.id != null &&
                          selectedAccount?.id != null) {
                        _approveTransaction(
                          pendingTx,
                          selectedAccount!,
                          selectedCategory!,
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Select Account and Category'),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
