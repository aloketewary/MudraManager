import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/reconciliation_service.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';

class MissingTransactionScreen extends ConsumerStatefulWidget {
  final Account account;

  const MissingTransactionScreen({super.key, required this.account});

  @override
  ConsumerState<MissingTransactionScreen> createState() =>
      _MissingTransactionScreenState();
}

class _MissingTransactionScreenState
    extends ConsumerState<MissingTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Missing Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(spacing.cardInner + 8),
          children: [
            // Account info
            Container(
              padding: EdgeInsets.all(spacing.cardInner),
              decoration: BoxDecoration(
                color: color.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(color: color.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color.primary, size: 20),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      'This transaction was found on your bank statement but is missing from ${widget.account.name}.',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap + 8),

            // Type toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selected) {
                HapticFeedback.mediumImpact();
                setState(() {
                  _isExpense = selected.first;
                  _selectedCategory = null;
                });
              },
            ),
            SizedBox(height: spacing.sectionGap + 8),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Bank Amount',
                hintText: '0.00',
                prefixIcon: Icon(
                  _isExpense ? Icons.remove : Icons.add,
                  color: _isExpense ? color.error : color.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                if (double.tryParse(value) == null) return 'Invalid amount';
                return null;
              },
            ),
            SizedBox(height: spacing.sectionGap),

            // Date
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final pick = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: now,
                );
                if (pick != null) setState(() => _selectedDate = pick);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Transaction Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: textTheme.bodyLarge,
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),

            // Category
            categoriesAsync.when(
              data: (categories) {
                final filtered = categories
                    .where(
                      (c) =>
                          (_isExpense
                              ? c.categoryType == CategoryType.expense
                              : c.categoryType == CategoryType.income) &&
                          c.parentCategory.value == null,
                    )
                    .toList();

                return DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category (optional)',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                  items: filtered
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(height: spacing.sectionGap),

            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description / Notes',
                hintText: 'What was this transaction for?',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: spacing.sectionGap + 16),

            // Save
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: spacing.cardInner),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Add Missing Transaction',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final service = ref.read(reconciliationServiceProvider);
      final amount = double.parse(_amountController.text);

      await service.addMissingTransaction(
        account: widget.account,
        bankAmount: amount,
        isExpense: _isExpense,
        date: _selectedDate,
        description: _descController.text.isNotEmpty
            ? _descController.text
            : null,
      );

      ref.invalidate(transactionProvider);
      ref.invalidate(accountServiceProvider);

      if (mounted) {
        SnackbarService.success('Missing transaction added');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        SnackbarService.error('Failed to add transaction');
      }
    }
  }
}
