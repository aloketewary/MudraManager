import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  final Account account;

  const ReconciliationScreen({super.key, required this.account});

  @override
  ConsumerState<ReconciliationScreen> createState() =>
      _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  final _balanceController = TextEditingController();
  double? _calculatedBalance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCalculatedBalance();
  }

  Future<void> _loadCalculatedBalance() async {
    final balance = await ref
        .read(reconciliationServiceProvider)
        .getCalculatedBalance(widget.account.id);
    if (mounted) setState(() => _calculatedBalance = balance);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  double? get _enteredBalance => double.tryParse(_balanceController.text);

  double? get _difference {
    final entered = _enteredBalance;
    if (entered == null || _calculatedBalance == null) return null;
    return entered - _calculatedBalance!;
  }

  Future<void> _reconcile() async {
    final entered = _enteredBalance;
    if (entered == null) {
      SnackbarService.error(BuddyMessages.invalidAmount);
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(reconciliationServiceProvider);
      final adj = await service.reconcileBalance(
        account: widget.account,
        actualBalance: entered,
      );

      ref.invalidate(transactionProvider);
      ref.invalidate(accountsProvider);

      if (mounted) {
        if (adj.abs() < 0.01) {
          SnackbarService.success(BuddyMessages.txnAdded);
        } else {
          SnackbarService.success('Balance adjusted by ${adj > 0 ? "+" : ""}${adj.toStringAsFixed(2)}');
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        SnackbarService.error(BuddyMessages.genericError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final diff = _difference;

    return Scaffold(
      appBar: AppBar(title: Text('Reconcile ${widget.account.name}')),
      body: _calculatedBalance == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(spacing.cardInner + 8),
              children: [
                // Info card
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: color.primary, size: 20),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Text(
                          'Enter the current balance shown in your bank app or passbook. We\'ll adjust the difference automatically.',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sectionGap + 8),

                // Calculated balance
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(
                      color: color.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance in App',
                        style: textTheme.titleSmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      CurrencyText(
                        amount: _calculatedBalance!,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        compact: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sectionGap),

                // Actual balance input
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Actual Bank Balance',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.account_balance, size: 22),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: spacing.sectionGap),

                // Difference display
                if (diff != null)
                  Container(
                    padding: EdgeInsets.all(spacing.cardInner),
                    decoration: BoxDecoration(
                      color: diff.abs() < 0.01
                          ? color.primary.withValues(alpha: 0.1)
                          : color.errorContainer.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
                      border: Border.all(
                        color: diff.abs() < 0.01
                            ? color.primary.withValues(alpha: 0.4)
                            : color.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              diff.abs() < 0.01
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.arrowLeftRight,
                              size: 18,
                              color: diff.abs() < 0.01
                                  ? color.primary
                                  : color.error,
                            ),
                            SizedBox(width: spacing.elementGap),
                            Text(
                              diff.abs() < 0.01
                                  ? 'Balanced!'
                                  : 'Difference',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: diff.abs() < 0.01
                                    ? color.primary
                                    : color.error,
                              ),
                            ),
                          ],
                        ),
                        if (diff.abs() >= 0.01)
                          CurrencyText(
                            amount: diff.abs(),
                            showSign: true,
                            isExpense: diff < 0,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: diff > 0
                                  ? color.primary
                                  : color.error,
                            ),
                            compact: false,
                          ),
                      ],
                    ),
                  ),

                if (diff != null && diff.abs() >= 0.01) ...[
                  SizedBox(height: spacing.elementGap),
                  Text(
                    diff > 0
                        ? 'An income adjustment of ${diff.toStringAsFixed(2)} will be added.'
                        : 'An expense adjustment of ${diff.abs().toStringAsFixed(2)} will be added.',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: spacing.sectionGap + 16),

                // Reconcile button
                FilledButton.icon(
                  onPressed: _saving || _enteredBalance == null
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          _reconcile();
                        },
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.check),
                  label: Text(
                    diff != null && diff.abs() < 0.01
                        ? 'Confirm Balance'
                        : 'Adjust & Reconcile',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: spacing.cardInner),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(spacing.radiusMedium),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
    );
  }
}
