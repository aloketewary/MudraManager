import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/category.dart';
import 'package:mudra_manager/providers/category_provider.dart';
import 'package:mudra_manager/screens/reusable/category_card.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/components/responsive_helper.dart';

class CategorySelectorBottomSheet extends ConsumerWidget {
  final Category? selectedCategory;
  final bool isExpense;
  final Function(Category) onCategorySelected;

  const CategorySelectorBottomSheet({
    super.key,
    this.selectedCategory,
    required this.isExpense,
    required this.onCategorySelected,
  });

  static Future<Category?> show(
    BuildContext context, {
    Category? selectedCategory,
    required bool isExpense,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CategorySelectorBottomSheet(
        selectedCategory: selectedCategory,
        isExpense: isExpense,
        onCategorySelected: (category) => Navigator.pop(context, category),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Category',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filtered = categories
                    .where((c) => (isExpense && c.categoryType == CategoryType.expense) || 
                                  (!isExpense && c.categoryType == CategoryType.income))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories found',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }

                return GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: ResponsiveHelper.getGridAspectRatio(context, defaultRatio: 2.5, singleColumnRatio: 4.0),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    return CategoryCard(
                      label: category.name,
                      color: Color(category.colorValue ?? 0xFF000000),
                      icon: IconHelper.getIconData(category.iconName),
                      isSelected: selectedCategory?.id == category.id,
                      callbackAction: () => onCategorySelected(category),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
