import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/theme/app_color_theme_enum.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/domain/achievement.dart';
import 'package:mudra_manager/features/gamification/domain/user_rank.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/presentation/widgets/achievement_card.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkLevelUp(
    UserLevel? level,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) async {
    if (level == null) return;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getInt('last_seen_level');

    if (lastSeen == null) {
      await prefs.setInt('last_seen_level', level.level);
      return;
    }

    if (level.level > lastSeen) {
      Future.microtask(() {
        _confettiController.play();
        SnackbarService.success(
          ctxt.achieve_levelUpSnack(level.level),
          spacing,
        );
      });
      await prefs.setInt('last_seen_level', level.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final achievementsAsync = ref.watch(achievementsProvider);
    final streaksAsync = ref.watch(streaksProvider);
    final levelAsync = ref.watch(userLevelProvider);
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    final loaded =
        achievementsAsync.maybeWhen(data: (_) => true, orElse: () => false);

    levelAsync.maybeWhen(
      data: (level) => _checkLevelUp(level, ctxt, spacing),
      orElse: () {},
    );

    return Stack(
      children: [
        Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 600 ? 600.0 : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    key: ValueKey(loaded),
                    child: loaded
                        ? _AchievementsContent(
                            reduceMotion: reduceMotion,
                            streaksAsync: streaksAsync,
                            levelAsync: levelAsync,
                          )
                        : const _AchievementsLoading(),
                  ),
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              FinanceColors.statusGood,
              Colors.blue,
              Colors.pink,
              FinanceColors.statusWarning,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          ACHIEVEMENTS CONTENT                             ║
// ════════════════════════════════════════════════════════════════════════════

class _AchievementsContent extends ConsumerStatefulWidget {
  final bool reduceMotion;
  final AsyncValue<List<Streak>> streaksAsync;
  final AsyncValue<UserLevel?> levelAsync;

  const _AchievementsContent({
    required this.reduceMotion,
    required this.streaksAsync,
    required this.levelAsync,
  });

  @override
  ConsumerState<_AchievementsContent> createState() =>
      _AchievementsContentState();
}

class _AchievementsContentState extends ConsumerState<_AchievementsContent> {
  AchievementCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return achievementsAsync.when(
      data: (achievements) {
        final allVisible = achievements.where((a) => a.isVisible).toList();
        final visible = _filterCategory != null
            ? allVisible.where((a) => a.category == _filterCategory).toList()
            : allVisible;
        final unlocked = visible.where((a) => a.isUnlocked).toList();
        final locked = visible.where((a) => !a.isUnlocked).toList();
        final recentUnlocked = allVisible
            .where((a) => a.isUnlocked && a.unlockedAt != null)
            .toList()
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              title: Text(ctxt.title_achievements),
              flexibleSpace: FlexibleSpaceBar(
                background: widget.levelAsync.when(
                  data: (level) => level != null
                      ? AchievementHeroCard(
                          level: level,
                          isDark: isDark,
                          reduceMotion: widget.reduceMotion,
                          ctxt: ctxt,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                left: spacing.cardHorizontal,
                right: spacing.cardHorizontal,
                top: spacing.cardVertical,
                bottom: spacing.cardVertical,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (recentUnlocked.isNotEmpty) ...[
                    _TrophyShelfSection(
                      recentUnlocked: recentUnlocked,
                      color: color,
                      textTheme: textTheme,
                      spacing: spacing,
                      ctxt: ctxt,
                    ),
                    SizedBox(height: spacing.sectionGap),
                  ],
                  _StatPillsSection(
                    unlocked: unlocked.length,
                    inProgress: locked.length,
                    totalXP: widget.levelAsync.value?.totalXP ?? 0,
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    ctxt: ctxt,
                  ),
                  SizedBox(height: spacing.sectionGap),
                  _StreaksSection(
                    streaks: widget.streaksAsync.value ?? [],
                    color: color,
                    textTheme: textTheme,
                    spacing: spacing,
                    ctxt: ctxt,
                  ),
                  if (widget.streaksAsync.value?.isNotEmpty == true)
                    SizedBox(height: spacing.sectionGap),
                  _CategoryChipsSection(
                    filterCategory: _filterCategory,
                    onChanged: (cat) => setState(() => _filterCategory = cat),
                    color: color,
                    textTheme: textTheme,
                    ctxt: ctxt,
                  ),
                  SizedBox(height: spacing.elementGap),
                  if (unlocked.isNotEmpty) ...[
                    SectionHeader(ctxt.achieve_unlocked),
                    SizedBox(height: spacing.elementGap),
                    _AchievementGridSection(
                      items: unlocked,
                      reduceMotion: widget.reduceMotion,
                    ),
                    SizedBox(height: spacing.sectionGap),
                  ],
                  if (locked.isNotEmpty) ...[
                    SectionHeader(ctxt.achieve_inProgress),
                    SizedBox(height: spacing.elementGap),
                    _AchievementGridSection(
                      items: locked,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ],
                  if (visible.isEmpty) ...[
                    SizedBox(height: spacing.sectionGap * 2),
                    _EmptyStateSection(
                      filterCategory: _filterCategory,
                      ctxt: ctxt,
                    ),
                  ],
                  SizedBox(height: spacing.sectionGap),
                  const AmbientBrandSection(
                    showSignature: false,
                    absorbBottomInset: false,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          LOADING STATE                                     ║
// ════════════════════════════════════════════════════════════════════════════

class _AchievementsLoading extends ConsumerWidget {
  const _AchievementsLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _HeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _StatPillsSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _StreaksSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        SizedBox(height: spacing.elementGap),
        _AchievementGridSkeleton(spacing: spacing, color: color),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          HERO CARD                                         ║
// ════════════════════════════════════════════════════════════════════════════

class AchievementHeroCard extends ConsumerWidget {
  final UserLevel level;
  final bool isDark;
  final bool reduceMotion;
  final AppLocalizations ctxt;

  const AchievementHeroCard({
    required this.level,
    required this.isDark,
    required this.reduceMotion,
    required this.ctxt,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final rank = FinanceRank.getRankForLevel(level.level);
    final accent = color.primary;

    return Semantics(
      label:
          'Level ${level.level}, ${rank.name}. ${level.currentXP} of ${level.xpForNextLevel} XP to next level',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.15),
              accent.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 900),
                        curve: Curves.easeOutBack,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: TweenAnimationBuilder<double>(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          tween: Tween(begin: 0, end: level.progressPercent),
                          builder: (_, progress, __) => CustomPaint(
                            size: const Size(100, 100),
                            painter: _XpRingPainter(
                              progress: progress,
                              trackColor: accent.withValues(alpha: 0.12),
                              progressColor: accent,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.surface,
                          boxShadow: [
                            BoxShadow(
                              color: rank.accent.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(rank.icon, size: 32, color: rank.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.elementGap * 1.5),
                Text(
                  rank.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: rank.accent,
                  ),
                ),
                Text(
                  ctxt.achieve_levelLabel(level.level),
                  style: textTheme.bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
                Text(
                  '${level.currentXP} / ${level.xpForNextLevel} XP',
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          TROPHY SHELF                                      ║
// ════════════════════════════════════════════════════════════════════════════

class _TrophyShelfSection extends StatelessWidget {
  final List<Achievement> recentUnlocked;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _TrophyShelfSection({
    required this.recentUnlocked,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    final items = recentUnlocked.take(10).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shelfColor =
        isDark ? const Color(0xFF3E2C1A) : const Color(0xFF8B6914);
    final shelfHighlight =
        isDark ? const Color(0xFF5A3D1E) : const Color(0xFFBB9B40);
    final shelfShadow =
        isDark ? const Color(0xFF1A1008) : const Color(0xFF5C4510);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.achieve_trophyShelf),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(spacing.radiusSmall),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.surfaceContainerHighest.withValues(alpha: 0.3),
                      color.surfaceContainerLow,
                    ],
                  ),
                ),
                child: SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final a = items[index];
                      final accent = _categoryAccent(a.category, color);
                      return Semantics(
                        label: '${a.title} achievement unlocked',
                        child: SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.08),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/20/${a.icon}.png',
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing.elementGapMin),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    spacing.radiusSmall * 0.5,
                                  ),
                                ),
                                child: Text(
                                  a.title,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 8,
                                    color: color.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [shelfHighlight, shelfColor, shelfShadow],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      shelfShadow.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          STAT PILLS                                        ║
// ════════════════════════════════════════════════════════════════════════════

class _StatPillsSection extends StatelessWidget {
  final int unlocked;
  final int inProgress;
  final int totalXP;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _StatPillsSection({
    required this.unlocked,
    required this.inProgress,
    required this.totalXP,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGroupCard(
      items: [
        SettingItem(
          icon: LucideIcons.trophy,
          title: unlocked.toString(),
          subtitle: ctxt.achieve_unlocked,
          onTap: () {},
          disabled: false,
        ),
        SettingItem(
          icon: LucideIcons.loader,
          title: inProgress.toString(),
          subtitle: ctxt.achieve_inProgress,
          onTap: () {},
          disabled: false,
        ),
        SettingItem(
          icon: LucideIcons.sparkles,
          title: totalXP.toString(),
          subtitle: ctxt.achieve_totalXP,
          onTap: () {},
          disabled: false,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          STREAKS SECTION                                   ║
// ════════════════════════════════════════════════════════════════════════════

class _StreaksSection extends ConsumerWidget {
  final List<Streak> streaks;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;
  final AppLocalizations ctxt;

  const _StreaksSection({
    required this.streaks,
    required this.color,
    required this.textTheme,
    required this.spacing,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (streaks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(ctxt.achieve_streaks),
        SizedBox(height: spacing.elementGap),
        SettingsGroupCard(
          items: streaks.map((streak) {
            final icon = streak.type == 'daily_checkin'
                ? LucideIcons.flame
                : LucideIcons.piggyBank;
            final label = streak.type == 'daily_checkin'
                ? ctxt.achieve_dailyCheckIn
                : ctxt.achieve_budgetAdherence;
            return SettingItem(
              icon: icon,
              title: streak.currentCount.toString(),
              subtitle:
                  '$label • ${ctxt.achieve_bestDays(streak.longestCount)}',
              onTap: () {},
              disabled: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          CATEGORY CHIPS                                    ║
// ════════════════════════════════════════════════════════════════════════════

class _CategoryChipsSection extends StatelessWidget {
  final AchievementCategory? filterCategory;
  final void Function(AchievementCategory?) onChanged;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _CategoryChipsSection({
    required this.filterCategory,
    required this.onChanged,
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip(
            null,
            ctxt.achieve_catAll,
            LucideIcons.layoutGrid,
            color,
            textTheme,
            filterCategory,
            onChanged,
          ),
          const SizedBox(width: 8),
          ...AchievementCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _categoryChip(
                cat,
                _categoryLabel(cat, ctxt),
                _categoryIcon(cat),
                color,
                textTheme,
                filterCategory,
                onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    AchievementCategory? cat,
    String label,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
    AchievementCategory? filterCategory,
    void Function(AchievementCategory?) onChanged,
  ) {
    final selected = filterCategory == cat;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 14),
      label: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onChanged(cat),
    );
  }

  String _categoryLabel(AchievementCategory cat, AppLocalizations ctxt) {
    switch (cat) {
      case AchievementCategory.budgeting:
        return ctxt.achieve_catBudgeting;
      case AchievementCategory.saving:
        return ctxt.achieve_catSavings;
      case AchievementCategory.tracking:
        return ctxt.achieve_catTracking;
      case AchievementCategory.milestone:
        return ctxt.achieve_catMilestones;
      case AchievementCategory.engagement:
        return ctxt.achieve_catEngagement;
    }
  }

  IconData _categoryIcon(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.budgeting:
        return LucideIcons.chartPie;
      case AchievementCategory.saving:
        return LucideIcons.piggyBank;
      case AchievementCategory.tracking:
        return LucideIcons.clipboardList;
      case AchievementCategory.milestone:
        return LucideIcons.flag;
      case AchievementCategory.engagement:
        return LucideIcons.flame;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          ACHIEVEMENT GRID                                  ║
// ════════════════════════════════════════════════════════════════════════════

class _AchievementGridSection extends StatelessWidget {
  final List<Achievement> items;
  final bool reduceMotion;

  const _AchievementGridSection({
    required this.items,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: reduceMotion
              ? Duration.zero
              : Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: AchievementCard(achievement: items[index]),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          EMPTY STATE                                       ║
// ════════════════════════════════════════════════════════════════════════════

class _EmptyStateSection extends ConsumerWidget {
  final AchievementCategory? filterCategory;
  final AppLocalizations ctxt;

  const _EmptyStateSection({required this.filterCategory, required this.ctxt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Column(
      children: [
        Icon(
          LucideIcons.trophy,
          size: 48,
          color: color.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        SizedBox(height: spacing.elementGap * 1.5),
        Text(
          filterCategory != null
              ? ctxt.achieve_noBadgesYet(
                  _categoryLabel(filterCategory!, ctxt).toLowerCase(),
                )
              : BuddyMessages.noTransactions,
          style: textTheme.bodyLarge?.copyWith(color: color.onSurfaceVariant),
        ),
      ],
    );
  }

  String _categoryLabel(AchievementCategory cat, AppLocalizations ctxt) {
    switch (cat) {
      case AchievementCategory.budgeting:
        return ctxt.achieve_catBudgeting;
      case AchievementCategory.saving:
        return ctxt.achieve_catSavings;
      case AchievementCategory.tracking:
        return ctxt.achieve_catTracking;
      case AchievementCategory.milestone:
        return ctxt.achieve_catMilestones;
      case AchievementCategory.engagement:
        return ctxt.achieve_catEngagement;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          SKELETON LOADERS                                  ║
// ════════════════════════════════════════════════════════════════════════════

class _HeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _HeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SkeletonLoader(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.circular(50),
          ),
          SizedBox(height: spacing.elementGap * 1.5),
          const SkeletonLoader(width: 80, height: 18),
          SizedBox(height: spacing.elementGapMin),
          const SkeletonLoader(width: 120, height: 14),
        ],
      ),
    );
  }
}

class _StatPillsSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _StatPillsSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return SettingsGroupCard(
      items: List.generate(
        3,
        (index) => SettingItem(
          icon: LucideIcons.loader,
          title: '...',
          subtitle: '...',
          onTap: () {},
          disabled: true,
        ),
      ),
    );
  }
}

class _StreaksSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _StreaksSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 100, height: 20),
        SizedBox(height: spacing.elementGap),
        Container(
          decoration: BoxDecoration(
            color: color.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: List.generate(2, (index) {
              final isLast = index == 1;
              return Padding(
                padding: EdgeInsets.only(
                  left: spacing.cardInner,
                  right: spacing.cardInner,
                  top: spacing.cardInner,
                  bottom: isLast ? spacing.cardInner : spacing.elementGapMin,
                ),
                child: Row(
                  children: [
                    SkeletonLoader(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(spacing.radiusSmall),
                    ),
                    SizedBox(width: spacing.cardInner),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(width: 120, height: 16),
                          SizedBox(height: 6),
                          SkeletonLoader(width: 80, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AchievementGridSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _AchievementGridSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border:
              Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: [
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            SizedBox(height: spacing.elementGap),
            const SkeletonLoader(width: 80, height: 14),
            SizedBox(height: spacing.elementGapUltraMin),
            const SkeletonLoader(width: 60, height: 10),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          HELPERS                                           ║
// ════════════════════════════════════════════════════════════════════════════

Color _categoryAccent(AchievementCategory cat, ColorScheme color) {
  switch (cat) {
    case AchievementCategory.budgeting:
      return color.secondary;
    case AchievementCategory.saving:
      return color.primary;
    case AchievementCategory.tracking:
      return color.tertiary;
    case AchievementCategory.milestone:
      return color.primaryContainer;
    case AchievementCategory.engagement:
      return color.error;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ║                          XP RING PAINTER                                   ║
// ════════════════════════════════════════════════════════════════════════════

class _XpRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _XpRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
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
  bool shouldRepaint(_XpRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
