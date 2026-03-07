import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;

class AchievementUnlockDialog extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final int xpReward;

  const AchievementUnlockDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
  });

  IconData _getIconData(String iconKey) {
    final iconMap = {
      'target': LucideIcons.target,
      'note': LucideIcons.notepadText,
      'chart': LucideIcons.chartBar,
      'hundred': LucideIcons.hash,
      'trophy': LucideIcons.trophy,
      'flame': LucideIcons.flame,
      'bolt': LucideIcons.zap,
      'medal': LucideIcons.medal,
      'crown': LucideIcons.crown,
      'clipboard': LucideIcons.clipboardList,
      'diamond': LucideIcons.gem,
      'goal': LucideIcons.target,
      'award': LucideIcons.award,
      'sprout': LucideIcons.sprout,
      'leaf': LucideIcons.leaf,
      'tree': LucideIcons.trees,
      'building': LucideIcons.building2,
      'message': LucideIcons.messageSquare,
      'robot': LucideIcons.bot,
      'folder': LucideIcons.folder,
      'grid': LucideIcons.grid3x3,
      'wallet': LucideIcons.wallet,
      'briefcase': LucideIcons.briefcase,
      'arrows': LucideIcons.arrowLeftRight,
      'repeat': LucideIcons.repeat,
      'calendar': LucideIcons.calendar,
      'tag': LucideIcons.tag,
      'pie': LucideIcons.chartPie,
      'download': LucideIcons.download,
      'plane': LucideIcons.plane,
      'map': LucideIcons.map,
    };
    return iconMap[iconKey] ?? LucideIcons.trophy;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Confetti particles
          ...List.generate(30, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 300,
              top: random.nextDouble() * 400,
              child: _ConfettiParticle(
                color: Color.lerp(
                  Colors.primaries[random.nextInt(Colors.primaries.length)],
                  Colors.white,
                  0.3,
                )!,
                delay: Duration(milliseconds: random.nextInt(300)),
              ),
            );
          }),

          // Main card
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with glow
                  Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              color.primary.withValues(alpha: 0.3),
                              color.primary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.primary.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconData(icon),
                          size: 50,
                          color: color.primary,
                        ),
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .shimmer(
                        duration: 1500.ms,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),

                  const SizedBox(height: 24),

                  // Achievement Unlocked text
                  Text(
                        '🎉 Achievement Unlocked!',
                        style: textTheme.titleMedium?.copyWith(
                          color: color.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                        title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 24),

                  // XP reward
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.primaryContainer,
                              color.primaryContainer.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: color.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+$xpReward XP',
                              style: textTheme.titleMedium?.copyWith(
                                color: color.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .scale(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Awesome!'),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle extends StatelessWidget {
  final Color color;
  final Duration delay;

  const _ConfettiParticle({required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final size = 6.0 + random.nextDouble() * 8;

    final isCircle = random.nextBool();
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: !isCircle && random.nextBool() ? BorderRadius.circular(2) : null,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: delay, duration: 300.ms)
        .moveY(
          delay: delay,
          begin: -50,
          end: 400,
          duration: Duration(milliseconds: 2000 + random.nextInt(1000)),
          curve: Curves.easeIn,
        )
        .rotate(
          delay: delay,
          begin: 0,
          end: random.nextDouble() * 4,
          duration: Duration(milliseconds: 2000 + random.nextInt(1000)),
        )
        .fadeOut(delay: delay + 1500.ms, duration: 500.ms);
  }
}
