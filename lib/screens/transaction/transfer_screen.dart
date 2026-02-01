import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/transaction/account_card_mini.dart' show AccountCardMini;
import 'package:mudra_manager/theme/app_colors.dart';

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

    ref.invalidate(transactionProvider);

    context.pop();
  }

  @override
  Widget build(BuildContext ctx) {
    final accountsAsync = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ref.watch(accountServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Funds'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _fromAccount = null;
                _toAccount = null;
              });
            },
            tooltip: 'Reset',
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_toAccount?.id == null) ...[
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 16),
                        child: Text('SELECT ACCOUNTS', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color.primary, letterSpacing: 0.5, fontSize: 12)),
                      ),
                      SizedBox(
                        height: 150,
                        child: buildTransferSelector(
                          accounts: accounts,
                          from: _fromAccount,
                          to: _toAccount,
                          onFromChanged: (v) => setState(() => _fromAccount = _fromAccount == v ? null : v),
                          onToChanged: (v) => setState(() => _toAccount = _toAccount == v ? null : v),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.glassGradient(AppColors.transfer, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.transfer.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: AppColors.glassShadow(AppColors.transfer, isDark),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('FROM', style: textTheme.labelSmall?.copyWith(color: AppColors.transfer.withValues(alpha: 0.7), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                SizedBox(height: 12),
                                SizedBox(height: 140, child: _fromAccount != null ? AccountCardMini(account: _fromAccount!, selected: true, balance: service.getAccountBalance(_fromAccount!.id)) : AccountCardMini.skeleton()),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: AppColors.transfer.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                              ),
                              child: Icon(Icons.arrow_forward, color: AppColors.transfer, size: 24),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text('TO', style: textTheme.labelSmall?.copyWith(color: AppColors.transfer.withValues(alpha: 0.7), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                SizedBox(height: 12),
                                SizedBox(height: 140, child: _toAccount != null ? AccountCardMini(account: _toAccount!, selected: true, balance: service.getAccountBalance(_toAccount!.id)) : AccountCardMini.skeleton()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                        SizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 16),
                          child: Text('TRANSFER DETAILS', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color.primary, letterSpacing: 0.5, fontSize: 12)),
                        ),
                        TextFormField(
                          controller: _amountC,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.outline, width: 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.outline, width: 1.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.primary, width: 2)),
                          ),
                          validator: (v) {
                            final x = double.tryParse(v ?? '');
                            return x == null || x <= 0 ? 'Enter valid amount' : null;
                          },
                        ),
                        SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final pick = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
                            if (pick != null) setState(() => _date = pick);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: AppColors.glassGradient(color.primary, isDark), begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.primary.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: AppColors.glassShadow(color.primary, isDark),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: color.primary.withValues(alpha: 0.15), blurRadius: 12, offset: Offset(0, 4))],
                                  ),
                                  child: Icon(Icons.calendar_today, color: color.primary, size: 20),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date', style: textTheme.labelMedium?.copyWith(color: color.primary.withValues(alpha: 0.7))),
                                      SizedBox(height: 2),
                                      Text(DateFormat.yMMMd().format(_date), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color.primary, letterSpacing: -0.2)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: color.primary.withValues(alpha: 0.5), size: 18),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _noteC,
                          style: textTheme.bodyLarge,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Note (optional)',
                            prefixIcon: Icon(Icons.note_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.outline, width: 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.outline, width: 1.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color.primary, width: 2)),
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.transfer,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(isUpdate ? 'Update Transfer' : 'Transfer', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading accounts')),
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
    var fromAccountList =
        accounts.where((a) => a.id != _toAccount?.id).toList();
    var toAccountList =
        accounts.where((a) => a.id != _fromAccount?.id).toList();
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
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
                  var accountBalance = service.getAccountBalance(acct.id);
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
                  var accountBalance = service.getAccountBalance(acct.id);
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
}
