import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/features/budget/data/budget_service_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/db/isar_service.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/category/data/category_merge_service.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/category_summary_card.dart';
import 'package:mudra_manager/shared/widgets/type_section_header.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final transactionCounts = ref.watch(transactionCountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.categories_manageCategoriesTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'add_category',
            label: ctxt.categories_addCategoryLabel,
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.addCategory);
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return NoDataFound(
              iconData: LucideIcons.tag,
              message: BuddyMessages.noCategories,
              action: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.addCategory),
                icon: const Icon(LucideIcons.plus),
                label: Text(ctxt.categories_addCategoryLabel),
              ),
            );
          }

          final expenses = categories
              .where(
                (c) =>
                    c.categoryType == CategoryType.expense &&
                    c.parentCategory.value == null,
              )
              .toList();
          final incomes = categories
              .where(
                (c) =>
                    c.categoryType == CategoryType.income &&
                    c.parentCategory.value == null,
              )
              .toList();

          final totalCount = transactionCounts.when(
            data: (map) => map.values.fold(0, (a, b) => a + b),
            loading: () => 0,
            error: (_, __) => 0,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth > 600 ? spacing.cardHorizontalMax : spacing.cardHorizontal;

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  // ── SUMMARY ──
                  CategorySummaryCard(
                    categoryCount: categories.length,
                    expenseCount: expenses.length,
                    incomeCount: incomes.length,
                    transactionCount: totalCount,
                  ),
                  SizedBox(height: spacing.sectionGap),

                  // ── EXPENSE CATEGORIES ──
                  if (expenses.isNotEmpty) ...[
                    TypeSectionHeader(
                      label: ctxt.transaction_type_expense,
                      icon: LucideIcons.arrowUpRight,
                      accentColor: color.error,
                    ),
                    SizedBox(height: spacing.elementGap),
                    _buildCategoryGroup(
                      context,
                      ref,
                      expenses,
                      categories,
                      transactionCounts,
                      color,
                      textTheme,
                      ctxt,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap),
                  ],

                  // ── INCOME CATEGORIES ──
                  if (incomes.isNotEmpty) ...[
                    TypeSectionHeader(
                      label: ctxt.transaction_type_income,
                      icon: LucideIcons.arrowDownLeft,
                      accentColor: color.primary,
                    ),
                    SizedBox(height: spacing.elementGap),
                    _buildCategoryGroup(
                      context,
                      ref,
                      incomes,
                      categories,
                      transactionCounts,
                      color,
                      textTheme,
                      ctxt,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap * 3),
                  ],
                ],
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: EdgeInsets.fromLTRB(
            spacing.cardHorizontal,
            spacing.cardVertical,
            spacing.cardHorizontal,
            100,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const TransactionCardSkeleton(),
        ),
        error: (err, _) => Center(child: Text(BuddyMessages.errorWith('$err'))),
      ),
    );
  }

  // ── GROUPED CARD ──
  Widget _buildCategoryGroup(
    BuildContext context,
    WidgetRef ref,
    List<Category> parents,
    List<Category> allCategories,
    AsyncValue<Map<int, int>> transactionCounts,
    ColorScheme color,
    TextTheme textTheme,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: parents.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          indent: 60,
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
        itemBuilder: (context, index) {
          final category = parents[index];
          final subcategories = allCategories
              .where((c) => c.parentCategory.value?.id == category.id)
              .toList();

          return CategoryRow(
            category: category,
            subcategories: subcategories,
            allCategories: allCategories,
            transactionCounts: transactionCounts,
            onEdit: () => context.push(
              AppRoutes.addCategory,
              extra: {'category': category},
            ),
            onDelete: () => _deleteCategory(context, ref, category, ctxt, spacing),
            onDeleteSubcategory: (sub) => _deleteCategory(context, ref, sub, ctxt, spacing),
          );
        },
      ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) async {
    final service = ref.read(categoryServiceProvider);
    final txCount = await service.getLinkedTransactionCount(category.id);
    final budgetCount = await service.getLinkedBudgetCount(category.id);

    if (!context.mounted) return;

    final parts = <String>[];
    if (txCount > 0) {
      parts.add(ctxt.categories_deleteWithTransactions(category.name, txCount));
    }
    if (budgetCount > 0) {
      parts.add(ctxt.budget_categoryDeleteWarning(budgetCount));
    }
    final message = parts.isNotEmpty
        ? parts.join('\n\n')
        : BuddyMessages.deleteMessage(category.name);

    final shouldDelete = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: BuddyMessages.deleteTitle,
      message: message,
      deleteText: (txCount > 0 || budgetCount > 0) ? ctxt.categories_deleteAll : null,
    );

    if (shouldDelete == true) {
      await service.deleteCategory(category.id);
      ref.invalidate(categoryListProvider);
      ref.invalidate(transactionCountsProvider);
      ref.invalidate(transactionProvider);
      if (budgetCount > 0) ref.invalidate(budgetsWithProgressProvider);
      SnackbarService.success(BuddyMessages.categoryDeleted, spacing);
    }
  }
}

// ── CATEGORY ROW ──
class CategoryRow extends ConsumerStatefulWidget {
  final Category category;
  final List<Category> subcategories;
  final List<Category> allCategories;
  final AsyncValue<Map<int, int>> transactionCounts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(Category subcategory) onDeleteSubcategory;

  const CategoryRow({
    super.key,
    required this.category,
    required this.subcategories,
    required this.allCategories,
    required this.transactionCounts,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteSubcategory,
  });

  @override
  ConsumerState<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends ConsumerState<CategoryRow> {
  bool _expanded = false;

  bool get _hasChildren => widget.subcategories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryColor =
        Color(widget.category.colorValue ?? Colors.grey.toARGB32());
    final count = widget.transactionCounts.when(
      data: (map) => map[widget.category.id] ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      key: ValueKey('category_${widget.category.id}'),
      children: [
        RepaintBoundary(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showContextSheet(
                  context,
                  widget.category,
                  color,
                  textTheme,
                  spacing,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                );
              },
              child: AnimatedPadding(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          IconHelper.getIconData(widget.category.iconName),
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            semanticsLabel: 'Category: ${widget.category.name}',
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Row(
                            children: [
                              Text(
                                '$count txn${count == 1 ? '' : 's'}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                                semanticsLabel: '$count transactions',
                              ),
                              if (_hasChildren) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '•',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.subcategories.length} sub',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                  semanticsLabel: '${widget.subcategories.length} subcategories',
                                ),
                              ],
                              if (widget.category.keywords != null &&
                                  widget.category.keywords!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '•',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.category.keywords!.join(', '),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: color.primary.withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_hasChildren)
                      _buildExpandButton(color, reduceMotion)
                    else
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: color.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── SUBCATEGORIES ──
        if (_hasChildren)
          RepaintBoundary(
            child: AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: widget.subcategories.map((sub) {
                  final subColor = Color(sub.colorValue ?? Colors.grey.toARGB32());
                  final subCount = widget.transactionCounts.when(
                    data: (map) => map[sub.id] ?? 0,
                    loading: () => 0,
                    error: (_, __) => 0,
                  );
                  return _SubcategoryRow(
                    subcategory: sub,
                    subCount: subCount,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showContextSheet(
                        context,
                        sub,
                        color,
                        textTheme,
                        spacing,
                        onEdit: () => context.push(
                          AppRoutes.addCategory,
                          extra: {'category': sub},
                        ),
                        onDelete: () => widget.onDeleteSubcategory(sub),
                      );
                    },
                  );
                }).toList(),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandButton(ColorScheme color, bool reduceMotion) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedRotation(
        turns: _expanded ? 0.5 : 0,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            LucideIcons.chevronDown,
            size: 18,
            color: color.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showContextSheet(
    BuildContext context,
    Category category,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final catColor = Color(category.colorValue ?? Colors.grey.toARGB32());
    final ctxt = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    child: Icon(
                      IconHelper.getIconData(category.iconName),
                      color: catColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          category.categoryType.name.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            ListTile(
              leading: Icon(LucideIcons.pencil, color: color.primary),
              title: Text(ctxt.categories_edit),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.merge, color: color.tertiary),
              title: Text(ctxt.category_merge),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                _showMergeSheet(context, category, color, textTheme, spacing);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: color.error),
              title: Text(
                ctxt.categories_delete,
                style: TextStyle(color: color.error),
              ),
              subtitle: Text(ctxt.categories_deleteSubtitle),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMergeSheet(
    BuildContext context,
    Category source,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final candidates = widget.allCategories
        .where((c) => c.id != source.id && c.categoryType == source.categoryType && !c.isSystem)
        .toList();

    if (candidates.isEmpty) {
      SnackbarService.info(ctxt.category_mergeSameError, spacing);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall * 2)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${ctxt.category_mergeInto} "${source.name}"',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (_, i) {
                  final target = candidates[i];
                  final catColor = Color(target.colorValue ?? Colors.grey.toARGB32());
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconHelper.getIconData(target.iconName),
                        color: catColor,
                        size: 20,
                      ),
                    ),
                    title: Text(target.name),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _executeMerge(context, source, target, spacing);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeMerge(
    BuildContext context,
    Category source,
    Category target,
    AppSpacing spacing,
  ) async {
    final ctxt = AppLocalizations.of(context)!;
    final isarService = IsarService();
    final mergeService = CategoryMergeService(
      isarService,
      AppLog(getLogger(), 'CategoryMerge'),
    );

    final preview = await mergeService.preview(source.id, target.id);

    if (!context.mounted) return;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      spacing,
      title: ctxt.category_merge,
      message: ctxt.category_mergePreview(preview.totalAffected, target.name),
      deleteText: ctxt.category_mergeConfirm,
    );

    if (confirmed != true) return;

    await mergeService.merge(source.id, target.id);

    if (context.mounted) {
      SnackbarService.success(ctxt.category_mergeSuccess, spacing);
    }
  }
}

// ── SUBCATEGORY ROW ──
class _SubcategoryRow extends StatelessWidget {
  final Category subcategory;
  final int subCount;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final VoidCallback onTap;

  const _SubcategoryRow({
    required this.subcategory,
    required this.subCount,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = Color(subcategory.colorValue ?? Colors.grey.toARGB32());

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 60,
              right: 16,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                Icon(
                  IconHelper.getIconData(subcategory.iconName),
                  color: subColor,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subcategory.name,
                    style: textTheme.bodyMedium,
                    semanticsLabel: 'Subcategory: ${subcategory.name}',
                  ),
                ),
                Text(
                  '$subCount',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                  semanticsLabel: '$subCount transactions',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}