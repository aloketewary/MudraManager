import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/shared/widgets/no_data_found.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/analytics/data/analytics_provider.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/features/dashboard/presentation/widgets/spending_personality_card.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

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

    return ScreenShell(
      config: ScreenShellConfig(
        title: AppLocalizations.of(context)!.title_spendingPersonality,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: personality.when(
        data: (data) {
          if (data == null) {
            return NoDataFound(
              message: BuddyMessages.noData,
              iconData: LucideIcons.brain,
            );
          }

          final archetype = PersonalityArchetype.fromSpendingPersonality(data);

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. Hero
              _buildHero(archetype, color, textTheme, spacing, isDark),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: spacing.sectionGap),

                    // 2. Traits
                    _buildTraits(
                      archetype,
                      color,
                      textTheme,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // 3. Data Insights
                    _buildDataInsights(
                      data,
                      color,
                      textTheme,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // 4. Spending DNA
                    _buildSpendingDNA(
                      data,
                      spendingByDayAsync,
                      color,
                      textTheme,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // 5. Guidance
                    _buildGuidance(
                      archetype,
                      color,
                      textTheme,
                      spacing,
                    ),
                    SizedBox(height: spacing.sectionGap * 3),
                    const AmbientBrandSection(),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => ListView(
          children: List.generate(3, (_) => const DashboardCardSkeleton()),
        ),
        error: (_, __) =>
            const Center(child: Text('Unable to load personality data')),
      ),
    );
  }

  // ── 1. HERO ──
  Widget _buildHero(
    PersonalityArchetype archetype,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing.cardHorizontal,
        spacing.sectionGap * 2,
        spacing.cardHorizontal,
        spacing.sectionGap * 2,
      ),
      child: Column(
        children: [
          // Icon circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: archetype.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              archetype.icon,
              size: 44,
              color: archetype.color,
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          Text(
            archetype.name,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: spacing.elementGap),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardInner,
              vertical: spacing.elementGap,
            ),
            decoration: BoxDecoration(
              color: archetype.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(spacing.radiusSmall),
            ),
            child: Text(
              archetype.tagline,
              style: textTheme.titleSmall?.copyWith(
                color: archetype.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          Text(
            archetype.description,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 2. TRAITS ──
  Widget _buildTraits(
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
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.listChecks, size: 18, color: archetype.color),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Your Traits',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            ...archetype.traits.map(
              (t) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: archetype.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 14,
                        color: archetype.color,
                      ),
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Text(
                        t,
                        style: textTheme.bodyMedium?.copyWith(
                          color: color.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. DATA INSIGHTS ──
  Widget _buildDataInsights(
    SpendingPersonality data,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final insights = <_InsightItem>[
      _InsightItem(
        LucideIcons.piggyBank,
        '${data.savingsRate.toStringAsFixed(0)}% savings rate',
        data.savingsRate > 20
            ? FinanceColors.statusGood
            : FinanceColors.statusWarning,
      ),
      _InsightItem(
        LucideIcons.tag,
        '${(data.essentialRatio * 100).toStringAsFixed(0)}% on essentials',
        data.essentialRatio > 0.5 ? Colors.blue : Colors.amber,
      ),
      _InsightItem(
        LucideIcons.receipt,
        '${data.txnCount} transactions this month',
        color.primary,
      ),
      if (data.activeGoals > 0)
        _InsightItem(
          LucideIcons.target,
          '${data.activeGoals} active ${data.activeGoals == 1 ? 'goal' : 'goals'}',
          FinanceColors.statusGood,
        ),
      _InsightItem(
        LucideIcons.calendarDays,
        data.spendingPattern,
        color.tertiary,
      ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
                Icon(LucideIcons.chartBar, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Data Insights',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            ...insights.map(
              (i) => Padding(
                padding: EdgeInsets.only(bottom: spacing.elementGap),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: i.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(spacing.radiusSmall),
                      ),
                      child: Icon(i.icon, size: 16, color: i.color),
                    ),
                    SizedBox(width: spacing.elementGap * 1.5),
                    Expanded(
                      child: Text(
                        i.label,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. SPENDING DNA ──
  Widget _buildSpendingDNA(
    SpendingPersonality data,
    AsyncValue<Map<String, double>> spendingByDayAsync,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final dnaItems = [
      _DNABar(
        'Weekend Spending',
        data.weekendRatio > 0.4 ? 'Weekend heavy' : 'Weekday focused',
        data.weekendRatio,
        LucideIcons.calendarDays,
        data.weekendRatio > 0.4 ? color.tertiary : color.primary,
      ),
      _DNABar(
        'Impulse Score',
        data.highActivityDays >= 2 ? 'High impulse' : 'Planned',
        (data.highActivityDays / 5).clamp(0.0, 1.0),
        LucideIcons.zap,
        data.highActivityDays >= 2 ? color.error : color.secondary,
      ),
      _DNABar(
        'Essential Ratio',
        '${(data.essentialRatio * 100).toStringAsFixed(0)}% essentials',
        data.essentialRatio,
        LucideIcons.shieldCheck,
        color.primary,
      ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
                Icon(LucideIcons.dna, size: 18, color: color.primary),
                SizedBox(width: spacing.elementGap),
                Text(
                  'Spending DNA',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            ...dnaItems.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: spacing.sectionGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 14, color: item.barColor),
                        SizedBox(width: spacing.elementGap),
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
                    SizedBox(height: spacing.elementGap),
                    _AnimatedBar(
                      progress: item.progress,
                      barColor: item.barColor,
                      radius: spacing.radiusSmall,
                    ),
                  ],
                ),
              ),
            ),
            // Day-of-week mini chart
            spendingByDayAsync.maybeWhen(
              data: (byDay) =>
                  _buildDayOfWeekMini(byDay, color, textTheme, spacing),
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
    AppSpacing spacing,
  ) {
    final maxVal = byDay.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: spacing.sectionGap * 2),
        Text(
          'Spending by Day',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: spacing.elementGap * 1.5),
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
                        child: _AnimatedDayBar(
                          ratio: ratio,
                          barColor: isWeekend ? color.tertiary : color.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      day[0],
                      style: textTheme.labelSmall?.copyWith(
                        color:
                            isWeekend ? color.tertiary : color.onSurfaceVariant,
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

  // ── 5. GUIDANCE ──
  Widget _buildGuidance(
    PersonalityArchetype archetype,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            archetype.color.withValues(alpha: 0.08),
            archetype.color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(
          color: archetype.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 18, color: archetype.color),
              SizedBox(width: spacing.elementGap),
              Text(
                'Your Next Step',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: archetype.color,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          Text(
            archetype.guidance,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper classes ──

class _InsightItem {
  final IconData icon;
  final String label;
  final Color color;
  _InsightItem(this.icon, this.label, this.color);
}

class _DNABar {
  final String label;
  final String value;
  final double progress;
  final IconData icon;
  final Color barColor;
  _DNABar(this.label, this.value, this.progress, this.icon, this.barColor);
}

/// Progress bar that animates only when it becomes visible on screen.
class _AnimatedBar extends StatefulWidget {
  final double progress;
  final Color barColor;
  final double radius;

  const _AnimatedBar({
    required this.progress,
    required this.barColor,
    required this.radius,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _maybeStart(bool visible) {
    if (visible && !_started) {
      _started = true;
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('bar_${widget.progress}_${widget.barColor.toARGB32()}'),
      onVisibilityChanged: (info) => _maybeStart(info.visibleFraction > 0.3),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: LinearProgressIndicator(
            semanticsLabel: 'Progress',
            value: _anim.value * widget.progress,
            minHeight: 8,
            backgroundColor: widget.barColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(widget.barColor),
          ),
        ),
      ),
    );
  }
}

/// Day-of-week bar that animates only when visible.
class _AnimatedDayBar extends StatefulWidget {
  final double ratio;
  final Color barColor;

  const _AnimatedDayBar({
    required this.ratio,
    required this.barColor,
  });

  @override
  State<_AnimatedDayBar> createState() => _AnimatedDayBarState();
}

class _AnimatedDayBarState extends State<_AnimatedDayBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _maybeStart(bool visible) {
    if (visible && !_started) {
      _started = true;
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('day_${widget.ratio}_${widget.barColor.toARGB32()}'),
      onVisibilityChanged: (info) => _maybeStart(info.visibleFraction > 0.3),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => FractionallySizedBox(
          heightFactor: (_anim.value * widget.ratio).clamp(0.05, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: widget.barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
