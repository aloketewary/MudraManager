import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/frequency.dart';
import 'package:mudra_manager/core/db/models/recurring_transaction.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/transactions/data/recurring_transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/transaction_form/transaction_form_widgets.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? recurring;

  const AddRecurringTransactionScreen({super.key, this.recurring});

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends ConsumerState<AddRecurringTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isExpense = true;
  DateTime _startDate = DateTime.now();
  Frequency _frequency = Frequency.monthly;
  Account? _selectedAccount;
  Category? _selectedCategory;

  final _categoryScrollController = ScrollController();
  final _subcategoryScrollController = ScrollController();

  bool get _isEditing => widget.recurring != null;
  final _accountScrollController = ScrollController();
  bool _accountScrolled = false;
  bool _categoryScrolled = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _amountController.text = widget.recurring!.amount.toString();
      _descController.text = widget.recurring!.description ?? '';
      _isExpense = widget.recurring!.isExpense;
      _startDate = widget.recurring!.startDate;
      _frequency = widget.recurring!.frequency;
      _selectedAccount = widget.recurring!.account.value;
      _selectedCategory = widget.recurring!.category.value;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _categoryScrollController.dispose();
    _subcategoryScrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final accentColor = _isExpense ? color.error : color.primary;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.pop();
          },
        ),
        title: Text(
          _isEditing ? 'Edit Recurring' : 'Add Recurring',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardHorizontal,
                vertical: spacing.cardVertical,
              ),
              children: [
                // ── Type Toggle ──
                TypeToggle(
                  isExpense: _isExpense,
                  onChanged: (val) => setState(() {
                    _isExpense = val;
                    _selectedCategory = null;
                    _categoryScrolled = false;
                  }),
                ),
                SizedBox(height: spacing.sectionGap),

                // ── Amount ──
                HeroAmountInput(
                  controller: _amountController,
                  accentColor: accentColor,
                ),
                SizedBox(height: spacing.sectionGap),

                // ── Description ──
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    prefixIcon: Icon(
                      LucideIcons.fileText,
                      size: 20,
                      color: color.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      borderSide: BorderSide(
                        color: color.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                      borderSide: BorderSide(
                        color: color.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                SizedBox(height: spacing.sectionGap),

                // ── Frequency ──
                _buildSectionLabel(
                  'Frequency',
                  LucideIcons.repeat,
                  color,
                  textTheme,
                ),
                SizedBox(height: spacing.elementGap),

                Wrap(
                  spacing: 8,
                  children: Frequency.values.map((f) {
                    final selected = _frequency == f;
                    return ChoiceChip(
                      label: Text(_frequencyLabel(f)),
                      selected: selected,
                      avatar: Icon(
                        _frequencyIcon(f),
                        size: 16,
                        color:
                            selected ? color.primary : color.onSurfaceVariant,
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _frequency = f);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: spacing.sectionGap),

                // ── Account ──
                _buildSectionLabel(
                  'Account',
                  LucideIcons.landmark,
                  color,
                  textTheme,
                ),
                SizedBox(height: spacing.elementGap),
                if (_selectedAccount != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.elementGap),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Color(
                            _selectedAccount?.colorValue ??
                                color.primary.toARGB32(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedAccount!.name,
                          style: textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                _buildAccountSelector(color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),

                // ── Category ──
                _buildSectionLabel(
                  'Category',
                  LucideIcons.tag,
                  color,
                  textTheme,
                ),
                SizedBox(height: spacing.elementGap),
                _buildCategorySelector(color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),

                // ── Start Date ──
                _buildSectionLabel(
                  'Start Date',
                  LucideIcons.calendar,
                  color,
                  textTheme,
                ),
                SizedBox(height: spacing.elementGap),
                _buildDatePicker(color, textTheme, spacing),
                SizedBox(height: spacing.sectionGap),
              ],
            ),
          ),

          // ── Bottom Buttons ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.cardHorizontal,
              spacing.elementGap,
              spacing.cardHorizontal,
              spacing.cardHorizontalMax + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.radiusMedium),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(height: spacing.elementGap),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: Text(AppLocalizations.of(context)!.common_delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color.error,
                      side: BorderSide(color: color.error),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return InkWell(
      onTap: () async {
        final pick = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
        );
        if (pick != null) {
          HapticFeedback.lightImpact();
          setState(
            () => _startDate = DateTime(pick.year, pick.month, pick.day),
          );
        }
      },
      borderRadius: BorderRadius.circular(spacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: color.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              DateFormat('MMM dd, yyyy').format(_startDate),
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final accountsAsync = ref.watch(accountsProvider);
    return accountsAsync.when(
      data: (accounts) => SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          controller: _accountScrollController,
          itemCount: accounts.length,
          separatorBuilder: (_, __) => SizedBox(width: spacing.elementGap),
          itemBuilder: (context, index) {
            final account = accounts[index];
            final isSelected = _selectedAccount?.id == account.id;
            final acColor =
                Color(account.colorValue ?? color.primary.toARGB32());
            if (_selectedAccount != null && !_accountScrolled) {
              _accountScrolled = true;
              final idx =
                  accounts.indexWhere((a) => a.id == _selectedAccount!.id);
              if (idx > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_accountScrollController.hasClients) {
                    _accountScrollController.animateTo(
                      idx * 160.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedAccount = account);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? acColor.withValues(alpha: 0.1)
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? acColor.withValues(alpha: 0.5)
                        : color.outlineVariant.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: acColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(LucideIcons.landmark, size: 16, color: acColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      account.name,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? color.onSurface
                            : color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const SizedBox(height: 64),
      error: (_, __) => const SizedBox(),
    );
  }

  Category? _expandedParent(List<Category> parents) {
    if (_selectedCategory == null) return null;
    if (parents.any((p) => p.id == _selectedCategory!.id)) {
      return _selectedCategory;
    }
    final parentId = _selectedCategory!.parentCategory.value?.id;
    if (parentId != null) {
      return parents.where((p) => p.id == parentId).firstOrNull;
    }
    return null;
  }

  Widget _buildCategorySelector(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final categoriesAsync = ref.watch(categoryListProvider);
    return categoriesAsync.when(
      data: (categories) {
        final parents = categories
            .where(
              (c) =>
                  (_isExpense
                      ? c.categoryType == CategoryType.expense
                      : c.categoryType == CategoryType.income) &&
                  c.parentCategory.value == null,
            )
            .toList();

        final expanded = _expandedParent(parents);
        final hasChildren = expanded != null &&
            categories.any((c) => c.parentCategory.value?.id == expanded.id);
        final children = hasChildren
            ? categories
                .where((c) => c.parentCategory.value?.id == expanded.id)
                .toList()
            : <Category>[];
        if (_selectedCategory != null && !_categoryScrolled) {
          _categoryScrolled = true;
          final parentId = _selectedCategory!.parentCategory.value?.id ??
              _selectedCategory!.id;
          final idx = parents.indexWhere((c) => c.id == parentId);
          if (idx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_categoryScrollController.hasClients) {
                _categoryScrollController.animateTo(
                  idx * 120.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
        // Inside _buildCategorySelector, after building the children list:
        if (_selectedCategory != null &&
            _selectedCategory!.parentCategory.value != null &&
            children.isNotEmpty) {
          final subIdx =
              children.indexWhere((c) => c.id == _selectedCategory!.id);
          if (subIdx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_subcategoryScrollController.hasClients) {
                _subcategoryScrollController.animateTo(
                  subIdx * 100.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedCategory != null)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 16,
                      color: Color(
                        _selectedCategory!.colorValue ??
                            color.primary.toARGB32(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory!.name,
                      style: textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_selectedCategory!.parentCategory.value != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\u00b7 ${_selectedCategory!.parentCategory.value!.name}',
                        style: textTheme.labelMedium
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: parents.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: spacing.elementGap),
                itemBuilder: (context, index) {
                  final cat = parents[index];
                  final catColor =
                      Color(cat.colorValue ?? color.primary.toARGB32());
                  final isExpanded = expanded?.id == cat.id;
                  final isDirectlySelected = _selectedCategory?.id == cat.id;
                  final isSelected = isExpanded || isDirectlySelected;
                  final hasSubs = categories
                      .any((c) => c.parentCategory.value?.id == cat.id);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.1)
                            : color.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        border: Border.all(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.5)
                              : color.outlineVariant.withValues(alpha: 0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconHelper.iconFromName(
                              cat.iconName ?? 'category',
                            ),
                            size: 16,
                            color: catColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat.name,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color.onSurface
                                  : color.onSurfaceVariant,
                            ),
                          ),
                          if (hasSubs) ...[
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                                color: isSelected
                                    ? catColor
                                    : color.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: hasChildren
                  ? Padding(
                      padding: EdgeInsets.only(top: spacing.elementGap),
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          controller: _subcategoryScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: children.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: spacing.elementGap),
                          itemBuilder: (context, index) {
                            final sub = children[index];
                            final subColor = Color(
                              sub.colorValue ?? color.primary.toARGB32(),
                            );
                            final isSubSelected =
                                _selectedCategory?.id == sub.id;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = sub);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSubSelected
                                      ? subColor.withValues(alpha: 0.12)
                                      : color.surfaceContainerHighest
                                          .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color: isSubSelected
                                        ? subColor.withValues(alpha: 0.5)
                                        : color.outlineVariant
                                            .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconHelper.iconFromName(
                                        sub.iconName ?? 'category',
                                      ),
                                      size: 14,
                                      color: subColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sub.name,
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: isSubSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSubSelected
                                            ? color.onSurface
                                            : color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 52),
      error: (_, __) => const SizedBox(),
    );
  }

  IconData _frequencyIcon(Frequency f) {
    return switch (f) {
      Frequency.daily => LucideIcons.calendarDays,
      Frequency.weekly => LucideIcons.calendarRange,
      Frequency.monthly => LucideIcons.calendar,
      Frequency.yearly => LucideIcons.calendarClock,
    };
  }

  String _frequencyLabel(Frequency f) {
    return switch (f) {
      Frequency.daily => 'Daily',
      Frequency.weekly => 'Weekly',
      Frequency.monthly => 'Monthly',
      Frequency.yearly => 'Yearly',
    };
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      SnackbarService.error(BuddyMessages.invalidAmount);
      return;
    }
    if (_selectedAccount == null || _selectedCategory == null) {
      SnackbarService.error(BuddyMessages.selectAccountAndCategory);
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final recurring = widget.recurring ?? RecurringTransaction();
      recurring.amount = double.parse(_amountController.text);
      recurring.description = _descController.text;
      recurring.isExpense = _isExpense;
      recurring.frequency = _frequency;
      recurring.startDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day);
      if (!_isEditing) {
        recurring.nextDueDate = _startDate;
      } else {
        recurring.nextDueDate = widget.recurring!.nextDueDate;
      }
      recurring.isActive = true;
      recurring.account.value = _selectedAccount;
      recurring.category.value = _selectedCategory;

      await ref.read(recurringTransactionServiceProvider).save(recurring);
      if (!_isEditing) {
        ref
            .read(gamificationServiceProvider)
            ?.track(GamificationEvent.recurringTransactionCreated);
      }

      if (context.mounted) {
        SnackbarService.success(
          _isEditing ? BuddyMessages.txnUpdated : BuddyMessages.txnAdded,
        );
        context.pop();
      }
    } catch (e) {
      SnackbarService.error(BuddyMessages.errorWith('$e'));
    }
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    await ref
        .read(recurringTransactionServiceProvider)
        .delete(widget.recurring!.id);
    if (context.mounted) {
      SnackbarService.success(BuddyMessages.txnDeleted);
      context.pop();
    }
  }
}
