import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementUnlockDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
  });

  Color _categoryAccent() {
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
    final textTheme = Theme.of(context).textTheme;
    final accent = _categoryAccent();

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── LARGE BADGE with GLOW + RING ──
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow — double layer
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      // Full ring
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _ProgressRingPainter(
                          progress: 1.0,
                          trackColor: accent.withValues(alpha: 0.25),
                          progressColor: accent,
                          strokeWidth: 5,
                        ),
                      ),

                      // Icon circle
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/100/${achievement.icon}.png',
                            width: 64,
                            height: 64,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(
                      duration: 1500.ms,
                      color: accent.withValues(alpha: 0.4),
                    ),

                const SizedBox(height: 28),

                // ── "Achievement Unlocked!" ──
                Text(
                  '🎉 Achievement Unlocked!',
                  style: textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                // ── TITLE ──
                Text(
                  achievement.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                // ── DESCRIPTION ──
                Text(
                  achievement.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // ── XP REWARD PILL ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '+${achievement.rewardXP} XP',
                        style: textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      delay: 500.ms,
                      duration: 400.ms,
                    ),

                const SizedBox(height: 24),

                // ── SHARE BUTTON ──
                TextButton.icon(
                  onPressed: () {
                    final text = '🏆 I just unlocked "${achievement.title}" '
                        'in Mudra Manager! +${achievement.rewardXP} XP\n\n'
                        'Track your money the smart way 💰\n'
                        'https://play.google.com/store/apps/details?id=com.mudramanager.app';
                    Clipboard.setData(ClipboardData(text: text));
                    SnackbarService.success('Copied! Share it with friends 🙌');
                  },
                  icon: Icon(LucideIcons.share2, color: accent, size: 16),
                  label: Text(
                    'Share',
                    style: textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // ── TAP TO DISMISS ──
                Text(
                  'Tap anywhere to continue',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PROGRESS RING PAINTER ──

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
