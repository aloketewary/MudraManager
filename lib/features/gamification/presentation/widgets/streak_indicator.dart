import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';

class StreakIndicator extends ConsumerWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dailyStreakProvider);
    final spacing = ref.watch(spacingProvider);
    if (streak == null || streak.currentCount == 0) {
      return const SizedBox.shrink();
    }

    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final now = DateTime.now();
    final isCheckedToday = streak.lastChecked != null &&
        streak.lastChecked!.year == now.year &&
        streak.lastChecked!.month == now.month &&
        streak.lastChecked!.day == now.day;

    final flame = Icon(
      LucideIcons.flame,
      color: color.onError,
      size: spacing.iconMD,
    );
    final animatedFlame = isCheckedToday && !reduceMotion
        ? flame.animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1800.ms,
              color: color.onError.withValues(alpha: 0.48),
            )
        : flame;

    return Semantics(
      button: true,
      label: '${streak.currentCount} day streak',
      hint: isCheckedToday
          ? 'Checked in today. Double tap to view achievements.'
          : 'Double tap to view achievements.',
      child: Tooltip(
        message: '${streak.currentCount}-day streak',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.achievements);
            },
            borderRadius: BorderRadius.circular(spacing.radiusLarge),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: spacing.touchTarget),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.elementGapMin,
                  vertical: spacing.elementGapMin / 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: spacing.animNormal,
                          width: spacing.touchTargetSmall - spacing.elementGap,
                          height: spacing.touchTargetSmall - spacing.elementGap,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.error,
                                color.error.withValues(alpha: 0.78),
                              ],
                            ),
                            border: Border.all(
                              color: color.onError.withValues(alpha: 0.28),
                              width: spacing.strokeThin,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.error.withValues(
                                  alpha: isCheckedToday ? 0.30 : 0.16,
                                ),
                                blurRadius: isCheckedToday ? 12 : 8,
                                spreadRadius: isCheckedToday ? 1 : 0,
                              ),
                            ],
                          ),
                          child: Center(child: animatedFlame),
                        ),
                        if (isCheckedToday)
                          Positioned(
                            right: -2,
                            bottom: -1,
                            child: Container(
                              width: spacing.iconSM,
                              height: spacing.iconSM,
                              decoration: BoxDecoration(
                                color: color.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color.error.withValues(alpha: 0.24),
                                  width: spacing.strokeThin,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.check,
                                size:
                                    spacing.iconXS - spacing.elementGapMin / 2,
                                color: color.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: spacing.elementGapMin),
                    AnimatedContainer(
                      duration: spacing.animNormal,
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.elementGap,
                        vertical: spacing.elementGapMin + 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(spacing.radiusLarge),
                        border: Border.all(
                          color: color.error.withValues(alpha: 0.24),
                          width: spacing.strokeThin,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: spacing.animFast,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Text(
                          '${streak.currentCount}',
                          key: ValueKey(streak.currentCount),
                          style: textTheme.labelLarge?.copyWith(
                            color: color.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1,
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
