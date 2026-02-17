import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category;
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final transactionCounts = ref.watch(transactionCountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.categories_manageCategoriesTitle, style: textTheme.titleLarge),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const NoDataFound(
              iconData: Icons.category_outlined,
              message: "No categories found.",
            );
          }
          
          final parentCategories = categories.where((c) => c.parentCategory.value == null).toList();
          
          return ListView.separated(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 100,
            ),
            itemCount: parentCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = parentCategories[index];
              final subcategories = categories.where((c) => c.parentCategory.value?.id == category.id).toList();
              return _CategoryTile(
                category: category,
                subcategories: subcategories,
                transactionCounts: transactionCounts,
                onEdit: () => context.push('/add-category', extra: {'category': category}),
                onDelete: () => _deleteCategory(context, ref, category, ctxt),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-category');
        },
        icon: const Icon(Icons.add),
        label: Text(ctxt.categories_addCategoryLabel),
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


class _CategoryTile extends StatefulWidget {
  final Category category;
  final List<Category> subcategories;
  final AsyncValue<Map<int, int>> transactionCounts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.subcategories,
    required this.transactionCounts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final count = widget.transactionCounts.when(
      data: (map) => map[widget.category.id] ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final categoryColor = Color(widget.category.colorValue ?? 0xFFE0E0E0);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color.surfaceContainerHighest,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconHelper.getIconData(widget.category.iconName),
                color: categoryColor,
                size: 24,
              ),
            ),
            title: Text(
              widget.category.name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurface,
              ),
            ),
            subtitle: Text(
              '$count ${count == 1 ? 'transaction' : 'transactions'} • ${widget.category.categoryType.name.toUpperCase()}',
              style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.subcategories.isNotEmpty)
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: color.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') widget.onEdit();
                    else if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: color.primary, size: 20),
                          const SizedBox(width: 12),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: color.error, size: 20),
                          const SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: color.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_expanded && widget.subcategories.isNotEmpty)
            ...widget.subcategories.map((sub) {
              final subCount = widget.transactionCounts.when(
                data: (map) => map[sub.id] ?? 0,
                loading: () => 0,
                error: (_, __) => 0,
              );
              final subColor = Color(sub.colorValue ?? 0xFFE0E0E0);
              return Container(
                margin: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: color.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(IconHelper.getIconData(sub.iconName), color: subColor, size: 20),
                  title: Text(sub.name, style: textTheme.bodyMedium),
                  subtitle: Text('$subCount ${subCount == 1 ? 'transaction' : 'transactions'}', style: textTheme.bodySmall),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/add-category', extra: {'category': sub});
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: const Text('Edit')),
                      PopupMenuItem(value: 'delete', child: const Text('Delete')),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
