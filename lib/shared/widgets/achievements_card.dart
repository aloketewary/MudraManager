import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';

/// Achievements card showing unlocked count vs total visible.
class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        final visible = achievements.where((a) => a.isVisible).toList();
        final unlocked = visible.where((a) => a.isUnlocked).toList();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(),
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: onTap ??
                () {
                  HapticFeedback.mediumImpact();
                  context.push(AppRoutes.achievements);
                },
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    color: color.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Achievements',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${unlocked.length}/${visible.length}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    color: color.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Card(
        elevation: 0,
        margin: const EdgeInsets.only(),
        color: color.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          side: BorderSide(
            color: color.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(LucideIcons.trophy, color: color.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Your Achievements',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
