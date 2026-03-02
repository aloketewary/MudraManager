import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/utils/simple_color_picker.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

class AccountForm extends ConsumerStatefulWidget {
  final Account? account;
  final String? accountNumber;
  final String? bankName;

  const AccountForm({
    super.key,
    this.account,
    this.accountNumber,
    this.bankName,
  });

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
    _nameController = TextEditingController(
      text: widget.account?.name ?? widget.bankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.account?.accountNumber ?? widget.accountNumber ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance.toString() ?? '',
    );
    _selectedType = widget.account?.accountType ?? AccountType.cash;
    _selectedColor = widget.account?.colorValue != null
        ? Color(widget.account!.colorValue!)
        : Color(Colors.blue.toARGB32());
  }

  Future<void> _saveAccount(Id? id) async {
    if (!_formKey.currentState!.validate()) return;

    final isarService = ref.read(isarServiceProvider);
    final isar = await isarService.getInstance();

    final accountName = _nameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    // Check for duplicate account name
    final existingNameAccount = await isar.accounts
        .filter()
        .nameEqualTo(accountName)
        .findFirst();

    if (existingNameAccount != null && existingNameAccount.id != id) {
      SnackbarService.warning('Account with name "$accountName" already exists');
      return;
    }

    if (accountNumber.isNotEmpty) {
      final existingAccount = await isar.accounts
          .filter()
          .accountNumberEqualTo(accountNumber)
          .findFirst();

      if (existingAccount != null && existingAccount.id != id) {
        SnackbarService.warning('Account with number "$accountNumber" already exists');
        return;
      }
    }

    final account = widget.account ?? Account();
    final isNewAccount = widget.account == null;

    account.name = accountName;
    account.initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
    account.accountType = _selectedType!;
    account.accountNumber = accountNumber.isEmpty ? null : accountNumber;
    account.colorValue = _selectedColor?.toARGB32();
    account.isActive = true;

    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });

    if (isNewAccount) {
      final gamificationService =
          await ref.read(gamificationServiceInitProvider.future);
      await gamificationService.track(GamificationEvent.accountCreated);
    }

    ref.invalidate(accountsProvider);
    context.pop(true);
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
    final selectedColor = _selectedColor ?? color.primary;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        backgroundColor: color.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: AdaptiveText(
          widget.account == null ? 'Add Account' : 'Edit Account',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedType?.icon ?? Icons.account_balance_wallet,
                  size: 64,
                  color: selectedColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                (_selectedType?.label ?? 'Account').toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'Enter account name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Account Number',
                hintText: 'Last 4 digits',
                helperText: 'Enter last 4 digits for SMS matching',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 4) return 'At least 4 digits required';
                if (value.length > 4) return 'Only last 4 digits needed';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _selectedType == AccountType.creditCard
                    ? 'Current Outstanding'
                    : 'Initial Balance',
                hintText: _selectedType == AccountType.creditCard
                    ? 'Amount you owe (0 if paid off)'
                    : 'Enter initial balance',
                helperText: _selectedType == AccountType.creditCard
                    ? 'Enter outstanding amount. Use 0 if card is paid off.'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Account Type',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AccountType.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final type = AccountType.values[index];
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedType = type);
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withValues(alpha: 0.15)
                            : color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: selectedColor, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type.icon,
                            color: isSelected
                                ? selectedColor
                                : color.onSurfaceVariant,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          AdaptiveText(
                            type.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? selectedColor
                                  : color.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _pickColor();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selectedColor, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette, color: selectedColor),
                    const SizedBox(width: 12),
                    Text(
                      'TAP TO CHANGE COLOR',
                      style: textTheme.titleSmall?.copyWith(
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _saveAccount(widget.account?.id ?? null);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                (widget.account == null ? 'SAVE ACCOUNT' : 'UPDATE ACCOUNT'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
