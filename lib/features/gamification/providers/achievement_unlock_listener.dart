import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/widgets/achievement_unlock_dialog.dart';

final achievementUnlockListenerProvider = Provider<AchievementUnlockListener>((ref) {
  return AchievementUnlockListener(ref);
});

class AchievementUnlockListener {
  final Ref ref;
  final Set<String> _shownAchievements = {};

  AchievementUnlockListener(this.ref);

  void initialize(BuildContext context) {
    ref.listen<AsyncValue<List<Achievement>>>(
      achievementsProvider,
      (previous, next) {
        next.whenData((achievements) {
          final now = DateTime.now();
          
          for (final achievement in achievements) {
            if (achievement.isUnlocked && 
                achievement.unlockedAt != null &&
                !_shownAchievements.contains(achievement.key)) {
              
              final timeSinceUnlock = now.difference(achievement.unlockedAt!);
              if (timeSinceUnlock.inSeconds < 10) {
                _shownAchievements.add(achievement.key);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    _showAchievementDialog(context, achievement);
                  }
                });
              }
            }
          }
        });
      },
    );
  }

  void _showAchievementDialog(BuildContext context, Achievement achievement) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockDialog(
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        xpReward: achievement.rewardXP,
      ),
    );
  }

  void reset() {
    _shownAchievements.clear();
  }
}
