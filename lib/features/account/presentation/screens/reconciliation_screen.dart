import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/core/db/models/reconciliation_status.dart';
import 'package:mudra_manager/features/account/presentation/screens/missing_transaction_screen.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  final Account account;

  const ReconciliationScreen({super.key, required this.account});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final isar = await ref.read(isarServiceProvider).getInstance();
    return isar.transactions
        .filter()
        .account((q) => q.idEqualTo(widget.account.id))
        .sortByDateDesc()
        .findAll();
  }

  void _loadTransactions() {
    setState(() {
      _transactionsFuture = _fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGuestMode = ref.watch(guestModeProvider);
    final spacing = ref.watch(spacingProvider);
    final reconciliationService = ref.watch(reconciliationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reconcile ${widget.account.name}'),
        actions: [
          IconButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MissingTransactionScreen(account: widget.account),
                ),
              );
              if (result == true) _loadTransactions();
            },
            icon: const Icon(Icons.add),
            tooltip: 'Missing Transaction',
          ),
        ],
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions to reconcile'));
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontal,
              spacing.cardVertical,
              spacing.cardHorizontal,
              80,
            ),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _TransactionReconcileCard(
                transaction: tx,
                isGuestMode: isGuestMode,
                spacing: spacing,
                onVerify: () async {
                  await reconciliationService.verifyTransaction(tx.id);
                  _loadTransactions();
                },
                onMarkDiscrepancy: (bankAmount, notes) async {
                  await reconciliationService.markDiscrepancy(
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

class _TransactionReconcileCard extends ConsumerStatefulWidget {
  final Transaction transaction;
  final bool isGuestMode;
  final AppSpacing spacing;
  final VoidCallback onVerify;
  final Function(double, String) onMarkDiscrepancy;

  const _TransactionReconcileCard({
    required this.transaction,
    required this.isGuestMode,
    required this.spacing,
    required this.onVerify,
    required this.onMarkDiscrepancy,
  });

  @override
  ConsumerState<_TransactionReconcileCard> createState() =>
      _TransactionReconcileCardState();
}

class _TransactionReconcileCardState
    extends ConsumerState<_TransactionReconcileCard> {
  late TextEditingController _bankAmountController;
  late TextEditingController _notesController;
  bool _showDiscrepancyForm = false;
  ReconciliationStatus? _status;

  @override
  void initState() {
    super.initState();
    _bankAmountController = TextEditingController();
    _notesController = TextEditingController();
    _loadStatus();
  }

  void _loadStatus() async {
    final status = await ref
        .read(reconciliationServiceProvider)
        .getReconciliationStatus(widget.transaction.id);
    if (mounted) setState(() => _status = status);
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
    final spacing = widget.spacing;
    final displayAmount = GuestModeUtil.applyGuestMode(
      widget.transaction.amount,
      widget.isGuestMode,
    );

    final statusColor = _status == null
        ? Colors.transparent
        : switch (_status!.state) {
            ReconciliationState.verified => const Color(0xFF4CAF50),
            ReconciliationState.discrepancy => const Color(0xFFF44336),
            ReconciliationState.unrecognized => color.tertiary,
            ReconciliationState.pending => color.onSurfaceVariant,
          };

    return Container(
      margin: EdgeInsets.only(bottom: spacing.elementGap + 4),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + description + amount
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (widget.transaction.isExpense
                                ? color.error
                                : color.primary)
                            .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(
                        widget.transaction.isExpense
                            ? LucideIcons.arrowUpRight
                            : LucideIcons.arrowDownLeft,
                        size: 18,
                        color: widget.transaction.isExpense
                            ? color.error
                            : color.primary,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.transaction.description ?? 'Transaction',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: spacing.cardVerticalMin / 2),
                          Text(
                            widget.transaction.date.toString().split('.')[0],
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CurrencyText(
                          amount: displayAmount,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.transaction.isExpense
                                ? color.error
                                : color.primary,
                          ),
                        ),
                        if (_status != null) ...[
                          SizedBox(height: spacing.cardVerticalMin),
                          _buildStatusBadge(color, textTheme, spacing),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: spacing.elementGap + 4),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: LucideIcons.circleCheck,
                        label: 'Verify',
                        chipColor: const Color(0xFF4CAF50),
                        surfaceColor: color.surfaceContainerLow,
                        textTheme: textTheme,
                        spacing: spacing,
                        onTap: widget.onVerify,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: _ActionChip(
                        icon: LucideIcons.triangleAlert,
                        label: 'Discrepancy',
                        chipColor: const Color(0xFFF44336),
                        surfaceColor: color.surfaceContainerLow,
                        textTheme: textTheme,
                        spacing: spacing,
                        onTap: () => setState(
                          () => _showDiscrepancyForm = !_showDiscrepancyForm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Discrepancy form
          if (_showDiscrepancyForm)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                spacing.cardInner,
                0,
                spacing.cardInner,
                spacing.cardInner,
              ),
              child: Column(
                children: [
                  Divider(
                    color: color.outlineVariant.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  SizedBox(height: spacing.elementGap + 4),
                  TextField(
                    controller: _bankAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Bank Amount',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: spacing.elementGap),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      hintText: 'Describe the discrepancy',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: spacing.elementGap),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final bankAmount = double.tryParse(
                          _bankAmountController.text,
                        );
                        if (bankAmount == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid bank amount'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
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
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final (label, badgeColor) = switch (_status!.state) {
      ReconciliationState.verified => ('✓ Verified', color.primary),
      ReconciliationState.discrepancy => ('⚠ Discrepancy', color.error),
      ReconciliationState.unrecognized => ('? Unrecognized', color.tertiary),
      ReconciliationState.pending => ('⏳ Pending', color.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.cardVerticalMin,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(spacing.radiusSmall / 2),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color chipColor;
  final Color surfaceColor;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.chipColor,
    required this.surfaceColor,
    required this.textTheme,
    required this.spacing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: chipColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing.elementGap + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: chipColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: chipColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
