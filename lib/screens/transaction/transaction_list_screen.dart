import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/providers/pending_transaction_prodiver.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/screens/sms/review_pending_transactions_Screen.dart'
    show ReviewPendingTransactionsScreen;
import 'package:mudra_manager/screens/transaction/add_edit_transaction_screen.dart'
    show AddEditTransactionScreen;
import 'package:mudra_manager/screens/transaction/transaction_card.dart';
import 'package:mudra_manager/screens/transaction/transaction_group.dart';
import 'package:mudra_manager/util/date_group.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const TransactionListScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _filter = 'all';
  double rightBoxWidthFactor = 0.3;
  double leftBoxWidthFactor = 0.3;
  double middleBoxWidthFactor = 0.3;
  double tiltAngleDegrees = 20.0;
  double tiltExpenseAngleDegrees = 20.0;

  void _onFabPressed() {
    // Navigate to Add Transaction screen or open bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return widget.showAppBar
        ? Scaffold(
          appBar: AppBar(
            title: Text(
              'Transactions',
              style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
            ),
          ),
          body: _buildMainComponent(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), // slower and smoother
            switchInCurve: Curves.easeInOutBack,
            switchOutCurve: Curves.easeIn,
            child: FloatingActionButton.extended(
              key: const ValueKey('extended'),
              // backgroundColor: Theme.of(context).colorScheme.secondary,
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: const Text("Add Transaction"),
            ),
          ),
        )
        : _buildMainComponent();
  }

  Widget _buildMainComponent() {
    final transactionsAsync = ref.watch(filteredTransactionProvider(_filter));
    final pendingTxnCountService = ref.watch(pendingTxnCountProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        pendingTxnCountService.when(
          data: (count) {
            if (count > 0) {
              return MaterialBanner(
                backgroundColor: color.primaryContainer,
                content: Text(
                  "⚡ New transactions found! Review now",
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
                      "Review".toUpperCase(),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        _buildFilterChips(),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return NoDataFound(
                  message: 'No transactions found.',
                  // imagePath: 'assets/icons/512/transaction.png',
                  iconData: Icons.receipt_long_outlined,
                );
              }
              final sectioned = buildSectionedList(transactions);
              return ListView.builder(
                itemCount: sectioned.length,
                itemBuilder: (context, index) {
                  var entry = sectioned[index];
                  if (entry is TxHeader) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Text(
                        entry.group.label.toUpperCase(),
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddEditTransactionScreen(
                                  transaction: transaction,
                                ),
                          ),
                        );
                      },
                      onRemove: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text("Delete Transaction?"),
                                content: Text("This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
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
                          ref.invalidate(transactionProvider); // refresh list
                        }
                      },
                    );
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tiltAngleRadians = math.pi * tiltAngleDegrees / 180;
    final tiltExpenseAngleRadians = math.pi * tiltExpenseAngleDegrees / 180;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: (leftBoxWidthFactor * 100).toInt(),
            child: SizedBox(
              // width: MediaQuery.of(context).size.width / 3,
              child: GestureDetector(
                onTap: () => {setState(() => _filter = 'all')},
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color:
                        _filter == 'all' ? color.primary : Colors.transparent,
                    // Light background color
                    border: Border.all(color: color.primary), // Subtle border
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        // backgroundColor: Colors.lightBlueAccent,
                        child: Icon(
                          Icons.compare_arrows,
                          // color: Colors.black,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          "ALL".toUpperCase(),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                _filter == 'all'
                                    ? color.onPrimary
                                    : color.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (middleBoxWidthFactor * 100).toInt(),
            child: SizedBox(
              // width: MediaQuery.of(context).size.width / 3,
              child: GestureDetector(
                onTap: () => {setState(() => _filter = 'income')},
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color:
                        _filter == 'income'
                            ? color.primary
                            : Colors.transparent,
                    border: Border.all(color: color.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        // backgroundColor: Colors.greenAccent,
                        child: Transform.rotate(
                          angle: tiltAngleRadians,
                          child: Icon(
                            Icons.arrow_downward,
                            // color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          "INCOME".toUpperCase(),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                _filter == 'income'
                                    ? color.onPrimary
                                    : color.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (rightBoxWidthFactor * 100).toInt(),
            child: SizedBox(
              // width: MediaQuery.of(context).size.width / 3,
              child: GestureDetector(
                onTap: () => {setState(() => _filter = 'expense')},
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: _filter == 'expense' ? color.primary : Colors.transparent,
                    // Light background color
                    border: Border.all(color: color.primary), // Subtle border
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        // backgroundColor: Colors.redAccent,
                        child: Transform.rotate(
                          angle: tiltExpenseAngleRadians,
                          child: Icon(
                            Icons.arrow_upward,
                            // color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          "EXPENSE".toUpperCase(),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                _filter == 'expense'
                                    ? color.onPrimary
                                    : color.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
