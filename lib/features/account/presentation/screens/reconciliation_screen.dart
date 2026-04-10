import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
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
          final sign = adj > 0 ? '+' : '';
          SnackbarService.success(
            'Balance adjusted by $sign${formatCurrency(adj, code: widget.account.currencyCode, decimals: 2)}',
          );
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
    final ctxt = AppLocalizations.of(context)!;
    final diff = _difference;

    return Scaffold(
      appBar: AppBar(
        title: Text('${ctxt.reconcile_title} ${widget.account.name}'),
        actions: [
          TextButton(
            onPressed: _saving || _enteredBalance == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _reconcile();
                  },
            child: _saving
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color.primary),
                  )
                : Text(
                    diff != null && diff.abs() < 0.01 ? ctxt.common_confirm : ctxt.reconcile_title,
                    style: textTheme.titleSmall?.copyWith(
                      color: _enteredBalance != null ? color.primary : color.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: _calculatedBalance == null
          ? ListView(children: List.generate(3, (_) => const DashboardCardSkeleton()))
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // Info card
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: color.primary, size: 20),
                      SizedBox(width: spacing.elementGap),
                      Expanded(
                        child: Text(
                          ctxt.reconcile_info,
                          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sectionGap),

                // Calculated balance
                Container(
                  padding: EdgeInsets.all(spacing.cardInner),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ctxt.reconcile_balanceInApp, style: textTheme.titleSmall?.copyWith(color: color.onSurfaceVariant)),
                      CurrencyText(
                        amount: _calculatedBalance!,
                        currencyCode: widget.account.currencyCode,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        compact: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sectionGap),

                // Actual balance input
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: ctxt.reconcile_actualBalance,
                    hintText: '0.00',
                    prefixIcon: Icon(LucideIcons.landmark, size: 22, color: color.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(spacing.radiusMedium)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      borderSide: BorderSide(color: color.primary, width: 2),
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
                          ? FinanceColors.statusGood.withValues(alpha: 0.08)
                          : color.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      border: Border.all(
                        color: diff.abs() < 0.01
                            ? FinanceColors.statusGood.withValues(alpha: 0.3)
                            : color.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              diff.abs() < 0.01 ? LucideIcons.circleCheck : LucideIcons.arrowLeftRight,
                              size: 18,
                              color: diff.abs() < 0.01 ? FinanceColors.statusGood : color.error,
                            ),
                            SizedBox(width: spacing.elementGap),
                            Text(
                              diff.abs() < 0.01 ? ctxt.reconcile_balanced : ctxt.reconcile_difference,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: diff.abs() < 0.01 ? FinanceColors.statusGood : color.error,
                              ),
                            ),
                          ],
                        ),
                        if (diff.abs() >= 0.01)
                          CurrencyText(
                            amount: diff.abs(),
                            currencyCode: widget.account.currencyCode,
                            showSign: true,
                            isExpense: diff < 0,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: diff > 0 ? FinanceColors.statusGood : color.error,
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
                        ? ctxt.reconcile_incomeAdjustment(formatCurrency(diff, code: widget.account.currencyCode, decimals: 2))
                        : ctxt.reconcile_expenseAdjustment(formatCurrency(diff.abs(), code: widget.account.currencyCode, decimals: 2)),
                    style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
    );
  }
}
