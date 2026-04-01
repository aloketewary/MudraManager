import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';

class SpendingPersonalityScreen extends ConsumerWidget {
  const SpendingPersonalityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final personality = ref.watch(spendingPersonalityProvider);
    final spendingByDayAsync = ref.watch(spendingByDayProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: color.surface,
      body: personality.when(
        data: (data) {
          if (data == null) {
            return _buildEmptyState(color, textTheme);
          }

          final archetype = PersonalityArchetype.fromSpendingPersonality(data);

          return CustomScrollView(
            slivers: [
              // Hero app bar
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                backgroundColor: color.surface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroSection(
                    archetype,
                    color,
                    textTheme,
                    isDark,
                  ),
                ),
                title: const Text('Spending Personality'),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Bento trait pills
                    _buildBentoTraits(data, color, textTheme, spacing),
                    SizedBox(height: spacing.sectionGap),

                    // Spending DNA
                    _buildSpendingDNA(
                      data,
                      spendingByDayAsync,
                      color,
                      textTheme,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // Behavior map
                    _buildBehaviorMap(data, archetype, color, textTheme, spacing,),
                    SizedBox(height: spacing.sectionGap),

                    // Vibe cloud
                    _buildVibeCloud(data, archetype, color, textTheme, spacing,),
                    SizedBox(height: spacing.sectionGap * 2),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Unable to load personality data')),
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState(ColorScheme color, TextTheme textTheme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Personality'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.brain, size: 64, color: color.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Not enough data yet',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add more transactions to discover your personality',
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO SECTION ──
  Widget _buildHeroSection(
    PersonalityArchetype archetype,
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            archetype.color.withValues(alpha: isDark ? 0.15 : 0.08),
            color.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace the SvgPicture.asset block with:
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: archetype.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      archetype.icon,
                      size: 48,
                      color: archetype.color,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    archetype.name,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: archetype.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      archetype.tagline,
                      style: textTheme.titleSmall?.copyWith(
                        color: archetype.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BENTO TRAIT PILLS ──
  Widget _buildBentoTraits(
    SpendingPersonality data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final traits = [
      _Trait(LucideIcons.tag, data.topCategory, 'Category'),
      _Trait(LucideIcons.calendar, data.spendingPattern, 'Pattern'),
      _Trait(LucideIcons.brain, data.behaviorType, 'Behavior'),
      _Trait(LucideIcons.trendingUp, data.spendingTrend, 'Trend'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: traits.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(t.icon, size: 16, color: color.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.label,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── SPENDING DNA ──
  Widget _buildSpendingDNA(
    SpendingPersonality data,
    AsyncValue<Map<String, double>> spendingByDayAsync,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    // Derive ratios from personality data
    final isWeekend = data.spendingPattern.toLowerCase().contains('weekend');
    final isImpulse = data.behaviorType.toLowerCase().contains('impulse');
    final isIncreasing =
        data.spendingTrend.toLowerCase().contains('increasing');
    final isDecreasing =
        data.spendingTrend.toLowerCase().contains('decreasing');

    final dnaItems = [
      _DNAItem(
        'Weekday vs Weekend',
        isWeekend ? 'Weekend heavy' : 'Weekday heavy',
        isWeekend ? 0.7 : 0.3,
        LucideIcons.calendarDays,
        isWeekend ? color.tertiary : color.primary,
      ),
      _DNAItem(
        'Impulse Score',
        isImpulse ? 'High impulse' : 'Planned',
        isImpulse ? 0.75 : 0.25,
        LucideIcons.zap,
        isImpulse ? color.error : color.secondary,
      ),
      _DNAItem(
        'Trend Direction',
        data.spendingTrend,
        isIncreasing
            ? 0.8
            : isDecreasing
                ? 0.2
                : 0.5,
        LucideIcons.activity,
        isIncreasing
            ? color.error
            : isDecreasing
                ? color.primary
                : color.secondary,
      ),
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.sectionGap),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  ),
                  child: Icon(LucideIcons.dna, color: color.primary, size: 20),
                ),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Spending DNA',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ...dnaItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 14, color: item.barColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          item.value,
                          style: textTheme.labelMedium?.copyWith(
                            color: item.barColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: item.progress),
                        builder: (context, animValue, child) {
                          return LinearProgressIndicator(
                            value: animValue,
                            minHeight: 8,
                            backgroundColor:
                                item.barColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(item.barColor),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Day-of-week mini chart
            spendingByDayAsync.maybeWhen(
              data: (byDay) => _buildDayOfWeekMini(byDay, color, textTheme),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeekMini(
    Map<String, double> byDay,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    final maxVal = byDay.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Spending by Day',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: days.map((day) {
            final val = byDay[day] ?? 0;
            final ratio = (val / maxVal).clamp(0.0, 1.0);
            final isWeekend = day == 'Sat' || day == 'Sun';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: ratio),
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              heightFactor: value.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isWeekend
                                      ? color.tertiary
                                      : color.primary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day[0],
                      style: textTheme.labelSmall?.copyWith(
                        color: isWeekend
                            ? color.tertiary
                            : color.onSurfaceVariant,
                        fontWeight:
                            isWeekend ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── BEHAVIOR MAP ──
  Widget _buildBehaviorMap(
    SpendingPersonality data,
    PersonalityArchetype archetype,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.map, color: color.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Behavior Map',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBehaviorRow(
              'Pattern',
              data.spendingPattern,
              LucideIcons.calendar,
              color,
              textTheme,
            ),
            const SizedBox(height: 10),
            _buildBehaviorRow(
              'Style',
              data.behaviorType,
              LucideIcons.zap,
              color,
              textTheme,
            ),
            const SizedBox(height: 10),
            _buildBehaviorRow(
              'Trend',
              data.spendingTrend,
              LucideIcons.trendingUp,
              color,
              textTheme,
            ),
            const SizedBox(height: 10),
            _buildBehaviorRow(
              'Archetype',
              archetype.trait,
              archetype.icon,
              color,
              textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorRow(
    String label,
    String value,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── VIBE CLOUD ──
  Widget _buildVibeCloud(
    SpendingPersonality data,
    PersonalityArchetype archetype,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: color.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Vibe',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              archetype.description,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildVibeBubble(
                  data.topCategory,
                  archetype.color,
                  color,
                  textTheme,
                  isPrimary: true,
                ),
                _buildVibeBubble(
                  data.spendingPattern.split(' ')[0],
                  archetype.color,
                  color,
                  textTheme,
                ),
                _buildVibeBubble(
                  data.behaviorType.split(' ')[0],
                  archetype.color,
                  color,
                  textTheme,
                ),
                _buildVibeBubble(
                  archetype.trait,
                  archetype.color,
                  color,
                  textTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeBubble(
    String text,
    Color accentColor,
    ColorScheme color,
    TextTheme textTheme, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary
            ? accentColor.withValues(alpha: 0.15)
            : color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: isPrimary ? accentColor : color.onSurface,
        ),
      ),
    );
  }
}

// ── HELPER CLASSES ──

class _Trait {
  final IconData icon;
  final String label;
  final String subtitle;
  _Trait(this.icon, this.label, this.subtitle);
}

class _DNAItem {
  final String label;
  final String value;
  final double progress;
  final IconData icon;
  final Color barColor;
  _DNAItem(this.label, this.value, this.progress, this.icon, this.barColor);
}
