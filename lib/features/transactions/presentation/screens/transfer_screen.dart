import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/widgets/account_card_mini.dart';
import 'package:mudra_manager/features/profile/data/guest_mode_provider.dart';
import 'package:mudra_manager/core/utils/guest_mode_util.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final Account? fromAccount;
  final Account? toAccount;
  final int? fromId;
  final int? toId;
  final String? amount;
  final String? note;
  final DateTime? date;

  const TransferScreen({
    super.key,
    this.amount,
    this.note,
    this.date,
    this.fromAccount,
    this.toAccount,
    this.fromId,
    this.toId,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  Account? _fromAccount;
  Account? _toAccount;

  final _amountC = TextEditingController();
  final _noteC = TextEditingController();
  DateTime _date = DateTime.now();
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    _fromAccount = widget.fromAccount;
    _toAccount = widget.toAccount;
    _amountC.text = widget.amount ?? '';
    _noteC.text = widget.note ?? '';
    _date = widget.date ?? DateTime.now();
    setState(() {
      isUpdate = widget.fromAccount != null && widget.toAccount != null;
    });
  }

  @override
  void dispose() {
    _amountC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccount == null || _toAccount == null) return;

    final amt = double.parse(_amountC.text);
    final note = _noteC.text.trim();

    final service = ref.read(transactionProvider);

    await service.transfer(
      from: _fromAccount!,
      to: _toAccount!,
      amount: amt,
      date: _date,
      note: note.isEmpty ? null : note,
      fromId: widget.fromId,
      toId: widget.toId,
    );

    await WidgetService.updateWidget(ref);
    
    if (mounted) {
      invalidateAll(ref);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final accountsAsync = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ref.watch(accountServiceProvider);
    final ctxt = AppLocalizations.of(context)!;
    final isGuestMode = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.transfer_screenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _fromAccount = null;
                _toAccount = null;
              });
            },
            tooltip: ctxt.transfer_resetTooltip,
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_toAccount?.id == null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          ctxt.transfer_selectAccountsLabel,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color.primary,
                            letterSpacing: 0.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: buildTransferSelector(
                          accounts: accounts,
                          from: _fromAccount,
                          to: _toAccount,
                          onFromChanged: (v) => setState(
                            () => _fromAccount = _fromAccount == v ? null : v,
                          ),
                          onToChanged: (v) => setState(
                            () => _toAccount = _toAccount == v ? null : v,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    ctxt.transfer_fromLabel,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 140,
                                    child: _fromAccount != null
                                        ? AccountCardMini(
                                            account: _fromAccount!,
                                            selected: true,
                                            balance: service.getAccountBalance(
                                              _fromAccount!.id,
                                            ),
                                          )
                                        : AccountCardMini.skeleton(),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.primaryContainer,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.primary.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: color.onPrimaryContainer,
                                  size: 28,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    ctxt.transfer_toLabel,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: color.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 140,
                                    child: _toAccount != null
                                        ? AccountCardMini(
                                            account: _toAccount!,
                                            selected: true,
                                            balance: service.getAccountBalance(
                                              _toAccount!.id,
                                            ),
                                          )
                                        : const AccountCardMini.skeleton(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        ctxt.transfer_detailsLabel,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color.primary,
                          letterSpacing: 0.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _amountC,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: ctxt.transfer_amountLabel,
                        prefixIcon: Icon(Icons.currency_rupee, size: 28),
                        filled: true,
                        fillColor: color.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: color.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final x = double.tryParse(v ?? '');
                        return x == null || x <= 0
                            ? ctxt.transfer_amountValidationError
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [500, 1000, 2000, 5000].map((amt) {
                        return ActionChip(
                          label: Text('₹$amt'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _amountC.text = amt.toString();
                          },
                          backgroundColor: color.surfaceContainerHigh,
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerHighest,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final pick = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pick != null) setState(() => _date = pick);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: color.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ctxt.transfer_dateLabel,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.yMMMd().format(_date),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: color.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: color.onSurfaceVariant,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteC,
                      style: textTheme.bodyLarge,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: ctxt.transfer_noteLabel,
                        hintText: 'Add a note (optional)',
                        prefixIcon: const Icon(Icons.note_outlined),
                        filled: true,
                        fillColor: color.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: color.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (_fromAccount != null && _toAccount != null && _amountC.text.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Card(
                        elevation: 0,
                        color: color.primaryContainer.withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: color.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Transfer Summary',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Amount', '₹${GuestModeUtil.applyGuestMode(double.parse(_amountC.text), isGuestMode).toStringAsFixed(0)}', textTheme, color),
                              _buildSummaryRow('From', _fromAccount!.name, textTheme, color),
                              _buildSummaryRow('To', _toAccount!.name, textTheme, color),
                              _buildSummaryRow('Date', DateFormat.yMMMd().format(_date), textTheme, color),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isUpdate
                              ? ctxt.transfer_updateButtonLabel
                              : ctxt.transfer_buttonLabel,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onPrimary
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(ctxt.transfer_errorLoadingAccounts)),
      ),
    );
  }

  Widget buildTransferSelector({
    required List<Account> accounts,
    required Account? from,
    required Account? to,
    required ValueChanged<Account> onFromChanged,
    required ValueChanged<Account> onToChanged,
  }) {
    final fromAccountList = accounts
        .where((a) => a.id != _toAccount?.id)
        .toList();
    final toAccountList = accounts
        .where((a) => a.id != _fromAccount?.id)
        .toList();
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final service = ref.watch(accountServiceProvider);

    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_fromAccount == null)
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fromAccountList.length,
                padding: const EdgeInsets.only(left: 0),
                itemBuilder: (context, i) {
                  final acct = fromAccountList[i];
                  final accountBalance = service.getAccountBalance(acct.id);
                  final selected = acct.id == from?.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onFromChanged(acct);
                    },
                    child: AccountCardMini(
                      account: acct,
                      selected: selected,
                      balance: accountBalance,
                    ),
                  );
                },
              ),
            ),
          if (_fromAccount != null && _toAccount == null)
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: toAccountList.length,
                padding: const EdgeInsets.only(right: 16),
                itemBuilder: (context, i) {
                  final acct = toAccountList[i];
                  final accountBalance = service.getAccountBalance(acct.id);
                  final selected = acct.id == to?.id;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onToChanged(acct);
                    },
                    child: AccountCardMini(
                      account: acct,
                      selected: selected,
                      balance: accountBalance,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, TextTheme textTheme, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
