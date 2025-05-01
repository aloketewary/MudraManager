import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/providers/transaction_provider.dart';
import 'package:mudra_manager/screens/profile/add_edit_category_screen.dart';
import 'package:mudra_manager/screens/reusable/no_data_found.dart'
    show NoDataFound;
import 'package:mudra_manager/util/icon_helper.dart';

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
        title: Text(
          "Manage Categories",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return NoDataFound(
              // imagePath: 'assets/icons/512/category.png',
              iconData: Icons.category_outlined,
              message: "No categories found.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(thickness: 0.1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = transactionCounts.when(
                data: (map) => map[category.id] ?? 0,
                loading: () => 0,
                error: (_, __) => 0,
              );
              return Container(
                width: 120,
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primary,
                      // color.primaryFixed,
                      color.primaryFixed,
                      Color(category.colorValue ?? 0xFFE0E0E0)
                    ],
                  ),
                  // Light background color
                  border: Border.all(color: color.primary), // Subtle border
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            // backgroundColor: Color(
                            //   category.colorValue ?? 0xFFE0E0E0,
                            // ),
                            child: Icon(
                              IconHelper.getIconData(category.iconName),
                              // color: Colors.black,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  textAlign: TextAlign.start,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: color.onPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  category.categoryType.name.toUpperCase(),
                                  textAlign: TextAlign.start,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "total $count transaction${count == 1 ? '' : 's'} present",
                                  textAlign: TextAlign.start,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: color.onPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      icon: Icon(Icons.edit, color: color.onPrimary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddEditCategoryScreen(
                                  key: key,
                                  existing: category,
                                ),
                          ),
                        );
                      },
                    ),
                    IconButton.filled(
                      icon: Icon(Icons.delete, color: color.onPrimary,),
                      onPressed: () => _deleteCategory(context, ref, category),
                    ),
                  ],
                ),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text("Add Category"),
      ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: const Text(
              'Are you sure you want to delete this category?\nAll associated transactions will also be removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;
    final categoryProvider = ref.read(categoryServiceProvider);
    categoryProvider.deleteCategoryWithTransactions(category.id);
    // Invalidate category and transaction providers to refresh UI
    ref.invalidate(categoryListProvider);
    ref.invalidate(transactionProvider); // if you have one

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Category and its transactions deleted")),
    );
  }
}
