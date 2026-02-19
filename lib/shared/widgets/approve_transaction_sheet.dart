import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/pending_transaction.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/account_selector.dart';
import 'package:mudra_manager/shared/widgets/category_selector.dart';

class ApproveTransactionSheet extends StatefulWidget {
  final PendingTransaction transaction;
  final Account? matchedAccount;
  final Account? matchedToAccount;
  final Category? suggestedCategory;
  final Function(Account, Category, DateTime, double) onApprove;
  final Function(Account, Account)? onApproveTransfer;

  const ApproveTransactionSheet({
    super.key,
    required this.transaction,
    this.matchedAccount,
    this.matchedToAccount,
    this.suggestedCategory,
    required this.onApprove,
    this.onApproveTransfer,
  });

  @override
  State<ApproveTransactionSheet> createState() =>
      _ApproveTransactionSheetState();
}

class _ApproveTransactionSheetState extends State<ApproveTransactionSheet> {
  Account? _selectedAccount;
  Account? _selectedToAccount;
  Category? _selectedCategory;
  bool _isTransfer = false;
  late DateTime _selectedDate;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.matchedAccount;
    _selectedToAccount = widget.matchedToAccount;
    _selectedCategory = widget.suggestedCategory;
    _selectedDate = widget.transaction.date;
    _amountController = TextEditingController(
      text: widget.transaction.amount?.toStringAsFixed(0) ?? '',
    );
    _isTransfer =
        widget.transaction.type?.toLowerCase().contains('transfer') == true ||
        (widget.transaction.fromBank != null &&
            widget.transaction.toAccount != null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ctxt.sms_approveTransactionTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.sms_outlined, size: 20, color: color.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.transaction.body,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Account', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            AccountSelector(
              selectedAccount: _selectedAccount,
              onAccountSelected: (account) =>
                  setState(() => _selectedAccount = account),
              accountNumber: widget.transaction.account,
              bankName: widget.transaction.fromBank,
            ),
            const SizedBox(height: 16),
            if (_isTransfer) ...[
              Text('To Account', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              AccountSelector(
                selectedAccount: _selectedToAccount,
                onAccountSelected: (account) =>
                    setState(() => _selectedToAccount = account),
                accountNumber: widget.transaction.toAccount,
                bankName: widget.transaction.fromBank,
              ),
              const SizedBox(height: 16),
            ],
            if (!_isTransfer) ...[
              Text('Category', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) =>
                    setState(() => _selectedCategory = category),
                categoryType: widget.transaction.isIncome == true
                    ? CategoryType.income
                    : CategoryType.expense,
              ),
              const SizedBox(height: 16),
            ],
            Text('Amount', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Date', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: color.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: color.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (_isTransfer) {
                  if (_selectedAccount != null && _selectedToAccount != null) {
                    Navigator.pop(context);
                    widget.onApproveTransfer?.call(
                      _selectedAccount!,
                      _selectedToAccount!,
                    );
                  } else {
                    SnackbarService.warning(
                      'Select both accounts for transfer',
                    );
                  }
                } else {
                  if (_selectedCategory != null && _selectedAccount != null) {
                    final amount = double.tryParse(_amountController.text);
                    if (amount == null || amount <= 0) {
                      SnackbarService.warning('Enter valid amount');
                      return;
                    }
                    Navigator.pop(context);
                    widget.onApprove(_selectedAccount!, _selectedCategory!, _selectedDate, amount);
                  } else {
                    SnackbarService.warning('Select Account & Category');
                  }
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isTransfer ? 'Approve Transfer' : 'Approve Transaction',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
