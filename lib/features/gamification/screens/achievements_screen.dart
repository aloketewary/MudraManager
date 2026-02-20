import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:mudra_manager/features/gamification/models/user_rank.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/providers/gamification_providers.dart';
import 'package:mudra_manager/features/gamification/widgets/achievement_card.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';

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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
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

    levelAsync.whenData((level) => _checkLevelUp(level));

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Achievements')),
          body: achievementsAsync.when(
            data: (achievements) {
              final unlocked = achievements.where((a) => a.isUnlocked).toList();
              final locked = achievements.where((a) => !a.isUnlocked).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Card
                    levelAsync.when(
                      data: (level) => level != null
                          ? _buildLevelCard(context, level)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '${unlocked.length}',
                            'Unlocked',
                            Icons.emoji_events,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '${locked.length}',
                            'In Progress',
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Streaks Section
                    streaksAsync.when(
                      data: (streaks) => streaks.isNotEmpty
                          ? _buildStreaksSection(context, streaks)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Unlocked Achievements
                    if (unlocked.isNotEmpty) ...[
                      Text(
                        'Unlocked',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: unlocked.length,
                        itemBuilder: (context, index) {
                          return AchievementCard(achievement: unlocked[index]);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Locked Achievements
                    if (locked.isNotEmpty) ...[
                      Text(
                        'In Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: locked.length,
                        itemBuilder: (context, index) {
                          return AchievementCard(achievement: locked[index]);
                        },
                      ),
                    ],
                  ],
                ),
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

  Widget _buildLevelCard(BuildContext context, UserLevel level) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final rank = FinanceRank.getRankForLevel(level.level);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.primaryContainer, color.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: color.primaryContainer,
                  child: Image.asset('assets/icons/medals/${rank.icon}.png'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${level.level}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        rank.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${level.totalXP} Total XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${level.currentXP} / ${level.xpForNextLevel} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${(level.progressPercent * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: level.progressPercent,
                    minHeight: 8,
                    backgroundColor: color.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksSection(BuildContext context, List<Streak> streaks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streaks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...streaks.map((streak) => _buildStreakRow(context, streak)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakRow(BuildContext context, Streak streak) {
    final icon = streak.type == 'daily_checkin' ? '🔥' : '💰';
    final label = streak.type == 'daily_checkin'
        ? 'Daily Check-in'
        : 'Budget Adherence';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Best: ${streak.longestCount} days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${streak.currentCount}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
