import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/db/models/budget.dart'
    show Budget, BudgetRecurrence;
import 'package:mudra_manager/db/models/budget_category_allocation.dart'
    show BudgetCategoryAllocation;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_dropdown_field.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? existing;

  const AddBudgetScreen({super.key, this.existing});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameC;
  late TextEditingController _amountC;
  DateTime? _startDate;
  DateTime? _endDate;

  // category allocations in progress
  final Map<int, TextEditingController> _allocCtrls = {};
  final List<Category> _selectedCats = [];
  final List<int> selectedCategories = [];
  BudgetRecurrence _recurrence = BudgetRecurrence.none;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.existing?.name);
    _amountC = TextEditingController(
      text: widget.existing != null ? widget.existing!.amount.toString() : '',
    );

    if (widget.existing != null) {
      _startDate = widget.existing!.startDate;
      _endDate = widget.existing!.endDate;
      // load existing allocations
      widget.existing!.allocations.load().then((_) {
        for (final alloc in widget.existing!.allocations) {
          alloc.category.load().then((_) {
            final cat = alloc.category.value!;
            _selectedCats.add(cat);
            selectedCategories.add(cat.id);
            _allocCtrls[cat.id] = TextEditingController(
              text: alloc.amount.toString(),
            );
            setState(() {});
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _amountC.dispose();
    for (final c in _allocCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final now = DateTime.now();
    final def = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await showDatePicker(
      context: ctx,
      initialDate: def,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ctxt = AppLocalizations.of(context)!;

    if (_startDate == null || _endDate == null) {
      SnackbarService.error(ctxt.budget_pickBothDatesErrorText);
      return;
    }
    if (_selectedCats.isEmpty) {
      SnackbarService.error(ctxt.budget_selectAtLeastOneCategoryErrorText);
      return;
    }

    final service = ref.read(budgetServiceProvider);
    final isEditing = widget.existing != null;
    final totalAmount = double.parse(_amountC.text.trim());

    // Parse entered allocations
    final Map<Category, double?> enteredAllocations = {};
    for (final categoryId in selectedCategories) {
      final cat = _selectedCats.firstWhere((c) => c.id == categoryId);
      final raw = _allocCtrls[categoryId]?.text.trim() ?? '0';
      final value = raw.isNotEmpty ? double.tryParse(raw) : null;
      enteredAllocations[cat] = value;
    }

    // Compute how to distribute unentered allocations
    final allocated = enteredAllocations.values.whereType<double>().toList();
    final remaining = totalAmount - allocated.fold(0.0, (a, b) => a + b);
    final unenteredCats =
        enteredAllocations.entries
            .where((e) => e.value == null)
            .map((e) => e.key)
            .toList();
    final distributeAmount =
        unenteredCats.isNotEmpty ? (remaining / unenteredCats.length) : 0.0;

    // Validate manually entered allocations
    final totalAllocated = allocated.fold(0.0, (a, b) => a + b);
    final remainingBudget = totalAmount - totalAllocated;

    if (remainingBudget < 0) {
      SnackbarService.error(ctxt.budget_allocatedAmountExceedsTotalBudgetText);
      return;
    }

    final bud =
        widget.existing ??
        Budget.create(
          name: _nameC.text.trim(),
          amount: double.parse(_amountC.text),
          startDate: _startDate!,
          endDate: _endDate!,
        );
    bud.recurrence = _recurrence;

    bud
      ..name = _nameC.text.trim()
      ..amount = totalAmount
      ..startDate = _startDate!
      ..endDate = _endDate!
      ..recurrence = _recurrence;

    if (isEditing) {
      await bud.categories.load();
      await bud.allocations.load();
      // ⚠️ Clear existing allocations from DB
      await service.deleteAllocation(bud.allocations.toList());

      bud.categories.clear();
      bud.allocations.clear();
    }

    // Link selected categories and apply allocations
    for (final categoryId in selectedCategories) {
      final cat = _selectedCats.firstWhere((c) => c.id == categoryId);
      bud.categories.add(cat);

      final alloc =
          BudgetCategoryAllocation()
            ..amount = enteredAllocations[cat] ?? distributeAmount;
      alloc.category.value = cat;
      alloc.budget.value = bud;

      bud.allocations.add(alloc);
    }

    await service.save(bud);

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoryListProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final totalAlloc = _selectedCats.fold<double>(
      0,
      (sum, cat) =>
          sum + (double.tryParse(_allocCtrls[cat.id]?.text ?? '') ?? 0),
    );
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? ctxt.budget_buttonAddText
              : ctxt.budget_buttonEditText,
          style: textTheme.titleLarge,
        ),
      ),
      body: catsAsync.when(
        data: (cats) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        CommonTextInputField(
                          controller: _nameC,
                          labelText: ctxt.budget_budgetNameControllerText,
                          iconData: Icons.pie_chart_outline,
                          validateField:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? ctxt.budget_nameRequiredHintText
                                      : null,
                        ),
                        CommonTextInputField(
                          controller: _amountC,
                          labelText: ctxt.budget_budgetAmountControllerText,
                          iconData: Icons.money,
                          inputType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validateField:
                              (v) =>
                                  v == null ||
                                          double.tryParse(v) == null ||
                                          double.parse(v) <= 0
                                      ? ctxt.budget_amountRequiredHintText
                                      : null,
                        ),
                        const SizedBox(height: 16),

                        // Date pickers
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: color.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ), // Adjust the radius for more or less rounding
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () {
              HapticFeedback.mediumImpact();
              _pickDate(context, true);
            },
                                child: Text(
                                  _startDate == null
                                      ? ctxt.budget_selectStartDateText
                                      : ctxt.budget_selectedStartDateText(
                                        DateFormat(
                                          'dd-MM-yyyy',
                                          ctxt.localeName,
                                        ).format(_startDate!),
                                      ),
                                  style: textTheme.labelLarge?.copyWith(
                                    color: color.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () {
              HapticFeedback.mediumImpact();
              _pickDate(context, false);
            },
                                child: Text(
                                  _endDate == null
                                      ? ctxt.budget_selectEndDateText
                                      : ctxt.budget_selectedEndDateText(
                                        DateFormat(
                                          'dd-MM-yyyy',
                                          ctxt.localeName,
                                        ).format(_endDate!),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ctxt.budget_categoryTitle,
                          style: textTheme.titleMedium?.copyWith(
                            color: color.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            ctxt.budget_categoryMessageInfoText,
                            style: textTheme.labelMedium,
                            textAlign: TextAlign.justify,
                          ),
                          tileColor: color.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        ...cats.map((cat) {
                          final isSelected = selectedCategories.contains(
                            cat.id,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedCats.remove(cat);
                                            _allocCtrls.remove(cat.id);
                                            selectedCategories.remove(cat.id);
                                          } else {
                                            _selectedCats.add(cat);
                                            _allocCtrls[cat
                                                .id] = TextEditingController(
                                              text:
                                                  _allocCtrls[cat.id]?.text ??
                                                  '',
                                            );
                                            selectedCategories.add(cat.id);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            cat.name,
                                            style: textTheme.titleMedium,
                                          ),
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: CommonTextInputField(
                                                controller: _allocCtrls[cat.id],
                                                labelText:
                                                    ctxt.budget_allocateAmountText,
                                                iconData: Icons.numbers,
                                                inputType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        Text(
                          ctxt.budget_totalAllocatedBudgetText(
                            ctxt.formatCurrencyWithSign(0, totalAlloc),
                          ),
                          style: textTheme.titleMedium?.copyWith(
                            color: color.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CommonDropdownField(
                          value:
                              widget.existing?.recurrence ??
                              BudgetRecurrence.none,
                          items: BudgetRecurrence.values,
                          onChanged: (val) {
                            if (val != null) setState(() => _recurrence = val);
                          },
                          labelText: ctxt.budget_recurrenceText,
                          itemBuilder:
                              (BudgetRecurrence budget) => Row(
                                children: [
                                  Text(
                                    ctxt.translate(budget.name).toTitleCase(),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                CommonButton(
                  text:
                      widget.existing == null
                          ? ctxt.budget_saveButtonText
                          : ctxt.budget_updateButtonText,
                  onPressed: _save,
                  backGroundColor: color.primary,
                  textColor: color.onPrimary,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
