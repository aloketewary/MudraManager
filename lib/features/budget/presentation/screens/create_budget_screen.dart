import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/budget_category_allocation.dart';
import 'package:mudra_manager/core/db/models/budget_type.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/extension/localization_extenstion.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/features/budget/data/category_spending_history_provider.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/trip/data/trip_services_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';

/// Budget period presets.
enum _BudgetPeriod { thisWeek, thisMonth, thisYear, custom }

class CreateBudgetScreen extends ConsumerStatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _amountC = TextEditingController();
  Category? _selectedCategory;
  _BudgetPeriod _period = _BudgetPeriod.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _saving = false;
  bool _showAdvanced = false;

  // Advanced options
  BudgetRecurrence _recurrence = BudgetRecurrence.none;
  BudgetType _budgetType = BudgetType.categoryWise;
  final List<int> _selectedTagIds = [];

  @override
  void dispose() {
    _amountC.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    return switch (_period) {
      _BudgetPeriod.thisWeek => (
          now.subtract(Duration(days: now.weekday - 1)),
          now.add(Duration(days: 7 - now.weekday)),
        ),
      _BudgetPeriod.thisMonth => (
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1, 0),
        ),
      _BudgetPeriod.thisYear => (
          DateTime(now.year),
          DateTime(now.year, 12, 31),
        ),
      _BudgetPeriod.custom => (
          _customStart ?? now,
          _customEnd ?? now,
        ),
    };
  }

  int get _daysInPeriod {
    final (start, end) = _getDateRange();
    return end.difference(start).inDays + 1;
  }

  double get _dailyAllowance {
    final amount = double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;
    final days = _daysInPeriod;
    return days > 0 && amount > 0 ? amount / days : 0;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final l10n = AppLocalizations.of(context)!;

    // Entitlement check
    final canCreate = await ref.read(canCreateBudgetProvider.future);
    if (!canCreate) {
      setState(() => _saving = false);
      SnackbarService.warning(l10n.budget_freePlanLimit);
      return;
    }

    // Validation
    final amount = double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      setState(() => _saving = false);
      SnackbarService.error(l10n.budget_amountRequiredHintText);
      return;
    }

    if (_budgetType == BudgetType.categoryWise && _selectedCategory == null) {
      setState(() => _saving = false);
      SnackbarService.error(l10n.budget_selectAtLeastOneCategoryErrorText);
      return;
    }

    if (_budgetType == BudgetType.tagWise && _selectedTagIds.isEmpty) {
      setState(() => _saving = false);
      SnackbarService.error(l10n.budget_selectAtLeastOneTag);
      return;
    }

    if (_period == _BudgetPeriod.custom &&
        (_customStart == null || _customEnd == null)) {
      setState(() => _saving = false);
      SnackbarService.error(l10n.budget_pickBothDatesErrorText);
      return;
    }

    final (startDate, endDate) = _getDateRange();

    // Auto-generate name from category
    final name = _selectedCategory != null
        ? '${_selectedCategory!.name} Budget'
        : 'Budget';

    final budget = Budget.create(
      name: name,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
    );
    budget.recurrence = _recurrence;
    budget.budgetType = _budgetType;

    final allocations = <BudgetCategoryAllocation>[];

    if (_budgetType == BudgetType.categoryWise && _selectedCategory != null) {
      budget.categories.add(_selectedCategory!);
      final alloc = BudgetCategoryAllocation()..amount = amount;
      alloc.category.value = _selectedCategory;
      alloc.budget.value = budget;
      allocations.add(alloc);
    }

    if (_budgetType == BudgetType.tagWise) {
      final isar = await ref.read(isarServiceProvider).getInstance();
      for (final tagId in _selectedTagIds) {
        final tag = await isar.tags.get(tagId);
        if (tag != null) budget.budgetTags.add(tag);
      }
    }

    final service = ref.read(budgetServiceProvider);
    await service.save(budget, newAllocations: allocations);

    if (mounted) {
      HapticFeedback.mediumImpact();
      ref.invalidate(budgetServiceProvider);
      SnackbarService.success(BuddyMessages.budgetCreated);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final catsAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: color.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.budget_createBudget,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: catsAsync.when(
        data: (cats) => _buildBody(cats, spacing, color, textTheme, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildBody(
    List<Category> cats,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final amount =
        double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(spacing.sectionGap),
            children: [
              // ── CATEGORY PICKER ──
              _buildCategoryPicker(cats, spacing, color, textTheme, l10n),
              SizedBox(height: spacing.sectionGap),

              // ── AMOUNT (HERO) ──
              _buildAmountInput(spacing, color, textTheme, l10n),

              // ── SPENDING HISTORY CONTEXT ──
              if (_selectedCategory != null)
                _buildSpendingContext(spacing, color, textTheme, l10n),

              SizedBox(height: spacing.sectionGap),

              // ── PERIOD ──
              _buildPeriodSelector(spacing, color, textTheme, l10n),
              SizedBox(height: spacing.sectionGap),

              // ── DAILY ALLOWANCE ──
              if (amount > 0)
                _buildDailyAllowance(spacing, color, textTheme, l10n),

              // ── ADVANCED ──
              SizedBox(height: spacing.sectionGap),
              _buildAdvancedSection(spacing, color, textTheme, l10n),
              SizedBox(height: spacing.sectionGap * 2),
            ],
          ),
        ),

        // ── CREATE BUTTON ──
        _buildCreateButton(spacing, color, textTheme, l10n),
      ],
    );
  }

  // ── CATEGORY PICKER ──

  Widget _buildCategoryPicker(
    List<Category> cats,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final parents = cats.where((c) => c.parentCategory.value == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budget_categoriesTitle,
          style: textTheme.labelMedium?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        InkWell(
          onTap: () => _showCategorySheet(cats, parents, spacing, color, textTheme),
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          child: Container(
            padding: EdgeInsets.all(spacing.cardInner),
            decoration: BoxDecoration(
              color: _selectedCategory != null
                  ? color.primaryContainer.withValues(alpha: 0.3)
                  : color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: _selectedCategory != null
                    ? color.primary.withValues(alpha: 0.5)
                    : color.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                if (_selectedCategory != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _selectedCategory!.colorValue != null
                          ? Color(_selectedCategory!.colorValue!).withValues(alpha: 0.15)
                          : color.primaryContainer,
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      IconHelper.getIconData(_selectedCategory!.iconName),
                      size: 18,
                      color: _selectedCategory!.colorValue != null
                          ? Color(_selectedCategory!.colorValue!)
                          : color.primary,
                    ),
                  ),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      _selectedCategory!.name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(LucideIcons.tag, size: 20, color: color.onSurfaceVariant),
                  SizedBox(width: spacing.elementGap),
                  Expanded(
                    child: Text(
                      l10n.budget_selectCategories,
                      style: textTheme.bodyLarge?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: color.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(
    List<Category> cats,
    List<Category> parents,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusLarge),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.all(spacing.sectionGap),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            ...parents.map((parent) {
              final subs = cats
                  .where((c) => c.parentCategory.value?.id == parent.id)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parent as tappable option
                  _categoryTile(parent, spacing, color, textTheme),
                  // Subcategories indented
                  if (subs.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: spacing.sectionGap),
                      child: Column(
                        children: subs
                            .map((s) => _categoryTile(s, spacing, color, textTheme))
                            .toList(),
                      ),
                    ),
                  SizedBox(height: spacing.elementGap),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(
    Category cat,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final catColor = cat.colorValue != null ? Color(cat.colorValue!) : color.primary;
    final isSelected = _selectedCategory?.id == cat.id;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategory = cat);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.elementGap,
          vertical: spacing.elementGap,
        ),
        decoration: BoxDecoration(
          color: isSelected ? catColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child: Icon(
                IconHelper.getIconData(cat.iconName),
                size: 16,
                color: catColor,
              ),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Text(
                cat.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? catColor : color.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, size: 16, color: catColor),
          ],
        ),
      ),
    );
  }

  // ── AMOUNT INPUT (HERO) ──

  Widget _buildAmountInput(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budget_limit,
          style: textTheme.labelMedium?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        TextField(
          controller: _amountC,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color.onSurface,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            prefixText: '${BaseCurrency.symbol} ',
            prefixStyle: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: spacing.elementGap),
          ),
        ),
      ],
    );
  }

  // ── SPENDING HISTORY + TEMPLATES ──

  Widget _buildSpendingContext(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final historyAsync =
        ref.watch(categorySpendingHistoryProvider(_selectedCategory!.id));

    return historyAsync.when(
      data: (history) {
        if (!history.hasHistory) return const SizedBox.shrink();

        final amount =
            double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;
        final buffer = amount - history.lastMonthSpent;

        return Padding(
          padding: EdgeInsets.only(top: spacing.elementGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spending context
              Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  color: color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(color: color.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.budget_basedOnHistory,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.elementGap),
                    _historyRow(
                      l10n.budget_lastMonth,
                      history.lastMonthSpent,
                      textTheme,
                      color,
                      spacing,
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    _historyRow(
                      l10n.budget_threeMonthAvg,
                      history.threeMonthAverage,
                      textTheme,
                      color,
                      spacing,
                    ),
                    if (amount > 0 && history.lastMonthSpent > 0) ...[
                      SizedBox(height: spacing.elementGap),
                      Divider(
                        height: 1,
                        color: color.outlineVariant.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: spacing.elementGap),
                      Row(
                        children: [
                          Icon(
                            buffer >= 0
                                ? LucideIcons.shieldCheck
                                : LucideIcons.triangleAlert,
                            size: 14,
                            color: buffer >= 0
                                ? color.onSurfaceVariant
                                : color.error,
                          ),
                          SizedBox(width: spacing.elementGapMin),
                          CurrencyText(
                            amount: buffer.abs(),
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: buffer >= 0
                                  ? color.onSurfaceVariant
                                  : color.error,
                            ),
                          ),
                          Text(
                            buffer >= 0
                                ? ' ${l10n.budget_bufferAbove}'
                                : ' ${l10n.budget_bufferBelow}',
                            style: textTheme.bodySmall?.copyWith(
                              color: buffer >= 0
                                  ? color.onSurfaceVariant
                                  : color.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Budget templates
              SizedBox(height: spacing.elementGap),
              _buildTemplates(history, spacing, color, textTheme, l10n),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: spacing.elementGap),
        child: const LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _historyRow(
    String label,
    double amount,
    TextTheme textTheme,
    ColorScheme color,
    AppSpacing spacing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
        ),
        CurrencyText(
          amount: amount,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTemplates(
    CategorySpendingHistory history,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final templates = <(String, double)>[];
    if (history.recommendedLimit > 0) {
      templates.add((l10n.budget_templateRecommended, history.recommendedLimit));
    }
    if (history.conservativeLimit > 0 &&
        history.conservativeLimit != history.recommendedLimit) {
      templates.add((l10n.budget_templateConservative, history.conservativeLimit));
    }
    if (history.flexibleLimit > 0 &&
        history.flexibleLimit != history.recommendedLimit) {
      templates.add((l10n.budget_templateFlexible, history.flexibleLimit));
    }

    if (templates.isEmpty) return const SizedBox.shrink();

    final currentAmount =
        double.tryParse(_amountC.text.trim().replaceAll(',', '')) ?? 0;

    return Wrap(
      spacing: spacing.elementGap,
      runSpacing: spacing.elementGap,
      children: templates.map((t) {
        final (label, value) = t;
        final isSelected = currentAmount == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _amountC.text = value.toInt().toString());
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.elementGap,
              vertical: spacing.elementGapMin,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.primary.withValues(alpha: 0.12)
                  : color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
              border: Border.all(
                color: isSelected ? color.primary : color.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected ? color.primary : color.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CurrencyText(
                  amount: value,
                  compact: true,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color.primary : color.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── PERIOD SELECTOR ──

  Widget _buildPeriodSelector(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final periods = [
      (_BudgetPeriod.thisWeek, l10n.budget_periodThisWeek),
      (_BudgetPeriod.thisMonth, l10n.budget_periodThisMonth),
      (_BudgetPeriod.thisYear, l10n.budget_periodThisYear),
      (_BudgetPeriod.custom, l10n.budget_periodCustom),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budget_duration,
          style: textTheme.labelMedium?.copyWith(
            color: color.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.elementGap),
        Wrap(
          spacing: spacing.elementGap,
          runSpacing: spacing.elementGap,
          children: periods.map((p) {
            final (period, label) = p;
            final isActive = _period == period;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _period = period);
                if (period == _BudgetPeriod.custom) {
                  _pickCustomDates();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardInner,
                  vertical: spacing.elementGap,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.primary.withValues(alpha: 0.1)
                      : color.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: isActive ? color.primary : color.outlineVariant,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? color.primary : color.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_period == _BudgetPeriod.custom &&
            _customStart != null &&
            _customEnd != null) ...[
          SizedBox(height: spacing.elementGap),
          Text(
            '${DateFormat.yMMMd(AppLocalizations.of(context)!.localeName).format(_customStart!)} – ${DateFormat.yMMMd(AppLocalizations.of(context)!.localeName).format(_customEnd!)}',
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Future<void> _pickCustomDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _customStart ?? now,
        end: _customEnd ?? now.add(const Duration(days: 30)),
      ),
    );
    if (range != null) {
      setState(() {
        _customStart = range.start;
        _customEnd = range.end;
      });
    }
  }

  // ── DAILY ALLOWANCE ──

  Widget _buildDailyAllowance(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Row(
        children: [
          CurrencyText(
            amount: _dailyAllowance,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '/${l10n.budget_perDay}',
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '$_daysInPeriod ${l10n.budget_days}',
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── ADVANCED SECTION ──

  Widget _buildAdvancedSection(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _showAdvanced = !_showAdvanced);
          },
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.elementGap),
            child: Row(
              children: [
                Icon(
                  _showAdvanced
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 16,
                  color: color.onSurfaceVariant,
                ),
                SizedBox(width: spacing.elementGapMin),
                Text(
                  l10n.budget_advanced,
                  style: textTheme.labelLarge?.copyWith(
                    color: color.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          SizedBox(height: spacing.elementGap),

          // Recurrence
          _advancedTile(
            icon: LucideIcons.repeat,
            label: l10n.budget_recurrenceText,
            value: l10n.translate(_recurrence.name),
            onTap: () => _showRecurrencePicker(l10n),
            spacing: spacing,
            color: color,
            textTheme: textTheme,
          ),
          SizedBox(height: spacing.elementGap),

          // Budget type (tag-wise, travel)
          _advancedTile(
            icon: LucideIcons.layoutGrid,
            label: l10n.budget_budgetType,
            value: _budgetType.localizedName(l10n),
            onTap: () => _showBudgetTypePicker(l10n, spacing, color, textTheme),
            spacing: spacing,
            color: color,
            textTheme: textTheme,
          ),

          // Tags (when tag-wise)
          if (_budgetType == BudgetType.tagWise) ...[
            SizedBox(height: spacing.elementGap),
            _buildTagSelector(spacing, color, textTheme, l10n),
          ],
        ],
      ],
    );
  }

  Widget _advancedTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required AppSpacing spacing,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.radiusSmall),
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          border: Border.all(color: color.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.onSurfaceVariant),
            SizedBox(width: spacing.elementGap),
            Text(label, style: textTheme.bodyMedium),
            const Spacer(),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: spacing.elementGapMin),
            Icon(LucideIcons.chevronRight, size: 14, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showRecurrencePicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BudgetRecurrence.values.map((r) {
            return ListTile(
              title: Text(l10n.translate(r.name)),
              trailing: _recurrence == r
                  ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() => _recurrence = r);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBudgetTypePicker(
    AppLocalizations l10n,
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final activeTripAsync = ref.read(activeTripProvider);
    final hasActiveTrip = activeTripAsync.value != null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BudgetType.values.map((type) {
            final isTravel = type == BudgetType.travel;
            final isDisabled = isTravel && !hasActiveTrip;
            return ListTile(
              title: Text(type.localizedName(l10n)),
              subtitle: Text(
                type.localizedDesc(l10n),
                style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
              ),
              trailing: _budgetType == type
                  ? Icon(LucideIcons.check, color: color.primary)
                  : null,
              enabled: !isDisabled,
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() => _budgetType = type);
                      Navigator.pop(ctx);
                    },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTagSelector(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    final tagsAsync = ref.watch(tagListProvider);
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return Text(
            l10n.budget_noTags,
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
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
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── CREATE BUTTON ──

  Widget _buildCreateButton(
    AppSpacing spacing,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.sectionGap),
      decoration: BoxDecoration(
        color: color.surface,
        border: Border(
          top: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: spacing.cardInner),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.onPrimary,
                    ),
                  )
                : Text(
                    l10n.budget_createBudget,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
