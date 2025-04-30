import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/account.dart' show Account;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/db/models/tag.dart' show GetTagCollection, Tag;
import 'package:mudra_manager/db/models/transaction.dart' show Transaction;
import 'package:mudra_manager/providers/account_providers.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/tag_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart';
import 'package:mudra_manager/screens/reusable/account_display_card.dart';
import 'package:mudra_manager/screens/reusable/category_card.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/screens/reusable/swipeable_week_calendar.dart';
import 'package:mudra_manager/util/icon_helper.dart' show IconHelper;

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
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "Add Transaction",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
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
                                  return AccountDisplayCard(
                                    title: account.name,
                                    amount:
                                        "₹${account.initialBalance.toStringAsFixed(2)}",
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
                    Text(
                      "Select Category",
                      style: textTheme.titleLarge?.copyWith(
                        color: color.primary,
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final categoriesAsync = ref.watch(categoryListProvider);
                        return categoriesAsync.when(
                          data: (categories) {
                            return SizedBox(
                              height: 90, // Adjust height as needed
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(16.0),
                                itemCount: categories.length + 1,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index < categories.length) {
                                    var category = categories[index];
                                    return CategoryCard(
                                      label: category.name,
                                      color: Color(
                                        category.colorValue ?? 0xFF000000,
                                      ),
                                      icon: IconHelper.iconFromName(
                                        category.iconName ??
                                            Icons.category.toString(),
                                      ),
                                      isSelected:
                                          _selectedCategory?.id == category.id,
                                      callbackAction: () {
                                        setState(
                                          () => _selectedCategory = category,
                                        );
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
                                            builder:
                                                (_) => AddEditCategoryScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
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
              backGroundColor: color.secondary,
              textColor: color.onSecondary,
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  // Save to DB here
                  final txn = Transaction.create(
                    date: _selectedDate,
                    amount: double.parse(_amountController.text),
                    isExpense: _isExpense,
                    description: _descController.text,
                  );
                  txn.id = widget.transaction?.id ?? -1;
                  txn.account.value = _selectedAccount!;
                  txn.category.value = _selectedCategory!;
                  txn.tags.clear();
                  txn.tags.addAll(selectedTags);
                  await ref.read(transactionProvider).addTransaction(txn);
                  invalidateAll(ref);
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
}
