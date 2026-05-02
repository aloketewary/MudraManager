import 'package:isar_community/isar.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/shared/widgets/inline_error.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'dart:math' as math;
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
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
import 'package:mudra_manager/features/trip/data/trip_services_provider.dart';
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

  bool _allocationsLoaded = false;
  bool _saving = false;
  int _step = 0;
  static const _totalSteps = 4;
  String _categoryQuery = '';

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
      if (_budgetType == BudgetType.tagWise) {
        widget.existing!.budgetTags.load().then((_) {
          for (final tag in widget.existing!.budgetTags) {
            _selectedTagIds.add(tag.id);
          }
          if (mounted) setState(() {});
        });
      }
      _loadAllocations();
    } else {
      _allocationsLoaded = true;
    }
  }

  Future<void> _loadAllocations() async {
    final budget = widget.existing!;
    final isar = await ref.read(isarServiceProvider).getInstance();

    final allocs = await isar.budgetCategoryAllocations
        .filter()
        .budget((q) => q.idEqualTo(budget.id))
        .findAll();

    for (final alloc in allocs) {
      await alloc.category.load();
      final cat = alloc.category.value;
      if (cat == null) continue;
      _selectedCats.add(cat);
      selectedCategories.add(cat.id);
      _allocCtrls[cat.id] = TextEditingController(
        text: alloc.amount.toString(),
      );
      await cat.parentCategory.load();
      final parentId = cat.parentCategory.value?.id;
      if (parentId != null) {
        _expandedParents[parentId] = true;
      }
    }
    _allocationsLoaded = true;
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
    if (_saving) return;
    setState(() => _saving = true);
    final ctxt = AppLocalizations.of(context)!;
    // ── Entitlement check (new budgets only) ──
    if (widget.existing == null) {
      final canCreate = await ref.read(canCreateBudgetProvider.future);
      if (!canCreate) {
        setState(() => _saving = false);
        SnackbarService.warning(
          ctxt.budget_freePlanLimit,
        );
        return;
      }
    }
    if (!_formKey.currentState!.validate()) {
      setState(() => _saving = false);
      return;
    }

    if (_startDate == null || _endDate == null) {
      setState(() => _saving = false);
      SnackbarService.error(ctxt.budget_pickBothDatesErrorText);
      return;
    }
    if (_budgetType == BudgetType.categoryWise && _selectedCats.isEmpty) {
      setState(() => _saving = false);
      SnackbarService.error(ctxt.budget_selectAtLeastOneCategoryErrorText);
      return;
    }
    if (_budgetType == BudgetType.tagWise && _selectedTagIds.isEmpty) {
      setState(() => _saving = false);
      SnackbarService.error(ctxt.budget_selectAtLeastOneTag);
      return;
    }

    final service = ref.read(budgetServiceProvider);
    final isEditing = widget.existing != null;
    final totalAmount = double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;
    if (totalAmount <= 0) {
      setState(() => _saving = false);
      return;
    }

    final bud = widget.existing ??
        Budget.create(
          name: _nameC.text.trim(),
          amount: totalAmount,
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
      final isar = await ref.read(isarServiceProvider).getInstance();
      await bud.categories.load();
      await bud.budgetTags.load();

      final oldAllocs = await isar.budgetCategoryAllocations
          .filter()
          .budget((q) => q.idEqualTo(bud.id))
          .findAll();
      await service.deleteAllocation(oldAllocs);
      bud.categories.clear();
      bud.allocations.clear();
      bud.budgetTags.clear();
    }

    final newAllocations = <BudgetCategoryAllocation>[];

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
        setState(() => _saving = false);
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
        newAllocations.add(alloc);
      }
    }

    if (_budgetType == BudgetType.tagWise) {
      final isar = await ref.read(isarServiceProvider).getInstance();
      for (final tagId in _selectedTagIds) {
        final tag = await isar.tags.get(tagId);
        if (tag != null) bud.budgetTags.add(tag);
      }
    }

    await service.save(bud, newAllocations: newAllocations);

    if (context.mounted) {
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
    final catsAsync = ref.watch(expenseCategoriesProvider);
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
        leading: IconButton(
          tooltip: 'Close',
          icon: Icon(LucideIcons.x, color: color.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.existing == null
              ? ctxt.budget_buttonAddText
              : ctxt.budget_buttonEditText,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: catsAsync.when(
          data: (cats) {
            if (!_allocationsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final parentCategories = _getParentCategories(cats);
            return Column(
              children: [
                // ── STEP HEADER: Back + Progress + Counter + Next ──
                _buildStepHeader(color, textTheme, spacing, ctxt),
                // ── CONTENT ──
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStepContent(
                        _step, cats, parentCategories,
                        color, textTheme, spacing, ctxt,
                        totalAmount, totalAlloc, remaining,
                      ),
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

  // ── STEP ROUTER ──

  Widget _buildStepContent(
    int step, List<Category> cats, List<Category> parentCategories,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt, double totalAmount, double totalAlloc, double remaining,
  ) {
    return switch (step) {
      0 => _buildStep0(color, textTheme, spacing, ctxt, totalAmount),
      1 => _buildStep1(color, textTheme, spacing, ctxt),
      2 => _buildStep2(cats, parentCategories, color, textTheme, spacing, ctxt, totalAmount, totalAlloc, remaining),
      3 => _buildStep3(color, textTheme, spacing, ctxt, totalAmount, totalAlloc, remaining),
      _ => const SizedBox(),
    };
  }

  // ── BOTTOM NAV ──

  Widget _buildStepHeader(
    ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt,
  ) {
    final isFirst = _step == 0;
    final isLast = _step == _totalSteps - 1;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGap,
      ),
      child: Row(
        children: [
          // Back button
          _stepNavButton(
            icon: LucideIcons.chevronLeft,
            label: ctxt.common_back,
            onTap: isFirst ? null : _prevStep,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
          ),
          const Spacer(),
          // Progress pills + counter
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_totalSteps, (i) {
                  final active = i <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: spacing.elementGapUltraMin),
                    width: active ? 20 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? color.primary
                          : color.onSurfaceVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              SizedBox(height: spacing.elementGapUltraMin),
              Text(
                '${_step + 1}/$_totalSteps',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Next / Save button
          _stepNavButton(
            icon: isLast ? LucideIcons.check : LucideIcons.chevronRight,
            label: isLast
                ? (widget.existing == null
                    ? ctxt.budget_saveButtonText
                    : ctxt.budget_updateButtonText)
                : ctxt.common_next,
            onTap: (isLast && _saving) ? null : _nextStep,
            color: color,
            textTheme: textTheme,
            spacing: spacing,
            isPrimary: true,
            isLoading: isLast && _saving,
          ),
        ],
      ),
    );
  }

  Widget _stepNote(
    String text, ColorScheme color, TextTheme textTheme, AppSpacing spacing,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 18,
              color: color.primary,
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    final enabled = onTap != null && !isLoading;
    final fg = !enabled
        ? color.onSurfaceVariant.withValues(alpha: 0.3)
        : isPrimary
            ? color.primary
            : color.onSurfaceVariant;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap,
          vertical: spacing.elementGapMin,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPrimary) Icon(icon, size: 16, color: fg),
            if (!isPrimary) SizedBox(width: spacing.elementGapMin),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color.primary,
                ),
              )
            else
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            if (isPrimary && !isLoading) SizedBox(width: spacing.elementGapMin),
            if (isPrimary && !isLoading) Icon(icon, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  // ── STEP 0: NAME + AMOUNT ──

  Widget _buildStep0(
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt, double totalAmount,
  ) {
    return ListView(
      key: const ValueKey(0),
      padding: EdgeInsets.all(spacing.sectionGap),
      children: [
        _stepNote(ctxt.budget_stepNote0, color, textTheme, spacing),
        _buildSectionHeader(ctxt.budget_basicInfo, LucideIcons.info, color, textTheme, spacing),
        SizedBox(height: spacing.elementGap),
        CommonTextInputField(
          controller: _nameC,
          labelText: ctxt.budget_budgetNameControllerText,
          iconData: LucideIcons.chartPie,
          validateField: (v) => v == null || v.isEmpty
              ? ctxt.budget_nameRequiredHintText
              : null,
        ),
        SizedBox(height: spacing.elementGap),
        CommonTextInputField(
          controller: _amountC,
          labelText: ctxt.budget_budgetAmountControllerText,
          iconData: currencyIcon(null),
          inputType: const TextInputType.numberWithOptions(decimal: true),
          validateField: (v) => v == null ||
                  (double.tryParse(v.replaceAll(',', '')) ?? 0) <= 0
              ? ctxt.budget_amountRequiredHintText
              : null,
          onChanged: (v) => setState(() {}),
        ),
        _buildQuickChips(color, textTheme, spacing),
        if (totalAmount > 0)
          _buildSmartSlider(totalAmount, color, spacing),
        if (widget.existing != null && totalAmount > 0)
          _buildLiveProgress(totalAmount, color, textTheme, spacing),
        if (totalAmount > 0)
          _buildSmartFeedback(totalAmount, color, textTheme, spacing),
      ],
    );
  }

  // ── STEP 1: PERIOD ──

  Widget _buildStep1(
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return ListView(
      key: const ValueKey(1),
      padding: EdgeInsets.all(spacing.sectionGap),
      children: [
        _stepNote(ctxt.budget_stepNote1, color, textTheme, spacing),
        _buildSectionHeader(ctxt.budget_recurrenceText, LucideIcons.repeat, color, textTheme, spacing),
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
            children: [Text(ctxt.translate(budget.name).toTitleCase())],
          ),
        ),
        SizedBox(height: spacing.sectionGap * 1.5),
        _buildSectionHeader(ctxt.budget_duration, LucideIcons.calendar, color, textTheme, spacing),
        SizedBox(height: spacing.elementGap),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(context, _startDate, true, ctxt.budget_selectStartDateText, color, textTheme, ctxt, spacing),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: _buildDateButton(context, _endDate, false, ctxt.budget_selectEndDateText, color, textTheme, ctxt, spacing),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 2: CATEGORIES / TAGS ──

  Widget _buildStep2(
    List<Category> cats, List<Category> parentCategories,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt, double totalAmount, double totalAlloc, double remaining,
  ) {
    return ListView(
      key: const ValueKey(2),
      padding: EdgeInsets.all(spacing.sectionGap),
      children: [
        _stepNote(ctxt.budget_stepNote2, color, textTheme, spacing),
        _buildSectionHeader(ctxt.budget_budgetType, LucideIcons.layoutGrid, color, textTheme, spacing),
        SizedBox(height: spacing.elementGap),
        // Budget type selector
        Wrap(
          spacing: spacing.elementGap,
          runSpacing: spacing.elementGap,
          children: BudgetType.values.map((type) {
            final isActive = _budgetType == type;
            final isTravel = type == BudgetType.travel;
            final activeTripAsync = isTravel ? ref.watch(activeTripProvider) : null;
            final hasActiveTrip = activeTripAsync?.value != null;
            final isDisabled = isTravel && !hasActiveTrip;
            return GestureDetector(
              onTap: isDisabled
                  ? () => SnackbarService.warning(ctxt.budget_noActiveTrip)
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() => _budgetType = type);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.elementGap,
                ),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? color.surfaceContainerLow.withValues(alpha: 0.5)
                      : isActive
                          ? color.primary.withValues(alpha: 0.1)
                          : color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: isActive
                        ? color.primary
                        : color.outlineVariant.withValues(alpha: isDisabled ? 0.2 : 0.4),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.localizedName(ctxt),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isDisabled
                                ? color.onSurfaceVariant.withValues(alpha: 0.4)
                                : isActive
                                    ? color.primary
                                    : color.onSurface,
                          ),
                        ),
                        if (isDisabled) ...[
                          SizedBox(width: spacing.elementGapMin),
                          Icon(
                            LucideIcons.lock,
                            size: 12,
                            color: color.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: spacing.elementGapUltraMin),
                    Text(
                      isDisabled
                          ? ctxt.budget_noActiveTrip
                          : type.localizedDesc(ctxt),
                      style: textTheme.labelSmall?.copyWith(
                        color: isDisabled
                            ? color.onSurfaceVariant.withValues(alpha: 0.4)
                            : color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: spacing.sectionGap),

        if (_budgetType == BudgetType.categoryWise) ...[
          // Allocation summary
          if (totalAmount > 0) ...[
            _buildAllocationSummary(totalAmount, totalAlloc, remaining, color, textTheme, spacing, ctxt),
            SizedBox(height: spacing.sectionGap),
          ],
          _buildSectionHeader(ctxt.budget_selectCategories, LucideIcons.tags, color, textTheme, spacing),
          SizedBox(height: spacing.elementGap),
          // Search
          TextField(
            onChanged: (v) => setState(() => _categoryQuery = v.trim().toLowerCase()),
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing.cardInner,
                vertical: spacing.elementGap,
              ),
              hintText: ctxt.budget_selectCategories,
              prefixIcon: Icon(LucideIcons.search, size: 18, color: color.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                borderSide: BorderSide(color: color.primary, width: 2),
              ),
            ),
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          // Category chips grouped by parent
          ...parentCategories.where((p) {
            if (_categoryQuery.isEmpty) return true;
            final subs = _getSubcategories(cats, p);
            return p.name.toLowerCase().contains(_categoryQuery) ||
                subs.any((s) => s.name.toLowerCase().contains(_categoryQuery));
          }).map((parent) {
            final subcategories = _getSubcategories(cats, parent);
            final allInGroup = [parent, ...subcategories].where((c) {
              if (_categoryQuery.isEmpty) return true;
              return c.name.toLowerCase().contains(_categoryQuery);
            }).toList();
            if (allInGroup.isEmpty) return const SizedBox.shrink();
            final isParentSelected = selectedCategories.contains(parent.id);
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGap * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parent.name,
                    style: textTheme.labelMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Wrap(
                    spacing: spacing.elementGap,
                    runSpacing: spacing.elementGap,
                    children: allInGroup.map((cat) {
                      final isChild = cat.parentCategory.value != null;
                      final isSelected = selectedCategories.contains(cat.id);
                      // Disable child if parent is selected
                      final isDisabled = isChild && isParentSelected;
                      final catColor = cat.colorValue != null
                          ? Color(cat.colorValue!)
                          : color.primary;
                      return GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (isSelected) {
                                    _selectedCats.removeWhere((c) => c.id == cat.id);
                                    _allocCtrls.remove(cat.id);
                                    selectedCategories.remove(cat.id);
                                  } else {
                                    if (!selectedCategories.contains(cat.id)) {
                                      _selectedCats.add(cat);
                                      _allocCtrls[cat.id] = TextEditingController(
                                        text: _allocCtrls[cat.id]?.text ?? '',
                                      );
                                      selectedCategories.add(cat.id);
                                    }
                                    // If selecting parent, deselect its children
                                    if (!isChild) {
                                      for (final sub in subcategories) {
                                        _selectedCats.removeWhere((c) => c.id == sub.id);
                                        _allocCtrls.remove(sub.id);
                                        selectedCategories.remove(sub.id);
                                      }
                                    }
                                  }
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.elementGap,
                            vertical: spacing.elementGapMin,
                          ),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? color.surfaceContainerLow.withValues(alpha: 0.5)
                                : isSelected
                                    ? catColor.withValues(alpha: 0.15)
                                    : color.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(spacing.radiusMedium),
                            border: Border.all(
                              color: isDisabled
                                  ? color.outlineVariant.withValues(alpha: 0.2)
                                  : isSelected
                                      ? catColor
                                      : color.outlineVariant.withValues(alpha: 0.4),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDisabled
                                      ? color.surfaceContainerHighest.withValues(alpha: 0.5)
                                      : isSelected
                                          ? catColor.withValues(alpha: 0.15)
                                          : color.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                                ),
                                child: Icon(
                                  IconHelper.getIconData(cat.iconName),
                                  size: 14,
                                  color: isDisabled
                                      ? color.onSurfaceVariant.withValues(alpha: 0.3)
                                      : isSelected
                                          ? catColor
                                          : color.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(width: spacing.elementGapMin),
                              Text(
                                cat.name,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isDisabled
                                      ? color.onSurfaceVariant.withValues(alpha: 0.3)
                                      : isSelected
                                          ? catColor
                                          : color.onSurface,
                                ),
                              ),
                              if (isSelected) ...[
                                SizedBox(width: spacing.elementGapMin),
                                Icon(LucideIcons.check, size: 14, color: catColor),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          // Allocation inputs for selected categories
          if (_selectedCats.isNotEmpty) ...[
            SizedBox(height: spacing.sectionGap),
            _buildSectionHeader(ctxt.budget_categoryAllocation, LucideIcons.slidersHorizontal, color, textTheme, spacing),
            SizedBox(height: spacing.elementGap),
            ..._selectedCats.map((cat) {
              final catColor = cat.colorValue != null
                  ? Color(cat.colorValue!)
                  : color.primary;
              return Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Icon(
                      IconHelper.getIconData(cat.iconName),
                      size: 16,
                      color: catColor,
                    ),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      cat.name,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: TextField(
                        controller: _allocCtrls[cat.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: spacing.elementGap,
                            vertical: spacing.elementGap,
                          ),
                          hintText: '0',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: color.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(spacing.radiusSmall),
                            borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(spacing.radiusSmall),
                            borderSide: BorderSide(color: catColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],

        if (_budgetType == BudgetType.tagWise) ...[
          _buildSectionHeader(ctxt.budget_selectTags, LucideIcons.tag, color, textTheme, spacing),
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: color.primary, size: 20),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(ctxt.budget_tagInfo, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
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
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: spacing.sectionGap),
                        child: Text(ctxt.budget_noTags, style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
                      ),
                    );
                  }
                  return Wrap(
                    spacing: spacing.elementGap,
                    runSpacing: spacing.elementGap,
                    children: tags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (selected) { _selectedTagIds.add(tag.id); } else { _selectedTagIds.remove(tag.id); }
                          });
                        },
                        showCheckmark: true,
                      );
                    }).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const InlineError(),
              );
            },
          ),
        ],
        SizedBox(height: spacing.sectionGap * 3),
      ],
    );
  }

  // ── STEP 3: REVIEW ──

  Widget _buildStep3(
    ColorScheme color, TextTheme textTheme, AppSpacing spacing,
    AppLocalizations ctxt, double totalAmount, double totalAlloc, double remaining,
  ) {
    return ListView(
      key: const ValueKey(3),
      padding: EdgeInsets.all(spacing.sectionGap),
      children: [
        _stepNote(ctxt.budget_stepNote3, color, textTheme, spacing),
        _buildSectionHeader(ctxt.budget_reviewTitle, LucideIcons.clipboardCheck, color, textTheme, spacing),
        SizedBox(height: spacing.elementGap),
        // Name + Amount → tap to go to step 0
        _reviewCard(
          step: 0,
          icon: LucideIcons.chartPie,
          title: _nameC.text.trim(),
          subtitle: formatCurrency(totalAmount, code: BaseCurrency.code),
          color: color,
          textTheme: textTheme,
          spacing: spacing,
        ),
        SizedBox(height: spacing.elementGap),

        // Period → tap to go to step 1
        _reviewCard(
          step: 1,
          icon: LucideIcons.calendar,
          title: ctxt.translate(_recurrence.name).toTitleCase(),
          subtitle: (_startDate != null && _endDate != null)
              ? '${DateFormat('dd MMM', ctxt.localeName).format(_startDate!)} — ${DateFormat('dd MMM yyyy', ctxt.localeName).format(_endDate!)}'
              : ctxt.budget_pickBothDatesErrorText,
          color: color,
          textTheme: textTheme,
          spacing: spacing,
        ),
        SizedBox(height: spacing.elementGap),

        // Categories / Tags → tap to go to step 2
        _reviewCard(
          step: 2,
          icon: _budgetType == BudgetType.tagWise ? LucideIcons.tag : LucideIcons.tags,
          title: _budgetType.localizedName(ctxt),
          subtitle: _budgetType == BudgetType.categoryWise
              ? ctxt.budget_categoriesCount(_selectedCats.length)
              : ctxt.budget_tagsCount(_selectedTagIds.length),
          color: color,
          textTheme: textTheme,
          spacing: spacing,
        ),

        // Category allocation breakdown
        if (_budgetType == BudgetType.categoryWise && _selectedCats.isNotEmpty) ...[
          SizedBox(height: spacing.sectionGap),
          if (totalAmount > 0)
            _buildAllocationSummary(totalAmount, totalAlloc, remaining, color, textTheme, spacing, ctxt),
          SizedBox(height: spacing.elementGap),
          ..._selectedCats.map((cat) {
            final allocAmount = double.tryParse(_allocCtrls[cat.id]?.text ?? '') ?? 0;
            final autoDistributed = allocAmount == 0 && totalAmount > 0;
            final displayAmount = autoDistributed
                ? _computeAutoAlloc(totalAmount, totalAlloc, allocAmount)
                : allocAmount;
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.elementGapMin),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.elementGap,
                ),
                decoration: BoxDecoration(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.circle, size: 8, color: color.primary),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CurrencyText(
                      amount: displayAmount,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: autoDistributed ? color.onSurfaceVariant : color.onSurface,
                      ),
                    ),
                    if (autoDistributed) ...[
                      SizedBox(width: spacing.elementGapMin),
                      Text(
                        ctxt.budget_autoDistributed,
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],

        SizedBox(height: spacing.sectionGap * 3),
      ],
    );
  }

  double _computeAutoAlloc(double total, double manualAlloc, double thisAlloc) {
    final unallocated = total - manualAlloc;
    final autoCount = _selectedCats.where((c) {
      final v = double.tryParse(_allocCtrls[c.id]?.text ?? '') ?? 0;
      return v == 0;
    }).length;
    return autoCount > 0 ? unallocated / autoCount : 0;
  }

  Widget _reviewCard({
    required int step,
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _step = step);
      },
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGap * 0.75),
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(icon, size: 20, color: color.primary),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.pencil,
              size: 16,
              color: color.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── ALLOCATION SUMMARY ──

  Widget _buildAllocationSummary(
    double totalAmount, double totalAlloc, double remaining,
    ColorScheme color, TextTheme textTheme, AppSpacing spacing, AppLocalizations ctxt,
  ) {
    return Container(
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
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctxt.budget_totalBudget, style: textTheme.bodySmall?.copyWith(color: color.onTertiaryContainer)),
                  SizedBox(height: spacing.elementGapUltraMin),
                  CurrencyText(amount: totalAmount, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color.onTertiaryContainer)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ctxt.budget_allocated, style: textTheme.bodySmall?.copyWith(color: color.onTertiaryContainer)),
                  SizedBox(height: spacing.elementGapUltraMin),
                  CurrencyText(amount: totalAlloc, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color.onTertiaryContainer)),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap),
          ClipRRect(
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            child: LinearProgressIndicator(
              semanticsLabel: 'Progress',
              value: totalAmount > 0 ? (totalAlloc / totalAmount).clamp(0.0, 1.0) : 0,
              minHeight: 6,
              backgroundColor: color.surface.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(remaining < 0 ? color.error : color.tertiary),
            ),
          ),
          SizedBox(height: spacing.elementGapMin),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(remaining >= 0 ? ctxt.budget_remaining : ctxt.budget_overBudget, style: textTheme.bodySmall?.copyWith(color: color.onTertiaryContainer)),
              CurrencyText(amount: remaining.abs(), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: remaining < 0 ? color.error : color.onTertiaryContainer)),
            ],
          ),
        ],
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
            ? FinanceColors.statusWarning
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
                semanticsLabel: 'Progress',
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
      accent = FinanceColors.statusWarning;
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
    return ref.read(budgetsWithProgressProvider).value
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

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_nameC.text.trim().isEmpty) {
          SnackbarService.error(AppLocalizations.of(context)!.budget_nameRequiredHintText);
          return false;
        }
        final amt = double.tryParse(_amountC.text.trim());
        if (amt == null || amt <= 0) {
          SnackbarService.error(AppLocalizations.of(context)!.budget_amountRequiredHintText);
          return false;
        }
        return true;
      case 1:
        if (_startDate == null || _endDate == null) {
          SnackbarService.error(AppLocalizations.of(context)!.budget_pickBothDatesErrorText);
          return false;
        }
        return true;
      case 2:
        final ctxt = AppLocalizations.of(context)!;
        if (_budgetType == BudgetType.categoryWise && _selectedCats.isEmpty) {
          SnackbarService.error(ctxt.budget_selectAtLeastOneCategoryErrorText);
          return false;
        }
        if (_budgetType == BudgetType.tagWise && _selectedTagIds.isEmpty) {
          SnackbarService.error(ctxt.budget_selectAtLeastOneTag);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep()) return;
    HapticFeedback.lightImpact();
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      setState(() => _step--);
    } else {
      context.pop();
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
                    isStart ? ctxt.budget_startDate : ctxt.budget_endDate,
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
}
