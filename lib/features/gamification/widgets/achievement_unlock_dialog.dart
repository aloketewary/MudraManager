import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementUnlockDialog extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _categoryAccent();
    final spacing = ref.watch(spacingProvider);

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
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: _ProgressRingPainter(
                          progress: 1.0,
                          trackColor: accent.withValues(alpha: 0.25),
                          progressColor: accent,
                          strokeWidth: 5,
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Image.asset(
                            semanticLabel: 'Decorative image',
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
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
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

                const SizedBox(height: 28),

                // ── SHARE BUTTON (Duolingo-style) ──
                GestureDetector(
                  onTap: () => _shareAchievement(context, accent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(spacing.radiusSmall * 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Share Achievement',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 16),

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

  Future<void> _shareAchievement(
    BuildContext context,
    Color accent,
  ) async {
    HapticFeedback.mediumImpact();
    // Close the unlock dialog first
    Navigator.of(context).pop();

    // Show the share card preview as a bottom sheet
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareCardPreview(
        achievement: achievement,
        accent: accent,
      ),
    );
  }
}

/// Bottom sheet that shows the share card preview with Share and Close buttons.
class _ShareCardPreview extends ConsumerWidget {
  final Achievement achievement;
  final Color accent;
  final _cardKey = GlobalKey();

  _ShareCardPreview({
    required this.achievement,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(spacing.radiusSmall * 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // ── CARD PREVIEW ──
            ClipRRect(
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
              child: RepaintBoundary(
                key: _cardKey,
                child: _ShareCard(
                  achievement: achievement,
                  accent: accent,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── SHARE BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _captureAndShare(context),
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(
                  'Share to Story',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── CLOSE ──
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    HapticFeedback.mediumImpact();

    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mudra_achievement_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          text: '\u{1F3C6} I just unlocked "${achievement.title}" '
              'in Mudra Manager! +${achievement.rewardXP} XP\n\n'
              'Track your money the smart way \u{1F4B0}\n'
              'https://play.google.com/store/apps/details?id=com.mudramanager.app',
          files: [XFile(file.path)],
        ),
      );
    } catch (_) {
      final text = '\u{1F3C6} I just unlocked "${achievement.title}" '
          'in Mudra Manager! +${achievement.rewardXP} XP\n\n'
          'Track your money the smart way \u{1F4B0}\n'
          'https://play.google.com/store/apps/details?id=com.mudramanager.app';
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard!')),
        );
      }
    }
  }
}

/// Duolingo-style branded share card — rendered offscreen, captured as image.
///
/// Fixed 1080x1920 (9:16 story ratio) card with:
/// - Dark gradient background
/// - Large achievement badge
/// - Title + description + XP
/// - Mudra Manager branding at bottom
class _ShareCard extends ConsumerWidget {
  final Achievement achievement;
  final Color accent;

  const _ShareCard({required this.achievement, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              Color.lerp(const Color(0xFF1A1A2E), accent, 0.15)!,
              const Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              // Subtle pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotPatternPainter(accent.withValues(alpha: 0.05)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    // ── "ACHIEVEMENT UNLOCKED" header ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '🎉 ACHIEVEMENT UNLOCKED',
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── BADGE ──
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          CustomPaint(
                            size: const Size(160, 160),
                            painter: _ProgressRingPainter(
                              progress: 1.0,
                              trackColor: accent.withValues(alpha: 0.2),
                              progressColor: accent,
                              strokeWidth: 6,
                            ),
                          ),
                          Container(
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.withValues(alpha: 0.2),
                                  accent.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/100/${achievement.icon}.png',
                                width: 72,
                                height: 72,
                                errorBuilder: (_, __, ___) => Icon(
                                  LucideIcons.trophy,
                                  size: 72,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── TITLE ──
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // ── DESCRIPTION ──
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    // ── XP PILL ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(spacing.radiusSmall),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkles, color: accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+${achievement.rewardXP} XP',
                            style: TextStyle(
                              color: accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── BRANDING FOOTER ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo/logo.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => Icon(
                            LucideIcons.indianRupee,
                            size: 28,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Mudra Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Your money, your language, your rules.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 40),
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

/// Subtle dot pattern for the share card background.
class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}

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
