import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

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
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnlocked = achievement.isUnlocked;
    final accent = _categoryAccent();
    final progress = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: isUnlocked ? 2 : 0,
      shadowColor: isUnlocked ? accent.withValues(alpha: 0.3) : null,
      margin: EdgeInsets.zero,
      color: isUnlocked ? null : color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        side: BorderSide(
          color: isUnlocked
              ? accent.withValues(alpha: 0.4)
              : color.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showShowcase(context);
        },
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        child: Container(
          decoration: isUnlocked
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.14),
                      accent.withValues(alpha: 0.04),
                    ],
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              const Spacer(),

              // ── BADGE with PROGRESS RING ──
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(64, 64),
                      painter: _ProgressRingPainter(
                        progress: isUnlocked ? 1.0 : progress,
                        trackColor: isUnlocked
                            ? accent.withValues(alpha: 0.2)
                            : color.onSurfaceVariant.withValues(alpha: 0.08),
                        progressColor:
                            isUnlocked ? accent : accent.withValues(alpha: 0.5),
                        strokeWidth: 3,
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    Image.asset(
                      semanticLabel: 'Decorative image',
                      'assets/icons/100/${achievement.icon}.png',
                      width: 34,
                      height: 34,
                      color: isUnlocked
                          ? null
                          : color.onSurfaceVariant.withValues(alpha: 0.25),
                    ),
                    if (!isUnlocked)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: color.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  color.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.lock,
                            size: 10,
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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

              Text(
                achievement.description,
                style: textTheme.labelSmall?.copyWith(
                  color: color.onSurfaceVariant
                      .withValues(alpha: isUnlocked ? 0.8 : 0.55),
                  fontSize: 10,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              if (isUnlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tone.current.borderRadius),
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
                      borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.5),
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Progress',
                        value: progress,
                        minHeight: 4,
                        backgroundColor:
                            color.onSurfaceVariant.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          accent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.progress} / ${achievement.target}',
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.55),
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

  // ── SHOWCASE DIALOG ──
  void _showShowcase(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
      pageBuilder: (context, _, __) {
        return _AchievementShowcase(achievement: achievement);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FULL-SCREEN TRANSPARENT SHOWCASE
// ══════════════════════════════════════════════════════════════

class _AchievementShowcase extends StatelessWidget {
  final Achievement achievement;

  const _AchievementShowcase({required this.achievement});

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUnlocked = achievement.isUnlocked;
    final accent = _categoryAccent();
    final progress = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;
    final remaining = achievement.target - achievement.progress;

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
                      // Outer glow
                      if (isUnlocked)
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: accent.withValues(alpha: 0.15),
                                blurRadius: 80,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),

                      // Progress ring
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _ProgressRingPainter(
                          progress: isUnlocked ? 1.0 : progress,
                          trackColor: isUnlocked
                              ? accent.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.1),
                          progressColor: isUnlocked
                              ? accent
                              : accent.withValues(alpha: 0.7),
                          strokeWidth: 5,
                        ),
                      ),

                      // Icon circle
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? accent.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Center(
                          child: Image.asset(
                            semanticLabel: 'Decorative image',
                            'assets/icons/100/${achievement.icon}.png',
                            width: 64,
                            height: 64,
                            color: isUnlocked
                                ? null
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(
                      duration: 1500.ms,
                      color: isUnlocked
                          ? accent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),

                const SizedBox(height: 28),

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
                    .fadeIn(delay: 200.ms, duration: 400.ms)
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
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // ── INFO PILLS ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _showcasePill(
                      _categoryLabel(achievement.category),
                      accent,
                    ),
                    _showcasePill(
                      '+${achievement.rewardXP} XP',
                      accent,
                    ),
                    if (isUnlocked && achievement.unlockedAt != null)
                      _showcasePill(
                        DateFormat('MMM dd, yyyy')
                            .format(achievement.unlockedAt!),
                        Colors.white.withValues(alpha: 0.5),
                      ),
                    if (!isUnlocked)
                      _showcasePill(
                        '$remaining more to go',
                        Colors.white.withValues(alpha: 0.5),
                      ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                // ── PROGRESS BAR for locked ──
                if (!isUnlocked) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.5),
                          child: LinearProgressIndicator(
                            semanticsLabel: 'Progress',
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${achievement.progress} / ${achievement.target}',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                ],

                const SizedBox(height: 32),

                // ── TAP TO DISMISS hint ──
                Text(
                  'Tap anywhere to close',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _showcasePill(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Tone.current.borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
