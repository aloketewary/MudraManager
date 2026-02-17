import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/components/adaptive_text.dart';

class IconPickerBottomSheet extends StatefulWidget {
  final Color? backgroundColor;

  const IconPickerBottomSheet({super.key, this.backgroundColor = Colors.blueAccent});

  @override
  State<IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends State<IconPickerBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, IconData> _iconMap = IconHelper.iconMap;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    final headerColor = widget.backgroundColor ?? color.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.category, color: color.primary),
                SizedBox(width: 12),
                Text(
                  'Pick an Icon',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All Icons'),
              Tab(text: 'By Category'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllIconsTab(color, textTheme, headerColor, context),
                _buildCategoryIconsTab(color, textTheme, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllIconsTab(ColorScheme color, TextTheme textTheme, Color headerColor, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _iconMap.entries.map((entry) {
          return InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.pop(entry.key);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    entry.value,
                    size: 32,
                    color: headerColor,
                  ),
                  SizedBox(height: 4),
                  AdaptiveText(
                    entry.key.toTitleCase().split('_').first,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryIconsTab(ColorScheme color, TextTheme textTheme, BuildContext context) {
    final iconCategories = {
      'Financial': ['bank', 'attach_money', 'credit_card', 'savings', 'wallet', 'atm', 'investment', 'salary'],
      'Food & Dining': ['restaurant', 'coffee', 'fastfood', 'groceries', 'wine', 'nightlife', 'cake'],
      'Shopping': ['shopping_cart', 'shopping_bag', 'groceries', 'clothing', 'gift', 'electronics', 'furniture'],
      'Transportation': ['directions_car', 'gas', 'bus', 'train', 'flight', 'taxi', 'bike', 'walk'],
      'Entertainment': ['entertainment', 'games', 'music', 'sports', 'camera', 'photo', 'tv', 'videogame'],
      'Health & Fitness': ['local_hospital', 'medical', 'pharmacy', 'fitness', 'spa', 'beauty'],
      'Education': ['school', 'book', 'library', 'work', 'business'],
      'Home & Utilities': ['home', 'electric', 'water', 'wifi', 'phone', 'bills', 'cleaning', 'laundry'],
      'Travel': ['flight', 'hotel', 'travel', 'beach', 'park'],
      'Family & Social': ['pets', 'child', 'baby', 'toys', 'celebration', 'donation', 'charity'],
      'Work & Business': ['work', 'business', 'computer', 'phone_mobile', 'print', 'mail'],
      'Personal Care': ['beauty', 'spa', 'watch', 'clothing', 'headphones'],
      'Maintenance': ['repair', 'tools', 'garden', 'cleaning', 'laundry', 'delivery'],
      'Other': ['subscriptions', 'insurance', 'tax', 'refund', 'bonus', 'trending_up', 'parking', 'others'],
    };
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: iconCategories.length,
      itemBuilder: (context, index) {
        final category = iconCategories.keys.elementAt(index);
        final icons = iconCategories[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: icons.length,
              itemBuilder: (context, iconIndex) {
                final iconName = icons[iconIndex];
                final iconData = IconHelper.iconFromName(iconName);
                
                return InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.pop(iconName);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          size: 28,
                          color: widget.backgroundColor ?? color.primary,
                        ),
                        SizedBox(height: 4),
                        AdaptiveText(
                          iconName.split('_').first,
                          style: textTheme.labelSmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
