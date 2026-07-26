import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

class BadgeShowcase extends ConsumerWidget {
  const BadgeShowcase({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final spacing = ref.watch(spacingProvider);

    return achievementsAsync.when(
      data: (achievements) {
        final visible = achievements.where((a) => a.isVisible).toList();
        final unlocked = visible.where((a) => a.isUnlocked).toList();
        final total = visible.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (unlocked.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trophy,
                      color: color.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start tracking to unlock achievements!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.take(10).map((achievement) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      semanticLabel: 'Decorative image',
                      'assets/icons/20/${achievement.icon}.png',
                      width: 35,
                    ),
                  );
                }).toList(),
              ),
            if (unlocked.length > 10) ...[
              const SizedBox(height: 8),
              Text(
                '+${unlocked.length - 10} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Progress',
                    value: total > 0 ? unlocked.length / total : 0,
                    backgroundColor: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.achievements);
                  },
                  child: Text(
                    'View All',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
