import 'package:isar_community/isar.dart';

part 'achievement.g.dart';

@collection
class Achievement {
  Id id = Isar.autoIncrement;

  late String key;

  late String title;
  late String description;
  late String icon;

  @enumerated
  late AchievementCategory category;

  @Index()
  @enumerated
  late AchievementType type;

  late int progress;
  late int target;

  late int rewardXP;
  late int rewardCoins;

  DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;
}

enum AchievementCategory { budgeting, saving, tracking, milestone, engagement }

enum AchievementType { badge, streak, challenge }

@collection
class Streak {
  Id id = Isar.autoIncrement;

  @Index()
  late String type; // 'daily_checkin', 'budget_adherence', 'tracking'

  late int currentCount;
  late int longestCount;
  late DateTime lastUpdated;
  late DateTime? lastChecked;
}

@collection
class Challenge {
  Id id = Isar.autoIncrement;

  late String title;
  late String description;
  late String icon;

  @enumerated
  late ChallengeType type;

  @enumerated
  late ChallengePeriod period;

  late DateTime startDate;
  late DateTime endDate;

  late int progress;
  late int target;

  late bool isActive;
  late bool isCompleted;

  late int rewardXP;
  late bool isExpired;
  DateTime? completedAt;
}

enum ChallengeType {
  spendingLimit,
  savingsGoal,
  trackingConsistency,
  categoryBudget,
  noSpendCategory,
}

enum ChallengePeriod { daily, weekly, monthly }

@collection
class UserLevel {
  Id id = Isar.autoIncrement;

  late int level;
  late int currentXP;
  late int totalXP;
  late DateTime lastUpdated;

  int get xpForNextLevel {
    return 100 + (level * level * 25);
  }

  int get xpProgress => currentXP;
  double get progressPercent => currentXP / xpForNextLevel;
}

@collection
class XpLog {
  Id id = Isar.autoIncrement;
  late int amount;
  late String reason;
  late DateTime createdAt;
}
