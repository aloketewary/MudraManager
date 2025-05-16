import 'package:flutter/material.dart';
import 'package:mudra_manager/theme/app_color_theme_enum.dart';

class ThemePreviewCard extends StatelessWidget {
  final AppColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final light = theme.lightColorScheme();
    final dark = theme.darkColorScheme();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? light.primary : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Card(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: light.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: light.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [Tab(text: 'Light'), Tab(text: 'Dark')],
                    ),
                    SizedBox(
                      height: 180,
                      child: TabBarView(
                        children: [
                          _ThemePreviewSurface(colorScheme: light),
                          _ThemePreviewSurface(colorScheme: dark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: light.primary,
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// class _ThemePreviewSurface extends StatelessWidget {
//   final ColorScheme colorScheme;
//
//   const _ThemePreviewSurface({required this.colorScheme});
//
//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//     final color = Theme.of(context).colorScheme;
//
//     return Container(
//       color: colorScheme.surface,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Primary Color',
//             style: textTheme.titleMedium?.copyWith(color: color.primary),
//           ),
//           Text(
//             'Secondary Color',
//             style: textTheme.titleMedium?.copyWith(color: color.secondary),
//           ),
//           Text(
//             'Tertiary Color',
//             style: textTheme.titleMedium?.copyWith(color: color.tertiary),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: colorScheme.primary,
//               foregroundColor: colorScheme.onPrimary,
//             ),
//             onPressed: () {},
//             child: const Text("FAB Example"),
//           ),
//         ],
//       ),
//     );
//   }
// }
class _ThemePreviewSurface extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ThemePreviewSurface({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: () {},
              child: const Text("FAB Example"),
            ),
          ),
        ],
      ),
    );
  }
}
