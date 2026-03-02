import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  final Account account;

  const ReconciliationScreen({
    super.key,
    required this.account,
  });

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  late Future<List<Transaction>> _transactionsFuture;
  final Map<int, ReconciliationStatus?> _reconciliationMap = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    final isar = await IsarService.initIsar();
    _transactionsFuture = isar.transactions
        .filter()
        .account((q) => q.idEqualTo(widget.account.id))
        .sortByDateDesc()
        .findAll();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isGuestMode = ref.watch(guestModeProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reconcile ${widget.account.name}'),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No transactions to reconcile'),
            );
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _TransactionReconcileCard(
                transaction: tx,
                isGuestMode: isGuestMode,
                onVerify: () async {
                  await ReconciliationService.instance
                      .verifyTransaction(tx.id);
                  _loadTransactions();
                },
                onMarkDiscrepancy: (bankAmount, notes) async {
                  await ReconciliationService.instance.markDiscrepancy(
                    tx.id,
                    bankAmount,
                    notes: notes,
                  );
                  _loadTransactions();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TransactionReconcileCard extends StatefulWidget {
  final Transaction transaction;
  final bool isGuestMode;
  final VoidCallback onVerify;
  final Function(double, String) onMarkDiscrepancy;

  const _TransactionReconcileCard({
    required this.transaction,
    required this.isGuestMode,
    required this.onVerify,
    required this.onMarkDiscrepancy,
  });

  @override
  State<_TransactionReconcileCard> createState() =>
      _TransactionReconcileCardState();
}

class _TransactionReconcileCardState extends State<_TransactionReconcileCard> {
  late TextEditingController _bankAmountController;
  late TextEditingController _notesController;
  bool _showDiscrepancyForm = false;
  ReconciliationStatus? _status;

  @override
  void initState() {
    super.initState();
    _bankAmountController = TextEditingController();
    _notesController = TextEditingController();
    _displayAmount = GuestModeUtil.applyGuestMode(widget.transaction.amount, widget.isGuestMode);
    _loadStatus();
  }

  late double _displayAmount;

  void _loadStatus() async {
    final status = await ReconciliationService.instance
        .getReconciliationStatus(widget.transaction.id);
    setState(() => _status = status);
  }

  @override
  void dispose() {
    _bankAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transaction.description ?? 'Transaction',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.transaction.date.toString().split('.')[0],
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_displayAmount.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.transaction.isExpense
                            ? color.error
                            : color.primary,
                      ),
                    ),
                    if (_status != null) ...[const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _status!.state == ReconciliationState.verified
                              ? color.primary.withValues(alpha: 0.2)
                              : color.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _status!.state == ReconciliationState.verified
                              ? '✓ Verified'
                              : '⚠ Discrepancy',
                          style: textTheme.labelSmall?.copyWith(
                            color: _status!.state == ReconciliationState.verified
                                ? color.primary
                                : color.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: widget.onVerify,
                    child: const Text('✓ Verify'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _showDiscrepancyForm = !_showDiscrepancyForm);
                    },
                    child: const Text('⚠ Discrepancy'),
                  ),
                ),
              ],
            ),
            if (_showDiscrepancyForm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bankAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Bank Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Describe the discrepancy',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  final bankAmount =
                      double.tryParse(_bankAmountController.text) ?? 0;
                  widget.onMarkDiscrepancy(
                    bankAmount,
                    _notesController.text,
                  );
                  setState(() => _showDiscrepancyForm = false);
                  _bankAmountController.clear();
                  _notesController.clear();
                },
                child: const Text('Save Discrepancy'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
