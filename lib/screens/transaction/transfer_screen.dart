import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/screens/transaction/account_card_mini.dart'
    show AccountCardMini;

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
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    final service = ref.watch(accountServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds'),
        actions: [
          IconButton.outlined(
            onPressed: () {
              setState(() {
                _fromAccount = null;
                _toAccount = null;
              });
            },
            icon: const Icon(Icons.undo_outlined),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child:
                              _toAccount?.id == null
                                  ? Column(
                                    key: const ValueKey("accountSelector"),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          "Select Accounts",
                                          style: textTheme.titleLarge?.copyWith(
                                            color: color.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      buildTransferSelector(
                                        accounts: accounts,
                                        from: _fromAccount,
                                        to: _toAccount,
                                        onFromChanged:
                                            (v) => setState(() {
                                              _fromAccount =
                                                  _fromAccount == v ? null : v;
                                            }),
                                        onToChanged:
                                            (v) => setState(() {
                                              _toAccount =
                                                  _toAccount == v ? null : v;
                                            }),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  )
                                  : const SizedBox.shrink(
                                    key: ValueKey("empty"),
                                  ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "From".toUpperCase(),
                                    style: textTheme.titleLarge?.copyWith(
                                      color: color.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 150,
                                  child:
                                      _fromAccount != null
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
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child: Icon(
                                Icons.arrow_forward_ios_outlined,
                                size: 32,
                                color: color.secondary,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    "To".toUpperCase(),
                                    style: textTheme.titleLarge?.copyWith(
                                      color: color.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 150,
                                  child:
                                      _toAccount != null
                                          ? AccountCardMini(
                                            account: _toAccount!,
                                            selected: true,
                                            balance: service.getAccountBalance(
                                              _toAccount!.id,
                                            ),
                                          )
                                          : AccountCardMini.skeleton(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CommonTextInputField(
                          controller: _amountC,
                          labelText: "Amount",
                          inputType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          iconData: Icons.money,
                          validateField: (v) {
                            final x = double.tryParse(v ?? '');
                            return x == null || x <= 0
                                ? 'Enter valid amount'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Date picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Date: ${DateFormat.yMMMd().format(_date)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final pick = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pick != null) setState(() => _date = pick);
                          },
                        ),

                        const SizedBox(height: 12),
                        CommonTextInputField(
                          controller: _noteC,
                          labelText: "Note (optional)",
                          iconData: Icons.note,
                        ),
                      ],
                    ),
                  ),
                ),

                CommonButton(
                  text: isUpdate ? 'Update Transfer' : 'Transfer',
                  backGroundColor: color.secondary,
                  textColor: color.onSecondary,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
                    onTap: () => onFromChanged(acct),
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
                    onTap: () => onToChanged(acct),
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
