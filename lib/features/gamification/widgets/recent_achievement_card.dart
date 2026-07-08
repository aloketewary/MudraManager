import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class RecentAchievementCard extends ConsumerWidget {
  final double horizontalPadding;

  const RecentAchievementCard({super.key, this.horizontalPadding = 12});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final spacing = ref.watch(spacingProvider);

    final achievements = ref.watch(achievementsProvider);

    return achievements.when(
      data: (list) {
        final recent = list.where((a) => a.isUnlocked).toList()
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

        if (recent.isEmpty) return const SizedBox.shrink();

        final achievement = recent.first;

        final isRecent =
            DateTime.now().difference(achievement.unlockedAt!).inDays <= 7;

        if (!isRecent) return const SizedBox.shrink();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _AchievementCard(
            key: ValueKey(achievement.id),
            achievement: achievement,
            theme: theme,
            color: color,
            padding: horizontalPadding,
          ),
        );
      },

      loading: () => const _AchievementSkeleton(),

      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/* ---------------------------------------------------------- */
/* Card Widget */
/* ---------------------------------------------------------- */

class _AchievementCard extends ConsumerWidget {
  final dynamic achievement;
  final ThemeData theme;
  final ColorScheme color;
  final double padding;

  const _AchievementCard({
    super.key,
    required this.achievement,
    required this.theme,
    required this.color,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 6),

      child: Card(
        elevation: 1,
        shadowColor: color.shadow.withValues(alpha: 0.2),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusSmall)),

        color: color.surfaceContainerHighest,

        child: InkWell(
          borderRadius: BorderRadius.circular(spacing.radiusSmall),

          onTap: () {
            HapticFeedback.selectionClick();
            context.push(AppRoutes.achievements);
          },

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                _IconBadge(icon: achievement.icon),

                const SizedBox(width: 16),

                Expanded(child: _TextSection(achievement: achievement)),

                const Icon(LucideIcons.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------- */
/* Icon */
/* ---------------------------------------------------------- */

class _IconBadge extends ConsumerWidget {
  final String icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      width: 52,
      height: 52,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: color.primaryContainer,
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
      ),

      child: Text(icon, style: const TextStyle(fontSize: 26)),
    );
  }
}

/* ---------------------------------------------------------- */
/* Text Section */
/* ---------------------------------------------------------- */

class _TextSection extends StatelessWidget {
  final dynamic achievement;

  const _TextSection({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Achievement Unlocked',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          achievement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,

          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          achievement.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,

          style: theme.textTheme.bodySmall?.copyWith(
            color: color.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/* ---------------------------------------------------------- */
/* Skeleton Loader */
/* ---------------------------------------------------------- */

class _AchievementSkeleton extends ConsumerWidget {
  const _AchievementSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: Card(
        color: color.surfaceContainerHighest,
        elevation: 0,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusSmall)),

        child: const Padding(
          padding: EdgeInsets.all(16),

          child: Row(
            children: [
              _SkeletonBox(52, 52),

              SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _SkeletonBox(120, 12),
                    SizedBox(height: 8),
                    _SkeletonBox(double.infinity, 14),
                    SizedBox(height: 6),
                    _SkeletonBox(200, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends ConsumerWidget {
  final double width;
  final double height;

  const _SkeletonBox(this.width, this.height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return Container(
      width: width,
      height: height,

      decoration: BoxDecoration(
        color: color.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
      ),
    );
  }
}
