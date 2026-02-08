import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/icon_helper.dart';
import 'package:mudra_manager/components/adaptive_text.dart';

class IconPickerBottomSheet extends StatelessWidget {
  final Color? backgroundColor;

  IconPickerBottomSheet({super.key, this.backgroundColor = Colors.blueAccent});

  final Map<String, IconData> _iconMap = IconHelper.iconMap;

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    final headerColor = backgroundColor ?? color.primary;
    
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
          Divider(height: 1),
          Expanded(
            child: Padding(
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
            ),
          ),
        ],
      ),
    );
  }
}
