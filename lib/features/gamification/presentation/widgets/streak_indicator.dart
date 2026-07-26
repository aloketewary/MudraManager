import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final now = DateTime.now();
    final isCheckedToday = streak.lastChecked != null &&
        streak.lastChecked!.year == now.year &&
        streak.lastChecked!.month == now.month &&
        streak.lastChecked!.day == now.day;

    final icon = Icon(LucideIcons.flame, color: color.onError, size: 18);

    return Semantics(
      label: '${streak.currentCount} day streak',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.error.withValues(alpha: 0.8),
              color.error,
            ],
          ),
          borderRadius: BorderRadius.circular(spacing.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isCheckedToday
                ? icon
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1500.ms,
                      color: color.onError.withValues(alpha: 0.4),
                    )
                : icon,
            const SizedBox(width: 4),
            Text(
              '${streak.currentCount}',
              style: TextStyle(
                color: color.onError,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
