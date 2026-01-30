import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/util/case_extension.dart';
import 'package:mudra_manager/util/icon_helper.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  headerColor.withValues(alpha: 0.8),
                  headerColor,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Pick an Icon',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: _iconMap.entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.pop(entry.key);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
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
                          Text(
                            entry.key.toTitleCase().split('_').first,
                            style: textTheme.labelSmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
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
