import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/achievement_registry.dart';

class GamificationService {
  final Isar isar;
  final AppLog log;

  GamificationService(this.isar, this.log);

  /* =====================================================
     INITIALIZATION
  ===================================================== */

  /// Call on app startup
  Future<void> initialize() async {
    await _cleanupDuplicates();
    for (final def in AchievementRegistry.all.values) {
      final exists = await isar.achievements
          .filter()
          .keyEqualTo(def.key)
          .findFirst();

      if (exists == null) {
        await isar.writeTxn(() async {
          await isar.achievements.put(_clone(def));
        });
      }
    }
  }

  Future<void> _cleanupDuplicates() async {
    final all = await isar.achievements.where().findAll();
    final seen = <String>{};
    final toDelete = <int>[];

    for (final achievement in all) {
      if (seen.contains(achievement.key)) {
        toDelete.add(achievement.id);
      } else {
        seen.add(achievement.key);
      }
    }

    if (toDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.achievements.deleteAll(toDelete);
      });
      log.i('🧹 Cleaned up ${toDelete.length} duplicate achievements');
    }
  }

  /* =====================================================
     EVENT TRACKER (ENTRY POINT)
  ===================================================== */

  Future<void> track(GamificationEvent event) async {
    switch (event) {
      case GamificationEvent.transactionAdded:
        await _increment('first_transaction');
        await _increment('transaction_10');
        await _increment('transaction_50');
        await _increment('transaction_100');
        await _increment('transaction_500');
        break;

      case GamificationEvent.dailyCheckIn:
        await _handleDailyStreak();
        break;

      case GamificationEvent.goalCompleted:
        await _increment('goal_completed');
        break;

      case GamificationEvent.goalCreated:
        await _increment('first_goal');
        break;

      case GamificationEvent.budgetCreated:
        await _increment('first_budget');
        break;

      case GamificationEvent.smsTransactionApproved:
        await _increment('sms_10');
        await _increment('sms_50');
        break;

      case GamificationEvent.categoryCreated:
        await _increment('category_5');
        await _increment('category_10');
        break;

      case GamificationEvent.accountCreated:
        await _increment('account_3');
        await _increment('account_5');
        break;

      case GamificationEvent.transferCompleted:
        await _increment('transfer_10');
        break;

      case GamificationEvent.recurringTransactionCreated:
        await _increment('recurring_5');
        await _increment('recurring_10');
        break;

      case GamificationEvent.tagUsed:
        await _increment('tag_25');
        break;

      case GamificationEvent.analyticsViewed:
        await _increment('analytics_10');
        break;

      case GamificationEvent.reportExported:
        await _increment('export_first');
        break;

      case GamificationEvent.tripCreated:
        await _increment('trip_first');
        await _increment('trip_5');
        break;
    }
  }

  /* =====================================================
     ACHIEVEMENT ENGINE
  ===================================================== */

  Future<void> _increment(String key, [int amount = 1]) async {
    var achievement = await isar.achievements
        .filter()
        .keyEqualTo(key)
        .findFirst();

    if (achievement == null) {
      achievement = _clone(_getAchievementDefinition(key));
      await isar.writeTxn(() => isar.achievements.put(achievement!));
    }

    final wasUnlocked = achievement.isUnlocked;
    achievement.progress += amount;

    await isar.writeTxn(() => isar.achievements.put(achievement!));

    if (!wasUnlocked && achievement.progress >= achievement.target) {
      achievement.unlockedAt = DateTime.now();
      await isar.writeTxn(() => isar.achievements.put(achievement!));
      await _addXP(achievement.rewardXP, 'Achievement: ${achievement.title}');
      log.i('🏆 Achievement Unlocked: ${achievement.title}');
      SnackbarService.success(
        '🏆 ${achievement.title} unlocked! +${achievement.rewardXP} XP',
      );
      NotificationService.showAchievementUnlocked(
        achievement.title,
        achievement.rewardXP,
      );
    }
  }

  void _onLevelUp(int newLevel, int gainedLevels) {
    log.d('🎉 Level Up! New Level: $newLevel');
    SnackbarService.success('🎉 Level Up! You are now Level $newLevel!');
    NotificationService.showLevelUp(newLevel);
  }

  Achievement _getAchievementDefinition(String key) {
    return AchievementRegistry.all[key]!;
  }

  Future<void> _unlock(Achievement ach, Achievement def) async {
    ach.progress = def.target;
    ach.unlockedAt = DateTime.now();

    await _addXP(def.rewardXP, 'Achievement: ${ach.title}');

    await isar.writeTxn(() => isar.achievements.put(ach));

    print('🏆 Unlocked: ${ach.title}');
  }

  Future<Achievement> _getOrCreate(Achievement def) async {
    final existing = await isar.achievements
        .filter()
        .keyEqualTo(def.key)
        .findFirst();

    if (existing != null) return existing;

    final fresh = _clone(def);

    await isar.writeTxn(() => isar.achievements.put(fresh));

    return fresh;
  }

  Achievement _clone(Achievement def) {
    return Achievement()
      ..key = def.key
      ..title = def.title
      ..description = def.description
      ..icon = def.icon
      ..category = def.category
      ..type = def.type
      ..progress = 0
      ..target = def.target
      ..rewardXP = def.rewardXP
      ..rewardCoins = def.rewardCoins
      ..unlockedAt = null;
  }

  /* =====================================================
     XP + LEVEL SYSTEM
  ===================================================== */

  Future<void> _addXP(int amount, String reason) async {
    final now = DateTime.now();

    int levelsGained = 0;

    final level = await _getOrCreateLevel();

    level.currentXP += amount;
    level.totalXP += amount;

    while (level.currentXP >= _xpForNext(level.level)) {
      level.currentXP -= _xpForNext(level.level);
      level.level++;
      levelsGained++;
    }

    level.lastUpdated = now;

    await isar.writeTxn(() async {
      await isar.userLevels.put(level);
    });

    // Optional: log / analytics
    log.i('⭐ +$amount XP → $reason');

    if (levelsGained > 0) {
      _onLevelUp(level.level, levelsGained);
    }
  }

  Future<UserLevel> _getOrCreateLevel() async {
    final existing = await isar.userLevels.where().findFirst();

    if (existing != null) return existing;

    final level = UserLevel()
      ..level = 1
      ..currentXP = 0
      ..totalXP = 0
      ..lastUpdated = DateTime.now();

    await isar.writeTxn(() => isar.userLevels.put(level));

    return level;
  }

  int _xpForNext(int level) {
    return 100 + (level * level * 25);
  }

  /* =====================================================
     STREAK ENGINE
  ===================================================== */

  Future<void> _handleDailyStreak() async {
    final streak = await _getOrCreateStreak();

    final now = DateTime.now();

    if (streak.lastChecked != null && _isSameDay(streak.lastChecked!, now)) {
      return;
    }

    if (streak.lastChecked != null &&
        _isConsecutiveDay(streak.lastChecked!, now)) {
      streak.currentCount++;
    } else {
      streak.currentCount = 1;
    }

    if (streak.currentCount > streak.longestCount) {
      streak.longestCount = streak.currentCount;
    }

    streak.lastChecked = now;
    streak.lastUpdated = now;

    await isar.writeTxn(() => isar.streaks.put(streak));

    await _checkStreaks(streak.currentCount);

    await _addXP(5, 'Daily Streak: ${streak.currentCount}');
  }

  Future<Streak> _getOrCreateStreak() async {
    final existing = await isar.streaks
        .filter()
        .typeEqualTo('daily_checkin')
        .findFirst();

    if (existing != null) return existing;

    final streak = Streak()
      ..type = 'daily_checkin'
      ..currentCount = 0
      ..longestCount = 0
      ..lastChecked = null
      ..lastUpdated = DateTime.now();

    await isar.writeTxn(() => isar.streaks.put(streak));

    return streak;
  }

  Future<void> _checkStreaks(int count) async {
    if (count == 3) {
      await _increment('streak_3_days');
      NotificationService.showStreakMilestone(3);
    }
    if (count == 7) {
      await _increment('streak_7_days');
      NotificationService.showStreakMilestone(7);
    }
    if (count == 30) {
      await _increment('streak_30_days');
      NotificationService.showStreakMilestone(30);
    }
    if (count == 100) {
      await _increment('streak_100_days');
      NotificationService.showStreakMilestone(100);
    }
  }

  int _calculateStreakXP(int streak) {
    if (streak >= 100) return 50;
    if (streak >= 30) return 30;
    if (streak >= 7) return 20;
    if (streak >= 3) return 10;

    return 5;
  }

  /* =====================================================
     HELPERS
  ===================================================== */

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isConsecutiveDay(DateTime last, DateTime now) {
    final d1 = DateTime(last.year, last.month, last.day);
    final d2 = DateTime(now.year, now.month, now.day);

    return d2.difference(d1).inDays == 1;
  }

  bool _withinGracePeriod(DateTime last, DateTime now) {
    return now.difference(last).inHours <= 36;
  }

  /* =====================================================
     STREAMS (UI)
  ===================================================== */

  Stream<List<Achievement>> watchAchievements() {
    return isar.achievements.where().watch(fireImmediately: true);
  }

  Stream<List<Streak>> watchStreaks() {
    return isar.streaks.where().watch(fireImmediately: true);
  }

  Stream<UserLevel?> watchUserLevel() {
    return isar.userLevels
        .where()
        .watch(fireImmediately: true)
        .map((e) => e.firstOrNull);
  }

  Future<String?> updateDailyCheckIn() async {
    final now = DateTime.now();
    log.i('🔍 Daily check-in called at: $now');

    // -------------------------------
    // 1. Update streak (DB only)
    // -------------------------------
    final streak = await isar.streaks
        .filter()
        .typeEqualTo('daily_checkin')
        .findFirst();

    log.i('📊 Existing streak: ${streak?.lastChecked}');

    final existing =
        streak ??
        (Streak()
          ..type = 'daily_checkin'
          ..currentCount = 0
          ..longestCount = 0
          ..lastChecked = null
          ..lastUpdated = now);

    final last = existing.lastChecked;

    // Already checked today
    if (last != null && _isSameDay(last, now)) {
      log.i('⏭️ Already checked in today. Last: $last, Now: $now');
      return null;
    }

    log.i('✅ Proceeding with check-in. Last: $last, Now: $now');

    // Continue or reset
    if (last != null &&
        (_isConsecutiveDay(last, now) || _withinGracePeriod(last, now))) {
      existing.currentCount++;
      log.i('🔥 Streak continued: ${existing.currentCount}');
    } else {
      existing.currentCount = 1;
      log.i('🆕 Streak reset to 1');
    }

    if (existing.currentCount > existing.longestCount) {
      existing.longestCount = existing.currentCount;
    }

    existing.lastChecked = now;
    existing.lastUpdated = now;

    await isar.writeTxn(() => isar.streaks.put(existing));

    final newStreak = existing.currentCount;

    // Schedule reminder for next day if streak >= 3
    if (newStreak >= 3) {
      await NotificationService.scheduleStreakReminder(newStreak);
    }

    // -------------------------------
    // 2. Give rewards (outside txn)
    // -------------------------------
    await _checkStreaks(newStreak);

    final xp = _calculateStreakXP(newStreak);
    await _addXP(xp, 'Daily Streak: $newStreak');

    log.i('🎉 Check-in complete: Day $newStreak, +$xp XP');
    return 'Day $newStreak streak! +$xp XP';
  }
}
