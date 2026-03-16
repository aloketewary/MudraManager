import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/dialog_utils.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/widgets/skeleton_loader.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/features/transactions/data/transaction_provider.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ctxt.categories_manageCategoriesTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push('/add-category');
            },
            tooltip: ctxt.categories_addCategoryLabel,
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return NoDataFound(
              iconData: LucideIcons.tag,
              message: 'No categories found.',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/add-category'),
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

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // ── SUMMARY ──
              _buildSummary(
                categories.length,
                totalCount,
                color,
                textTheme,
                spacing,
              ),
              SizedBox(height: spacing.sectionGap),

              // ── EXPENSE CATEGORIES ──
              if (expenses.isNotEmpty) ...[
                _buildTypeHeader(
                  'Expense',
                  LucideIcons.arrowUpRight,
                  color.error,
                  textTheme,
                ),
                SizedBox(height: spacing.sectionGap),
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
                _buildTypeHeader(
                  'Income',
                  LucideIcons.arrowDownLeft,
                  const Color(0xFF4CAF50),
                  textTheme,
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 100),
              ],
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonListTile(),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // ── SUMMARY CARD ──
  Widget _buildSummary(
    int categoryCount,
    int totalTransactions,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primaryContainer,
            color.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: textTheme.labelLarge?.copyWith(
                    color: color.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$categoryCount',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            decoration: BoxDecoration(
              color: color.onPrimaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(spacing.radiusMedium),
            ),
            child: Text(
              '$totalTransactions transactions',
              style: textTheme.labelSmall?.copyWith(
                color: color.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TYPE HEADER ──
  Widget _buildTypeHeader(
    String label,
    IconData icon,
    Color iconColor,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: iconColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
      child: Column(
        children: parents.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isLast = index == parents.length - 1;
          final subcategories = allCategories
              .where((c) => c.parentCategory.value?.id == category.id)
              .toList();

          return Column(
            children: [
              _CategoryRow(
                category: category,
                subcategories: subcategories,
                allCategories: allCategories,
                transactionCounts: transactionCounts,
                onEdit: () => context.push(
                  '/add-category',
                  extra: {'category': category},
                ),
                onDelete: () => _deleteCategory(context, ref, category, ctxt),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
    AppLocalizations ctxt,
  ) async {
    final shouldDelete = await DialogUtils.showDeleteConfirmation(
      context,
      title: ctxt.categories_deleteCategoryTitle,
      message: ctxt.categories_deleteCategoryMessage,
    );

    if (shouldDelete == true) {
      final categoryProvider = ref.read(categoryServiceProvider);
      categoryProvider.deleteCategoryWithTransactions(category.id);
      ref.invalidate(categoryListProvider);
      ref.invalidate(transactionProvider);
      SnackbarService.success(ctxt.categories_categoryDeletedMessage);
    }
  }
}

// ── CATEGORY ROW (with expandable subcategories) ──
class _CategoryRow extends StatefulWidget {
  final Category category;
  final List<Category> subcategories;
  final List<Category> allCategories;
  final AsyncValue<Map<int, int>> transactionCounts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.subcategories,
    required this.allCategories,
    required this.transactionCounts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _expanded = false;

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
    final hasChildren = widget.subcategories.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showContextSheet(context, widget.category, color, textTheme,
                onEdit: widget.onEdit, onDelete: widget.onDelete);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconHelper.getIconData(widget.category.iconName),
                    color: categoryColor,
                    size: 20,
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
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$count txn${count == 1 ? '' : 's'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          if (hasChildren) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            Text(
                              '${widget.subcategories.length} sub',
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (widget.category.keywords != null &&
                              widget.category.keywords!.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
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
                if (hasChildren)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _expanded = !_expanded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
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

        // ── SUBCATEGORIES ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.subcategories.map((sub) {
              final subColor = Color(sub.colorValue ?? Colors.grey.toARGB32());
              final subCount = widget.transactionCounts.when(
                data: (map) => map[sub.id] ?? 0,
                loading: () => 0,
                error: (_, __) => 0,
              );
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showContextSheet(
                    context,
                    sub,
                    color,
                    textTheme,
                    onEdit: () => context.push(
                      '/add-category',
                      extra: {'category': sub},
                    ),
                    onDelete: widget.onDelete,
                  );
                },
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
                        IconHelper.getIconData(sub.iconName),
                        color: subColor,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sub.name,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '$subCount',
                        style: textTheme.labelSmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // ── SHARED CONTEXT BOTTOM SHEET ──
  void _showContextSheet(
    BuildContext context,
    Category category,
    ColorScheme color,
    TextTheme textTheme, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final catColor = Color(category.colorValue ?? Colors.grey.toARGB32());

    showModalBottomSheet(
      context: context,
      backgroundColor: color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      borderRadius: BorderRadius.circular(12),
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
              title: const Text('Edit Category'),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: color.error),
              title: Text(
                'Delete Category',
                style: TextStyle(color: color.error),
              ),
              subtitle: const Text('Removes all linked transactions'),
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
}
