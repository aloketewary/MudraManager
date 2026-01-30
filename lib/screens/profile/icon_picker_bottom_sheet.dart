import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      height: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pick an Icon",
            style: textTheme.titleLarge?.copyWith(
              color: color.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children:
                  _iconMap.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => context.pop(entry.key),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: backgroundColor,
                            child: Icon(
                              entry.value,
                              size: 28,
                              color: color.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key.toTitleCase().split("_").join(" "),
                            style: textTheme.labelMedium?.copyWith(color: color.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
