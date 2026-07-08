import 'package:mudra_manager/shared/widgets/currency_badge.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/services/widget_service.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/account/data/account_access_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_query_provider.dart';
import 'package:mudra_manager/shared/widgets/transaction_form/transaction_form_widgets.dart';

class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  final bool compact;
  const QuickAddTransactionSheet({super.key, this.compact = false});

  @override
  ConsumerState<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState
    extends ConsumerState<QuickAddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _accountScrollController = ScrollController();
  final _categoryScrollController = ScrollController();
  final _subcategoryScrollController = ScrollController();
  bool _isExpense = true;
  Account? _selectedAccount;
  Category? _selectedCategory;
  bool _saving = false;
  late bool _showFullMode;

  @override
  void initState() {
    super.initState();
    _showFullMode = !widget.compact;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _accountScrollController.dispose();
    _categoryScrollController.dispose();
    _subcategoryScrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accentColor = _isExpense ? color.error : color.primary;

    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = _isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Container(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontalMax,
        right: spacing.cardHorizontalMax,
        top: spacing.cardHorizontalMax,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            spacing.cardHorizontalMax,
      ),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusSmall * 2),),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Text(
                  ctxt.quickAdd_title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: ctxt.common_close,
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Type Toggle ──
            TypeToggle(
              isExpense: _isExpense,
              onChanged: (val) => setState(() {
                _isExpense = val;
                _selectedCategory = null;
              }),
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Amount ──
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
              decoration: InputDecoration(
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CurrencyBadge(code: BaseCurrency.code, size: 16),
                ),
                hintText: '0',
                hintStyle: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accentColor.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: accentColor.withValues(alpha: 0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),

            // ── Account (hidden in compact, auto-selected) ──
            if (_showFullMode)
              accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccount == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedAccount == null) {
                        setState(() => _selectedAccount = accounts.first);
                      }
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedAccount != null)
                        _buildSelectedLabel(
                          _selectedAccount!.name,
                          Color(_selectedAccount!.colorValue ??
                              color.primary.toARGB32(),),
                          textTheme,
                        ),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          controller: _accountScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: accounts.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: spacing.elementGap),
                          itemBuilder: (_, i) {
                            final acc = accounts[i];
                            final selected = _selectedAccount?.id == acc.id;
                            final acColor = Color(
                                acc.colorValue ?? color.primary.toARGB32(),);
                            final unlockedIds =
                                ref.watch(unlockedAccountIdsProvider);
                            final isUnlocked =
                                unlockedIds.value?.contains(acc.id) ?? true;

                            return GestureDetector(
                              onTap: () {
                                if (isUnlocked) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedAccount = acc);
                                } else {
                                  HapticFeedback.mediumImpact();
                                  _showUnlockPrompt(context, accounts.length);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? acColor.withValues(alpha: 0.1)
                                      : isUnlocked
                                          ? color.surfaceContainerHighest
                                          : color.surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(
                                      spacing.radiusMedium,),
                                  border: Border.all(
                                    color: selected
                                        ? acColor.withValues(alpha: 0.5)
                                        : color.outlineVariant
                                            .withValues(alpha: 0.2),
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.landmark,
                                        size: 16, color: acColor,),
                                    SizedBox(width: spacing.elementGap),
                                    Text(
                                      acc.name,
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: selected
                                            ? color.onSurface
                                            : color.onSurfaceVariant,
                                      ),
                                    ),
                                    if (!isUnlocked) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.lock,
                                        size: 12,
                                        color: color.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox(),
              ),
            if (_showFullMode) SizedBox(height: spacing.sectionGap),

            // ── Category ──
            if (!_showFullMode) ...[
              // Compact: 4×2 grid of frequent categories
              _buildCompactCategoryGrid(color, textTheme, spacing),
              SizedBox(height: spacing.sectionGap),
            ] else
              categoriesAsync.when(
                data: (categories) {
                  final parents = categories
                      .where((c) => c.parentCategory.value == null)
                      .toList();

                  if (_selectedCategory == null && parents.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedCategory == null) {
                        setState(() => _selectedCategory = parents.first);
                      }
                    });
                  }

                  final expanded = _expandedParent(parents);
                  final hasChildren = expanded != null &&
                      categories.any(
                          (c) => c.parentCategory.value?.id == expanded.id,);
                  final children = hasChildren
                      ? categories
                          .where(
                            (c) => c.parentCategory.value?.id == expanded.id,
                          )
                          .toList()
                      : <Category>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedCategory != null)
                        _buildSelectedLabel(
                          _selectedCategory!.parentCategory.value != null
                              ? '${_selectedCategory!.name} · ${_selectedCategory!.parentCategory.value?.name ?? ""}'
                              : _selectedCategory!.name,
                          Color(_selectedCategory!.colorValue ??
                              color.primary.toARGB32(),),
                          textTheme,
                        ),
                      // Parent row
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          controller: _categoryScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: parents.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: spacing.elementGap),
                          itemBuilder: (_, i) {
                            final cat = parents[i];
                            final catColor = Color(
                                cat.colorValue ?? color.primary.toARGB32(),);
                            final isExpanded = expanded?.id == cat.id;
                            final isSelected =
                                isExpanded || _selectedCategory?.id == cat.id;
                            final hasSubs = categories.any(
                              (c) => c.parentCategory.value?.id == cat.id,
                            );

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
                                  borderRadius: BorderRadius.circular(
                                      spacing.radiusMedium,),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor.withValues(alpha: 0.5)
                                        : color.outlineVariant
                                            .withValues(alpha: 0.2),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconHelper.iconFromName(
                                          cat.iconName ?? 'category',),
                                      size: 16,
                                      color: catColor,
                                    ),
                                    SizedBox(width: spacing.elementGap),
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
                                        duration:
                                            const Duration(milliseconds: 200),
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
                      // Subcategory row
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: hasChildren
                            ? Padding(
                                padding:
                                    EdgeInsets.only(top: spacing.elementGap),
                                child: SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    controller: _subcategoryScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: children.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(width: spacing.elementGap),
                                    itemBuilder: (_, i) {
                                      final sub = children[i];
                                      final subColor = Color(
                                        sub.colorValue ??
                                            color.primary.toARGB32(),
                                      );
                                      final isSubSelected =
                                          _selectedCategory?.id == sub.id;

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(
                                            () => _selectedCategory = sub,
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSubSelected
                                                ? subColor.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : color.surfaceContainerHighest
                                                    .withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(
                                              spacing.radiusSmall,
                                            ),
                                            border: Border.all(
                                              color: isSubSelected
                                                  ? subColor.withValues(
                                                      alpha: 0.5,
                                                    )
                                                  : color.outlineVariant
                                                      .withValues(
                                                      alpha: 0.15,
                                                    ),
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
                                                style: textTheme.labelMedium
                                                    ?.copyWith(
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
              ),
            SizedBox(height: spacing.sectionGap),

            // ── Note (hidden in compact until expanded) ──
            if (_showFullMode)
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: ctxt.transaction_descriptionControllerText,
                  prefixIcon: Icon(
                    LucideIcons.fileText,
                    size: 18,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
            if (_showFullMode) SizedBox(height: spacing.sectionGap),

            // ── More options (compact mode only) ──
            if (!_showFullMode) ...[
              TextButton.icon(
                onPressed: () => setState(() => _showFullMode = true),
                icon: Icon(LucideIcons.chevronDown,
                    size: 16, color: color.onSurfaceVariant,),
                label: Text(
                  ctxt.quickAdd_moreOptions,
                  style: textTheme.labelMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            SizedBox(height: spacing.elementGap),

            // ── Save ──
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _save(spacing);
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
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
                      ctxt.common_save,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCategoryGrid(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    // Reuse already-cached providers — no new Isar queries
    final categoriesAsync = _isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    // Auto-select account from already-cached list
    if (_selectedAccount == null) {
      final accountsAsync = ref.watch(accountsProvider);
      accountsAsync.whenData((accounts) {
        if (accounts.isNotEmpty && _selectedAccount == null) {
          final primary = accounts.where((a) => a.isPrimary).firstOrNull;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedAccount = primary ?? accounts.first);
            }
          });
        }
      });
    }

    return categoriesAsync.when(
      data: (categories) {
        final parents = categories
            .where((c) => c.parentCategory.value == null)
            .take(8)
            .toList();
        if (parents.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: parents.map((cat) {
            final isSelected = _selectedCategory?.id == cat.id;
            final catColor = Color(cat.colorValue ?? color.primary.toARGB32());
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor.withValues(alpha: 0.12)
                      : color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                      IconHelper.iconFromName(cat.iconName ?? 'category'),
                      size: 16,
                      color: catColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: textTheme.labelMedium?.copyWith(
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
          }).toList(),
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSelectedLabel(String label, Color accent, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppSpacing spacing) async {
    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      SnackbarService.error(BuddyMessages.invalidAmount, spacing);
      return;
    }
    if (_selectedAccount == null) {
      SnackbarService.error(BuddyMessages.pickAccount, spacing);
      return;
    }
    if (_selectedCategory == null) {
      SnackbarService.error(BuddyMessages.pickCategory, spacing);
      return;
    }

    setState(() => _saving = true);

    try {
      final txn = Transaction.create(
        date: DateTime.now(),
        amount:
            double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0,
        isExpense: _isExpense,
        description: _noteController.text,
      );

      txn.account.value = _selectedAccount;
      txn.category.value = _selectedCategory;

      await ref.read(transactionProvider).addTransaction(txn);
      await WidgetService.updateWidget(ref);
      ref.invalidate(transactionProvider);
      ref.invalidate(accountServiceProvider);
      ref.invalidate(transactionQueryProvider);

      if (context.mounted) {
        Navigator.pop(context);
        SnackbarService.success(BuddyMessages.txnAdded, spacing);
      }
    } catch (e) {
      SnackbarService.error(BuddyMessages.errorWith('$e'), spacing);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showUnlockPrompt(BuildContext context, int totalAccounts) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(spacing.radiusSmall * 2),),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 40, color: color.primary),
              const SizedBox(height: 16),
              Text(
                ctxt.upgrade_unlockAccountsTitle(totalAccounts),
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                ctxt.upgrade_accountsFreePlanLimit(FreeTierLimits.maxAccounts),
                style: textTheme.bodyMedium
                    ?.copyWith(color: color.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  context.push(AppRoutes.upgrade);
                },
                icon: const Icon(LucideIcons.sparkles, size: 18),
                label: Text(
                  ctxt.profile_upgradeToProLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        ref.read(spacingProvider).radiusMedium,),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  ctxt.common_maybeLater,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
