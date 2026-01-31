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
import 'package:mudra_manager/util/icon_helper.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? recurring;

  const AddRecurringTransactionScreen({super.key, this.recurring});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() => _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState extends ConsumerState<AddRecurringTransactionScreen> {
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
    final headerColor = _isExpense ? colorScheme.error : const Color(0xFF00BFA5);

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypeToggle('EXPENSE', true),
              _buildTypeToggle('INCOME', false),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AMOUNT',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 56,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: textTheme.displayLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 56,
                      ),
                      border: InputBorder.none,
                      prefixText: _isExpense ? '- ' : '+ ',
                      prefixStyle: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Frequency', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                        selectedColor: headerColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selected ? headerColor : colorScheme.onSurface,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Account', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _selectedAccount = account);
                                },
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              Color(account.colorValue ?? 0xFF000000).withValues(alpha: 0.8),
                                              Color(account.colorValue ?? 0xFF000000),
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.3) : colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: isSelected ? Colors.white : colorScheme.onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        account.name,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: isSelected ? Colors.white : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Category', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _selectedCategory = category);
                                },
                                child: Container(
                                  width: 100,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              Color(category.colorValue ?? 0xFF000000).withValues(alpha: 0.8),
                                              Color(category.colorValue ?? 0xFF000000),
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.3) : colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        IconHelper.iconFromName(category.iconName ?? 'category'),
                                        color: isSelected ? Colors.white : colorScheme.onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        category.name,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: isSelected ? Colors.white : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
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
                          Text(
                            'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: headerColor,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  if (widget.recurring != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(String label, bool isExpenseBtn) {
    final isSelected = _isExpense == isExpenseBtn;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _isExpense = isExpenseBtn);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
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
    recurring.nextDueDate = calculateNextDueDate(_startDate, _frequency, _startDate);
    recurring.isActive = true;
    recurring.account.value = _selectedAccount;
    recurring.category.value = _selectedCategory;

    await ref.read(recurringTransactionServiceProvider).save(recurring);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(recurringTransactionServiceProvider).delete(widget.recurring!.id);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
