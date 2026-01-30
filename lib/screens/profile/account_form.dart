import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    context.pop();
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
    final headerColor = _selectedColor ?? color.primary;

    return Scaffold(
      backgroundColor: headerColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          widget.account == null ? 'Add Account' : 'Edit Account',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedType?.icon ?? Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  (_selectedType?.label ?? 'Account').toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 32,
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    children: [
                      Text(
                        'Account Name',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: color.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter account name',
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Account Number',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: color.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _accountNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Last 4 digits',
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.numbers,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : value.length != 4
                                      ? '4 digits required'
                                      : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Initial Balance',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: color.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _balanceController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter initial balance',
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.currency_rupee,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Account Type',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AccountType.values.length,
                          separatorBuilder: (_, __) => SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final type = AccountType.values[index];
                            final isSelected = _selectedType == type;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _selectedType = type);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: 100,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              headerColor.withValues(
                                                alpha: 0.8,
                                              ),
                                              headerColor,
                                            ],
                                          )
                                          : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              color.surfaceContainerHighest
                                                  .withValues(alpha: 0.6),
                                              color.surfaceContainerHighest
                                                  .withValues(alpha: 0.3),
                                            ],
                                          ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: headerColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ]
                                          : [],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      type.icon,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : color.onSurfaceVariant,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      type.label,
                                      style: textTheme.labelSmall?.copyWith(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : color.onSurfaceVariant,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Color',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _pickColor();
                        },
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                headerColor.withValues(alpha: 0.8),
                                headerColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: headerColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.palette, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'TAP TO CHANGE COLOR',
                                style: textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 48),
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _saveAccount();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: headerColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          minimumSize: Size(double.infinity, 52),
                        ),
                        child: Text(
                          (widget.account == null
                              ? 'SAVE ACCOUNT'
                              : 'UPDATE ACCOUNT'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom,
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
