import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';

class AmbientBrandSection extends ConsumerWidget {
  final bool showSignature;
  final bool absorbBottomInset;

  const AmbientBrandSection({
    super.key,
    this.showSignature = false,
    this.absorbBottomInset = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(dailyStreakProvider);

    final moment = _pickMoment(streak?.currentCount ?? 0);
    final patternColor = color.primary.withValues(alpha: isDark ? 0.12 : 0.08);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.cardHorizontal),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        child: SizedBox(
          width: double.infinity,
          height: 140 +
              (absorbBottomInset
                  ? MediaQuery.of(context).padding.bottom +
                      kBottomNavigationBarHeight +
                      16
                  : 0),
          child: Stack(
            children: [
              // Icon doodle pattern background
              Positioned.fill(
                child: _DoodleIconPattern(
                  color: patternColor,
                  seed: DateTime.now().day,
                ),
              ),

              // Vertical fade — top and bottom edges
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.surface,
                        color.surface.withValues(alpha: 0.0),
                        color.surface.withValues(alpha: 0.0),
                        color.surface,
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // Soft gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        color.surface.withValues(alpha: 0.7),
                        color.surface.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal + 4,
                  vertical: spacing.cardVerticalMax * 4,
                ),
               
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Tag — graffiti style
                    Text(
                      moment.tag.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: color.primary.withValues(alpha: 0.45),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideX(
                          begin: -0.02,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      moment.title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      moment.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.35),
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                    const SizedBox(height: 10),

                    if (showSignature)
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          final parts = <String>[
                            if (info?.version != null) 'v${info!.version}',
                            if (info?.buildNumber != null &&
                                info!.buildNumber.isNotEmpty)
                              'build ${info.buildNumber}',
                            'Made with ❤️ in India',
                          ];
                          return Text(
                            parts.join(' · '),
                            style: textTheme.labelSmall?.copyWith(
                              color: color.onSurfaceVariant
                                  .withValues(alpha: 0.25),
                              letterSpacing: 0.3,
                            ),
                          );
                        },
                      ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Moment _pickMoment(int streakDays) {
    final hour = DateTime.now().hour;
    final day = DateTime.now().day;

    if (streakDays >= 30) {
      return _Moment(
        tag: '#Unstoppable',
        title: '$streakDays days and counting',
        subtitle: 'Consistency is your superpower',
      );
    }
    if (streakDays >= 7) {
      return _Moment(
        tag: '#OnFire',
        title: '$streakDays day streak — keep going',
        subtitle: 'Small habits, big results',
      );
    }

    if (hour < 6) return _moments[day % _moments.length];
    if (hour < 12) return _morningMoments[day % _morningMoments.length];
    if (hour < 18) return _afternoonMoments[day % _afternoonMoments.length];
    return _eveningMoments[day % _eveningMoments.length];
  }
}

// ── Finance icon tile pattern (WhatsApp wallpaper style) ──

const _doodleIcons = [
  LucideIcons.indianRupee,
  LucideIcons.dollarSign,
  LucideIcons.euro,
  LucideIcons.wallet,
  LucideIcons.piggyBank,
  LucideIcons.chartLine,
  LucideIcons.coins,
  LucideIcons.creditCard,
  LucideIcons.receipt,
  LucideIcons.trendingUp,
  LucideIcons.landmark,
  LucideIcons.banknote,
  LucideIcons.percent,
  LucideIcons.target,
  LucideIcons.sparkles,
  LucideIcons.chartBar,
];

class _DoodleIconPattern extends StatelessWidget {
  final Color color;
  final int seed;

  const _DoodleIconPattern({required this.color, required this.seed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rng = Random(seed);
        const iconSize = 18.0;
        const cellSize = 36.0;
        final cols = (constraints.maxWidth / cellSize).ceil();
        final rows = (constraints.maxHeight / cellSize).ceil();

        // Shuffle icons deterministically
        final shuffled = List<IconData>.from(_doodleIcons)..shuffle(rng);

        final children = <Widget>[];
        for (int r = 0; r < rows; r++) {
          final offsetX = (r.isOdd) ? cellSize * 0.5 : 0.0;
          for (int c = 0; c < cols; c++) {
            final idx = (r * cols + c) % shuffled.length;
            final x = c * cellSize + offsetX;
            final y = r * cellSize;
            if (x > constraints.maxWidth || y > constraints.maxHeight) continue;

            children.add(
              Positioned(
                left: x,
                top: y,
                child: SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Icon(
                      shuffled[idx],
                      size: iconSize,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(children: children);
      },
    );
  }
}

// ── Moment data ──
class _Moment {
  final String tag;
  final String title;
  final String subtitle;
  const _Moment({
    required this.tag,
    required this.title,
    required this.subtitle,
  });
}

const _morningMoments = [
  _Moment(
    tag: '#StartSmart',
    title: 'A new day to stay in control',
    subtitle: 'Offline · Private · Yours',
  ),
  _Moment(
    tag: '#MorningClarity',
    title: 'Your money, your rules',
    subtitle: 'Track smarter, not harder',
  ),
  _Moment(
    tag: '#FreshStart',
    title: 'Every rupee tells a story',
    subtitle: 'What will today\'s chapter be?',
  ),
];

const _afternoonMoments = [
  _Moment(
    tag: '#StayInControl',
    title: 'Made for your money',
    subtitle: 'Offline · Private · Powerful',
  ),
  _Moment(
    tag: '#TrackSmarter',
    title: 'Your finances, simplified',
    subtitle: 'Built for clarity',
  ),
  _Moment(
    tag: '#MoneyMindful',
    title: 'Awareness is the first step',
    subtitle: 'You\'re already ahead',
  ),
];

const _eveningMoments = [
  _Moment(
    tag: '#DayInReview',
    title: 'How did today go?',
    subtitle: 'A quick look keeps you sharp',
  ),
  _Moment(
    tag: '#WindDown',
    title: 'Savings today, freedom tomorrow',
    subtitle: 'Rest easy — your data is safe',
  ),
  _Moment(
    tag: '#Reflect',
    title: 'Small wins add up',
    subtitle: 'Every tracked expense matters',
  ),
];

const _moments = [
  _Moment(
    tag: '#MudraManager',
    title: 'Paisa bolta hai',
    subtitle: 'Hisaab kitaab, sab yaad rakhenge',
  ),
  _Moment(
    tag: '#BudgetKaro',
    title: 'Budget karo, chill karo',
    subtitle: 'Your wallet\'s best friend',
  ),
  _Moment(
    tag: '#TrackKaro',
    title: 'Track karo, tension nahi',
    subtitle: 'Spend smart, live large',
  ),
];
