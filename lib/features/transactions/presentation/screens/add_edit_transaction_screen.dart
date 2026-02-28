import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/notification_record_service.dart';
import 'package:mudra_manager/core/providers/shared_preference_provider.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_provider.dart';
import 'package:mudra_manager/features/budget/data/budget_alert_service.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/adaptive_text.dart';
import 'package:mudra_manager/shared/widgets/simple_calculator.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();

  Account? _selectedAccount;
  Category? _selectedCategory;
  List<Tag> selectedTags = [];
  Map<int, double> _balanceMap = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amountController.text =
        widget.transaction?.amount.toStringAsFixed(2) ?? '';
    _descController.text = widget.transaction?.description ?? '';
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _selectedAccount = widget.transaction?.account.value;
    _selectedCategory = widget.transaction?.category.value;
    _isExpense = widget.transaction?.isExpense ?? true;
    selectedTags.addAll(widget.transaction?.tags.toList() ?? []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(accountServiceProvider).getAccountBalanceMap().then((val) {
        if (mounted) {
          setState(() {
            _balanceMap = val;
            _initialized = true;
          });
        }
      });
    }
  }

  void _showCalculator(BuildContext context, Function(double) onResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      enableDrag: true,
      showDragHandle: true,
      isDismissible: false,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SimpleCalculator(
            onResultSelected: (value) {
              context.pop();
              onResult(value); // Pass result back to amount field
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        centerTitle: true,
        title: AdaptiveText(
          widget.transaction == null
              ? ctxt.add_edit_transaction_screen_title
              : ctxt.transaction_editTransactionTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showCalculator(context, (calculatedValue) {
                _amountController.text = calculatedValue.toString();
              });
            },
            icon: const Icon(Icons.calculate_outlined),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Type Toggle
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(ctxt.transaction_expenseButtonLabel),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(ctxt.transaction_incomeButtonLabel),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (Set<bool> selected) {
                HapticFeedback.mediumImpact();
                setState(() => _isExpense = selected.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
            ),
            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: ctxt.transaction_amountControllerText,
                hintText: '0.00',
                prefixIcon: Icon(
                  _isExpense ? Icons.remove : Icons.add,
                  color: _isExpense ? color.error : color.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? ctxt.transaction_amountControllerErrorText
                  : null,
            ),
            const SizedBox(height: 32),
            // 1. Account Section
            AdaptiveText(
              ctxt.transaction_selectAccountLabel,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final accountsAsync = ref.watch(accountsProvider);
                return accountsAsync.when(
                  data: (accounts) => SizedBox(
                    height: 130,
                    child: _buildAccountListView(accounts, textTheme, color),
                  ),
                  loading: () => const SizedBox(height: 90),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
            const SizedBox(height: 32),

            // 2. Category Section
            AdaptiveText(
              ctxt.transaction_selectCategoryLabel,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final categoriesAsync = ref.watch(categoryListProvider);
                return categoriesAsync.when(
                  data: (categories) => SizedBox(
                    height: 120,
                    child: _buildCategoryListView(categories, textTheme, color),
                  ),
                  loading: () => const SizedBox(height: 90),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
            const SizedBox(height: 32),

            // 3. Date Field
            InkWell(
              onTap: () async {
                final pick = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pick != null) {
                  setState(() => _selectedDate = pick);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: ctxt.transaction_dateLabel,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Description Field
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: ctxt.transaction_descriptionControllerText,
                hintText: ctxt.transaction_addNoteHint,
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 5. Tags
            Consumer(
              builder: (context, ref, _) {
                final tagsAsync = ref.watch(tagListProvider);
                return tagsAsync.when(
                  data: (tags) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...tags.map((tag) {
                        final isSelected = selectedTags.any(
                          (t) => t.id == tag.id,
                        );
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.removeWhere((t) => t.id == tag.id);
                              }
                            });
                          },
                          showCheckmark: false,
                        );
                      }),
                      ActionChip(
                        label: Text(ctxt.transaction_addNewTagText),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: () => showAddTagBottomSheet(context, ref),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
            const SizedBox(height: 48),

            FilledButton(
              onPressed: _saveTransaction,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                ctxt.transaction_saveTransactionButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.eWallet:
        return Icons.account_balance_wallet;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.other:
        return Icons.attach_money;
    }
  }

  Future<void> _saveTransaction() async {
    final ctxt = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      if (_amountController.text.isEmpty ||
          double.tryParse(_amountController.text) == null) {
        SnackbarService.error(ctxt.transaction_enterValidAmountError);
        return;
      }
      if (_selectedAccount == null) {
        SnackbarService.error(ctxt.transaction_selectOneAccountErrorText);
        return;
      }
      if (_selectedCategory == null) {
        SnackbarService.error(ctxt.transaction_selectOneCategoryErrorText);
        return;
      }

      final txn = Transaction.create(
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        isExpense: _isExpense,
        description: _descController.text,
      );

      if (widget.transaction?.id != null) {
        txn.id = widget.transaction!.id;
      }

      txn.account.value = _selectedAccount;
      txn.category.value = _selectedCategory;
      txn.tags.clear();
      txn.tags.addAll(selectedTags);

      await ref.read(transactionProvider).addTransaction(txn);
      await _checkLowBalance(txn.account.value);
      await _checkBudgetAlerts(txn);
      await WidgetService.updateWidget(ref);
      invalidateAll(ref);

      if (mounted) context.pop();
    }
  }

  void showAddTagBottomSheet(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final isarService = ref.read(isarServiceProvider);
    final ctxt = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctxt.transaction_addNewTagText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: ctxt.transaction_tagNameControllerText,
                  hintText: 'e.g., Travel, Food, Shopping',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final tag = Tag()..name = name;
                    final isar = await isarService.getInstance();
                    await isar.writeTxn(() async {
                      await isar.tags.put(tag);
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                      ref.invalidate(tagListProvider);
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  ctxt.transaction_saveTagButtonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _checkLowBalance(Account? account) async {
    if (account == null) return;
    final accountsService = ref.watch(accountServiceProvider);
    final notificationService = ref.watch(notificationRecordServiceProvider);
    final currentBalance = await accountsService.getAccountBalance(account.id);
    final lowBalanceThreshold = SharedPrefsUtil.instance
        .getLowBalanceThreshold(); // Set your own threshold
    final ctxt = AppLocalizations.of(context)!;

    if (currentBalance < lowBalanceThreshold) {
      await notificationService.logNotification(
        title: 'Low Balance Alert',
        body:
            'Your account "${account.name}" has ${ctxt.formatCurrencyWithSign(2, currentBalance)} remaining.',
        type: 'low_balance',
      );
      await NotificationService.showLocalNotification(
        id: 1000 + account.id, // Unique per account
        title: 'Low Balance Alert',
        body:
            'Your balance in ${account.name} is ${ctxt.formatCurrencyWithSign(2, currentBalance)}.',
      );
    }
  }

  Future<void> _checkBudgetAlerts(Transaction txn) async {
    if (!txn.isExpense || txn.isTransfer) return;

    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    final alertService = BudgetAlertService(
      ref.read(isarServiceProvider),
      notificationsPlugin,
    );

    final alerts = await alertService.checkBudgetsAfterTransaction(txn);
    if (alerts.isNotEmpty) {
      ref.read(budgetAlertsProvider.notifier).addAlerts(alerts);
    }
  }

  Widget? _buildAccountListView(
    List<Account> accounts,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    final ctxt = AppLocalizations.of(context)!;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSelected = _selectedAccount?.id == account.id;
        final balance = _balanceMap[account.id] ?? account.initialBalance;

        return GestureDetector(
          onTap: () => setState(() => _selectedAccount = account),
          child: Card(
            elevation: 0,
            color: isSelected
                ? color.primaryContainer
                : color.surfaceContainerHighest,
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
                      color: Color(
                        account.colorValue ?? color.primary.toARGB32(),
                      ).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForAccountType(account.accountType),
                      color: Color(
                        account.colorValue ?? color.primary.toARGB32(),
                      ),
                      size: 20,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? color.onPrimaryContainer
                              : color.onSurface,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      AdaptiveText(
                        ctxt.formatCurrencyWithSign(2, balance, compact: true),
                        style: textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? color.onPrimaryContainer
                              : color.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        isNumeric: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildCategoryListView(
    List<Category> categories,
    TextTheme textTheme,
    ColorScheme color,
  ) {
    final ctxt = AppLocalizations.of(context)!;

    // Filter by expense/income type and show only parent categories
    final filtered = categories
        .where(
          (c) =>
              (_isExpense
                  ? c.categoryType == CategoryType.expense
                  : c.categoryType == CategoryType.income) &&
              c.parentCategory.value == null,
        )
        .toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: filtered.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index < filtered.length) {
          final cat = filtered[index];
          final isParentSelected = _selectedCategory?.id == cat.id;
          final isChildSelected =
              _selectedCategory?.parentCategory.value?.id == cat.id;
          final isSelected = isParentSelected || isChildSelected;
          final hasSubcategories = categories.any(
            (c) => c.parentCategory.value?.id == cat.id,
          );

          return GestureDetector(
            onTap: () async {
              if (hasSubcategories) {
                final subcategories = categories
                    .where((c) => c.parentCategory.value?.id == cat.id)
                    .toList();
                final selected = await showModalBottomSheet<Category>(
                  context: context,
                  builder: (_) => _SubcategoryPicker(
                    parent: cat,
                    subcategories: subcategories,
                    selected: _selectedCategory,
                  ),
                );
                if (selected != null) {
                  setState(() => _selectedCategory = selected);
                }
              } else {
                setState(() => _selectedCategory = cat);
              }
            },
            onLongPress: hasSubcategories
                ? () => setState(() => _selectedCategory = cat)
                : null,
            child: Card(
              elevation: isSelected ? 4 : 0,
              shadowColor: isSelected
                  ? color.primary.withValues(alpha: 0.3)
                  : null,
              color: isSelected
                  ? color.primaryContainer
                  : color.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(color: color.primary, width: 2)
                    : BorderSide.none,
              ),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon with stacking if subcategory selected
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(
                                cat.colorValue ?? color.primary.toARGB32(),
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconHelper.iconFromName(
                                cat.iconName ?? 'category',
                              ),
                              color: Color(
                                cat.colorValue ?? color.primary.toARGB32(),
                              ),
                              size: 20,
                            ),
                          ),
                          if (isChildSelected && _selectedCategory != null)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Color(
                                    _selectedCategory!.colorValue ??
                                        color.primary.toARGB32(),
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  IconHelper.iconFromName(
                                    _selectedCategory!.iconName ?? 'category',
                                  ),
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          if (hasSubcategories && !isChildSelected)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: color.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 12,
                                  color: color.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          isChildSelected && _selectedCategory != null
                              ? _selectedCategory!.name
                              : cat.name,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? color.onPrimaryContainer
                                : color.onSurface,
                          ),
                          maxLines: 1,
                        ),
                        if (isChildSelected && _selectedCategory != null)
                          Text(
                            cat.name,
                            style: textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? color.onPrimaryContainer.withValues(
                                      alpha: 0.7,
                                    )
                                  : color.onSurfaceVariant,
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
        } else {
          return GestureDetector(
            onTap: () => context.push('/add-category'),
            child: Card(
              elevation: 0,
              color: color.surfaceContainerHigh,
              child: SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: color.onSurfaceVariant),
                    const SizedBox(height: 4),
                    AdaptiveText(
                      ctxt.common_addLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
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
          ...subcategories.map(
            (sub) => ListTile(
              leading: Icon(
                IconHelper.iconFromName(sub.iconName ?? 'category'),
                color: Color(sub.colorValue ?? 0xFF000000),
              ),
              title: Text(sub.name),
              selected: selected?.id == sub.id,
              onTap: () => Navigator.pop(context, sub),
            ),
          ),
        ],
      ),
    );
  }
}
