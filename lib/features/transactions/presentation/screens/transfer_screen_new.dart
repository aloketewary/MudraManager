import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/db/models/sms_activity.dart';
import 'package:mudra_manager/features/sms/data/sms_activity_service.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_query_provider.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class TransferScreenNew extends ConsumerStatefulWidget {
  final String? initialAmount;
  final String? initialNote;
  final DateTime? initialDate;
  final Account? initialFromAccount;
  final Account? initialToAccount;
  final int? editFromId;
  final int? editToId;
  final SmsActivity? smsActivity;

  const TransferScreenNew({
    super.key,
    this.initialAmount,
    this.initialNote,
    this.initialDate,
    this.initialFromAccount,
    this.initialToAccount,
    this.editFromId,
    this.editToId,
    this.smsActivity,
  });

  @override
  ConsumerState<TransferScreenNew> createState() => _TransferScreenNewState();
}

class _TransferScreenNewState extends ConsumerState<TransferScreenNew>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  bool get _isEditing => widget.editFromId != null && widget.editToId != null;

  Account? _fromAccount;
  Account? _toAccount;
  DateTime _date = DateTime.now();
  bool _saving = false;
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  late AnimationController _flowController;
  bool _flowControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // ── Pre-fill for edit mode ──
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!;
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    if (widget.initialDate != null) {
      _date = widget.initialDate!;
    }
    _fromAccount = widget.initialFromAccount;
    _toAccount = widget.initialToAccount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize flow controller with reduced motion detection
    if (!_flowControllerInitialized) {
      _flowControllerInitialized = true;
      final isReducedMotion = MediaQuery.of(context).disableAnimations;
      _flowController.duration = isReducedMotion
          ? const Duration(milliseconds: 2000)
          : const Duration(milliseconds: 1500);
      _flowController.repeat();
    }

    // Load account balances
    if (!_initialized) {
      _initialized = true;
      ref.read(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) setState(() => _balanceMap = val);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _flowController.dispose();
    super.dispose();
  }

  void _swapAccounts() {
    if (_fromAccount == null && _toAccount == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
    });
  }

  bool get _canTransfer =>
      !_saving &&
      _fromAccount != null &&
      _toAccount != null &&
      _amountController.text.isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) > 0;

  bool get _isCrossCurrency {
    if (_fromAccount == null || _toAccount == null) return false;
    final fromCur = _fromAccount!.currencyCode;
    final toCur = _toAccount!.currencyCode;
    return fromCur != toCur;
  }

  Future<void> _executeTransfer(AppSpacing spacing) async {
    if (!_canTransfer) return;
    setState(() => _saving = true);

    try {
      HapticFeedback.heavyImpact();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
      if (amount <= 0) {
        setState(() => _saving = false);
        return;
      }
      final fromCur = _fromAccount!.currencyCode;
      final toCur = _toAccount!.currencyCode;

      // For cross-currency: convert amount to destination currency
      double creditAmount = amount;
      if (_isCrossCurrency) {
        final service = await ref.read(currencyServiceProvider.future);
        final result = await service.convert(
            amount, fromCur ?? BaseCurrency.code, toCur ?? BaseCurrency.code,);
        if (result != null) {
          creditAmount = result.converted;
        }
      }

      await ref.read(transactionProvider).transfer(
            from: _fromAccount!,
            to: _toAccount!,
            amount: amount,
            creditAmount: creditAmount,
            date: _date,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            fromId: widget.editFromId,
            toId: widget.editToId,
          );

      await WidgetService.updateWidget(ref);

      // Mark SMS activity as approved if this came from SMS
      if (widget.smsActivity != null) {
        await SmsActivityService.instance.markTransferApproved(
          widget.smsActivity!,
        );
      }

      if (context.mounted) {
        ref.invalidate(transactionProvider);
        ref.invalidate(accountServiceProvider);
        ref.invalidate(transactionQueryProvider);

        SnackbarService.success(
          _isEditing ? 'Transfer updated' : 'Transfer completed',
          spacing,
        );

        context.pop(true); // return true so list screen knows to refresh
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isGuestMode = ref.watch(guestModeProvider);

    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: _isEditing
            ? ctxt.transaction_editTransactionTitle
            : ctxt.transfer_screenTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.pop();
        },
      ),
      actions: ScreenActions.build(
        trailing: ScreenTextAction(
          id: 'transfer',
          label: _isEditing ? ctxt.common_update : ctxt.common_done,
          onTap: _canTransfer ? () => _executeTransfer(spacing) : null,
          isLoading: _saving,
        ),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: NoDataFound(
                  message: BuddyMessages.noAccounts,
                  iconData: LucideIcons.wallet,),
            );
          }

          if (_fromAccount == null && accounts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _fromAccount = accounts.first);
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.cardHorizontal,
                    vertical: spacing.cardVertical,
                  ),
                  children: [
                    // ── AMOUNT ──
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.cardHorizontal,
                        vertical: spacing.cardVertical,
                      ),
                      decoration: BoxDecoration(
                        color: color.primaryContainer.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _amountController,
                            focusNode: _amountFocus,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: color.primary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color.primary.withValues(alpha: 0.2),
                              ),
                              prefix: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CurrencyBadge(
                                  code: BaseCurrency.code,
                                  size: 28,
                                  color: color.primary.withValues(alpha: 0.6),
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: spacing.cardVerticalMax,
                              ),
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          // Quick amounts
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: spacing.elementGap),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer(
                                  builder: (context, ref, _) {
                                    final amounts =
                                        ref.watch(quickAmountsProvider);
                                    final chips = amounts.value ??
                                        [100, 500, 1000, 2000, 5000];
                                    final currentAmount = double.tryParse(
                                            _amountController.text,) ??
                                        0.0;
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: chips.map((amt) {
                                        final isSelected =
                                            currentAmount == amt.toDouble();
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: spacing.elementGapMin,),
                                          child: _buildQuickAmountChip(
                                            amt: amt,
                                            isSelected: isSelected,
                                            color: color,
                                            textTheme: textTheme,
                                            spacing: spacing,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing.sectionGap + 8),

                    // ── FROM / SWAP / TO ──
                    _buildAccountCard(
                      label: 'FROM',
                      icon: LucideIcons.arrowUpRight,
                      iconColor: color.error,
                      account: _fromAccount,
                      accounts: accounts
                          .where((a) => a.id != _toAccount?.id)
                          .toList(),
                      isGuestMode: isGuestMode,
                      onSelect: (a) => setState(() => _fromAccount = a),
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                    ),

                    // Swap row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          AnimatedBuilder(
                            animation: _flowController,
                            builder: (_, __) {
                              final isReducedMotion = MediaQuery.of(context).disableAnimations;
                              return CustomPaint(
                                size: const Size(2, 32),
                                painter: _FlowLinePainter(
                                  color: color.primary,
                                  progress: _flowController.value,
                                  enabled: _canTransfer,
                                  isReducedMotion: isReducedMotion,
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: color.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: IconButton(
                              onPressed:
                                  _fromAccount != null || _toAccount != null
                                      ? _swapAccounts
                                      : null,
                              icon: Icon(
                                LucideIcons.arrowUpDown,
                                size: 18,
                                color:
                                    _fromAccount != null || _toAccount != null
                                        ? color.primary
                                        : color.onSurfaceVariant
                                            .withValues(alpha: 0.3),
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Swap accounts',
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 22),
                        ],
                      ),
                    ),

                    _buildAccountCard(
                      label: 'TO',
                      icon: LucideIcons.arrowDownLeft,
                      iconColor: const Color(0xFF4CAF50),
                      account: _toAccount,
                      accounts: accounts
                          .where((a) => a.id != _fromAccount?.id)
                          .toList(),
                      isGuestMode: isGuestMode,
                      onSelect: (a) => setState(() => _toAccount = a),
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                    ),

                    SizedBox(height: spacing.sectionGap + 8),

                    // ── CROSS-CURRENCY PREVIEW ──
                    if (_isCrossCurrency)
                      _buildCrossCurrencyPreview(color, textTheme, spacing),

                    if (_isCrossCurrency) SizedBox(height: spacing.elementGap),

                    // ── NOTE ──
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: ctxt.transfer_noteLabel,
                        prefixIcon: Icon(
                          LucideIcons.pencilLine,
                          size: 18,
                          color: color.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    SizedBox(height: spacing.elementGap + 4),

                    // ── DATE ──
                    Semantics(
                      label: 'Transfer date: ${DateFormat('MMMM dd, yyyy').format(_date)}, tap to change',
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              HapticFeedback.lightImpact();
                              setState(() => _date = picked);
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(spacing.radiusMedium),
                              border: Border.all(
                                color:
                                    color.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(spacing.elementGap),
                                  decoration: BoxDecoration(
                                    color: color.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.calendar,
                                    size: spacing.iconSM,
                                    color: color.primary,
                                  ),
                                ),
                                SizedBox(width: spacing.elementGap * 2),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: color.onSurfaceVariant,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(
                                        height: spacing.elementGapUltraMin,),
                                    Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(_date),
                                      style: textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                AnimatedRotation(
                                  duration: spacing.animFast,
                                  turns: 0,
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: spacing.iconMD,
                                    color: color.onSurfaceVariant,
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
              ),
            ],
          );
        },
        loading: () => Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: const AccountCardSkeleton(),),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  // ── CROSS-CURRENCY PREVIEW ──
  Widget _buildCrossCurrencyPreview(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fromCur = _fromAccount?.currencyCode ?? BaseCurrency.code;
    final toCur = _toAccount?.currencyCode ?? BaseCurrency.code;

    return FutureBuilder<({double converted, double rate})?>(
      future: () async {
        if (amount <= 0) return null;
        final service = await ref.read(currencyServiceProvider.future);
        return service.convert(amount, fromCur, toCur);
      }(),
      builder: (context, snapshot) {
        final result = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.tertiaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.arrowLeftRight, size: 18, color: color.tertiary),
              SizedBox(width: spacing.radiusMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatCurrency(amount, code: fromCur)} → ${result != null ? formatCurrency(result.converted, code: toCur) : '...'} $toCur',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onTertiaryContainer,
                      ),
                    ),
                    if (result != null)
                      Text(
                        'Rate: 1 $fromCur = ${result.rate.toStringAsFixed(4)} $toCur',
                        style: textTheme.bodySmall?.copyWith(
                          color:
                              color.onTertiaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── QUICK AMOUNT CHIP BUILDER ──
  Widget _buildQuickAmountChip({
    required int amt,
    required bool isSelected,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return AnimatedContainer(
      duration: spacing.animFast,
      decoration: BoxDecoration(
        color: isSelected ? color.primary : color.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          onTap: () {
            HapticFeedback.selectionClick();
            _amountController.text = amt.toString();
            setState(() {});
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap + 2,
              vertical: spacing.elementGapMin,
            ),
            child: Text(
              formatCurrency(amt.toDouble(), decimals: 0),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? color.onPrimary : color.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ACCOUNT CARD ──
  Widget _buildAccountCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Account? account,
    required List<Account> accounts,
    required bool isGuestMode,
    required ValueChanged<Account> onSelect,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    final accountColor = account != null
        ? Color(account.colorValue ?? color.primary.toARGB32())
        : color.onSurfaceVariant;
    final balance = account != null ? _balanceMap[account.id] ?? 0.0 : 0.0;
    final displayBalance = GuestModeUtil.applyGuestMode(balance, isGuestMode);

    return Semantics(
      label: '${account?.name ?? 'Select $label account'} account, balance ${account != null ? formatCurrency(displayBalance, code: account.currencyCode) : 'not selected'}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountPicker(context, accounts, onSelect),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: account != null
                  ? accountColor.withValues(alpha: 0.06)
                  : color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: account != null
                    ? accountColor.withValues(alpha: 0.3)
                    : color.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: account != null
                ? Row(
                    children: [
                      // Direction icon
                      Container(
                        padding: EdgeInsets.all(spacing.elementGap),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: spacing.iconSM, color: iconColor),
                      ),
                      SizedBox(width: spacing.elementGap * 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: textTheme.labelSmall?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: spacing.elementGapUltraMin),
                            Text(
                              account.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            account.accountType.icon,
                            size: spacing.iconMD,
                            color: accountColor,
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          CurrencyText(
                            amount: displayBalance,
                            currencyCode: account.currencyCode,
                            compact: true,
                            style: textTheme.labelMedium?.copyWith(
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.elementGap),
                        decoration: BoxDecoration(
                          color: color.onSurfaceVariant.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: spacing.iconSM,
                          color: iconColor.withValues(alpha: 0.4),
                        ),
                      ),
                      SizedBox(width: spacing.elementGap * 2),
                      Text(
                        'Select $label account',
                        style: textTheme.bodyLarge?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.chevronRight,
                        size: spacing.iconSM,
                        color: color.onSurfaceVariant,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── ACCOUNT PICKER ──
  void _showAccountPicker(
    BuildContext context,
    List<Account> accounts,
    ValueChanged<Account> onSelect,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read(spacingProvider);
    final isGuestMode = ref.read(guestModeProvider);

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: spacing.elementGap),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Text(
              'Select Account',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.elementGap),
            ...accounts.map((account) {
              final acColor =
                  Color(account.colorValue ?? color.primary.toARGB32());
              final bal = _balanceMap[account.id] ?? 0.0;
              final displayBal = GuestModeUtil.applyGuestMode(bal, isGuestMode);

              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: acColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    account.accountType.icon,
                    color: acColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  account.name,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: CurrencyText(
                  amount: displayBal,
                  currencyCode: account.currencyCode,
                  compact: true,
                  style: textTheme.labelLarge?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onSelect(account);
                  ctx.pop();
                },
              );
            }),
            SizedBox(height: spacing.sectionGap),
          ],
        ),
      ),
    );
  }
}

// ── FLOW LINE PAINTER ──
class _FlowLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool enabled;
  final bool isReducedMotion;

  _FlowLinePainter({
    required this.color,
    required this.progress,
    required this.enabled,
    required this.isReducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      trackPaint,
    );

    if (!enabled) return;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final y = isReducedMotion
        ? size.height / 2
        : progress * size.height;
    canvas.drawCircle(Offset(size.width / 2, y), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowLinePainter old) =>
      old.progress != progress ||
      old.enabled != enabled ||
      old.isReducedMotion != isReducedMotion;
}
