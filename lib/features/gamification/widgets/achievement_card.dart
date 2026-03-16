import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  Color _categoryAccent(ColorScheme color) {
    switch (achievement.category) {
      case AchievementCategory.budgeting:
        return const Color(0xFF2196F3);
      case AchievementCategory.saving:
        return const Color(0xFF4CAF50);
      case AchievementCategory.tracking:
        return const Color(0xFF9C27B0);
      case AchievementCategory.milestone:
        return const Color(0xFFFF9800);
      case AchievementCategory.engagement:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnlocked = achievement.isUnlocked;
    final accent = _categoryAccent(color);
    final progress = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isUnlocked ? null : color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked
              ? accent.withValues(alpha: 0.4)
              : color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetail(context, color, textTheme, accent);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: isUnlocked
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.12),
                      accent.withValues(alpha: 0.04),
                    ],
                  ),
                )
              : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              const Spacer(),

              // ── BADGE ICON ──
              _BadgeIcon(
                icon: achievement.icon,
                isUnlocked: isUnlocked,
                accent: accent,
                color: color,
              ),

              const Spacer(),

              // ── TITLE ──
              Text(
                achievement.title,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUnlocked ? accent : color.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // ── DESCRIPTION ──
              Text(
                achievement.description,
                style: textTheme.labelSmall?.copyWith(
                  color: isUnlocked
                      ? color.onSurfaceVariant
                      : color.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // ── BOTTOM: XP or PROGRESS ──
              if (isUnlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.rewardXP} XP',
                        style: textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor:
                            color.onSurfaceVariant.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          accent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.progress} / ${achievement.target}',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DETAIL SHEET ──
  void _showDetail(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    Color accent,
  ) {
    final isUnlocked = achievement.isUnlocked;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Badge icon large
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked
                      ? accent.withValues(alpha: 0.3)
                      : color.outlineVariant.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isUnlocked
                    ? accent.withValues(alpha: 0.1)
                    : color.surfaceContainerLow,
                child: Image.asset(
                  'assets/icons/100/${achievement.icon}.png',
                  width: 48,
                  height: 48,
                  color: isUnlocked
                      ? null
                      : color.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              achievement.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Info row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoPill(
                  isUnlocked ? 'Unlocked' : 'In Progress',
                  isUnlocked
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                  color,
                  textTheme,
                ),
                const SizedBox(width: 8),
                _infoPill(
                  '+${achievement.rewardXP} XP',
                  accent,
                  color,
                  textTheme,
                ),
                const SizedBox(width: 8),
                _infoPill(
                  _categoryLabel(achievement.category),
                  accent,
                  color,
                  textTheme,
                ),
              ],
            ),

            // Progress bar for locked
            if (!isUnlocked) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.target > 0
                            ? achievement.progress / achievement.target
                            : 0,
                        minHeight: 8,
                        backgroundColor:
                            color.onSurfaceVariant.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${achievement.progress}/${achievement.target}',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],

            // Unlock date
            if (isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Unlocked ${DateFormat('MMM dd, yyyy').format(achievement.unlockedAt!)}',
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(
    String label,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _categoryLabel(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.budgeting:
        return 'Budget';
      case AchievementCategory.saving:
        return 'Savings';
      case AchievementCategory.tracking:
        return 'Tracking';
      case AchievementCategory.milestone:
        return 'Milestone';
      case AchievementCategory.engagement:
        return 'Engage';
    }
  }
}

// ── BADGE ICON WITH GLOW ──

class _BadgeIcon extends StatelessWidget {
  final String icon;
  final bool isUnlocked;
  final Color accent;
  final ColorScheme color;

  const _BadgeIcon({
    required this.icon,
    required this.isUnlocked,
    required this.accent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnlocked
              ? accent.withValues(alpha: 0.3)
              : color.outlineVariant.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: isUnlocked
            ? accent.withValues(alpha: 0.1)
            : color.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/icons/100/$icon.png',
              width: 36,
              height: 36,
              color: isUnlocked
                  ? null
                  : color.onSurfaceVariant.withValues(alpha: 0.25),
            ),
            if (!isUnlocked)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.surface.withValues(alpha: 0.4),
                ),
                child: Icon(
                  LucideIcons.lock,
                  size: 16,
                  color: color.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
