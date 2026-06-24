import 'package:isar_community/isar.dart';
import 'package:mudra_manager/core/db/models/budget.dart';
import 'package:mudra_manager/core/db/models/transaction.dart';
import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/services/notification_service.dart';
import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';
import 'package:mudra_manager/core/utils/budget_spent_calculator.dart';
import 'package:mudra_manager/features/gamification/models/gamification_enum.dart';
import 'package:mudra_manager/features/gamification/providers/achievement_registry.dart';

/// Manages achievements, streaks, XP, and levels.
///
/// TECH DEBT: This service directly calls SnackbarService and
/// NotificationService (10 call sites). These should be extracted to
/// return GamificationResult objects, letting the presentation layer
/// decide what UI feedback to show. This blocks proper unit testing
/// of the service without mocking static methods.
///
/// TECH DEBT: This class (1100+ lines) should be decomposed into:
/// - StreakEngine (5 streak types)
/// - AchievementEngine (series, progress, unlock)
/// - XpEngine (add, level-up, formula)
/// GamificationService becomes a thin facade.
class GamificationService {
  final Isar isar;
  final AppLog log;

  GamificationService(this.isar, this.log);

  /* =====================================================
     INITIALIZATION
  ===================================================== */

  /// Call on app startup
  Future<void> initialize() async {
    await _runMigrations();
    for (final def in AchievementRegistry.all.values) {
      final exists =
          await isar.achievements.filter().keyEqualTo(def.key).findFirst();

      if (exists == null) {
        await isar.writeTxn(() async {
          await isar.achievements.put(_clone(def));
        });
      }
    }
  }

  /// Force cleanup - for debugging
  Future<void> forceCleanup() async {
    await _cleanupDuplicates();
    await _cleanupDuplicateStreaks();
  }

  Future<void> _cleanupDuplicates() async {
    log.i('🔍 Starting achievement cleanup...');
    final all = await isar.achievements.where().findAll();
    log.i('📊 Found ${all.length} total achievements');

    final seen = <String>{};
    final toDelete = <int>[];

    for (final achievement in all) {
      if (seen.contains(achievement.key)) {
        log.d('❌ Duplicate found: ${achievement.key} (ID: ${achievement.id})');
        toDelete.add(achievement.id);
      } else {
        seen.add(achievement.key);
      }
    }

    if (toDelete.isNotEmpty) {
      log.i(
        '🗑️ Deleting ${toDelete.length} duplicate achievements: $toDelete',
      );
      await isar.writeTxn(() async {
        await isar.achievements.deleteAll(toDelete);
      });
      log.i('✅ Cleaned up ${toDelete.length} duplicate achievements');
    } else {
      log.i('✨ No duplicate achievements found');
    }
  }

  Future<void> _runMigrations() async {
    try {
      const currentMigrationVersion = 3;

      log.i('🔄 Checking migrations...');
      final versionConfig = await isar.appConfigs
          .filter()
          .keyEqualTo('migration_version')
          .findFirst();

      final lastVersion = versionConfig?.intValue ?? 0;
      log.i(
        '📊 Current migration version: $lastVersion, Target: $currentMigrationVersion',
      );

      if (lastVersion < 1) {
        log.i('🚀 Running migration v1: Cleanup duplicate streaks');
        await _cleanupDuplicateStreaks();
      }

      if (lastVersion < 2) {
        log.i('🚀 Running migration v2: Cleanup duplicate achievements');
        await _cleanupDuplicates();
      }

      if (lastVersion < 3) {
        log.i('🚀 Running migration v3: Update achievement series');
        try {
          await _updateAchievementSeries();
        } catch (e) {
          log.w('Migration v3 failed (non-critical): $e');
        }
      }

      if (lastVersion < currentMigrationVersion) {
        try {
          if (versionConfig != null) {
            versionConfig.intValue = currentMigrationVersion;
            await isar.writeTxn(() async {
              await isar.appConfigs.put(versionConfig);
            });
          } else {
            final newConfig = AppConfig()
              ..key = 'migration_version'
              ..intValue = currentMigrationVersion;
            await isar.writeTxn(() async {
              await isar.appConfigs.put(newConfig);
            });
          }
          log.i(
            '✅ Migrations complete. Updated to version $currentMigrationVersion',
          );
        } catch (e) {
          log.w('Failed to update migration version: $e');
        }
      } else {
        log.i('✨ All migrations already applied');
      }
    } catch (e, st) {
      log.e('Migration error', e, st);
      // Continue anyway - don't block app startup
    }
  }

  Future<void> _cleanupDuplicateStreaks() async {
    final allStreaks = await isar.streaks.where().findAll();
    final seenTypes = <String>{};
    final toDelete = <int>[];
    final toKeep = <String, Streak>{};

    for (final streak in allStreaks) {
      if (seenTypes.contains(streak.type)) {
        // Keep the one with higher count or more recent update
        final existing = toKeep[streak.type]!;
        if (streak.currentCount > existing.currentCount ||
            (streak.currentCount == existing.currentCount &&
                streak.lastUpdated.isAfter(existing.lastUpdated))) {
          toDelete.add(existing.id);
          toKeep[streak.type] = streak;
        } else {
          toDelete.add(streak.id);
        }
      } else {
        seenTypes.add(streak.type);
        toKeep[streak.type] = streak;
      }
    }

    if (toDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.streaks.deleteAll(toDelete);
      });
      log.i('🧹 Cleaned up ${toDelete.length} duplicate streaks');
    }
  }

  Future<void> _updateAchievementSeries() async {
    await isar.writeTxn(() async {
      final allAchievements = await isar.achievements.where().findAll();

      for (final achievement in allAchievements) {
        final def = AchievementRegistry.all[achievement.key];
        if (def != null &&
            (achievement.series != def.series ||
                achievement.seriesOrder != def.seriesOrder)) {
          achievement.series = def.series;
          achievement.seriesOrder = def.seriesOrder;
          await isar.achievements.put(achievement);
        }
      }
    });
    log.i('🔄 Updated achievement series');
  }

  /* =====================================================
     EVENT TRACKER (ENTRY POINT)
  ===================================================== */

  Future<void> track(GamificationEvent event) async {
    switch (event) {
      case GamificationEvent.transactionAdded:
        await _incrementAll([
          'first_transaction',
          'transaction_10',
          'transaction_50',
          'transaction_100',
          'transaction_500',
        ]);
        break;
      case GamificationEvent.dailyCheckIn:
        // No-op: daily streak is managed exclusively via updateDailyCheckIn()
        // to ensure grace period logic is applied consistently.
        break;
      case GamificationEvent.goalCompleted:
        await _incrementAll(['goal_completed']);
        break;
      case GamificationEvent.goalCreated:
        await _incrementAll(['first_goal']);
        break;
      case GamificationEvent.budgetCreated:
        await _incrementAll(['first_budget']);
        break;
      case GamificationEvent.smsTransactionApproved:
        await _incrementAll(['sms_10', 'sms_50']);
        break;
      case GamificationEvent.categoryCreated:
        await _incrementAll(['category_5', 'category_10']);
        break;
      case GamificationEvent.accountCreated:
        await _incrementAll(['account_3', 'account_5']);
        break;
      case GamificationEvent.transferCompleted:
        await _incrementAll(['transfer_10', 'transfer_50']);
        break;
      case GamificationEvent.recurringTransactionCreated:
        await _incrementAll(['recurring_5', 'recurring_10']);
        break;
      case GamificationEvent.tagUsed:
        await _incrementAll(['tag_5', 'tag_25']);
        break;
      case GamificationEvent.analyticsViewed:
        await _incrementAll(['analytics_10']);
        break;
      case GamificationEvent.reportExported:
        await _incrementAll(['export_first']);
        break;
      case GamificationEvent.tripCreated:
        await _incrementAll(['trip_first', 'trip_5']);
        break;
      case GamificationEvent.backupCreated:
        await _incrementAll(['first_backup', 'backup_10']);
        break;
      case GamificationEvent.expenseSplit:
        await _incrementAll(['first_split', 'split_20']);
        break;
      case GamificationEvent.reconciliationDone:
        await _incrementAll(['reconcile_first', 'reconcile_50']);
        break;
      case GamificationEvent.zeroSpendDay:
        await _incrementAll(['zero_spend_1', 'zero_spend_10']);
        break;
      case GamificationEvent.transactionTrackedToday:
        await _handleTrackingStreak();
        break;
      case GamificationEvent.underBudgetDay:
        await _handleUnderBudgetStreak();
        break;
    }
  }

  /* =====================================================
     ACHIEVEMENT ENGINE
  ===================================================== */

  Future<void> _setProgress(String key, int progress) async {
    var achievement =
        await isar.achievements.filter().keyEqualTo(key).findFirst();

    if (achievement == null) {
      achievement = _clone(_getAchievementDefinition(key));
      await isar.writeTxn(() => isar.achievements.put(achievement!));
    }

    // Skip if already unlocked — no need to keep writing
    if (achievement.isUnlocked) return;

    // Check if this achievement is locked in a series
    if (achievement.series != null &&
        achievement.seriesOrder != null &&
        achievement.seriesOrder! > 1) {
      final previous = await isar.achievements
          .filter()
          .seriesEqualTo(achievement.series)
          .seriesOrderEqualTo(achievement.seriesOrder! - 1)
          .findFirst();

      if (previous == null || !previous.isUnlocked) {
        return;
      }
    }

    final wasUnlocked = achievement.isUnlocked;
    achievement.progress = progress;

    await isar.writeTxn(() => isar.achievements.put(achievement!));

    if (!wasUnlocked && achievement.progress >= achievement.target) {
      achievement.unlockedAt = DateTime.now();
      await isar.writeTxn(() => isar.achievements.put(achievement!));
      await _addXP(achievement.rewardXP, 'Achievement: ${achievement.title}');
      log.i('🏆 Achievement Unlocked: ${achievement.title}');
      SnackbarService.success(
        Tone.appL10n?.notif_achievementBody(achievement.title, achievement.rewardXP) ??
            '🏆 ${achievement.title} — nice, +${achievement.rewardXP} XP!',
      );
      NotificationService.showAchievementUnlocked(
        achievement.title,
        achievement.rewardXP,
      );

      if (achievement.series != null) {
        await _unlockNextInSeries(
          achievement.series!,
          achievement.seriesOrder ?? 0,
        );
      }
    }
  }

  Future<void> _incrementAll(List<String> keys, [int amount = 1]) async {
    final toSave = <Achievement>[];
    final newlyUnlocked = <Achievement>[];

    for (final key in keys) {
      var achievement =
          await isar.achievements.filter().keyEqualTo(key).findFirst();

      achievement ??= _clone(_getAchievementDefinition(key));

      // Check series lock
      if (achievement.series != null &&
          achievement.seriesOrder != null &&
          achievement.seriesOrder! > 1) {
        final previous = await isar.achievements
            .filter()
            .seriesEqualTo(achievement.series)
            .seriesOrderEqualTo(achievement.seriesOrder! - 1)
            .findFirst();
        if (previous == null || !previous.isUnlocked) continue;
      }

      final wasUnlocked = achievement.isUnlocked;
      achievement.progress += amount;
      toSave.add(achievement);

      if (!wasUnlocked && achievement.progress >= achievement.target) {
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    if (toSave.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.achievements.putAll(toSave);
      });
    }

    // Handle rewards outside the write transaction
    for (final achievement in newlyUnlocked) {
      await _addXP(achievement.rewardXP, 'Achievement: ${achievement.title}');
      log.i('🏆 Achievement Unlocked: ${achievement.title}');
      SnackbarService.success(
        Tone.appL10n?.notif_achievementBody(achievement.title, achievement.rewardXP) ??
            '🏆 ${achievement.title} — nice, +${achievement.rewardXP} XP!',
      );

      NotificationService.showAchievementUnlocked(
        achievement.title,
        achievement.rewardXP,
      );
      if (achievement.series != null) {
        await _unlockNextInSeries(
          achievement.series!,
          achievement.seriesOrder ?? 0,
        );
      }
    }
  }

  Future<void> _handleTrackingStreak() async {
    final now = DateTime.now();
    final streak =
        await isar.streaks.filter().typeEqualTo('tracking').findFirst() ??
            (Streak()
              ..type = 'tracking'
              ..currentCount = 0
              ..longestCount = 0
              ..lastChecked = null
              ..lastUpdated = now);

    if (streak.lastChecked != null && _isSameDay(streak.lastChecked!, now)) {
      return; // already counted today
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

    if (streak.currentCount >= 3) {
      await _setProgress('tracking_streak_3', streak.currentCount);
    }
    if (streak.currentCount >= 7) {
      await _setProgress('tracking_streak_7', streak.currentCount);
    }
    if (streak.currentCount >= 30) {
      await _setProgress('tracking_streak_30', streak.currentCount);
    }
  }

  Future<void> _checkMonthlyBudgetCompletion() async {
    final now = DateTime.now();
    if (now.day != 1) return;

    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final budgets =
        await isar.budgets.filter().isArchivedEqualTo(false).findAll();

    if (budgets.isEmpty) return;

    bool allUnderBudget = true;
    for (final budget in budgets) {
      final (s, e) = budget.getCurrentPeriodRange(lastMonth);
      if (s.isAfter(lastMonthEnd) || e.isBefore(lastMonth)) continue;

      final spent = await _calculateBudgetSpent(budget, s, e);
      if (spent > budget.amount) {
        allUnderBudget = false;
        break;
      }
    }

    if (allUnderBudget) {
      await _incrementAll(['budget_month_complete']);
    }
  }

  Future<void> _unlockNextInSeries(String series, int currentOrder) async {
    final nextAchievement = await isar.achievements
        .filter()
        .seriesEqualTo(series)
        .seriesOrderEqualTo(currentOrder + 1)
        .findFirst();

    if (nextAchievement != null) {
      log.i('🔓 Next in series now visible: ${nextAchievement.title}');
    }
  }

  void _onLevelUp(int newLevel, int gainedLevels) {
    log.d('🎉 Level Up! New Level: $newLevel');
    SnackbarService.success(
      Tone.appL10n?.notif_levelUpBody ?? '🎉 Level $newLevel! You just leveled up!',
    );
    NotificationService.showLevelUp(newLevel);
  }

  Achievement _getAchievementDefinition(String key) {
    return AchievementRegistry.all[key]!;
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
      ..series = def.series
      ..seriesOrder = def.seriesOrder
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

  Future<void> _checkStreaks(int count) async {
    // Set progress directly to count for streak achievements
    if (count >= 3) {
      await _setProgress('streak_3_days', count);
      if (count == 3) {
        NotificationService.showStreakMilestone(3);
      }
    }
    if (count >= 7) {
      await _setProgress('streak_7_days', count);
      if (count == 7) {
        NotificationService.showStreakMilestone(7);
      }
    }
    if (count >= 30) {
      await _setProgress('streak_30_days', count);
      if (count == 30) {
        NotificationService.showStreakMilestone(30);
      }
    }
    if (count >= 100) {
      await _setProgress('streak_100_days', count);
      if (count == 100) {
        NotificationService.showStreakMilestone(100);
      }
    }
  }

  Future<void> _checkMilestones(int totalDays) async {
    if (totalDays >= 7) {
      await _setProgress('week_1', totalDays);
    }
    if (totalDays >= 30) {
      await _setProgress('month_1', totalDays);
    }
    if (totalDays >= 90) {
      await _setProgress('month_3', totalDays);
    }
    if (totalDays >= 365) {
      await _setProgress('year_1', totalDays);
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

  /// Calculate total spent for a budget in a date range.
  Future<double> _calculateBudgetSpent(Budget budget, DateTime s, DateTime e) =>
      BudgetSpentCalculator.calculate(isar, budget, s, e);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isConsecutiveDay(DateTime last, DateTime now) {
    final d1 = DateTime(last.year, last.month, last.day);
    final d2 = DateTime(now.year, now.month, now.day);

    return d2.difference(d1).inDays == 1;
  }

  bool _withinGracePeriod(DateTime last, DateTime now) {
    final d1 = DateTime(last.year, last.month, last.day);
    final d2 = DateTime(now.year, now.month, now.day);
    final daysDiff = d2.difference(d1).inDays;
    final hoursDiff = now.difference(last).inHours;

    // Must be exactly 1 day apart (next day) and within 48 hours
    return daysDiff == 1 && hoursDiff > 24 && hoursDiff <= 48;
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

  /// Get cumulative progress for series achievements
  Future<int> getCumulativeProgress(Achievement achievement) async {
    if (achievement.series == null || achievement.seriesOrder == null) {
      return achievement.progress;
    }

    // Sum progress from all previous achievements + current
    final allInSeries = await isar.achievements
        .filter()
        .seriesEqualTo(achievement.series)
        .seriesOrderLessThan(achievement.seriesOrder! + 1)
        .findAll();

    return allInSeries.fold<int>(0, (sum, ach) => sum + ach.progress);
  }

  Future<String?> updateDailyCheckIn() async {
    final now = DateTime.now();
    log.i('🔍 Daily check-in called at: $now');

    // -------------------------------
    // 1. Update streak (DB only)
    // -------------------------------
    final streak =
        await isar.streaks.filter().typeEqualTo('daily_checkin').findFirst();

    log.i('📊 Existing streak: ${streak?.lastChecked}');

    final existing = streak ??
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
      // Even if already checked in, ensure next day's reminder is scheduled
      final currentStreak = existing.currentCount;
      if (currentStreak >= 1) {
        await NotificationService.scheduleStreakReminder(
          currentStreak,
          forceNextDay: true,
        );
      }
      return null;
    }

    log.i('✅ Proceeding with check-in. Last: $last, Now: $now');

    // Continue or reset
    if (last != null &&
        (_isConsecutiveDay(last, now) || _withinGracePeriod(last, now))) {
      existing.currentCount++;
      log.i('🔥 Streak continued: ${existing.currentCount}');
    } else if (last == null) {
      existing.currentCount = 1;
      log.i('🆕 First check-in');
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

    // Schedule reminder for next day if streak >= 1
    if (newStreak >= 1) {
      await NotificationService.scheduleStreakReminder(
        newStreak,
        forceNextDay: true,
      );
    }

    // -------------------------------
    // 2. Give rewards (outside txn)
    // -------------------------------
    await _checkStreaks(newStreak);
    await _checkMilestones(existing.longestCount);

    final xp = _calculateStreakXP(newStreak);
    await _addXP(xp, 'Daily Streak: $newStreak');

    // -------------------------------
    // 3. Check budget adherence (async, don't await)
    // -------------------------------
    await _checkBudgetAdherence();
    await _checkMonthlyBudgetCompletion();
    // Check zero-spend yesterday
    await _checkZeroSpendDay(now);

    // Check savings streak
    await _checkSavingsStreak(now);

    // Check under-budget spending streak
    await _handleUnderBudgetStreak();

    log.i('🎉 Check-in complete: Day $newStreak, +$xp XP');
    return 'Day $newStreak streak! +$xp XP';
  }

  Future<void> _checkBudgetAdherence() async {
    try {
      final now = DateTime.now();
      if (await _isBeforeTrackingStart(now)) return;
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      final yesterdayEnd = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );

      final budgets = await isar.budgets
          .filter()
          .isArchivedEqualTo(false)
          .startDateLessThan(yesterdayEnd)
          .and()
          .endDateGreaterThan(yesterdayStart)
          .findAll();

      if (budgets.isEmpty) {
        log.i('💰 No active budgets to check');
        return;
      }

      bool allWithinBudget = true;
      for (final budget in budgets) {
        final (s, e) = budget.getCurrentPeriodRange(yesterday);
        final totalSpent = await _calculateBudgetSpent(budget, s, e);

        if (totalSpent > budget.amount) {
          allWithinBudget = false;
          log.i(
            '💰 Budget exceeded: ${budget.name} ($totalSpent/${budget.amount})',
          );
          break;
        }
      }

      final streak = await isar.streaks
          .filter()
          .typeEqualTo('budget_adherence')
          .findFirst();

      final existing = streak ??
          (Streak()
            ..type = 'budget_adherence'
            ..currentCount = 0
            ..longestCount = 0
            ..lastChecked = null
            ..lastUpdated = now);

      final last = existing.lastChecked;

      if (last != null && _isSameDay(last, now)) {
        return;
      }

      if (allWithinBudget) {
        if (last != null && _isConsecutiveDay(last, now)) {
          existing.currentCount++;
          log.i(
            '💰 Budget adherence streak continued: ${existing.currentCount}',
          );
        } else {
          existing.currentCount = 1;
          log.i('💰 Budget adherence streak started: 1');
        }

        if (existing.currentCount > existing.longestCount) {
          existing.longestCount = existing.currentCount;
        }

        // Check budget_master achievement
        if (existing.currentCount >= 30) {
          await _setProgress('budget_master', existing.currentCount);
        }
      } else {
        existing.currentCount = 0;
        log.i('💰 Budget adherence streak broken');
      }

      existing.lastChecked = now;
      existing.lastUpdated = now;

      await isar.writeTxn(() => isar.streaks.put(existing));
    } catch (e) {
      log.e('Error checking budget adherence', e);
    }
  }

  /// Returns true if yesterday is before the app install date — no meaningful
  /// "yesterday" data exists yet, so daily-comparison checks should be skipped.
  Future<bool> _isBeforeTrackingStart(DateTime now) async {
    final config = await isar.appConfigs
        .filter()
        .keyEqualTo('ent_install_date')
        .findFirst();
    if (config?.dateValue == null) return true;
    final install = config!.dateValue!;
    final installDay = DateTime(install.year, install.month, install.day);
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return yesterday.isBefore(installDay);
  }

  Future<void> _checkZeroSpendDay(DateTime now) async {
    try {
      final totalTxns = await isar.transactions.count();
      if (totalTxns == 0) return;
      if (await _isBeforeTrackingStart(now)) return;

      final yesterday = now.subtract(const Duration(days: 1));
      final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final end =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      final count = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .dateBetween(start, end)
          .count();
      if (count == 0) {
        await track(GamificationEvent.zeroSpendDay);
      }
    } catch (e) {
      log.e('Error checking zero spend day', e);
    }
  }

  Future<void> _checkSavingsStreak(DateTime now) async {
    try {
      final totalTxns = await isar.transactions.count();
      if (totalTxns == 0) return;
      if (await _isBeforeTrackingStart(now)) return;
      final yesterday = now.subtract(const Duration(days: 1));
      final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final end =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

      final income = await isar.transactions
          .filter()
          .isExpenseEqualTo(false)
          .isTransferEqualTo(false)
          .dateBetween(start, end)
          .amountProperty()
          .sum();
      final expense = await isar.transactions
          .filter()
          .isExpenseEqualTo(true)
          .isTransferEqualTo(false)
          .dateBetween(start, end)
          .amountProperty()
          .sum();

      final streak =
          await isar.streaks.filter().typeEqualTo('savings_streak').findFirst();

      final existing = streak ??
          (Streak()
            ..type = 'savings_streak'
            ..currentCount = 0
            ..longestCount = 0
            ..lastChecked = null
            ..lastUpdated = now);

      final last = existing.lastChecked;
      if (last != null && _isSameDay(last, now)) return;

      if (expense <= income) {
        if (last != null && _isConsecutiveDay(last, now)) {
          existing.currentCount++;
        } else {
          existing.currentCount = 1;
        }
        if (existing.currentCount > existing.longestCount) {
          existing.longestCount = existing.currentCount;
        }
        if (existing.currentCount >= 7) {
          await _setProgress('savings_streak_7', existing.currentCount);
        }
        if (existing.currentCount >= 30) {
          await _setProgress('savings_streak_30', existing.currentCount);
        }
      } else {
        existing.currentCount = 0;
      }

      existing.lastChecked = now;
      existing.lastUpdated = now;
      await isar.writeTxn(() => isar.streaks.put(existing));
    } catch (e) {
      log.e('Error checking savings streak', e);
    }
  }

  /// Under-budget spending streak: tracks consecutive days where
  /// daily spend ≤ daily budget allowance (budget.amount / days in period).
  Future<void> _handleUnderBudgetStreak() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yStart = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final yEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

      // Get active budgets that cover yesterday
      final budgets = await isar.budgets
          .filter()
          .isArchivedEqualTo(false)
          .startDateLessThan(yEnd)
          .and()
          .endDateGreaterThan(yStart)
          .findAll();

      if (budgets.isEmpty) return;

      // Check if yesterday's spend was under all budgets' daily allowance
      bool allUnder = true;
      for (final budget in budgets) {
        final (s, e) = budget.getCurrentPeriodRange(yesterday);
        final daysInPeriod = e.difference(s).inDays + 1;
        final dailyAllowance = daysInPeriod > 0 ? budget.amount / daysInPeriod : budget.amount;

        final spent = await _calculateBudgetSpent(budget, yStart, yEnd);
        if (spent > dailyAllowance) {
          allUnder = false;
          break;
        }
      }

      final streak = await isar.streaks
          .filter()
          .typeEqualTo('under_budget_spending')
          .findFirst();

      final existing = streak ??
          (Streak()
            ..type = 'under_budget_spending'
            ..currentCount = 0
            ..longestCount = 0
            ..lastChecked = null
            ..lastUpdated = now);

      final last = existing.lastChecked;
      if (last != null && _isSameDay(last, now)) return;

      if (allUnder) {
        if (last != null && _isConsecutiveDay(last, now)) {
          existing.currentCount++;
        } else {
          existing.currentCount = 1;
        }
        if (existing.currentCount > existing.longestCount) {
          existing.longestCount = existing.currentCount;
        }

        if (existing.currentCount >= 3) {
          await _setProgress('under_budget_3', existing.currentCount);
        }
        if (existing.currentCount >= 7) {
          await _setProgress('under_budget_7', existing.currentCount);
        }
        if (existing.currentCount >= 30) {
          await _setProgress('under_budget_30', existing.currentCount);
        }

        log.i('💰 Under-budget streak: ${existing.currentCount} days');
      } else {
        existing.currentCount = 0;
        log.i('💰 Under-budget streak broken');
      }

      existing.lastChecked = now;
      existing.lastUpdated = now;
      await isar.writeTxn(() => isar.streaks.put(existing));
    } catch (e) {
      log.e('Error checking under-budget streak', e);
    }
  }
}
