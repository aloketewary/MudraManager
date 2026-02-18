import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudra_manager/util/icon_helper.dart';

class IconSelector extends StatelessWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;
  final List<String> icons;

  const IconSelector({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.icons = const [
      'savings',
      'home',
      'directions_car',
      'flight',
      'laptop',
      'school',
      'travel',
      'entertainment',
    ],
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: icons.map((icon) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onIconSelected(icon);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selectedIcon == icon
                    ? color.primaryContainer
                    : color.surfaceContainerHighest,
                border: Border.all(
                  color: selectedIcon == icon ? color.primary : color.outline,
                  width: selectedIcon == icon ? 2 : 1,
                ),
              ),
              child: Icon(
                IconHelper.getIconData(icon),
                color: selectedIcon == icon ? color.primary : color.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
