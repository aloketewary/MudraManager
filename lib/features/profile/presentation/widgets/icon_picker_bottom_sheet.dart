import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';

class IconPickerBottomSheet extends ConsumerStatefulWidget {
  final Color? backgroundColor;
  final String? selectedIcon;

  const IconPickerBottomSheet({
    super.key,
    this.backgroundColor,
    this.selectedIcon,
  });

  @override
  ConsumerState<IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends ConsumerState<IconPickerBottomSheet> {
  late String _query;
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _query = '';
    _selected = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accentColor = widget.backgroundColor ?? color.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusLarge)),
      ),
      child: Column(
        children: [
          SizedBox(height: spacing.elementGap),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: spacing.sectionGap),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.elementGap),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selected != null ? IconHelper.iconFromName(_selected!) : LucideIcons.shapes,
                    color: accentColor, size: 22,
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: Text(
                    ctxt.iconPicker_title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_selected != null)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.pop(_selected);
                    },
                    child: Text(
                      ctxt.common_done,
                      style: textTheme.titleSmall?.copyWith(color: color.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: spacing.elementGap),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: ctxt.iconPicker_search,
                prefixIcon: Icon(LucideIcons.search, size: 18, color: color.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide(color: color.outlineVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                filled: true,
                fillColor: color.surfaceContainerLow,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.elementGap,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Divider(height: 1, color: color.outlineVariant.withValues(alpha: 0.3)),

          // Icon grid
          Expanded(
            child: _query.isEmpty
                ? _buildGroupedView(color, textTheme, accentColor, spacing)
                : _buildSearchResults(color, textTheme, accentColor, spacing),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedView(ColorScheme color, TextTheme textTheme, Color accentColor, AppSpacing spacing) {
    final groups = IconHelper.iconGroups;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(spacing.cardHorizontal, spacing.elementGap, spacing.cardHorizontal, spacing.sectionGap),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final category = groups.keys.elementAt(index);
        final icons = groups[category]!.keys.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: spacing.elementGap, bottom: spacing.elementGap, left: spacing.elementGapMin),
              child: Text(
                category,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: color.primary, letterSpacing: 0.3,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: spacing.elementGap,
                mainAxisSpacing: spacing.elementGap,
              ),
              itemCount: icons.length,
              itemBuilder: (context, i) => _buildIconTile(icons[i], color, textTheme, accentColor, spacing),
            ),
            SizedBox(height: spacing.elementGapMin),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(ColorScheme color, TextTheme textTheme, Color accentColor, AppSpacing spacing) {
    final ctxt = AppLocalizations.of(context)!;
    final results = IconHelper.iconMap.keys.where((k) => k.contains(_query)).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: color.onSurfaceVariant.withValues(alpha: 0.3)),
            SizedBox(height: spacing.elementGap),
            Text(ctxt.iconPicker_noResults, style: textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(spacing.cardHorizontal),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: spacing.elementGap,
          mainAxisSpacing: spacing.elementGap,
        ),
        itemCount: results.length,
        itemBuilder: (context, i) => _buildIconTile(results[i], color, textTheme, accentColor, spacing),
      ),
    );
  }

  Widget _buildIconTile(String iconName, ColorScheme color, TextTheme textTheme, Color accentColor, AppSpacing spacing) {
    final iconData = IconHelper.iconFromName(iconName);
    final isSelected = _selected == iconName;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selected = iconName);
      },
      onDoubleTap: () {
        HapticFeedback.mediumImpact();
        context.pop(iconName);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isSelected ? accentColor : color.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 24, color: isSelected ? accentColor : color.onSurfaceVariant),
            SizedBox(height: spacing.elementGapUltraMin),
            Text(
              iconName.split('_').first.toTitleCase(),
              style: textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isSelected ? accentColor : color.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
