import 'package:flutter/material.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({super.key, required this.achievement, this.onTap});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isUnlocked = achievement.isUnlocked;

    return Card(
      elevation: isUnlocked ? 4 : 0,
      shadowColor: isUnlocked ? color.primary.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isUnlocked
            ? BorderSide(color: color.primary.withValues(alpha: 0.3), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.primaryContainer, color.secondaryContainer],
                  )
                : null,
            color: isUnlocked
                ? null
                : color.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon with premium styling
              SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: Image.asset(
                    'assets/icons/100/${achievement.icon}.png',
                    color: isUnlocked ? null : Colors.grey.shade400,
                  ),
                ),
              ),
              const Spacer(),

              // Title
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? color.onPrimaryContainer
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                achievement.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUnlocked
                      ? color.onPrimaryContainer.withValues(alpha: 0.8)
                      : Colors.grey.shade500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Progress or XP badge
              if (!isUnlocked) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: achievement.progress / achievement.target,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      color.primary.withValues(alpha: 0.6),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.progress}/${achievement.target}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, size: 14, color: color.primary),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.rewardXP} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
