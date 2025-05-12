import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart'
    show Account, AccountType, GetAccountCollection;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_color_button.dart';
import 'package:mudra_manager/screens/reusable/common_dropdown_field.dart'
    show CommonDropdownField;
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/util/account_type_extension.dart';
import 'package:mudra_manager/util/simple_color_picker.dart'
    show SimpleColorPickerDialog;

class AccountForm extends ConsumerStatefulWidget {
  final Account? account;

  const AccountForm({super.key, this.account});

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _balanceController;
  AccountType? _selectedType;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance.toString() ?? '',
    );
    _selectedType = widget.account?.accountType ?? AccountType.cash;
    _selectedColor =
        widget.account?.colorValue != null
            ? Color(widget.account!.colorValue!)
            : Color(Colors.blue.toARGB32());
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final isarService = ref.read(isarServiceProvider);
    final isar = await isarService.getInstance();

    final account = widget.account ?? Account();

    account.name = _nameController.text.trim();
    account.initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
    account.accountType = _selectedType!;
    account.accountNumber = _accountNumberController.text;
    account.colorValue = _selectedColor?.toARGB32();
    account.isActive = true;

    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });

    Navigator.of(context).pop();
    ref.invalidate(accountsProvider);
  }

  void _pickColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => SimpleColorPickerDialog(initialColor: _selectedColor),
    );
    if (color != null) setState(() => _selectedColor = color);
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Add Account' : 'Edit Account'),
      ),
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommonTextInputField(
                        controller: _nameController,
                        labelText: 'Account Name',
                        hintText: 'Enter account name',
                        iconData: Icons.account_balance_wallet_outlined,
                        validateField:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      CommonTextInputField(
                        controller: _accountNumberController,
                        labelText: 'Account Number',
                        hintText: 'Last 4 Digit of Account Number',
                        iconData: Icons.numbers,
                        inputType: TextInputType.number,
                        validateField:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Required'
                                    : value.length != 4
                                    ? '4 digit required'
                                    : null,
                      ),
                      CommonTextInputField(
                        controller: _balanceController,
                        labelText: 'Initial Balance',
                        hintText: 'Enter initial balance',
                        iconData: Icons.money,
                        inputType: TextInputType.number,
                        validateField:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      CommonDropdownField<AccountType>(
                        labelText: 'Account Type',
                        value: _selectedType,
                        items: AccountType.values,
                        onChanged: (val) => setState(() => _selectedType = val),
                        itemBuilder:
                            (AccountType type) => Row(
                              children: [
                                Icon(type.icon),
                                const SizedBox(width: 8),
                                Text(type.label),
                              ],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CommonColorPickerButton(
                            backgroundColor: _selectedColor,
                            onPressed: _pickColor,
                            label: 'Pick Color',
                            textColor: color.onSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            CommonButton(
              text: widget.account == null ? "Save" : "update",
              onPressed: _saveAccount,
              backGroundColor: color.primary,
              textColor: color.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
