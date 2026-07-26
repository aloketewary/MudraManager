import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/category.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';

/// Parent category picker bottom sheet.
///
/// Usage:
/// ```dart
/// final selected = await showModalBottomSheet<Category?>(
///   context: context,
///   builder: (_) => ParentCategoryPicker(
///     categories: filtered,
///     selected: _selectedParent,
///   ),
/// );
/// ```
class ParentCategoryPicker extends ConsumerWidget {
  final List<Category> categories;
  final Category? selected;

  const ParentCategoryPicker({
    super.key,
    required this.categories,
    this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusMedium + 4),
        ),
        border: Border.all(
          color: color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusMedium + 4),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                // Header
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.elementGap),
                        decoration: BoxDecoration(
                          color: color.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(spacing.radiusSmall),
                        ),
                        child: Icon(
                          LucideIcons.folderPlus,
                          color: color.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: spacing.sectionGap),
                      Expanded(
                        child: Text(
                          ctxt.category_selectParent,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.sectionGap),
                Divider(
                  height: 1,
                  color: color.outlineVariant.withValues(alpha: 0.3),
                ),
                // Options
                Expanded(
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: Column(
                      children: [
                        _buildOption(
                          context: context,
                          label: ctxt.category_noneTopLevel,
                          color: color.primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context, Category());
                          },
                          isSelected: selected == null,
                          reduceMotion: reduceMotion,
                          spacing: spacing,
                        ),
                        ...categories.map((c) {
                          final catColor =
                              Color(c.colorValue ?? Colors.grey.toARGB32());
                          return _buildOption(
                            context: context,
                            label: c.name,
                            color: catColor,
                            icon: IconHelper.getIconData(c.iconName),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context, c);
                            },
                            isSelected: selected?.id == c.id,
                            reduceMotion: reduceMotion,
                            spacing: spacing,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
    required bool reduceMotion,
    required AppSpacing spacing,
    IconData? icon,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.elementGapMin,
      ),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(spacing.cardInner),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(
                    icon ?? LucideIcons.minus,
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing.sectionGap),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(spacing.elementGapMin),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: color,
                      size: 14,
                    ),
                  )
                else
                  Icon(
                    LucideIcons.chevronRight,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
