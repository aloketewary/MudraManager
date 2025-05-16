import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/tag.dart' show GetTagCollection, Tag;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/notification_record_service.dart';
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/providers/tag_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart';
import 'package:mudra_manager/screens/reusable/account_display_card.dart';
import 'package:mudra_manager/screens/reusable/category_card.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/screens/reusable/simple_calculator.dart'
    show SimpleCalculator;
import 'package:mudra_manager/screens/reusable/swipeable_week_calendar.dart';
import 'package:mudra_manager/service/notification_service.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/string_util.dart';

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
  double leftBoxWidthFactor = 0.5;
  double rightBoxWidthFactor = 0.5;
  List<Tag> selectedTags = [];
  Map<int, double> _balanceMap = {};
  bool _initialized = false;
  bool _isCategoryExpanded = false;

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
      final balanceMap =
          ref.watch(accountServiceProvider).getAccountBalanceMap();
      balanceMap.then(
        (val) => {
          setState(() {
            _balanceMap = val;
          }),
        },
      );
      _initialized = true;
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
              Navigator.pop(context);
              onResult(value); // Pass result back to amount field
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "Add Transaction",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showCalculator(context, (calculatedValue) {
                _amountController.text =
                    calculatedValue.toString(); // populate your field
              });
            },
            icon: Icon(
              Icons.calculate_outlined,
              color: color.onPrimary,
              size: 24,
            ),
            // label: const Text("Calculator"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    SwipeableWeeklyCalendar(
                      allowFutureDateSelection: false,
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                      },
                      existingDateTime: _selectedDate,
                    ),
                    const SizedBox(height: 24),
                    CommonTextInputField(
                      controller: _amountController,
                      labelText: "Amount",
                      inputType: TextInputType.numberWithOptions(decimal: true),
                      iconData: Icons.money,
                      validateField:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter amount'
                                  : null,
                    ),
                    CommonTextInputField(
                      controller: _descController,
                      labelText: "Description (optional)",
                      iconData: Icons.description,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Select Account",
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final accountsAsync = ref.watch(accountsProvider);
                        return accountsAsync.when(
                          data: (accounts) {
                            return SizedBox(
                              height: 180, // Adjust height as needed
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(16.0),
                                itemCount: accounts.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var account = accounts[index];
                                  var totalBalance = _balanceMap[account.id]
                                      ?.toStringAsFixed(2);
                                  return AccountDisplayCard(
                                    title: account.name,
                                    amount: ctxt.formatLocalizedNumberWithSign(2, ctxt.localeName, totalBalance?.toDouble() ?? 0.0),
                                    accountType: account.accountType,
                                    startColor: color.onSecondary,
                                    endColor: Color(
                                      account.colorValue ?? 0xFF000000,
                                    ),
                                    isSelected:
                                        _selectedAccount?.id == account.id,
                                    accountNumber: account.accountNumber,
                                    callbackAction: () {
                                      setState(
                                        () => _selectedAccount = account,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                          loading:
                              () => SizedBox(
                                width: 50,
                                child: const CircularProgressIndicator(),
                              ),
                          error: (err, _) => Text('Error loading accounts'),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Category",
                          style: textTheme.titleLarge?.copyWith(
                            color: color.primary,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () {
                            setState(() {
                              _isCategoryExpanded = !_isCategoryExpanded;
                            });
                          },
                          icon: Icon(
                            _isCategoryExpanded
                                ? Icons.close_fullscreen
                                : Icons.open_in_full_outlined,
                          ),
                        ),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final categoriesAsync = ref.watch(categoryListProvider);
                        return categoriesAsync.when(
                          data: (categories) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              child: _isCategoryExpanded
                                  ? AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Wrap(
                                  key: const ValueKey('wrapView'),
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.spaceEvenly,
                                  runAlignment: WrapAlignment.spaceEvenly,
                                  children: [
                                    ...categories.map((cat) {
                                      return SizedBox(
                                        height: 60,
                                        child: CategoryCard(
                                          label: cat.name,
                                          color: Color(cat.colorValue ?? 0xFF000000),
                                          icon: IconHelper.iconFromName(
                                              cat.iconName ?? Icons.category.toString()),
                                          isSelected: _selectedCategory?.id == cat.id,
                                          callbackAction: () {
                                            setState(() => _selectedCategory = cat);
                                          },
                                          isUnderWrap: true,
                                        ),
                                      );
                                    }),
                                    CategoryCard(
                                      label: "Add New \nCategory",
                                      color: color.secondary,
                                      icon: Icons.add,
                                      isSelected: false,
                                      isNewCard: true,
                                      callbackAction: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddEditCategoryScreen(),
                                          ),
                                        );
                                      },
                                      isUnderWrap: true,
                                    ),
                                  ],
                                ),
                              )
                                  : AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  key: const ValueKey('listView'),
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: categories.length + 1,
                                    itemBuilder: (BuildContext context, int index) {
                                      if (index < categories.length) {
                                        var category = categories[index];
                                        return CategoryCard(
                                          label: category.name,
                                          color: Color(category.colorValue ?? 0xFF000000),
                                          icon: IconHelper.iconFromName(
                                              category.iconName ?? Icons.category.toString()),
                                          isSelected: _selectedCategory?.id == category.id,
                                          callbackAction: () {
                                            setState(() => _selectedCategory = category);
                                          },
                                        );
                                      } else {
                                        return CategoryCard(
                                          label: "Add New \nCategory",
                                          color: color.secondary,
                                          icon: Icons.add,
                                          isSelected: false,
                                          isNewCard: true,
                                          callbackAction: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AddEditCategoryScreen(),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Text('Error loading categories'),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: (leftBoxWidthFactor * 100).toInt(),
                          child: SizedBox(
                            // width: MediaQuery.of(context).size.width / 3,
                            child: GestureDetector(
                              onTap: () => {setState(() => _isExpense = true)},
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  color:
                                      _isExpense
                                          ? color.primary
                                          : Colors.transparent,
                                  // Light background color
                                  border: Border.all(
                                    color: color.primary,
                                    width: 2,
                                  ), // Subtle border
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      child: Icon(
                                        Icons.arrow_downward,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        "EXPENSE".toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelLarge?.copyWith(
                                          color:
                                              _isExpense
                                                  ? color.onPrimary
                                                  : color.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: (rightBoxWidthFactor * 100).toInt(),
                          child: SizedBox(
                            // width: MediaQuery.of(context).size.width / 3,
                            child: GestureDetector(
                              onTap: () => {setState(() => _isExpense = false)},
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color:
                                      !_isExpense
                                          ? color.primary
                                          : Colors.transparent,
                                  // Light background color
                                  border: Border.all(
                                    color: color.primary,
                                    width: 2,
                                  ), // Subtle border
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 16,
                                      child: Icon(Icons.arrow_upward, size: 16),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        "INCOME".toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelLarge?.copyWith(
                                          color:
                                              !_isExpense
                                                  ? color.onPrimary
                                                  : color.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Select Tags",
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final tagsAsync = ref.watch(tagListProvider);
                        return tagsAsync.when(
                          data: (tags) {
                            return Wrap(
                              spacing: 8,
                              children: [
                                ...tags.map((tag) {
                                  final isSelected = selectedTags
                                      .map((it) => it.id)
                                      .contains(tag.id);
                                  return FilterChip(
                                    showCheckmark: false,
                                    backgroundColor:
                                        isSelected
                                            ? color.primary
                                            : Colors.transparent,
                                    selectedColor:
                                        isSelected
                                            ? color.primary
                                            : Colors.transparent,
                                    avatar:
                                        isSelected
                                            ? Icon(
                                              Icons.tag,
                                              color: color.onPrimary,
                                            )
                                            : Icon(
                                              Icons.tag,
                                              color: color.primary,
                                            ),
                                    checkmarkColor: color.primary,
                                    side: BorderSide(
                                      color: color.primary,
                                      width: 1,
                                    ),
                                    label: Text(
                                      tag.name,
                                      style: textTheme.labelMedium?.copyWith(
                                        color:
                                            isSelected
                                                ? color.onPrimary
                                                : color.primary,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedTags.add(tag);
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                  );
                                }),
                                FilterChip(
                                  showCheckmark: false,
                                  backgroundColor: color.primary,
                                  avatar: Icon(
                                    Icons.tag,
                                    color: color.onPrimary,
                                  ),
                                  checkmarkColor: color.primary,
                                  side: BorderSide(
                                    color: color.primary,
                                    width: 1,
                                  ),
                                  label: Text(
                                    'Add New Tag',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: color.onPrimary,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      showAddTagBottomSheet(context, ref);
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Text('Error loading tags'),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            CommonButton(
              text: "Save Transaction",
              backGroundColor: color.primary,
              textColor: color.onPrimary,
              onPressed: () async {
                if (_selectedAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select one Account')),
                  );
                  return;
                }
                if (_selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select one Category')),
                  );
                  return;
                }
                if (_formKey.currentState?.validate() ?? false) {
                  // Save to DB here
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
                  invalidateAll(ref);
                  // Now check for alerts
                  await _checkLowBalance(txn.account.value);
                  await _checkBudgetOverspend(txn);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void showAddTagBottomSheet(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final isarService = ref.read(isarServiceProvider);

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
                'Add New Tag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Tag Name'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final tag = Tag()..name = name;
                    final isar = await isarService.getInstance();
                    await isar.writeTxn(() async {
                      await isar.tags.put(tag);
                    });
                    Navigator.pop(context);
                    ref.invalidate(tagListProvider); // Trigger refresh
                  }
                },
                child: const Text('Save Tag'),
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

  Future<void> _checkBudgetOverspend(Transaction txn) async {
    if (!txn.isExpense) return;
    var notificationService = ref.watch(notificationRecordServiceProvider);

    final now = DateTime.now();
    var budgetService = ref.read(budgetServiceProvider);
    final budgets = await budgetService.getFilterBudget(now);

    for (var budget in budgets) {
      final spent = await budgetService.calculateSpentAmount(budget);
      if (spent > budget.amount) {
        await notificationService.logNotification(
          title: 'Budget Exceeded Alert',
          body: 'Your budget "${budget.name}" has been exceeded.',
          type: 'budget_overspent',
        );
        await NotificationService.showLocalNotification(
          id: (2000 + budget.id).toInt(),
          title: 'Budget Exceeded!',
          body: 'Your budget "${budget.name}" has been exceeded.',
        );
      }
    }
  }
}
