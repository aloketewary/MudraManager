import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

class ThemePreviewCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = brightness == Brightness.light
        ? theme.lightColorScheme()
        : theme.darkColorScheme();
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: '${theme.label} theme${isSelected ? ', selected' : ''}',
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: TweenAnimationBuilder<double>(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 1.0, end: isSelected ? 1.02 : 1.0),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
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
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 28,
                          color: colorScheme.surface,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.menu,
                                size: 12,
                                color: colorScheme.onSurface,
                              ),
                              SizedBox(width: spacing.elementGapMin),
                              Container(
                                height: 5,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: colorScheme.surfaceContainer,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                        spacing.radiusSmall,),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.check,
                                          size: 12,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                      SizedBox(width: spacing.elementGapMin),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 5,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color:
                                                  colorScheme.onPrimaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.pencil,
                                      size: 12,
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
                    AnimatedOpacity(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 150),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemePreviewGrid extends ConsumerWidget {
  final List<AppColorTheme> themes;
  final AppColorTheme? selectedTheme;
  final void Function(AppColorTheme) onSelect;

  const ThemePreviewGrid({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing.elementGap,
        mainAxisSpacing: spacing.elementGap,
        childAspectRatio: 0.85,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        return TweenAnimationBuilder<double>(
          duration: reduceMotion
              ? Duration.zero
              : Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: ThemePreviewCard(
            theme: theme,
            isSelected: selectedTheme == theme,
            onTap: () => onSelect(theme),
          ),
        );
      },
    );
  }
}

class ThemePreviewSkeleton extends ConsumerWidget {
  final int count;

  const ThemePreviewSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing.elementGap,
        mainAxisSpacing: spacing.elementGap,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.3),),
          ),
          child: Column(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const SkeletonLoader(width: 12, height: 12),
                    SizedBox(width: spacing.elementGapMin),
                    const SkeletonLoader(width: 36, height: 5),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      SkeletonLoader(
                        height: 44,
                        borderRadius: BorderRadius.circular(
                            spacing.radiusSmall,),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SkeletonLoader(
                          width: 28,
                          height: 28,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}