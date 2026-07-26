import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/category/data/category_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class CategorySelector extends ConsumerWidget {
  final Category? selectedCategory;
  final Function(Category) onCategorySelected;
  final CategoryType categoryType;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categoryType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return ref
        .watch(selectableCategoriesProvider(categoryType))
        .when(
          data: (categories) {
            final filtered = categories
                .where(
                  (c) =>
                      c.categoryType == categoryType &&
                      c.parentCategory.value == null,
                )
                .toList();

            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index < filtered.length) {
                    return _CategoryCard(
                      category: filtered[index],
                      allCategories: categories,
                      selectedCategory: selectedCategory,
                      onCategorySelected: onCategorySelected,
                      color: color,
                      textTheme: textTheme,
                    );
                  } else {
                    return _AddCategoryButton(
                      color: color,
                      textTheme: textTheme,
                      ctxt: ctxt,
                    );
                  }
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SkeletonLoader(width: 120, height: 120, borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          error: (_, __) => SizedBox(
            height: 120,
            child: Text(BuddyMessages.genericError),
          ),
        );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;
  final List<Category> allCategories;
  final Category? selectedCategory;
  final Function(Category) onCategorySelected;
  final ColorScheme color;
  final TextTheme textTheme;

  const _CategoryCard({
    required this.category,
    required this.allCategories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParentSelected = selectedCategory?.id == category.id;
    final isChildSelected =
        selectedCategory?.parentCategory.value?.id == category.id;
    final isSelected = isParentSelected || isChildSelected;
    final hasSubcategories = allCategories.any(
      (c) => c.parentCategory.value?.id == category.id,
    );
    final spacing = ref.watch(spacingProvider);

    return GestureDetector(
      onTap: () async {
        if (hasSubcategories) {
          final subcategories = allCategories
              .where((c) => c.parentCategory.value?.id == category.id)
              .toList();
          final selected = await showModalBottomSheet<Category>(
            context: context,
            builder: (_) => _SubcategoryPicker(
              parent: category,
              subcategories: subcategories,
              selected: selectedCategory,
            ),
          );
          if (selected != null) onCategorySelected(selected);
        } else {
          HapticFeedback.mediumImpact();
          onCategorySelected(category);
        }
      },
      onLongPress: hasSubcategories
          ? () {
              HapticFeedback.mediumImpact();
              onCategorySelected(category);
            }
          : null,
      child: Card(
        elevation: isSelected ? 4 : 0,
        shadowColor: isSelected ? color.primary.withValues(alpha: 0.3) : null,
        color: isSelected
            ? color.primaryContainer
            : color.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
          side: isSelected
              ? BorderSide(color: color.primary, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryIcon(hasSubcategories, isChildSelected),
              const SizedBox(height: 4),
              _buildCategoryName(isChildSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(bool hasSubcategories, bool isChildSelected) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(
                category.colorValue ?? color.primary.toARGB32(),
              ).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconHelper.iconFromName(category.iconName ?? 'category'),
              color: Color(category.colorValue ?? color.primary.toARGB32()),
              size: 20,
            ),
          ),
          if (isChildSelected && selectedCategory != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(
                    selectedCategory!.colorValue ?? color.primary.toARGB32(),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.surface, width: 2),
                ),
                child: Icon(
                  IconHelper.iconFromName(
                    selectedCategory!.iconName ?? 'category',
                  ),
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          if (hasSubcategories && !isChildSelected)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
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
      ),
    );
  }

  Widget _buildCategoryName(bool isChildSelected) {
    final isSelected = selectedCategory?.id == category.id || isChildSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isChildSelected && selectedCategory != null
              ? selectedCategory!.name
              : category.name,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? color.onPrimaryContainer : color.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (isChildSelected && selectedCategory != null)
          Text(
            category.name,
            style: textTheme.labelSmall?.copyWith(
              color: isSelected
                  ? color.onPrimaryContainer.withValues(alpha: 0.7)
                  : color.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _AddCategoryButton({
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.addCategory),
      child: Card(
        elevation: 0,
        color: color.surfaceContainerHigh,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, color: color.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                ctxt.common_addLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryPicker extends StatelessWidget {
  final Category parent;
  final List<Category> subcategories;
  final Category? selected;

  const _SubcategoryPicker({
    required this.parent,
    required this.subcategories,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parent.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select subcategory or tap parent',
            style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              IconHelper.iconFromName(parent.iconName ?? 'category'),
              color: Color(parent.colorValue ?? 0xFF000000),
            ),
            title: Text('${parent.name} (Parent)'),
            selected: selected?.id == parent.id,
            onTap: () => Navigator.pop(context, parent),
          ),
          const Divider(),
          ...subcategories.map(
            (sub) => ListTile(
              leading: Icon(
                IconHelper.iconFromName(sub.iconName ?? 'category'),
                color: Color(sub.colorValue ?? 0xFF000000),
              ),
              title: Text(sub.name),
              selected: selected?.id == sub.id,
              onTap: () => Navigator.pop(context, sub),
            ),
          ),
        ],
      ),
    );
  }
}
