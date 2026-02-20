import 'package:mudra_manager/features/backup/data/backable_model.dart';
import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementBackup implements BackupAdapter<Achievement> {
  late final int id;
  final String key;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementType type;
  final int progress;
  final int target;
  final int rewardXP;
  final int rewardCoins;
  final DateTime? unlockedAt;

  AchievementBackup.fromAchievement(Achievement achievement)
      : id = achievement.id,
        key = achievement.key,
        title = achievement.title,
        description = achievement.description,
        icon = achievement.icon,
        category = achievement.category,
        type = achievement.type,
        progress = achievement.progress,
        target = achievement.target,
        rewardXP = achievement.rewardXP,
        rewardCoins = achievement.rewardCoins,
        unlockedAt = achievement.unlockedAt;

  AchievementBackup()
      : id = 0,
        key = '',
        title = '',
        description = '',
        icon = '',
        category = AchievementCategory.tracking,
        type = AchievementType.badge,
        progress = 0,
        target = 0,
        rewardXP = 0,
        rewardCoins = 0,
        unlockedAt = null;

  @override
  Map<String, dynamic> toBackupJson() => {
        'id': id,
        'key': key,
        'title': title,
        'description': description,
        'icon': icon,
        'category': category.index,
        'type': type.index,
        'progress': progress,
        'target': target,
        'rewardXP': rewardXP,
        'rewardCoins': rewardCoins,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  @override
  Achievement fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    return Achievement()
      ..id = json['id']
      ..key = json['key']
      ..title = json['title']
      ..description = json['description']
      ..icon = json['icon']
      ..category = AchievementCategory.values[json['category'] as int]
      ..type = AchievementType.values[json['type'] as int]
      ..progress = json['progress']
      ..target = json['target']
      ..rewardXP = json['rewardXP']
      ..rewardCoins = json['rewardCoins']
      ..unlockedAt = json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null;
  }
}

class StreakBackup implements BackupAdapter<Streak> {
  late final int id;
  final String type;
  final int currentCount;
  final int longestCount;
  final DateTime lastUpdated;
  final DateTime? lastChecked;

  StreakBackup.fromStreak(Streak streak)
      : id = streak.id,
        type = streak.type,
        currentCount = streak.currentCount,
        longestCount = streak.longestCount,
        lastUpdated = streak.lastUpdated,
        lastChecked = streak.lastChecked;

  StreakBackup()
      : id = 0,
        type = '',
        currentCount = 0,
        longestCount = 0,
        lastUpdated = DateTime.now(),
        lastChecked = null;

  @override
  Map<String, dynamic> toBackupJson() => {
        'id': id,
        'type': type,
        'currentCount': currentCount,
        'longestCount': longestCount,
        'lastUpdated': lastUpdated.toIso8601String(),
        'lastChecked': lastChecked?.toIso8601String(),
      };

  @override
  Streak fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    return Streak()
      ..id = json['id']
      ..type = json['type']
      ..currentCount = json['currentCount']
      ..longestCount = json['longestCount']
      ..lastUpdated = DateTime.parse(json['lastUpdated'])
      ..lastChecked = json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'])
          : null;
  }
}

class UserLevelBackup implements BackupAdapter<UserLevel> {
  late final int id;
  final int level;
  final int currentXP;
  final int totalXP;
  final DateTime lastUpdated;

  UserLevelBackup.fromUserLevel(UserLevel userLevel)
      : id = userLevel.id,
        level = userLevel.level,
        currentXP = userLevel.currentXP,
        totalXP = userLevel.totalXP,
        lastUpdated = userLevel.lastUpdated;

  UserLevelBackup()
      : id = 0,
        level = 1,
        currentXP = 0,
        totalXP = 0,
        lastUpdated = DateTime.now();

  @override
  Map<String, dynamic> toBackupJson() => {
        'id': id,
        'level': level,
        'currentXP': currentXP,
        'totalXP': totalXP,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  @override
  UserLevel fromBackupJson(
    Map<String, dynamic> json,
    Map<String, dynamic> linkedRefs,
  ) {
    return UserLevel()
      ..id = json['id']
      ..level = json['level']
      ..currentXP = json['currentXP']
      ..totalXP = json['totalXP']
      ..lastUpdated = DateTime.parse(json['lastUpdated']);
  }
}
