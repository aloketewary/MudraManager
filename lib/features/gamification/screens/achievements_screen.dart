import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/models/user_rank.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/widgets/achievement_card.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late ConfettiController _confettiController;
  AchievementCategory? _filterCategory;

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

  void _checkLevelUp(UserLevel? level) async {
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
          '🎉 Level Up! You are now Level ${level.level}!',
        );
      });
      await prefs.setInt('last_seen_level', level.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final streaksAsync = ref.watch(streaksProvider);
    final levelAsync = ref.watch(userLevelProvider);
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    levelAsync.whenData((level) => _checkLevelUp(level));

    return Stack(
      children: [
        Scaffold(
          body: achievementsAsync.when(
            data: (achievements) {
              final allVisible =
                  achievements.where((a) => a.isVisible).toList();
              final visible = _filterCategory != null
                  ? allVisible
                      .where((a) => a.category == _filterCategory)
                      .toList()
                  : allVisible;
              final unlocked = visible.where((a) => a.isUnlocked).toList();
              final locked = visible.where((a) => !a.isUnlocked).toList();

              // Recently unlocked for trophy shelf
              final recentUnlocked = allVisible
                  .where((a) => a.isUnlocked && a.unlockedAt != null)
                  .toList()
                ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

              return CustomScrollView(
                slivers: [
                  // ── SLIVER APP BAR ──
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    title: const Text('Achievements'),
                    flexibleSpace: FlexibleSpaceBar(
                      background: levelAsync.when(
                        data: (level) => level != null
                            ? _RankHeader(
                                level: level,
                                color: color,
                                textTheme: textTheme,
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // ── BODY ──
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardHorizontal,
                      vertical: spacing.cardVertical,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── TROPHY SHELF ──
                        if (recentUnlocked.isNotEmpty) ...[
                          _buildTrophyShelf(recentUnlocked, color, textTheme),
                          const SizedBox(height: 20),
                        ],

                        // ── STAT PILLS ──
                        levelAsync.when(
                          data: (level) => _buildStatPills(
                            unlocked.length,
                            locked.length,
                            level?.totalXP ?? 0,
                            color,
                            textTheme,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),

                        // ── STREAKS ──
                        streaksAsync.when(
                          data: (streaks) => streaks.isNotEmpty
                              ? _buildStreaksCard(
                                  streaks,
                                  color,
                                  textTheme,
                                  spacing,
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (streaksAsync.valueOrNull?.isNotEmpty == true)
                          const SizedBox(height: 20),

                        // ── CATEGORY CHIPS ──
                        _buildCategoryChips(color, textTheme),
                        const SizedBox(height: 16),

                        // ── UNLOCKED ──
                        if (unlocked.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Unlocked',
                            '${unlocked.length}',
                            color,
                            textTheme,
                          ),
                          const SizedBox(height: 10),
                          _buildAchievementGrid(unlocked),
                          const SizedBox(height: 20),
                        ],

                        // ── IN PROGRESS ──
                        if (locked.isNotEmpty) ...[
                          _buildSectionHeader(
                            'In Progress',
                            '${locked.length}',
                            color,
                            textTheme,
                          ),
                          const SizedBox(height: 10),
                          _buildAchievementGrid(locked),
                        ],

                        // ── EMPTY STATE ──
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 64),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.trophy,
                                  size: 48,
                                  color: color.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _filterCategory != null
                                      ? 'No ${_categoryLabel(_filterCategory!).toLowerCase()} badges yet'
                                      : 'No achievements yet',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading achievements')),
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
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  // ── TROPHY SHELF ──
  Widget _buildTrophyShelf(
    List<Achievement> recentUnlocked,
    ColorScheme color,
    TextTheme textTheme,
  ) {
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
        _buildSectionHeader(
            'Trophy Shelf', '${items.length}', color, textTheme),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── Back wall with subtle pattern ──
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
                      return SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            // Trophy/medal icon with glow
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.08),
                                boxShadow: [
                                  // Downward shadow as if sitting on shelf
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 3),
                                  ),
                                  // Subtle glow
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
                            const SizedBox(height: 6),
                            // Name plate
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
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
                      );
                    },
                  ),
                ),
              ),

              // ── Wooden shelf plank ──
              Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      shelfHighlight,
                      shelfColor,
                      shelfShadow,
                    ],
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

              // ── Shelf bracket / support strip ──
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

  // ── CATEGORY CHIPS (replaces bottom sheet filter) ──
  Widget _buildCategoryChips(ColorScheme color, TextTheme textTheme) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip(null, 'All', LucideIcons.layoutGrid, color, textTheme),
          const SizedBox(width: 8),
          ...AchievementCategory.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _categoryChip(
                cat,
                _categoryLabel(cat),
                _categoryIcon(cat),
                color,
                textTheme,
              ),
            );
          }),
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
  ) {
    final selected = _filterCategory == cat;
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
      onSelected: (_) => setState(() => _filterCategory = cat),
    );
  }

  // ── STAT PILLS ──
  Widget _buildStatPills(
    int unlocked,
    int inProgress,
    int totalXP,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        _statPill(
          '$unlocked',
          'Unlocked',
          LucideIcons.trophy,
          color.primary,
          color,
          textTheme,
        ),
        const SizedBox(width: 8),
        _statPill(
          '$inProgress',
          'In Progress',
          LucideIcons.loader,
          color.tertiary,
          color,
          textTheme,
        ),
        const SizedBox(width: 8),
        _statPill(
          '$totalXP',
          'Total XP',
          LucideIcons.sparkles,
          color.primary,
          color,
          textTheme,
        ),
      ],
    );
  }

  Widget _statPill(
    String value,
    String label,
    IconData icon,
    Color accent,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STREAKS CARD ──
  Widget _buildStreaksCard(
    List<Streak> streaks,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Streaks', '${streaks.length}', color, textTheme),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: streaks.asMap().entries.map((entry) {
              final streak = entry.value;
              final isLast = entry.key == streaks.length - 1;
              final icon = streak.type == 'daily_checkin'
                  ? LucideIcons.flame
                  : LucideIcons.piggyBank;
              final label = streak.type == 'daily_checkin'
                  ? 'Daily Check-in'
                  : 'Budget Adherence';
              final accent = streak.type == 'daily_checkin'
                  ? color.tertiary
                  : color.primary;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Best: ${streak.longestCount} days',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${streak.currentCount}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 58,
                      color: color.outlineVariant.withValues(alpha: 0.4),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── ACHIEVEMENT GRID ──
  Widget _buildAchievementGrid(List<Achievement> items) {
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
          duration: Duration(milliseconds: 300 + (index * 50)),
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

  // ── HELPERS ──
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

  String _categoryLabel(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.budgeting:
        return 'Budgeting';
      case AchievementCategory.saving:
        return 'Savings';
      case AchievementCategory.tracking:
        return 'Tracking';
      case AchievementCategory.milestone:
        return 'Milestones';
      case AchievementCategory.engagement:
        return 'Engagement';
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

// ══════════════════════════════════════════════════════════════
// RANK HEADER — the SliverAppBar flexibleSpace background
// ══════════════════════════════════════════════════════════════

class _RankHeader extends StatelessWidget {
  final UserLevel level;
  final ColorScheme color;
  final TextTheme textTheme;

  const _RankHeader({
    required this.level,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final rank = FinanceRank.getRankForLevel(level.level);
    final accent = color.primary;

    return Container(
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
              // ── XP RING + MEDAL ──
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // XP arc ring
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
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
                      // Medal icon
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
                          child: Icon(
                            rank.icon,
                            size: 32,
                            color: rank.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rank.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: rank.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Level ${level.level}',
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
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
    );
  }
}

// ── CIRCULAR XP RING PAINTER ──

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

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -pi / 2, // start from top
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
