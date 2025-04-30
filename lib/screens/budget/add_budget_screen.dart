import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/budget.dart'
    show Budget, BudgetRecurrence;
import 'package:mudra_manager/db/models/budget_category_allocation.dart'
    show BudgetCategoryAllocation;
import 'package:mudra_manager/db/models/category.dart' show Category;
import 'package:mudra_manager/providers/budget_service_provider.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_dropdown_field.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/util/case_extension.dart';

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
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick both dates')));
      return;
    }
    if (_selectedCats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one category')),
      );
      return;
    }

    final service = ref.read(budgetServiceProvider);

    final bud =
        widget.existing ??
        Budget.create(
          name: _nameC.text.trim(),
          amount: double.parse(_amountC.text),
          startDate: _startDate!,
          endDate: _endDate!,
        );
    bud.recurrence = _recurrence;

    if (widget.existing != null) {
      bud
        ..name = _nameC.text.trim()
        ..amount = double.parse(_amountC.text)
        ..startDate = _startDate!
        ..endDate = _endDate!;
      bud.recurrence = _recurrence;
      await bud.categories.load();
      await bud.allocations.load();
      bud.categories.clear();
      bud.allocations.clear();
    }

    // link categories and allocations
    for (final cat in _selectedCats) {
      bud.categories.add(cat);
      final allocAmt = double.tryParse(_allocCtrls[cat.id]!.text) ?? 0;
      final alloc = BudgetCategoryAllocation()..amount = allocAmt;
      alloc.category.value = cat;
      alloc.budget.value = bud;
      bud.allocations.add(alloc);
    }

    await service.save(bud);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoryListProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add Budget' : 'Edit Budget',
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
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
                          labelText: 'Budget Name',
                          iconData: Icons.pie_chart_outline,
                          validateField:
                              (v) =>
                                  v == null || v.isEmpty ? 'Enter name' : null,
                        ),
                        CommonTextInputField(
                          controller: _amountC,
                          labelText: 'Total Amount',
                          iconData: Icons.money,
                          inputType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validateField:
                              (v) =>
                                  v == null ||
                                          double.tryParse(v) == null ||
                                          double.parse(v) <= 0
                                      ? 'Enter valid amount'
                                      : null,
                        ),
                        const SizedBox(height: 16),

                        // Date pickers
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ), // Adjust the radius for more or less rounding
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () => _pickDate(context, true),
                                child: Text(
                                  _startDate == null
                                      ? 'Select Start Date'
                                      : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                onPressed: () => _pickDate(context, false),
                                child: Text(
                                  _endDate == null
                                      ? 'Select End Date'
                                      : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Categories & Allocations',
                          style: textTheme.titleMedium?.copyWith(
                            color: color.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...cats.map((cat) {
                          final isSelected = selectedCategories.contains(
                            cat.id,
                          );
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(cat.name),
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  _selectedCats.remove(cat);
                                  _allocCtrls.remove(cat.id);
                                  selectedCategories.remove(cat.id);
                                } else {
                                  _selectedCats.add(cat);
                                  _allocCtrls[cat.id] = TextEditingController(
                                    text: _allocCtrls[cat.id]?.text,
                                  );
                                  selectedCategories.add(cat.id);
                                }
                              });
                            },
                            secondary:
                                isSelected
                                    ? SizedBox(
                                      width: 120,
                                      child: CommonTextInputField(
                                        controller: _allocCtrls[cat.id],
                                        labelText: 'Alloc',
                                        iconData: Icons.numbers,
                                        inputType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                      ),
                                    )
                                    : null,
                          );
                        }),
                        const SizedBox(height: 16),

                        CommonDropdownField(
                          value:
                              widget.existing?.recurrence ??
                              BudgetRecurrence.none,
                          items: BudgetRecurrence.values,
                          onChanged: (val) {
                            if (val != null) setState(() => _recurrence = val);
                          },
                          labelText: 'Recurrence',
                          itemBuilder:
                              (BudgetRecurrence budget) => Row(
                                children: [Text(budget.name.toTitleCase())],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                CommonButton(
                  text: widget.existing == null ? 'save' : 'update',
                  onPressed: _save,
                  backGroundColor: color.secondary,
                  textColor: color.onSecondary,
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
