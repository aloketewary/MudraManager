import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/shared/widgets/common_dropdown_field.dart';
import 'package:mudra_manager/shared/widgets/common_text_input_field.dart';

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

  final Map<int, TextEditingController> _allocCtrls = {};
  final List<Category> _selectedCats = [];
  final List<int> selectedCategories = [];
  BudgetRecurrence _recurrence = BudgetRecurrence.none;
  BudgetType _budgetType = BudgetType.categoryWise;
  final Map<int, bool> _expandedParents = {};

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
      _budgetType = widget.existing!.budgetType;
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

// Group categories by parent
  Map<Category?, List<Category>> _groupCategoriesByParent(
    List<Category> categories,
  ) {
    final Map<Category?, List<Category>> grouped = {};

    for (final cat in categories) {
      final parent = cat.parentCategory.value;
      if (!grouped.containsKey(parent)) {
        grouped[parent] = [];
      }
      grouped[parent]!.add(cat);
    }

    return grouped;
  }

  // Get all parent categories
  List<Category> _getParentCategories(List<Category> categories) {
    return categories.where((cat) => cat.parentCategory.value == null).toList();
  }

  // Get subcategories for a parent
  List<Category> _getSubcategories(List<Category> categories, Category parent) {
    return categories
        .where((cat) => cat.parentCategory.value?.id == parent.id)
        .toList();
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    HapticFeedback.lightImpact();
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
    // ── Entitlement check (new budgets only) ──
    if (widget.existing == null) {
      final canCreate = await ref.read(canCreateBudgetProvider.future);
      if (!canCreate) {
        SnackbarService.warning(
          'Free plan allows up to 2 budgets. Upgrade to Pro for unlimited.',
        );
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;
    final ctxt = AppLocalizations.of(context)!;

    if (_startDate == null || _endDate == null) {
      SnackbarService.error(ctxt.budget_pickBothDatesErrorText);
      return;
    }
    if (_budgetType == BudgetType.categoryWise && _selectedCats.isEmpty) {
      SnackbarService.error(ctxt.budget_selectAtLeastOneCategoryErrorText);
      return;
    }

    final service = ref.read(budgetServiceProvider);
    final isEditing = widget.existing != null;
    final totalAmount = double.parse(_amountC.text.trim());

    final bud = widget.existing ??
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
      ..recurrence = _recurrence
      ..budgetType = _budgetType;

    if (isEditing) {
      await bud.categories.load();
      await bud.allocations.load();
      await service.deleteAllocation(bud.allocations.toList());
      bud.categories.clear();
      bud.allocations.clear();
    }

    if (_budgetType == BudgetType.categoryWise) {
      final Map<Category, double?> enteredAllocations = {};
      for (final categoryId in selectedCategories) {
        final cat = _selectedCats.firstWhere((c) => c.id == categoryId);
        final raw = _allocCtrls[categoryId]?.text.trim() ?? '0';
        final value = raw.isNotEmpty ? double.tryParse(raw) : null;
        enteredAllocations[cat] = value;
      }

      final allocated = enteredAllocations.values.whereType<double>().toList();
      final remaining = totalAmount - allocated.fold(0.0, (a, b) => a + b);
      final unenteredCats = enteredAllocations.entries
          .where((e) => e.value == null)
          .map((e) => e.key)
          .toList();
      final distributeAmount =
          unenteredCats.isNotEmpty ? (remaining / unenteredCats.length) : 0.0;

      final totalAllocated = allocated.fold(0.0, (a, b) => a + b);
      final remainingBudget = totalAmount - totalAllocated;

      if (remainingBudget < 0) {
        SnackbarService.error(
          ctxt.budget_allocatedAmountExceedsTotalBudgetText,
        );
        return;
      }

      for (final categoryId in selectedCategories) {
        final cat = _selectedCats.firstWhere((c) => c.id == categoryId);
        bud.categories.add(cat);

        final alloc = BudgetCategoryAllocation()
          ..amount = enteredAllocations[cat] ?? distributeAmount;
        alloc.category.value = cat;
        alloc.budget.value = bud;

        bud.allocations.add(alloc);
      }
    }

    await service.save(bud);

    if (mounted) {
      HapticFeedback.mediumImpact();
      ref.invalidate(budgetServiceProvider);
      SnackbarService.success(
        isEditing
            ? 'Budget updated successfully'
            : 'Budget created successfully',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final catsAsync = ref.watch(categoryListProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final totalAmount = double.tryParse(_amountC.text.trim()) ?? 0;
    final totalAlloc = _selectedCats.fold<double>(
      0,
      (sum, cat) =>
          sum + (double.tryParse(_allocCtrls[cat.id]?.text ?? '') ?? 0),
    );
    final remaining = totalAmount - totalAlloc;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? ctxt.budget_buttonAddText
              : ctxt.budget_buttonEditText,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(LucideIcons.save),
            label: Text(
              widget.existing == null
                  ? ctxt.budget_saveButtonText.toUpperCase()
                  : ctxt.budget_updateButtonText.toUpperCase(),
            ),
          ),
          SizedBox(
            width: spacing.cardHorizontal,
          ),
        ],
      ),
      body: catsAsync.when(
        data: (cats) {
          final parentCategories = _getParentCategories(cats);
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(spacing.sectionGap),
                    children: [
                      // Budget Name
                      _buildSectionHeader(
                        'Basic Information',
                        LucideIcons.info,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),
                      CommonTextInputField(
                        controller: _nameC,
                        labelText: ctxt.budget_budgetNameControllerText,
                        iconData: Icons.pie_chart_outline,
                        validateField: (v) => v == null || v.isEmpty
                            ? ctxt.budget_nameRequiredHintText
                            : null,
                      ),

                      // Budget Amount
                      CommonTextInputField(
                        controller: _amountC,
                        labelText: ctxt.budget_budgetAmountControllerText,
                        iconData: Icons.currency_rupee,
                        inputType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validateField: (v) => v == null ||
                                double.tryParse(v) == null ||
                                double.parse(v) <= 0
                            ? ctxt.budget_amountRequiredHintText
                            : null,
                        onChanged: (v) => setState(() {}),
                      ),

                      SizedBox(height: spacing.sectionGap * 1.5),

                      // Date Range
                      _buildSectionHeader(
                        'Duration',
                        LucideIcons.calendar,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateButton(
                              context,
                              _startDate,
                              true,
                              ctxt.budget_selectStartDateText,
                              color,
                              textTheme,
                              ctxt,
                              spacing,
                            ),
                          ),
                          SizedBox(width: spacing.elementGap * 1.5),
                          Expanded(
                            child: _buildDateButton(
                              context,
                              _endDate,
                              false,
                              ctxt.budget_selectEndDateText,
                              color,
                              textTheme,
                              ctxt,
                              spacing,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing.sectionGap * 1.5),

                      // Budget Type
                      _buildSectionHeader(
                        'Budget Type',
                        LucideIcons.layoutGrid,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),
                      CommonDropdownField(
                        value: _budgetType,
                        items: BudgetType.values,
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.lightImpact();
                            setState(() => _budgetType = val);
                          }
                        },
                        labelText: 'Select Type',
                        itemBuilder: (BudgetType type) =>
                            Text(type.displayName),
                      ),

                      if (_budgetType == BudgetType.categoryWise) ...[
                        SizedBox(height: spacing.sectionGap * 1.5),

                        // Category Allocation
                        _buildSectionHeader(
                          'Category Allocation',
                          LucideIcons.tags,
                          color,
                          textTheme,
                          spacing,
                        ),
                        SizedBox(height: spacing.elementGap),

                        // Info Card
                        Container(
                          padding: EdgeInsets.all(spacing.cardInner),
                          decoration: BoxDecoration(
                            color: color.primaryContainer,
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                color: color.primary,
                                size: 20,
                              ),
                              SizedBox(width: spacing.elementGap),
                              Expanded(
                                child: Text(
                                  ctxt.budget_categoryMessageInfoText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: spacing.elementGap * 1.5),

                        // Budget Summary Card
                        Container(
                          padding: EdgeInsets.all(spacing.cardInner),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.tertiaryContainer,
                                color.tertiaryContainer.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusLarge),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Budget',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onTertiaryContainer,
                                        ),
                                      ),
                                      SizedBox(
                                        height: spacing.elementGap * 0.5,
                                      ),
                                      Text(
                                        '₹${totalAmount.toStringAsFixed(0)}',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Allocated',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: color.onTertiaryContainer,
                                        ),
                                      ),
                                      SizedBox(
                                        height: spacing.elementGap * 0.5,
                                      ),
                                      Text(
                                        '₹${totalAlloc.toStringAsFixed(0)}',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: color.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing.elementGap * 1.5),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(spacing.radiusSmall),
                                child: LinearProgressIndicator(
                                  value: totalAmount > 0
                                      ? (totalAlloc / totalAmount)
                                          .clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                  backgroundColor:
                                      color.surface.withValues(alpha: 0.5),
                                  valueColor: AlwaysStoppedAnimation(
                                    remaining < 0
                                        ? color.error
                                        : color.tertiary,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing.elementGap),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    remaining >= 0
                                        ? 'Remaining'
                                        : 'Over Budget',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.onTertiaryContainer,
                                    ),
                                  ),
                                  Text(
                                    '₹${remaining.abs().toStringAsFixed(0)}',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: remaining < 0
                                          ? color.error
                                          : color.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: spacing.elementGap * 1.5),

                        // Category List with Parent/Subcategory hierarchy
                        ...parentCategories.map((parent) {
                          final subcategories = _getSubcategories(cats, parent);
                          final hasSubcategories = subcategories.isNotEmpty;
                          final isParentExpanded =
                              _expandedParents[parent.id] ?? false;
                          final isParentSelected =
                              selectedCategories.contains(parent.id);

                          return Column(
                            children: [
                              // Parent Category
                              _buildCategoryCard(
                                parent,
                                isParentSelected,
                                hasSubcategories,
                                isParentExpanded,
                                color,
                                textTheme,
                                spacing,
                                isParent: true,
                                onToggleExpand: hasSubcategories
                                    ? () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _expandedParents[parent.id] =
                                              !isParentExpanded;
                                        });
                                      }
                                    : null,
                              ),

                              // Subcategories (shown when parent is expanded)
                              if (hasSubcategories && isParentExpanded)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: spacing.sectionGap * 1.5,
                                    top: spacing.elementGap * 0.5,
                                  ),
                                  child: Column(
                                    children: subcategories.map((subcat) {
                                      final isSubcatSelected =
                                          selectedCategories
                                              .contains(subcat.id);
                                      return _buildCategoryCard(
                                        subcat,
                                        isSubcatSelected,
                                        false,
                                        false,
                                        color,
                                        textTheme,
                                        spacing,
                                        isParent: false,
                                      );
                                    }).toList(),
                                  ),
                                ),

                              SizedBox(height: spacing.elementGap),
                            ],
                          );
                        }),
                      ],

                      SizedBox(height: spacing.sectionGap * 1.5),

                      // Recurrence
                      _buildSectionHeader(
                        'Recurrence',
                        LucideIcons.repeat,
                        color,
                        textTheme,
                        spacing,
                      ),
                      SizedBox(height: spacing.elementGap),
                      CommonDropdownField(
                        value: _recurrence,
                        items: BudgetRecurrence.values,
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.lightImpact();
                            setState(() => _recurrence = val);
                          }
                        },
                        labelText: ctxt.budget_recurrenceText,
                        itemBuilder: (BudgetRecurrence budget) => Row(
                          children: [
                            Text(ctxt.translate(budget.name).toTitleCase()),
                          ],
                        ),
                      ),

                      SizedBox(height: spacing.sectionGap * 5),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.primary),
        SizedBox(width: spacing.elementGap),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    DateTime? date,
    bool isStart,
    String placeholder,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            date != null ? color.primaryContainer : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: date != null
              ? color.primary.withValues(alpha: 0.5)
              : color.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _pickDate(context, isStart),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(spacing.cardInner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isStart ? LucideIcons.calendarCheck : LucideIcons.calendarX,
                    size: 16,
                    color:
                        date != null ? color.primary : color.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.elementGap * 0.5),
                  Text(
                    isStart ? 'Start Date' : 'End Date',
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          date != null ? color.primary : color.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.elementGap * 0.5),
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy', ctxt.localeName).format(date)
                    : placeholder,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: date != null
                      ? color.onPrimaryContainer
                      : color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Category cat,
    bool isSelected,
    bool hasSubcategories,
    bool isExpanded,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing, {
    required bool isParent,
    VoidCallback? onToggleExpand,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? color.primaryContainer.withValues(alpha: 0.3)
            : color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusLarge),
        border: Border.all(
          color: isSelected
              ? color.primary.withValues(alpha: 0.5)
              : color.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  _selectedCats.remove(cat);
                  _allocCtrls.remove(cat.id);
                  selectedCategories.remove(cat.id);
                } else {
                  _selectedCats.add(cat);
                  _allocCtrls[cat.id] = TextEditingController(
                    text: _allocCtrls[cat.id]?.text ?? '',
                  );
                  selectedCategories.add(cat.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(spacing.radiusLarge),
            child: Padding(
              padding: EdgeInsets.all(spacing.cardInner),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.elementGap),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.primary
                          : color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        spacing.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                      color:
                          isSelected ? color.onPrimary : color.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap * 1.5),
                  Expanded(
                    child: Row(
                      children: [
                        if (!isParent)
                          Padding(
                            padding: EdgeInsets.only(right: spacing.elementGap),
                            child: Icon(
                              LucideIcons.cornerDownRight,
                              size: 16,
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isParent ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSubcategories)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 20,
                        color: color.onSurfaceVariant,
                      ),
                      onPressed: onToggleExpand,
                    )
                  else if (isSelected)
                    Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: color.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.cardInner,
                0,
                spacing.cardInner,
                spacing.cardInner,
              ),
              child: CommonTextInputField(
                controller: _allocCtrls[cat.id],
                labelText: 'Allocate Amount',
                iconData: Icons.currency_rupee,
                inputType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
        ],
      ),
    );
  }
}
