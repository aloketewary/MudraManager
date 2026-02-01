import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/account.dart' show Account, AccountType;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/tag.dart' show GetTagCollection, Tag;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/tag_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/providers/budget_alert_provider.dart';
import 'package:mudra_manager/screens/reusable/simple_calculator.dart'
    show SimpleCalculator;
import 'package:mudra_manager/service/notification_service.dart';
import 'package:mudra_manager/theme/app_colors.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/snackbar_service.dart';
import 'package:mudra_manager/service/budget_alert_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

    // Determine header color based on transaction type
    // Using simple logic for now: Expense = Error (Red), Income = Tertiary/Secondary (Green/Teal)
    // Adjust colors as per your specific palette intent.
    final headerColor =
        _isExpense
            ? color.error
            : const Color(
              0xFF00BFA5,
            ); // Hardcoded Teal/Green for income distinction if theme doesn't suffice

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onHeaderColor = AppColors.white;

    return Scaffold(
      backgroundColor: headerColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: onHeaderColor),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        centerTitle: true,
        title: Container(
          decoration: BoxDecoration(
            color: onHeaderColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypeToggle(
                ctxt.transaction_expenseButtonLabel,
                true,
                onHeaderColor,
              ),
              _buildTypeToggle(
                ctxt.transaction_incomeButtonLabel,
                false,
                onHeaderColor,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showCalculator(context, (calculatedValue) {
                _amountController.text = calculatedValue.toString();
              });
            },
            icon: Icon(Icons.calculate_outlined, color: onHeaderColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- TOP SECTION (Amount) ---
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ctxt.transaction_amountControllerText.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: onHeaderColor.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(
                      color: onHeaderColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 56,
                    ),
                    cursorColor: onHeaderColor,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: textTheme.displayLarge?.copyWith(
                        color: onHeaderColor.withValues(alpha: 0.5),
                        fontSize: 56,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      prefixText: _isExpense ? '- ' : '+ ',
                      prefixStyle: textTheme.displayLarge?.copyWith(
                        color: onHeaderColor,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? ctxt.transaction_amountControllerErrorText
                                : null,
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM SECTION (Details) ---
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.zero),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.only(
                      top: 32,
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    children: [
                      // 1. Account Section
                      Text(
                        ctxt.transaction_selectAccountLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, _) {
                          final accountsAsync = ref.watch(accountsProvider);
                          return accountsAsync.when(
                            data:
                                (accounts) => SizedBox(
                                  height: 130,
                                  child: _buildAccountListView(
                                    accounts,
                                    textTheme,
                                    color,
                                  ),
                                ),
                            loading: () => const SizedBox(height: 90),
                            error: (_, __) => const SizedBox(),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // 2. Category Section
                      Text(
                        ctxt.transaction_selectCategoryLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: color.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, _) {
                          final categoriesAsync = ref.watch(
                            categoryListProvider,
                          );
                          return categoriesAsync.when(
                            data:
                                (categories) => SizedBox(
                                  height: 120,
                                  child: _buildCategoryListView(
                                    categories,
                                    textTheme,
                                    color,
                                  ),
                                ),
                            loading: () => const SizedBox(height: 90),
                            error: (_, __) => const SizedBox(),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // 3. Date & Note (Combined Row)
                      Row(
                        children: [
                          // Date Picker
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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.outline.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: color.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_selectedDate),
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Note Input
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.outline.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: TextFormField(
                                controller: _descController,
                                decoration: InputDecoration(
                                  hintText:
                                      ctxt.transaction_descriptionControllerText,
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  icon: Icon(
                                    Icons.edit_note,
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4. Tags
                      Consumer(
                        builder: (context, ref, _) {
                          final tagsAsync = ref.watch(tagListProvider);
                          return tagsAsync.when(
                            data:
                                (tags) => Wrap(
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
                                              selectedTags.removeWhere(
                                                (t) => t.id == tag.id,
                                              );
                                            }
                                          });
                                        },
                                        backgroundColor:
                                            color.surfaceContainerHighest,
                                        selectedColor: color.primaryContainer
                                            .withValues(alpha: 0.5),
                                        labelStyle: TextStyle(
                                          color:
                                              isSelected
                                                  ? color.onPrimaryContainer
                                                  : color.onSurfaceVariant,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide.none,
                                        ),
                                        showCheckmark: false,
                                      );
                                    }),
                                    ActionChip(
                                      label: Text(
                                        ctxt.transaction_addNewTagText,
                                      ),
                                      avatar: const Icon(Icons.add, size: 16),
                                      onPressed:
                                          () => showAddTagBottomSheet(
                                            context,
                                            ref,
                                          ),
                                      backgroundColor:
                                          color.surfaceContainerHigh,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
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
                          backgroundColor: Colors.transparent,
                          foregroundColor: onHeaderColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          minimumSize: Size(double.infinity, 52),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.glassGradient(
                                headerColor,
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: headerColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: AppColors.glassShadow(
                              headerColor,
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ctxt.transaction_saveTransactionButtonLabel
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: headerColor,
                            ),
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

  Widget _buildTypeToggle(String label, bool isExpenseBtn, Color onColor) {
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
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.black : onColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final ctxt = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      if (_amountController.text.isEmpty ||
          double.tryParse(_amountController.text) == null) {
        SnackbarService.error('Please enter a valid amount.');
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

      txn.account.value = _selectedAccount!;
      txn.category.value = _selectedCategory!;
      txn.tags.clear();
      txn.tags.addAll(selectedTags);

      await ref.read(transactionProvider).addTransaction(txn);
      await _checkLowBalance(txn.account.value);
      await _checkBudgetAlerts(txn);
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: ctxt.transaction_tagNameControllerText,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.glassGradient(
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.glassShadow(
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    ctxt.transaction_saveTagButtonLabel,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    var accountsService = ref.watch(accountServiceProvider);
    var notificationService = ref.watch(notificationRecordServiceProvider);
    final currentBalance = await accountsService.getAccountBalance(account.id);
    var lowBalanceThreshold =
        SharedPrefsUtil.instance
            .getLowBalanceThreshold(); // Set your own threshold

    if (currentBalance < lowBalanceThreshold) {
      await notificationService.logNotification(
        title: 'Low Balance Alert',
        body:
            'Your account "${account.name}" has ₹${currentBalance.toStringAsFixed(2)} remaining.',
        type: 'low_balance',
      );
      await NotificationService.showLocalNotification(
        id: 1000 + account.id, // Unique per account
        title: 'Low Balance Alert',
        body:
            'Your balance in ${account.name} is ₹${currentBalance.toStringAsFixed(2)}.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 150,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient:
                  isSelected
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.glassGradient(
                          Color(
                            account.colorValue ?? AppColors.dark.toARGB32(),
                          ),
                          isDark,
                        ),
                      )
                      : null,
              border: Border.all(
                color:
                    isSelected
                        ? Color(
                          account.colorValue ?? AppColors.dark.toARGB32(),
                        ).withValues(alpha: 0.3)
                        : color.outline.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow:
                  isSelected
                      ? AppColors.glassShadow(
                        Color(account.colorValue ?? AppColors.dark.toARGB32()),
                        isDark,
                      )
                      : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Watermark Icon
                  // if (isSelected)
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        _getIconForAccountType(account.accountType),
                        size: 80,
                        color: (isSelected
                                ? AppColors.textColor(isDark)
                                : Color(
                                  account.colorValue ??
                                      AppColors.dark.toARGB32(),
                                ))
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.white : color.surface,
                            shape: BoxShape.circle,
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Color(
                                          account.colorValue ??
                                              AppColors.dark.toARGB32(),
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Icon(
                            _getIconForAccountType(account.accountType),
                            color:
                                isSelected
                                    ? Color(
                                      account.colorValue ??
                                          AppColors.dark.toARGB32(),
                                    )
                                    : color.onSurfaceVariant,
                            size: 20,
                          ),
                        ),

                        // Text Data
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? AppColors.textColor(
                                          isDark,
                                        ).withValues(alpha: 0.7)
                                        : color.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ctxt.formatCurrencyWithSign(
                                2,
                                balance,
                                compact: true,
                              ),
                              style: textTheme.labelLarge?.copyWith(
                                color:
                                    isSelected
                                        ? AppColors.textColor(
                                          isDark,
                                        ).withValues(alpha: 0.7)
                                        : color.onSurfaceVariant.withValues(
                                          alpha: 0.7,
                                        ),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index < categories.length) {
          final cat = categories[index];
          final isSelected = _selectedCategory?.id == cat.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient:
                    isSelected
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.glassGradient(
                            Color(cat.colorValue ?? AppColors.dark.toARGB32()),
                            isDark,
                          ),
                        )
                        : null,
                border: Border.all(
                  color:
                      isSelected
                          ? Color(
                            cat.colorValue ?? 0xFF000000,
                          ).withValues(alpha: 0.3)
                          : color.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow:
                    isSelected
                        ? AppColors.glassShadow(
                          Color(cat.colorValue ?? 0xFF000000),
                          Theme.of(context).brightness == Brightness.dark,
                        )
                        : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Watermark Icon
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Icon(
                          IconHelper.iconFromName(cat.iconName ?? 'category'),
                          size: 70,
                          color: (isSelected
                                ? AppColors.textColor(isDark)
                                : Color(
                                  cat.colorValue ??
                                      AppColors.dark.toARGB32(),
                                )).withValues(alpha: 0.15),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? AppColors.white : color.surface,
                              shape: BoxShape.circle,
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: Color(
                                            cat.colorValue ?? 0xFF000000,
                                          ).withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Icon(
                              IconHelper.iconFromName(
                                cat.iconName ?? 'category',
                              ),
                              color:
                                  isSelected
                                      ? Color(cat.colorValue ?? 0xFF000000)
                                      : color.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          Text(
                            cat.name,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected
                                      ? Color(cat.colorValue ?? 0xFF000000)
                                      : color.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Add Category Button
          return GestureDetector(
            onTap: () => context.push('/add-category'),
            child: Container(
              width: 80, // Slimmer for "Add"
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: color.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border.all(
                  color: color.outline.withValues(alpha: 0.5),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: color.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(
                    "Add",
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
