import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/extension/case_extention.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';

class IconPickerBottomSheet extends StatefulWidget {
  final Color? backgroundColor;
  final String? selectedIcon;

  const IconPickerBottomSheet({
    super.key,
    this.backgroundColor,
    this.selectedIcon,
  });

  @override
  State<IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends State<IconPickerBottomSheet> {
  late String _query;
  late String? _selected;

  static const _iconCategories = {
    'Financial': [
      'bank',
      'attach_money',
      'credit_card',
      'savings',
      'wallet',
      'atm',
      'investment',
      'salary',
    ],
    'Food & Dining': [
      'restaurant',
      'coffee',
      'fastfood',
      'groceries',
      'wine',
      'nightlife',
      'cake',
    ],
    'Shopping': [
      'shopping_cart',
      'shopping_bag',
      'clothing',
      'gift',
      'electronics',
      'furniture',
    ],
    'Transportation': [
      'directions_car',
      'gas',
      'bus',
      'train',
      'flight',
      'taxi',
      'bike',
      'walk',
    ],
    'Entertainment': [
      'entertainment',
      'games',
      'music',
      'sports',
      'camera',
      'photo',
      'tv',
      'videogame',
    ],
    'Health & Fitness': [
      'local_hospital',
      'medical',
      'pharmacy',
      'fitness',
      'spa',
      'beauty',
    ],
    'Education': ['school', 'book', 'library', 'work', 'business'],
    'Home & Utilities': [
      'home',
      'electric',
      'water',
      'wifi',
      'phone',
      'bills',
      'cleaning',
      'laundry',
    ],
    'Travel': ['flight', 'hotel', 'travel', 'beach', 'park'],
    'Family & Social': [
      'pets',
      'child',
      'baby',
      'toys',
      'celebration',
      'donation',
      'charity',
    ],
    'Work & Business': [
      'work',
      'business',
      'computer',
      'phone_mobile',
      'print',
      'mail',
    ],
    'Personal Care': ['beauty', 'spa', 'watch', 'clothing', 'headphones'],
    'Maintenance': [
      'repair',
      'tools',
      'garden',
      'cleaning',
      'laundry',
      'delivery',
    ],
    'Other': [
      'subscriptions',
      'insurance',
      'tax',
      'refund',
      'bonus',
      'trending_up',
      'parking',
      'others',
    ],
  };

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
    final accentColor = widget.backgroundColor ?? color.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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

          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selected != null
                        ? IconHelper.iconFromName(_selected!)
                        : LucideIcons.shapes,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pick an Icon',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selected != null)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.pop(_selected);
                    },
                    child: Text(
                      'Done',
                      style: textTheme.titleSmall?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SEARCH ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: color.onSurfaceVariant,
                ),
                filled: true,
                fillColor: color.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: color.outlineVariant.withValues(alpha: 0.3),
          ),

          // ── ICON GRID ──
          Expanded(
            child: _query.isEmpty
                ? _buildGroupedView(color, textTheme, accentColor)
                : _buildSearchResults(color, textTheme, accentColor),
          ),
        ],
      ),
    );
  }

  // ── GROUPED VIEW ──
  Widget _buildGroupedView(
    ColorScheme color,
    TextTheme textTheme,
    Color accentColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _iconCategories.length,
      itemBuilder: (context, index) {
        final category = _iconCategories.keys.elementAt(index);
        final icons = _iconCategories[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10, left: 4),
              child: Text(
                category,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: icons.length,
              itemBuilder: (context, i) =>
                  _buildIconTile(icons[i], color, textTheme, accentColor),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  // ── SEARCH RESULTS ──
  Widget _buildSearchResults(
    ColorScheme color,
    TextTheme textTheme,
    Color accentColor,
  ) {
    final results =
        IconHelper.iconMap.keys.where((k) => k.contains(_query)).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No icons found',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: results.length,
        itemBuilder: (context, i) =>
            _buildIconTile(results[i], color, textTheme, accentColor),
      ),
    );
  }

  // ── SINGLE ICON TILE ──
  Widget _buildIconTile(
    String iconName,
    ColorScheme color,
    TextTheme textTheme,
    Color accentColor,
  ) {
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
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor
                : color.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 24,
              color: isSelected ? accentColor : color.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              iconName.split('_').first.toTitleCase(),
              style: textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isSelected
                    ? accentColor
                    : color.onSurfaceVariant.withValues(alpha: 0.7),
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
