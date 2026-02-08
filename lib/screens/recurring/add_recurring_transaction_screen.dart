import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/db/models/frequency.dart';
import 'package:mudra_manager/db/models/recurring_transaction.dart';
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/recurring_transaction_provider.dart';
import 'package:mudra_manager/components/adaptive_text.dart';
import 'package:mudra_manager/util/icon_helper.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? recurring;

  const AddRecurringTransactionScreen({super.key, this.recurring});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends ConsumerState<AddRecurringTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isExpense = true;
  DateTime _startDate = DateTime.now();
  Frequency _frequency = Frequency.monthly;
  Account? _selectedAccount;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      _amountController.text = widget.recurring!.amount.toString();
      _descController.text = widget.recurring!.description ?? '';
      _isExpense = widget.recurring!.isExpense;
      _startDate = widget.recurring!.startDate;
      _frequency = widget.recurring!.frequency;
      _selectedAccount = widget.recurring!.account.value;
      _selectedCategory = widget.recurring!.category.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: AdaptiveText(
          widget.recurring == null ? 'Add Recurring' : 'Edit Recurring',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('EXPENSE'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: false,
                label: Text('INCOME'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_isExpense},
            onSelectionChanged: (Set<bool> selected) {
              HapticFeedback.mediumImpact();
              setState(() => _isExpense = selected.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _isExpense ? colorScheme.errorContainer : colorScheme.primaryContainer;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _isExpense ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;
                }
                return null;
              }),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isExpense ? colorScheme.error : colorScheme.primary,
            ),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: _isExpense ? '- ₹' : '+ ₹',
              prefixStyle: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isExpense ? colorScheme.error : colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frequency',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Frequency.values.map((f) {
              final selected = _frequency == f;
              return ChoiceChip(
                label: Text(_getFrequencyLabel(f)),
                selected: selected,
                onSelected: (v) {
                  HapticFeedback.mediumImpact();
                  setState(() => _frequency = f);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Account',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final accountsAsync = ref.watch(accountsProvider);
              return accountsAsync.when(
                data: (accounts) => SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isSelected = _selectedAccount?.id == account.id;
                      final accountColor = Color(account.colorValue ?? 0xFF000000);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedAccount = account);
                        },
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accountColor.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: accountColor, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: accountColor,
                              ),
                              const SizedBox(height: 8),
                              AdaptiveText(
                                account.name,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading accounts'),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Category',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final categoriesAsync = ref.watch(categoryListProvider);
              return categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory?.id == category.id;
                      final categoryColor = Color(category.colorValue ?? 0xFF000000);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedCategory = category);
                        },
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? categoryColor.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: categoryColor, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconHelper.iconFromName(
                                  category.iconName ?? 'category',
                                ),
                                color: categoryColor,
                              ),
                              const SizedBox(height: 8),
                              AdaptiveText(
                                category.name,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Error loading categories'),
              );
            },
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _startDate = date);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  AdaptiveText(
                    'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (widget.recurring != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFrequencyLabel(Frequency f) {
    switch (f) {
      case Frequency.daily:
        return 'Daily';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.yearly:
        return 'Yearly';
    }
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty) return;
    if (_selectedAccount == null || _selectedCategory == null) return;

    final recurring = widget.recurring ?? RecurringTransaction();
    recurring.amount = double.parse(_amountController.text);
    recurring.description = _descController.text;
    recurring.isExpense = _isExpense;
    recurring.frequency = _frequency;
    recurring.startDate = _startDate;
    recurring.nextDueDate = calculateNextDueDate(
      _startDate,
      _frequency,
      _startDate,
    );
    recurring.isActive = true;
    recurring.account.value = _selectedAccount;
    recurring.category.value = _selectedCategory;

    await ref.read(recurringTransactionServiceProvider).save(recurring);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref
        .read(recurringTransactionServiceProvider)
        .delete(widget.recurring!.id);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
