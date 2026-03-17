import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';

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
                  return _isExpense
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _isExpense
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer;
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
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isSelected = _selectedAccount?.id == account.id;
                      final accountColor = Color(
                          account.colorValue ?? colorScheme.primary.toARGB32());
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedAccount = account);
                        },
                        child: Card(
                          elevation: 0,
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accountColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: accountColor,
                                    size: 20,
                                  ),
                                ),
                                AdaptiveText(
                                  account.name,
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
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
                data: (categories) {
                  final filtered = categories
                      .where((c) =>
                          (_isExpense
                              ? c.categoryType == CategoryType.expense
                              : c.categoryType == CategoryType.income) &&
                          c.parentCategory.value == null)
                      .toList();

                  return SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        final isParentSelected =
                            _selectedCategory?.id == category.id;
                        final isChildSelected =
                            _selectedCategory?.parentCategory.value?.id ==
                                category.id;
                        final isSelected = isParentSelected || isChildSelected;
                        final hasSubcategories = categories.any(
                            (c) => c.parentCategory.value?.id == category.id);
                        final categoryColor = Color(
                            category.colorValue ?? colorScheme.primary.value);

                        return GestureDetector(
                          onTap: () async {
                            if (hasSubcategories) {
                              final subcategories = categories
                                  .where((c) =>
                                      c.parentCategory.value?.id == category.id)
                                  .toList();
                              final selected =
                                  await showModalBottomSheet<Category>(
                                context: context,
                                builder: (_) => _SubcategoryPicker(
                                  parent: category,
                                  subcategories: subcategories,
                                  selected: _selectedCategory,
                                ),
                              );
                              if (selected != null)
                                setState(() => _selectedCategory = selected);
                            } else {
                              HapticFeedback.mediumImpact();
                              setState(() => _selectedCategory = category);
                            }
                          },
                          onLongPress: hasSubcategories
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _selectedCategory = category);
                                }
                              : null,
                          child: Card(
                            elevation: 0,
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withValues(
                                                alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            IconHelper.iconFromName(
                                                category.iconName ??
                                                    'category'),
                                            color: categoryColor,
                                            size: 20,
                                          ),
                                        ),
                                        if (isChildSelected &&
                                            _selectedCategory != null)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Color(_selectedCategory!
                                                        .colorValue ??
                                                    colorScheme.primary
                                                        .toARGB32()),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: colorScheme.surface,
                                                    width: 2),
                                              ),
                                              child: Icon(
                                                IconHelper.iconFromName(
                                                    _selectedCategory!
                                                            .iconName ??
                                                        'category'),
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        if (hasSubcategories &&
                                            !isChildSelected)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.chevron_right,
                                                  size: 12,
                                                  color: colorScheme.onPrimary),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AdaptiveText(
                                        isChildSelected &&
                                                _selectedCategory != null
                                            ? _selectedCategory!.name
                                            : category.name,
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                      ),
                                      if (isChildSelected &&
                                          _selectedCategory != null)
                                        Text(
                                          category.name,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: isSelected
                                                ? colorScheme.onPrimaryContainer
                                                    .withValues(alpha: 0.7)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
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
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (_selectedAccount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account and category')),
      );
      return;
    }

    try {
      final recurring = widget.recurring ?? RecurringTransaction();
      recurring.amount = double.parse(_amountController.text);
      recurring.description = _descController.text;
      recurring.isExpense = _isExpense;
      recurring.frequency = _frequency;
      recurring.startDate = _startDate;
      // For new recurring transactions, nextDueDate should be the start date
      // For existing ones being edited, keep the existing nextDueDate
      if (widget.recurring == null) {
        recurring.nextDueDate = _startDate;
      } else {
        recurring.nextDueDate = widget.recurring!.nextDueDate;
      }
      recurring.isActive = true;
      recurring.account.value = _selectedAccount;
      recurring.category.value = _selectedCategory;

      await ref.read(recurringTransactionServiceProvider).save(recurring);
      if (widget.recurring == null) {
        ref
            .read(gamificationServiceProvider)
            ?.track(GamificationEvent.recurringTransactionCreated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring transaction saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
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

class _SubcategoryPicker extends StatelessWidget {
  final Category parent;
  final List<Category> subcategories;
  final Category? selected;

  const _SubcategoryPicker({
    required this.parent,
    required this.subcategories,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parent.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select subcategory or tap parent',
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              IconHelper.iconFromName(parent.iconName ?? 'category'),
              color: Color(parent.colorValue ?? 0xFF000000),
            ),
            title: Text('${parent.name} (Parent)'),
            selected: selected?.id == parent.id,
            onTap: () => Navigator.pop(context, parent),
          ),
          const Divider(),
          ...subcategories.map((sub) => ListTile(
                leading: Icon(
                  IconHelper.iconFromName(sub.iconName ?? 'category'),
                  color: Color(sub.colorValue ?? 0xFF000000),
                ),
                title: Text(sub.name),
                selected: selected?.id == sub.id,
                onTap: () => Navigator.pop(context, sub),
              )),
        ],
      ),
    );
  }
}
