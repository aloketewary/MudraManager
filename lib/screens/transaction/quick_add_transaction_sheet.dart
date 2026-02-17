import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/transaction.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/service/widget_service.dart';
import 'package:mudra_manager/util/app_logger.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  const QuickAddTransactionSheet({super.key});

  @override
  ConsumerState<QuickAddTransactionSheet> createState() => _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends ConsumerState<QuickAddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isExpense = true;
  Account? _selectedAccount;
  Category? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ctxt = AppLocalizations.of(context)!;
    AppLogger.transaction('Quick add: Starting transaction save');
    
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      AppLogger.warning('Quick add: Invalid amount entered');
      SnackbarService.error(ctxt.transaction_enterValidAmountError);
      return;
    }
    if (_selectedAccount == null) {
      AppLogger.warning('Quick add: No account selected');
      SnackbarService.error(ctxt.transaction_selectOneAccountErrorText);
      return;
    }
    if (_selectedCategory == null) {
      AppLogger.warning('Quick add: No category selected');
      SnackbarService.error(ctxt.transaction_selectOneCategoryErrorText);
      return;
    }

    final txn = Transaction.create(
      date: DateTime.now(),
      amount: double.parse(_amountController.text),
      isExpense: _isExpense,
      description: _noteController.text,
    );

    txn.account.value = _selectedAccount!;
    txn.category.value = _selectedCategory!;

    AppLogger.transaction('Quick add: Saving ${_isExpense ? "expense" : "income"} of ₹${txn.amount}');
    await ref.read(transactionProvider).addTransaction(txn);
    await WidgetService.updateWidget(ref);
    AppLogger.widget('Quick add: Widget updated after transaction');
    
    if (mounted) {
      Navigator.pop(context);
      SnackbarService.success('Transaction added successfully');
      AppLogger.transaction('Quick add: Transaction saved successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Quick Add', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Expense/Income Toggle
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(value: false, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
            ],
            selected: {_isExpense},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isExpense = selection.first;
                _selectedCategory = null;
              });
            },
          ),
          SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),

          // Account
          Text('Account', style: textTheme.labelLarge),
          SizedBox(height: 8),
          accountsAsync.when(
            data: (accounts) => SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final acc = accounts[i];
                  final selected = _selectedAccount?.id == acc.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAccount = acc),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.primaryContainer : color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(color: color.primary, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 20, color: selected ? color.onPrimaryContainer : color.onSurface),
                          SizedBox(height: 4),
                          Text(acc.name, style: textTheme.labelSmall?.copyWith(color: selected ? color.onPrimaryContainer : color.onSurface)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            loading: () => SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => SizedBox(height: 60, child: Text('Error loading accounts')),
          ),
          SizedBox(height: 16),

          // Category
          Text('Category', style: textTheme.labelLarge),
          SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              final filtered = categories.where((c) => 
                (_isExpense ? c.categoryType == CategoryType.expense : c.categoryType == CategoryType.income) &&
                c.parentCategory.value == null
              ).toList();
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = filtered[i];
                    final selected = _selectedCategory?.id == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        width: 80,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected ? color.primaryContainer : color.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: selected ? Border.all(color: color.primary, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconHelper.iconFromName(cat.iconName ?? 'category'),
                              color: Color(cat.colorValue ?? color.primary.value),
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              cat.name,
                              style: textTheme.labelSmall?.copyWith(color: selected ? color.onPrimaryContainer : color.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => SizedBox(height: 80, child: Text('Error loading categories')),
          ),
          SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Add note (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),

          // Save Button
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
