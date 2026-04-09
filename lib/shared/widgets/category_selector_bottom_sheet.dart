import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/shared/widgets/category_card.dart';
import 'package:mudra_manager/shared/widgets/responsive_helper.dart';

class CategorySelectorBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<CategorySelectorBottomSheet> createState() =>
      _CategorySelectorBottomSheetState();
}

class _CategorySelectorBottomSheetState
    extends ConsumerState<CategorySelectorBottomSheet> {
  Category? _selectedParent;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      selectableCategoriesProvider(
        widget.isExpense ? CategoryType.expense : CategoryType.income,
      ),
    );
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

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
                Row(
                  children: [
                    if (_selectedParent != null)
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: () => setState(() => _selectedParent = null),
                      ),
                    Expanded(
                      child: Text(
                        _selectedParent == null
                            ? 'Select Category'
                            : _selectedParent!.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: _selectedParent == null
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                    ),
                  ],
                ),
                if (_selectedParent == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap to select • Long press parent to select without subcategories',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filtered = categories;

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories found',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }

                final displayCategories = _selectedParent == null
                    ? filtered
                        .where((c) => c.parentCategory.value == null)
                        .toList()
                    : filtered
                        .where(
                          (c) =>
                              c.parentCategory.value?.id == _selectedParent!.id,
                        )
                        .toList();

                return GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(
                      context,
                    ),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: ResponsiveHelper.getGridAspectRatio(
                      context,
                      defaultRatio: 2.5,
                      singleColumnRatio: 4.0,
                    ),
                  ),
                  itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                    final category = displayCategories[index];
                    final hasSubcategories = _selectedParent == null &&
                        filtered.any(
                          (c) => c.parentCategory.value?.id == category.id,
                        );

                    return Stack(
                      children: [
                        CategoryCard(
                          label: category.name,
                          color: Color(category.colorValue ?? 0xFF000000),
                          icon: IconHelper.getIconData(category.iconName),
                          isSelected:
                              widget.selectedCategory?.id == category.id,
                          callbackAction: () {
                            if (hasSubcategories) {
                              setState(() => _selectedParent = category);
                            } else {
                              widget.onCategorySelected(category);
                            }
                          },
                          onLongPress: hasSubcategories
                              ? () => widget.onCategorySelected(category)
                              : null,
                        ),
                        if (hasSubcategories)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.chevronRight,
                                size: 12,
                                color: color.onPrimary,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const SkeletonLoader(width: double.infinity, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
