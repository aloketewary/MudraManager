import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

class StreakIndicator extends ConsumerWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dailyStreakProvider);

    if (streak == null || streak.currentCount == 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final isCheckedToday = streak.lastChecked != null &&
        streak.lastChecked!.year == now.year &&
        streak.lastChecked!.month == now.month &&
        streak.lastChecked!.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isCheckedToday
              ? const Icon(LucideIcons.flame, color: Colors.white, size: 20)
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.yellow.withValues(alpha: 0.5),
                  )
                  .shake(
                    duration: 2000.ms,
                    hz: 2,
                    rotation: 0.05,
                  )
              : const Icon(LucideIcons.flame, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text(
            '${streak.currentCount}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
