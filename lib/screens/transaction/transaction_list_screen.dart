import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/reusable/month_tab_selector.dart'
    show MonthTabSelector;
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/screens/reusable/skeleton_loader.dart';
import 'package:mudra_manager/screens/sms/review_pending_transactions_Screen.dart'
    show ReviewPendingTransactionsScreen;
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart'
    show AddEditTransactionScreen;
import 'package:mudra_manager/screens/transaction/transaction_card.dart';
import 'package:mudra_manager/screens/transaction/transaction_group.dart';
import 'package:mudra_manager/screens/transaction/transfer_screen.dart';

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

  void _onFabPressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder:
            (_, animation, secondaryAnimation) => AddEditTransactionScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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
              label: Text(ctxt.dashboard_add_transaction_text),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPendingTransactionsScreen(),
                        ),
                      );
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
              if (sectioned.isEmpty) {
                return NoDataFound(
                  message: ctxt.transaction_noTransactionFoundText,
                  iconData: Icons.receipt_long_outlined,
                );
              }

              // OPTIMIZATION: Removed expensive animation controller recreation from build.
              // For a smoother experience, use standard ListView or a more stable animation pattern.
              return ListView.builder(
                itemCount: sectioned.length,
                itemBuilder: (context, index) {
                  return populateTransactionList(sectioned[index]);
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

  void showFilterBottomSheet(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                ctxt.transaction_filterCategoryText,
                style: textTheme.titleLarge?.copyWith(color: color.primary),
              ),
            ),
            RadioListTile<String>(
              value: 'all',
              groupValue: _filter,
              title: Text(
                ctxt.transaction_list_filter_all.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: _filter == 'all' ? color.primary : color.secondary,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'income',
              groupValue: _filter,
              title: Text(
                ctxt.transaction_list_filter_income.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: _filter == 'income' ? color.primary : color.secondary,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'expense',
              groupValue: _filter,
              title: Text(
                ctxt.transaction_list_filter_expense.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: _filter == 'expense' ? color.primary : color.secondary,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  populateTransactionList(TxListEntry entry) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    if (entry is TxHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          formatDateHeader(entry.group, ctxt.localeName).toUpperCase(),
          style: textTheme.labelMedium?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    } else {
      final transaction = (entry as TxItem).txn;
      transaction.tags.load();
      transaction.related.load();
      final tags = transaction.tags.toList();
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
        onEdit: () {
          transaction.isTransfer
              ? Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TransferScreen(
                        amount: transaction.amount.toStringAsFixed(2),
                        note: transaction.description,
                        date: transaction.date,
                        fromAccount: transaction.related.value?.account.value,
                        toAccount: transaction.account.value,
                        fromId: transaction.related.value?.id,
                        toId: transaction.id,
                      ),
                ),
              )
              : Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 300),
                  pageBuilder:
                      (_, animation, secondaryAnimation) =>
                          AddEditTransactionScreen(transaction: transaction),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
        },
        onRemove: () async {
          final confirm = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: color.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder:
                (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: color.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          Icons.delete_forever_rounded,
                          size: 48,
                          color: color.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ctxt.transaction_deleteAlertTitleText,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ctxt.transaction_deleteAlertBodyText,
                          style: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: color.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  ctxt.transaction_cancelButtonActionText
                                      .toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: color.error,
                                  foregroundColor: color.onError,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  ctxt.transaction_deleteButtonActionText
                                      .toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          );

          if (confirm == true) {
            if (transaction.isTransfer) {
              await ref
                  .read(transactionProvider)
                  .deleteTransaction(transaction.related.value?.id ?? 0);
            }
            await ref
                .read(transactionProvider)
                .deleteTransaction(transaction.id);
            ref.invalidate(transactionProvider); // refresh list
          }
        },
      );
    }
  }
}
