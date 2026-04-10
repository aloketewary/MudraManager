import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';

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
    // Determine which brightness to show based on system/app setting
    final brightness = Theme.of(context).brightness;
    final colorScheme = brightness == Brightness.light
        ? theme.lightColorScheme()
        : theme.darkColorScheme();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Mini App Preview
              Column(
                children: [
                  // Mini AppBar
                  Container(
                    height: 32,
                    color: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.menu,
                          size: 14,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 6,
                          width: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mini Body
                  Expanded(
                    child: Container(
                      color: colorScheme.surfaceContainer,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Primary Color Card
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colorScheme.primary,
                                  child: Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 6,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onPrimaryContainer,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // FAB
                          Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.tertiary,
                              child: Icon(
                                LucideIcons.pencil,
                                size: 16,
                                color: colorScheme.onTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Selection Checkmark Overlay
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
