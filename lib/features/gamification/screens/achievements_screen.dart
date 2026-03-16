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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    levelAsync.whenData((level) => _checkLevelUp(level));

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Achievements'),
            actions: [
              if (_filterCategory != null)
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => setState(() => _filterCategory = null),
                ),
              IconButton(
                icon: Icon(
                  _filterCategory != null
                      ? LucideIcons.listTodo
                      : LucideIcons.listFilter,
                  size: 20,
                ),
                onPressed: () => _showFilterSheet(color, textTheme),
              ),
            ],
          ),
          body: achievementsAsync.when(
            data: (achievements) {
              var visible = achievements.where((a) => a.isVisible).toList();
              if (_filterCategory != null) {
                visible = visible
                    .where((a) => a.category == _filterCategory)
                    .toList();
              }
              final unlocked = visible.where((a) => a.isUnlocked).toList();
              final locked = visible.where((a) => !a.isUnlocked).toList();

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontal,
                  vertical: spacing.cardVertical,
                ),
                children: [
                  // ── LEVEL HERO ──
                  levelAsync.when(
                    data: (level) => level != null
                        ? _buildLevelHero(
                            level,
                            color,
                            textTheme,
                            spacing,
                            isDark,
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

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

                  // ── FILTER CHIP ──
                  if (_filterCategory != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        children: [
                          Chip(
                            label: Text(
                              _categoryLabel(_filterCategory!),
                              style: textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            avatar: Icon(
                              _categoryIcon(_filterCategory!),
                              size: 14,
                            ),
                            deleteIcon: const Icon(LucideIcons.x, size: 14),
                            onDeleted: () => setState(
                              () => _filterCategory = null,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          Text(
                            '${visible.length} badge${visible.length == 1 ? '' : 's'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                            color:
                                color.onSurfaceVariant.withValues(alpha: 0.4),
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

  // ── LEVEL HERO ──
  Widget _buildLevelHero(
    UserLevel level,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    bool isDark,
  ) {
    final rank = FinanceRank.getRankForLevel(level.level);
    final accent = color.primary;

    return Container(
      padding: EdgeInsets.all(spacing.cardInner + 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.2 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: color.surface.withValues(alpha: 0.8),
                    child: Image.asset(
                      'assets/icons/medals/${rank.icon}.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${level.level} · ${level.totalXP} XP',
                      style: textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${level.currentXP} / ${level.xpForNextLevel} XP',
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(level.progressPercent * 100).toInt()}%',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: level.progressPercent),
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          const Color(0xFF4CAF50),
          color,
          textTheme,
        ),
        const SizedBox(width: 8),
        _statPill(
          '$inProgress',
          'In Progress',
          const Color(0xFFFF9800),
          color,
          textTheme,
        ),
        const SizedBox(width: 8),
        _statPill('$totalXP', 'Total XP', color.primary, color, textTheme),
      ],
    );
  }

  Widget _statPill(
    String value,
    String label,
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
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF4CAF50);

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
        childAspectRatio: 0.85,
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

  // ── FILTER SHEET ──
  void _showFilterSheet(ColorScheme color, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter by Category',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...[
              null,
              ...AchievementCategory.values,
            ].map((cat) {
              final selected = _filterCategory == cat;
              final label = cat == null ? 'All' : _categoryLabel(cat);
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: selected,
                selectedTileColor: color.primaryContainer,
                leading: Icon(
                  cat == null ? LucideIcons.list : _categoryIcon(cat),
                  size: 20,
                  color: selected
                      ? color.onPrimaryContainer
                      : color.onSurfaceVariant,
                ),
                title: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        selected ? color.onPrimaryContainer : color.onSurface,
                  ),
                ),
                trailing: selected
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: color.onPrimaryContainer,
                      )
                    : null,
                onTap: () {
                  setState(() => _filterCategory = cat);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──
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
