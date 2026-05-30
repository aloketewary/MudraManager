import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/account.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/db/models/tag.dart';
import 'package:mudra_manager/core/extension/account_type_extenstion.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/account/data/account_access_provider.dart';
import 'package:mudra_manager/features/account/data/account_providers.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/tag_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/features/transactions/presentation/providers/smart_defaults_provider.dart';
import 'package:mudra_manager/shared/widgets/currency_text.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

// ─────────────────────────────────────────────
// Skeleton Loaders
// ─────────────────────────────────────────────

class AccountSelectorSkeleton extends StatelessWidget {
  const AccountSelectorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 150,
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Tone.current.borderRadius),
          ),
        ),
      ),
    )
        .animate(onComplete: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: color.surface.withValues(alpha: 0.5));
  }
}

class CategorySelectorSkeleton extends StatelessWidget {
  const CategorySelectorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 110,
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Tone.current.borderRadius),
          ),
        ),
      ),
    )
        .animate(onComplete: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: color.surface.withValues(alpha: 0.5));
  }
}

class TagSelectorSkeleton extends StatelessWidget {
  const TagSelectorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        4,
        (_) => Container(
          width: 70,
          height: 32,
          decoration: BoxDecoration(
            color: color.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Tone.current.borderRadius),
          ),
        ),
      ),
    )
        .animate(onComplete: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: color.surface.withValues(alpha: 0.5));
  }
}

// ─────────────────────────────────────────────
// Account Selector
// ─────────────────────────────────────────────

class AccountSelector extends ConsumerWidget {
  final Account? selectedAccount;
  final Map<int, double> balanceMap;
  final ScrollController scrollController;
  final bool alreadyScrolled;
  final String? smsAccountNumber;
  final String? smsBankName;
  final String addLabel;
  final ValueChanged<Account> onSelected;
  final VoidCallback onAddResult;
  final ValueChanged<int> onShowUnlockPrompt;
  final bool showError;

  const AccountSelector({
    super.key,
    required this.selectedAccount,
    required this.balanceMap,
    required this.scrollController,
    required this.alreadyScrolled,
    this.smsAccountNumber,
    this.smsBankName,
    required this.addLabel,
    required this.onSelected,
    required this.onAddResult,
    required this.onShowUnlockPrompt,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(frequencySortedAccountsProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return accountsAsync.when(
      data: (accounts) {
        final unlockedIds =
            ref.watch(unlockedAccountIdsProvider).value ?? {};

        if (selectedAccount != null && !alreadyScrolled) {
          final idx = accounts.indexWhere((a) => a.id == selectedAccount!.id);
          if (idx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  idx * 160.0,
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
            if (selectedAccount != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 20,
                      color: Color(
                        selectedAccount!.colorValue ??
                            color.primary.toARGB32(),
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      selectedAccount!.name,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurface,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    CurrencyText(
                      amount: balanceMap[selectedAccount!.id] ??
                          selectedAccount!.initialBalance,
                      showPositiveSign: false,
                      showSign: true,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              )
            else if (showError)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                child: Row(
                  children: [
                    Icon(LucideIcons.circleAlert, size: 16, color: color.error),
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      AppLocalizations.of(context)!.transaction_accountRequired,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 64,
              child: ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length + 1,
                separatorBuilder: (_, __) =>
                    SizedBox(width: spacing.elementGap),
                itemBuilder: (context, index) {
                  if (index == accounts.length) {
                    return _AddButton(
                      label: addLabel,
                      spacing: spacing,
                      onTap: () async {
                        final router = GoRouter.of(context);
                        final result = await router.push<bool>(
                          '/manage-accounts/add',
                          extra: smsAccountNumber != null
                              ? {
                                  'accountNumber': smsAccountNumber,
                                  'bankName': smsBankName,
                                }
                              : null,
                        );
                        if (result == true) {
                          ref.invalidate(accountsProvider);
                          ref.invalidate(allAccountsProvider);
                          ref.invalidate(frequencySortedAccountsProvider);
                          onAddResult();
                        }
                      },
                    );
                  }

                  final account = accounts[index];
                  final isSelected = selectedAccount?.id == account.id;
                  final acColor = Color(
                    account.colorValue ?? color.primary.toARGB32(),
                  );
                  final balance =
                      balanceMap[account.id] ?? account.initialBalance;
                  final isLocked = !unlockedIds.contains(account.id);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (isLocked) {
                        onShowUnlockPrompt(
                          accounts.length - unlockedIds.length,
                        );
                        return;
                      }
                      onSelected(account);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? acColor.withValues(alpha: 0.1)
                            : isLocked
                                ? color.surfaceContainerHighest
                                    .withValues(alpha: 0.5)
                                : color.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
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
                            child: Icon(
                              account.accountType.icon,
                              size: 16,
                              color: acColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? color.onSurface
                                      : color.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 1),
                              CurrencyText(
                                amount: balance,
                                compact: true,
                                showSign: true,
                                showPositiveSign: false,
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.lock,
                              size: 14,
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
      loading: () => const AccountSelectorSkeleton(),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Add Button
// ─────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  final AppSpacing spacing;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.spacing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: color.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 16, color: color.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category Selector
// ─────────────────────────────────────────────

class CategorySelector extends ConsumerWidget {
  final bool isExpense;
  final Category? selectedCategory;
  final ScrollController categoryScrollController;
  final ScrollController subcategoryScrollController;
  final bool alreadyScrolled;
  final String addLabel;
  final ValueChanged<Category> onSelected;
  final List<Category> Function(List<Category>) expandedParentFinder;
  final bool showError;

  const CategorySelector({
    super.key,
    required this.isExpense,
    required this.selectedCategory,
    required this.categoryScrollController,
    required this.subcategoryScrollController,
    required this.alreadyScrolled,
    required this.addLabel,
    required this.onSelected,
    required this.expandedParentFinder,
    this.showError = false,
  });

  Category? _expandedParent(List<Category> parents) {
    if (selectedCategory == null) return null;
    if (parents.any((p) => p.id == selectedCategory!.id)) {
      return selectedCategory;
    }
    final parentId = selectedCategory!.parentCategory.value?.id;
    if (parentId != null) {
      return parents.where((p) => p.id == parentId).firstOrNull;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = isExpense ? CategoryType.expense : CategoryType.income;
    final categoriesAsync = ref.watch(frequencySortedCategoriesProvider(type));
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return categoriesAsync.when(
      data: (categories) {
        final parents =
            categories.where((c) => c.parentCategory.value == null).toList();
        final expanded = _expandedParent(parents);
        final hasChildren = expanded != null &&
            categories.any((c) => c.parentCategory.value?.id == expanded.id);
        final children = hasChildren
            ? categories
                .where((c) => c.parentCategory.value?.id == expanded.id)
                .toList()
            : <Category>[];

        if (selectedCategory != null && !alreadyScrolled) {
          final parentId =
              selectedCategory!.parentCategory.value?.id ?? selectedCategory!.id;
          final idx = parents.indexWhere((c) => c.id == parentId);
          if (idx > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (categoryScrollController.hasClients) {
                categoryScrollController.animateTo(
                  idx * 120.0,
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
            if (selectedCategory != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.cardVertical),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 20,
                      color: Color(
                        selectedCategory!.colorValue ??
                            color.primary.toARGB32(),
                      ),
                    ),
                    SizedBox(width: spacing.elementGap),
                    Text(
                      selectedCategory!.name,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.onSurface,
                      ),
                    ),
                    if (selectedCategory!.parentCategory.value != null) ...[
                      SizedBox(width: spacing.elementGap),
                      Text(
                        '· ${selectedCategory!.parentCategory.value?.name ?? ""}',
                        style: textTheme.labelMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (showError)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGapMin),
                child: Row(
                  children: [
                    Icon(LucideIcons.circleAlert, size: 16, color: color.error),
                    SizedBox(width: spacing.elementGapMin),
                    Text(
                      AppLocalizations.of(context)!.transaction_categoryRequired,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Parent row
            SizedBox(
              height: 52,
              child: ListView.separated(
                controller: categoryScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: parents.length + 1,
                separatorBuilder: (_, __) =>
                    SizedBox(width: spacing.elementGap),
                itemBuilder: (context, index) {
                  if (index == parents.length) {
                    return _AddButton(
                      label: addLabel,
                      spacing: spacing,
                      onTap: () => context.push(AppRoutes.addCategory),
                    );
                  }

                  final cat = parents[index];
                  final catColor = Color(
                    cat.colorValue ?? color.primary.toARGB32(),
                  );
                  final isExpanded = expanded?.id == cat.id;
                  final isDirectlySelected = selectedCategory?.id == cat.id;
                  final isSelected = isExpanded || isDirectlySelected;
                  final hasSubcategories = categories
                      .any((c) => c.parentCategory.value?.id == cat.id);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(cat);
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
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconHelper.iconFromName(
                                cat.iconName ?? 'category',
                              ),
                              size: 16,
                              color: catColor,
                            ),
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
                          if (hasSubcategories) ...[
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

            // Subcategory row
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
                          controller: subcategoryScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: children.length + 1,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: spacing.elementGap),
                          itemBuilder: (context, index) {
                            if (index == children.length) {
                              return GestureDetector(
                                onTap: () async {
                                  final router = GoRouter.of(context);
                                  final result = await router.push<bool>(
                                    AppRoutes.addCategory,
                                    extra: {
                                      'parent': expanded,
                                      'type': isExpense
                                          ? CategoryType.expense
                                          : CategoryType.income,
                                    },
                                  );
                                  if (result == true) {
                                    ref.invalidate(
                                      frequencySortedCategoriesProvider,
                                    );
                                    ref.invalidate(categoryListProvider);
                                    ref.invalidate(
                                      selectableCategoriesProvider,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      spacing.radiusSmall,
                                    ),
                                    border: Border.all(
                                      color: color.outlineVariant
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.plus,
                                        size: 14,
                                        color: color.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Add',
                                        style:
                                            textTheme.labelMedium?.copyWith(
                                          color: color.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final sub = children[index];
                            final subColor = Color(
                              sub.colorValue ?? color.primary.toARGB32(),
                            );
                            final isSubSelected =
                                selectedCategory?.id == sub.id;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onSelected(sub);
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
      loading: () => const CategorySelectorSkeleton(),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ─────────────────────────────────────────────
// Tag Selector
// ─────────────────────────────────────────────

class TagSelector extends ConsumerWidget {
  final List<Tag> selectedTags;
  final String addNewTagText;
  final ValueChanged<Tag> onToggle;
  final VoidCallback onAddNew;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.addNewTagText,
    required this.onToggle,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListProvider);

    return tagsAsync.when(
      data: (tags) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...tags.map((tag) {
            final isSelected = selectedTags.any((t) => t.id == tag.id);
            return FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onToggle(tag);
              },
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            );
          }),
          ActionChip(
            label: Text(addNewTagText),
            avatar: const Icon(LucideIcons.plus, size: 16),
            onPressed: onAddNew,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      loading: () => const TagSelectorSkeleton(),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ─────────────────────────────────────────────
// Quick Amounts
// ─────────────────────────────────────────────

class QuickAmounts extends ConsumerWidget {
  final Color accentColor;
  final ValueChanged<int> onAmountSelected;

  const QuickAmounts({
    super.key,
    required this.accentColor,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amounts = ref.watch(quickAmountsProvider);
    final textTheme = Theme.of(context).textTheme;
    final chips = amounts.value ?? [100, 500, 1000, 2000, 5000];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: chips.map((amt) {
        return ActionChip(
          label: Text(
            formatCurrency(amt.toDouble(), decimals: 0),
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            onAmountSelected(amt);
          },
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
          backgroundColor: accentColor.withValues(alpha: 0.08),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Smart Defaults Banner
// ─────────────────────────────────────────────

class SmartDefaultsBanner extends ConsumerWidget {
  final bool isExpense;
  final VoidCallback onApply;

  const SmartDefaultsBanner({
    super.key,
    required this.isExpense,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaults = ref.watch(smartDefaultsProvider(isExpense));
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return switch (defaults) {
      AsyncData(:final value) => value.suggestedCategory == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(top: spacing.elementGap),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onApply();
                },
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    border: Border.all(
                      color: color.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, size: 14, color: color.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          value.reason ??
                              'Suggested: ${value.suggestedCategory!.name}',
                          style: textTheme.labelSmall?.copyWith(
                            color: color.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to apply',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      _ => const SizedBox.shrink(),
    };
  }
}
