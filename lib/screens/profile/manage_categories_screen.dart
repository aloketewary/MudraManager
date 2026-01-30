import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/util/dialog_utils.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/util/snackbar_service.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final transactionCounts = ref.watch(transactionCountsProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Categories", style: textTheme.titleLarge),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const NoDataFound(
              iconData: Icons.category_outlined,
              message: "No categories found.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 100, // Space for FAB
            ),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = transactionCounts.when(
                data: (map) => map[category.id] ?? 0,
                loading: () => 0,
                error: (_, __) => 0,
              );

              final categoryColor = Color(category.colorValue ?? 0xFFE0E0E0);

              return Container(
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.shadow.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIconData(category.iconName),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${count} transaction${count == 1 ? '' : 's'} • ${category.categoryType.name.toUpperCase()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: color.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/add-category');
                      } else if (value == 'delete') {
                        _deleteCategory(context, ref, category);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: color.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: color.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: color.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-category');
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Category"),
      ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final shouldDelete = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Category',
      message:
          'Are you sure you want to delete this category?\nAll associated transactions will also be removed.',
    );

    if (shouldDelete == true) {
      final categoryProvider = ref.read(categoryServiceProvider);
      categoryProvider.deleteCategoryWithTransactions(category.id);
      ref.invalidate(categoryListProvider);
      ref.invalidate(transactionProvider);
      SnackbarService.success("Category and its transactions deleted");
    }
  }
}
