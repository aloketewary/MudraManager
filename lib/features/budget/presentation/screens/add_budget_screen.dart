import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'dart:math' as math;
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
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
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
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
  final List<int> _selectedTagIds = [];
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
      _recurrence = widget.existing!.recurrence;
      // Load tags for tag-wise budgets
      if (_budgetType == BudgetType.tagWise) {
        widget.existing!.budgetTags.load().then((_) {
          for (final tag in widget.existing!.budgetTags) {
            _selectedTagIds.add(tag.id);
          }
          if (mounted) setState(() {});
        });
      }
      // Load category allocations
      _loadAllocations();
    }
  }

  Future<void> _loadAllocations() async {
    final budget = widget.existing!;
    await budget.allocations.load();
    var allocs = budget.allocations.toList();

    // Fallback: if IsarLinks is empty (old budgets before link fix),
    // query allocations directly by their budget backlink
    if (allocs.isEmpty) {
      final isar = await ref.read(isarServiceProvider).getInstance();
      allocs = await isar.budgetCategoryAllocations
          .filter()
          .budget((q) => q.idEqualTo(budget.id))
          .findAll();
    }

    for (final alloc in allocs) {
      await alloc.category.load();
      final cat = alloc.category.value;
      if (cat == null) continue;
      _selectedCats.add(cat);
      selectedCategories.add(cat.id);
      _allocCtrls[cat.id] = TextEditingController(
        text: alloc.amount.toString(),
      );
    }
    if (mounted) setState(() {});
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
    if (_budgetType == BudgetType.tagWise && _selectedTagIds.isEmpty) {
      SnackbarService.error('Please select at least one tag');
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
      await bud.budgetTags.load();

      // Get old allocations — fallback to backlink query for old budgets
      var oldAllocs = bud.allocations.toList();
      if (oldAllocs.isEmpty) {
        final isar = await ref.read(isarServiceProvider).getInstance();
        oldAllocs = await isar.budgetCategoryAllocations
            .filter()
            .budget((q) => q.idEqualTo(bud.id))
            .findAll();
      }
      await service.deleteAllocation(oldAllocs);
      bud.categories.clear();
      bud.allocations.clear();
      bud.budgetTags.clear();
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

    // Handle tag-wise budget
    if (_budgetType == BudgetType.tagWise) {
      final isar = await ref.read(isarServiceProvider).getInstance();
      for (final tagId in _selectedTagIds) {
        final tag = await isar.tags.get(tagId);
        if (tag != null) bud.budgetTags.add(tag);
      }
    }

    await service.save(bud);

    if (mounted) {
      HapticFeedback.mediumImpact();
      ref.invalidate(budgetServiceProvider);
      SnackbarService.success(
        isEditing
            ? BuddyMessages.budgetUpdated
            : BuddyMessages.budgetCreated,
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
                        iconData: currencyIcon(null),
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

                      // Quick suggestion chips
                      _buildQuickChips(color, textTheme, spacing),

                      // Dynamic slider
                      if (totalAmount > 0)
                        _buildSmartSlider(totalAmount, color, spacing),

                      // Live progress bar
                      if (widget.existing != null && totalAmount > 0)
                        _buildLiveProgress(totalAmount, color, textTheme, spacing),

                      // Smart predictive feedback
                      if (totalAmount > 0)
                        _buildSmartFeedback(totalAmount, color, textTheme, spacing),

                      SizedBox(height: spacing.sectionGap * 1.5),

                      // Recurrence (pick first — drives duration)
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
                            setState(() {
                              _recurrence = val;
                              _autoFillDates(val);
                            });
                          }
                        },
                        labelText: ctxt.budget_recurrenceText,
                        itemBuilder: (BudgetRecurrence budget) => Row(
                          children: [
                            Text(ctxt.translate(budget.name).toTitleCase()),
                          ],
                        ),
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
                                        '${formatCurrency(totalAmount, code: BaseCurrency.code)}',
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
                                        '${formatCurrency(totalAlloc, code: BaseCurrency.code)}',
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
                                    '${formatCurrency(remaining.abs(), code: BaseCurrency.code)}',
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

                      // Tag-wise budget UI
                      if (_budgetType == BudgetType.tagWise) ...[
                        SizedBox(height: spacing.sectionGap * 1.5),
                        _buildSectionHeader(
                          'Select Tags',
                          LucideIcons.tag,
                          color,
                          textTheme,
                          spacing,
                        ),
                        SizedBox(height: spacing.elementGap),
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
                                  'All expenses with selected tags will count towards this budget.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing.elementGap * 1.5),
                        Consumer(
                          builder: (context, ref, _) {
                            final tagsAsync = ref.watch(tagListProvider);
                            return tagsAsync.when(
                              data: (tags) {
                                if (tags.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No tags yet. Add tags to your transactions first.',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((tag) {
                                    final isSelected =
                                        _selectedTagIds.contains(tag.id);
                                    return FilterChip(
                                      label: Text(tag.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (selected) {
                                            _selectedTagIds.add(tag.id);
                                          } else {
                                            _selectedTagIds.remove(tag.id);
                                          }
                                        });
                                      },
                                      showCheckmark: true,
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () =>
                                  const CircularProgressIndicator(),
                              error: (_, __) => const SizedBox(),
                            );
                          },
                        ),
                      ],

                      SizedBox(height: spacing.sectionGap * 5),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => ListView(children: List.generate(3, (_) => const BudgetCardSkeleton())),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  // ── QUICK CHIPS ──

  Widget _buildQuickChips(ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    // Smart suggestions based on context
    final existing = widget.existing;
    final currentAmount = double.tryParse(_amountC.text) ?? 0;
    final spent = _getSpent();

    final suggestions = <int>[];
    if (existing != null && spent > 0) {
      // Based on current spending pattern
      suggestions.add(((spent * 1.2) / 500).round() * 500); // 20% buffer
      suggestions.add(((spent * 1.5) / 1000).round() * 1000); // 50% buffer
    }
    // Round number suggestions
    suggestions.addAll([1000, 2000, 5000, 10000, 20000, 50000]);

    // Deduplicate + filter + take top 4
    final chips = suggestions.toSet()
        .where((v) => v > 0 && v != currentAmount.round())
        .toList()..sort();
    final display = chips.take(4).toList();

    if (display.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: spacing.elementGap, bottom: spacing.elementGap),
      child: Wrap(
        spacing: spacing.elementGap,
        runSpacing: spacing.elementGap,
        children: display.map((v) {
          final isSelected = currentAmount.round() == v;
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _amountC.text = v.toString());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.elementGap * 1.5,
                vertical: spacing.elementGap,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.primary.withValues(alpha: 0.15)
                    : color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? color.primary
                      : color.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                formatCurrency(v.toDouble(), code: BaseCurrency.code),
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color.primary : color.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── DYNAMIC SLIDER ──

  Widget _buildSmartSlider(double amount, ColorScheme color, AppSpacing spacing) {
    // Dynamic range: max = max(amount * 2, 10000), snaps to round numbers
    final maxVal = math.max(amount * 2, 10000.0);
    final step = maxVal <= 10000 ? 500.0 : maxVal <= 50000 ? 1000.0 : 5000.0;
    final divisions = (maxVal / step).round().clamp(10, 200);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color.primary,
          inactiveTrackColor: color.primary.withValues(alpha: 0.1),
          thumbColor: color.primary,
          overlayColor: color.primary.withValues(alpha: 0.08),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(
          value: amount.clamp(0, maxVal),
          min: 0,
          max: maxVal,
          divisions: divisions,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            // Snap to step
            final snapped = (v / step).round() * step;
            setState(() => _amountC.text = snapped.round().toString());
          },
        ),
      ),
    );
  }

  // ── LIVE PROGRESS BAR ──

  Widget _buildLiveProgress(
    double newBudget, ColorScheme color, TextTheme textTheme, AppSpacing spacing,
  ) {
    final spent = _getSpent();
    final pct = newBudget > 0 ? (spent / newBudget).clamp(0.0, 1.0) : 0.0;
    final accent = pct > 0.9
        ? color.error
        : pct > 0.7
            ? Colors.orange
            : FinanceColors.incomeColor(Theme.of(context).brightness);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: accent.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCurrency(spent, code: BaseCurrency.code)} spent',
                style: textTheme.labelSmall?.copyWith(color: color.onSurfaceVariant),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}% used',
                style: textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SMART FEEDBACK ──

  Widget _buildSmartFeedback(
    double newAmount, ColorScheme color, TextTheme textTheme, AppSpacing spacing,
  ) {
    final spent = _getSpent();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final remaining = newAmount - spent;
    final safePerDay = daysLeft > 0 && remaining > 0 ? remaining / daysLeft : 0.0;
    final burnRate = spent / now.day;
    final projectedSpend = burnRate * daysInMonth;
    final daysUntilExceed = burnRate > 0 ? ((newAmount - spent) / burnRate).round() : 999;

    final String message;
    final IconData icon;
    final Color accent;

    if (newAmount < spent) {
      // 🔴 Already exceeded
      message = BuddyMessages.budgetAlreadySpent(formatCurrency(spent, code: BaseCurrency.code));
      icon = LucideIcons.triangleAlert;
      accent = color.error;
    } else if (projectedSpend > newAmount && daysUntilExceed < daysLeft) {
      // 🟣 Over-optimistic
      message = BuddyMessages.budgetMayExceedIn(daysUntilExceed);
      icon = LucideIcons.trendingUp;
      accent = Colors.deepPurple;
    } else if (remaining / newAmount < 0.2) {
      // 🟠 Tight
      message = BuddyMessages.budgetGettingTight(formatCurrency(remaining, code: BaseCurrency.code), daysLeft);
      icon = LucideIcons.clock;
      accent = Colors.orange;
    } else {
      // 🟢 Healthy
      message = BuddyMessages.budgetInControl(formatCurrency(safePerDay, code: BaseCurrency.code));
      icon = LucideIcons.shieldCheck;
      accent = FinanceColors.incomeColor(Theme.of(context).brightness);
    }

    // Daily impact comparison (before vs after)
    final oldBudget = widget.existing?.amount ?? 0;
    final oldDaily = daysLeft > 0 && oldBudget > spent ? (oldBudget - spent) / daysLeft : 0.0;
    final showComparison = widget.existing != null && oldBudget != newAmount && oldDaily > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.elementGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (showComparison) ...[
              SizedBox(height: spacing.elementGap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGap,
                  vertical: spacing.elementGapMin,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Text(
                  '${formatCurrency(oldDaily, code: BaseCurrency.code)}/day \u2192 ${formatCurrency(safePerDay, code: BaseCurrency.code)}/day',
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getSpent() {
    if (widget.existing == null) return 0;
    return ref.read(budgetsWithProgressProvider).valueOrNull
        ?.where((b) => b.budget.id == widget.existing!.id)
        .firstOrNull?.spent ?? 0.0;
  }

  void _autoFillDates(BudgetRecurrence recurrence) {
    final now = DateTime.now();
    switch (recurrence) {
      case BudgetRecurrence.daily:
        _startDate = now;
        _endDate = now;
        break;
      case BudgetRecurrence.weekly:
        _startDate = now;
        _endDate = now.add(const Duration(days: 6));
        break;
      case BudgetRecurrence.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetRecurrence.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case BudgetRecurrence.none:
        break;
    }
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
                iconData: currencyIcon(null),
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
