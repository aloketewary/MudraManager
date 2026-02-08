import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/providers/trip_provider.dart';
import 'package:mudra_manager/screens/reusable/month_tab_selector.dart'
    show MonthTabSelector;
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/screens/reusable/skeleton_loader.dart';
import 'package:mudra_manager/screens/transaction/transaction_card.dart';
import 'package:mudra_manager/screens/transaction/transaction_group.dart';
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/components/adaptive_text.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const TransactionListScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      TransactionListScreenState();
}

class TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with TickerProviderStateMixin {
  String _filter = 'all';
  double rightBoxWidthFactor = 0.3;
  double leftBoxWidthFactor = 0.3;
  double middleBoxWidthFactor = 0.3;
  double tiltAngleDegrees = 20.0;
  double tiltExpenseAngleDegrees = 20.0;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  int? _selectedCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _onFabPressed() {
    context.push('/add-transaction');
  }

  List<DateTime> generateCircularMonths({int count = 12}) {
    final now = DateTime.now();
    return List.generate(
      count * 2 + 1,
      (i) => DateTime(now.year, now.month - count + i),
    );
  }

  String formatDateHeader(DateTime date, String locale) {
    final ctxt = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    if (dateOnly == todayOnly) return ctxt.transaction_listViewGroupTodayLabel;
    if (dateOnly == yesterdayOnly)
      return ctxt.transaction_listViewGroupYesterdayLabel;

    return DateFormat.yMMMMd(locale).format(date); // e.g., May 14, 2025
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return widget.showAppBar
        ? Scaffold(
          appBar: AppBar(
            title: Text(ctxt.transaction_list_cash_flow_screen_title),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showFilterBottomSheet(context);
                },
                icon: Icon(Icons.filter_list),
              ),
            ],
          ),
          body: Hero(tag: 'cashFlowPage', child: _buildMainComponent()),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), // slower and smoother
            switchInCurve: Curves.easeInOutBack,
            switchOutCurve: Curves.easeIn,
            child: FloatingActionButton.extended(
              key: const ValueKey('extended'),
              heroTag: 'addTransactionHero',
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: AdaptiveText(
                ctxt.dashboard_add_transaction_text,
                style: textTheme.labelLarge,
                maxLines: 1,
              ),
            ),
          ),
        )
        : Hero(tag: 'cashFlowPage', child: _buildMainComponent());
  }

  Widget _buildMainComponent() {
    final sectionedAsync = ref.watch(
      sectionedTransactionsProvider((month: _selectedDate, type: _filter)),
    );
    final pendingTxnCountService = ref.watch(pendingTxnCountProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Material(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search, color: color.primary),
                suffixIcon:
                    _searchQuery.isNotEmpty ||
                            _selectedCategoryId != null ||
                            _filterStartDate != null
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategoryId = null;
                              _filterStartDate = null;
                              _filterEndDate = null;
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: color.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        if (_selectedCategoryId != null || _filterStartDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                if (_selectedCategoryId != null)
                  Chip(
                    label: Text('Category Filter'),
                    onDeleted: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedCategoryId = null);
                    },
                  ),
                if (_filterStartDate != null)
                  Chip(
                    label: Text('Date Filter'),
                    onDeleted: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        pendingTxnCountService.when(
          data: (count) {
            if (count > 0) {
              return MaterialBanner(
                backgroundColor: color.primaryContainer,
                content: Text(
                  ctxt.transaction_list_pending_transaction_message_text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: color.onPrimaryContainer,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/pending-transactions');
                    },
                    child: Text(
                      ctxt.transaction_listPendingTransactionMessageActionLabel
                          .toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: color.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        MonthTabSelector(
          onMonthSelected: (date) {
            if (!mounted) return;
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        Expanded(
          child: sectionedAsync.when(
            data: (sectioned) {
              final filtered = _filterTransactions(sectioned);

              if (filtered.isEmpty) {
                return NoDataFound(
                  message:
                      _searchQuery.isNotEmpty ||
                              _selectedCategoryId != null ||
                              _filterStartDate != null
                          ? 'No matching transactions'
                          : ctxt.transaction_noTransactionFoundText,
                  iconData: Icons.receipt_long_outlined,
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  if (entry is TxHeader) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      child: Text(
                        formatDateHeader(
                          entry.group,
                          ctxt.localeName,
                        ).toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }

                  final transaction = (entry as TxItem).txn;
                  transaction.tags.load();
                  transaction.related.load();
                  final tags = transaction.tags.toList();

                  return FutureBuilder<String?>(
                    future: ref
                        .read(tripServiceProvider)
                        .getTripNameByTransactionId(transaction.id),
                    builder: (context, snapshot) {
                      return TransactionCard(
                        category: transaction.category.value,
                        description: transaction.description,
                        account: transaction.account.value,
                        amount: transaction.amount.toStringAsFixed(2),
                        date: transaction.date,
                        isExpense: transaction.isExpense,
                        isTransfer: transaction.isTransfer,
                        tags: tags,
                        related: transaction.related.value,
                        tripName: snapshot.data,
                        onEdit: () {
                          transaction.isTransfer
                              ? context.push(
                                '/transfer',
                                extra: {
                                  'amount': transaction.amount.toStringAsFixed(
                                    2,
                                  ),
                                  'note': transaction.description,
                                  'date': transaction.date,
                                  'fromAccount':
                                      transaction.related.value?.account.value,
                                  'toAccount': transaction.account.value,
                                  'fromId': transaction.related.value?.id,
                                  'toId': transaction.id,
                                },
                              )
                              : context.push(
                                '/add-transaction',
                                extra: {'transaction': transaction},
                              );
                        },
                        onRemove: () async {
                          final confirm =
                              await DialogUtils.showDeleteConfirmation(
                                context,
                                title: ctxt.transaction_deleteAlertTitleText,
                                message: ctxt.transaction_deleteAlertBodyText,
                                cancelText:
                                    ctxt.transaction_cancelButtonActionText,
                                deleteText:
                                    ctxt.transaction_deleteButtonActionText,
                              );

                          if (confirm == true) {
                            await ref
                                .read(tripServiceProvider)
                                .removeTransactionFromTrip(transaction.id);
                            if (transaction.isTransfer) {
                              await ref
                                  .read(transactionProvider)
                                  .deleteTransaction(
                                    transaction.related.value?.id ?? 0,
                                  );
                            }
                            await ref
                                .read(transactionProvider)
                                .deleteTransaction(transaction.id);
                            ref.invalidate(transactionProvider);
                            ref.invalidate(allTripsProvider);
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
            loading:
                () => ListView.builder(
                  itemCount: 5,
                  itemBuilder:
                      (context, index) => const TransactionCardSkeleton(),
                ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  List<TxListEntry> _filterTransactions(List<TxListEntry> sectioned) {
    if (_searchQuery.isEmpty &&
        _selectedCategoryId == null &&
        _filterStartDate == null) {
      return sectioned;
    }

    final filtered = <TxListEntry>[];
    DateTime? currentDate;

    for (var entry in sectioned) {
      if (entry is TxHeader) {
        currentDate = entry.group;
        continue;
      }

      final txItem = entry as TxItem;
      final tx = txItem.txn;

      bool matches = true;

      if (_searchQuery.isNotEmpty) {
        final desc = tx.description?.toLowerCase() ?? '';
        matches = matches && desc.contains(_searchQuery);
      }

      if (_selectedCategoryId != null) {
        matches = matches && tx.category.value?.id == _selectedCategoryId;
      }

      if (_filterStartDate != null && _filterEndDate != null) {
        matches =
            matches &&
            tx.date.isAfter(_filterStartDate!) &&
            tx.date.isBefore(_filterEndDate!);
      }

      if (matches) {
        if (currentDate != null &&
            (filtered.isEmpty ||
                filtered.last is! TxHeader ||
                (filtered.last as TxHeader).group != currentDate)) {
          filtered.add(TxHeader(currentDate));
        }
        filtered.add(txItem);
      }
    }

    return filtered;
  }

  void showFilterBottomSheet(BuildContext context) async {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isar = await ref.read(isarServiceProvider).getInstance();
    final categories = await isar.categorys.where().findAll();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Filter Options',
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Transaction Type',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    value: 'all',
                    groupValue: _filter,
                    title: Text(ctxt.transaction_list_filter_all.toUpperCase()),
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      setState(() => _filter = value!);
                      setModalState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    value: 'income',
                    groupValue: _filter,
                    title: Text(
                      ctxt.transaction_list_filter_income.toUpperCase(),
                    ),
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      setState(() => _filter = value!);
                      setModalState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    value: 'expense',
                    groupValue: _filter,
                    title: Text(
                      ctxt.transaction_list_filter_expense.toUpperCase(),
                    ),
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      setState(() => _filter = value!);
                      setModalState(() {});
                    },
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Category',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...categories.map(
                    (cat) => RadioListTile<int?>(
                      value: cat.id,
                      groupValue: _selectedCategoryId,
                      title: Row(
                        children: [
                          Icon(
                            IconHelper.getIconData(cat.iconName),
                            size: 20,
                            color: Color(cat.colorValue ?? 0xFF9E9E9E),
                          ),
                          SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                      onChanged: (value) {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedCategoryId = value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  RadioListTile<int?>(
                    value: null,
                    groupValue: _selectedCategoryId,
                    title: Text('All Categories'),
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedCategoryId = null);
                      setModalState(() {});
                    },
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('APPLY FILTERS'),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
