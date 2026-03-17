import 'package:mudra_manager/features/gamification/models/achievement.dart';

class AchievementRegistry {
  static final all = <String, Achievement>{
    // ==================== TRACKING ACHIEVEMENTS ====================
    'first_transaction': Achievement()
      ..key = 'first_transaction'
      ..title = 'First Step'
      ..description = 'Record your first transaction'
      ..icon = 'target'
      ..category = AchievementCategory.tracking
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 1
      ..rewardXP = 10
      ..rewardCoins = 0
      ..series = 'transactions'
      ..seriesOrder = 1,

    'transaction_10': Achievement()
      ..key = 'transaction_10'
      ..title = 'Getting Started'
      ..description = 'Track 10 transactions'
      ..icon = 'note'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 10
      ..rewardXP = 25
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transactions'
      ..seriesOrder = 2,

    'transaction_50': Achievement()
      ..key = 'transaction_50'
      ..title = 'Consistent Tracker'
      ..description = 'Track 50 transactions'
      ..icon = 'chart'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 50
      ..rewardXP = 50
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transactions'
      ..seriesOrder = 3,

    'transaction_100': Achievement()
      ..key = 'transaction_100'
      ..title = 'Century Club'
      ..description = 'Track 100 transactions'
      ..icon = 'hundred'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 100
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transactions'
      ..seriesOrder = 4,

    'transaction_500': Achievement()
      ..key = 'transaction_500'
      ..title = 'Master Tracker'
      ..description = 'Track 500 transactions'
      ..icon = 'tracker_master'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 500
      ..rewardXP = 250
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transactions'
      ..seriesOrder = 5,

    // ==================== STREAK ACHIEVEMENTS ====================
    'streak_3_days': Achievement()
      ..key = 'streak_3_days'
      ..title = 'On Fire'
      ..description = 'Check in for 3 days straight'
      ..icon = 'flame'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 3
      ..rewardXP = 15
      ..rewardCoins = 0
      ..type = AchievementType.streak
      ..series = 'streaks'
      ..seriesOrder = 1,

    'streak_7_days': Achievement()
      ..key = 'streak_7_days'
      ..title = 'Week Warrior'
      ..description = 'Check in for 7 days straight'
      ..icon = 'bolt'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 7
      ..rewardXP = 35
      ..rewardCoins = 0
      ..type = AchievementType.streak
      ..series = 'streaks'
      ..seriesOrder = 2,

    'streak_30_days': Achievement()
      ..key = 'streak_30_days'
      ..title = 'Unstoppable'
      ..description = 'Check in for 30 days straight'
      ..icon = 'medal'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 30
      ..rewardXP = 150
      ..rewardCoins = 0
      ..type = AchievementType.streak
      ..series = 'streaks'
      ..seriesOrder = 3,

    'streak_100_days': Achievement()
      ..key = 'streak_100_days'
      ..title = 'Legend'
      ..description = 'Check in for 100 days straight'
      ..icon = 'crown'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 100
      ..rewardXP = 500
      ..rewardCoins = 0
      ..type = AchievementType.streak
      ..series = 'streaks'
      ..seriesOrder = 4,

    // ==================== BUDGET ACHIEVEMENTS ====================
    'first_budget': Achievement()
      ..key = 'first_budget'
      ..title = 'Budget Planner'
      ..description = 'Create your first budget'
      ..icon = 'budget-planner'
      ..category = AchievementCategory.budgeting
      ..progress = 0
      ..target = 1
      ..rewardXP = 20
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'budget'
      ..seriesOrder = 1,

    'budget_master': Achievement()
      ..key = 'budget_master'
      ..title = 'Budget Master'
      ..description = 'Stay within budget for a month'
      ..icon = 'budget-master'
      ..category = AchievementCategory.budgeting
      ..progress = 0
      ..target = 30
      ..rewardXP = 200
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'budget'
      ..seriesOrder = 2,

    // ==================== SAVINGS ACHIEVEMENTS ====================
    'first_goal': Achievement()
      ..key = 'first_goal'
      ..title = 'Goal Setter'
      ..description = 'Create your first savings goal'
      ..icon = 'goal'
      ..category = AchievementCategory.saving
      ..progress = 0
      ..target = 1
      ..rewardXP = 20
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'goal'
      ..seriesOrder = 1,

    'goal_completed': Achievement()
      ..key = 'goal_completed'
      ..title = 'Goal Crusher'
      ..description = 'Complete your first savings goal'
      ..icon = 'award'
      ..category = AchievementCategory.saving
      ..progress = 0
      ..target = 1
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'goal'
      ..seriesOrder = 2,

    // ==================== MILESTONE ACHIEVEMENTS ====================
    'week_1': Achievement()
      ..key = 'week_1'
      ..title = 'Seedling'
      ..description = 'Use the app for 1 week'
      ..icon = 'sprout'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 7
      ..rewardXP = 30
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'milestone'
      ..seriesOrder = 1,

    'month_1': Achievement()
      ..key = 'month_1'
      ..title = 'Growing'
      ..description = 'Use the app for 1 month'
      ..icon = 'leaf'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 30
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'milestone'
      ..seriesOrder = 2,

    'month_3': Achievement()
      ..key = 'month_3'
      ..title = 'Committed'
      ..description = 'Use the app for 3 months'
      ..icon = 'tree'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 90
      ..rewardXP = 300
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'milestone'
      ..seriesOrder = 3,

    'year_1': Achievement()
      ..key = 'year_1'
      ..title = 'Financial Sage'
      ..description = 'Use the app for 1 year'
      ..icon = 'forest'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 365
      ..rewardXP = 1000
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'milestone'
      ..seriesOrder = 4,

    // ==================== SMS/AUTO-IMPORT ACHIEVEMENTS ====================
    'sms_10': Achievement()
      ..key = 'sms_10'
      ..title = 'SMS Wizard'
      ..description = 'Approve 10 SMS transactions'
      ..icon = 'message'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 10
      ..rewardXP = 30
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'sms'
      ..seriesOrder = 1,

    'sms_50': Achievement()
      ..key = 'sms_50'
      ..title = 'Automation Master'
      ..description = 'Approve 50 SMS transactions'
      ..icon = 'robot'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 50
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'sms'
      ..seriesOrder = 2,

    // ==================== CATEGORY ACHIEVEMENTS ====================
    'category_5': Achievement()
      ..key = 'category_5'
      ..title = 'Organized Mind'
      ..description = 'Create 5 custom categories'
      ..icon = 'folder'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 5
      ..rewardXP = 25
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'categories'
      ..seriesOrder = 1,

    'category_10': Achievement()
      ..key = 'category_10'
      ..title = 'Category Expert'
      ..description = 'Use 10 different categories'
      ..icon = 'grid'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 10
      ..rewardXP = 50
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'categories'
      ..seriesOrder = 2,

    // ==================== ACCOUNT ACHIEVEMENTS ====================
    'account_3': Achievement()
      ..key = 'account_3'
      ..title = 'Multi-Account Manager'
      ..description = 'Create 3 accounts'
      ..icon = 'wallet'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 3
      ..rewardXP = 30
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'accounts'
      ..seriesOrder = 1,

    'account_5': Achievement()
      ..key = 'account_5'
      ..title = 'Portfolio Builder'
      ..description = 'Manage 5+ accounts'
      ..icon = 'briefcase'
      ..category = AchievementCategory.milestone
      ..progress = 0
      ..target = 5
      ..rewardXP = 75
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'accounts'
      ..seriesOrder = 2,

    // ==================== TRANSFER ACHIEVEMENTS ====================
    'transfer_10': Achievement()
      ..key = 'transfer_10'
      ..title = 'Money Mover'
      ..description = 'Complete 10 transfers between accounts'
      ..icon = 'transfer'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 10
      ..rewardXP = 40
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transfers'
      ..seriesOrder = 1,

    'transfer_50': Achievement()
      ..key = 'transfer_50'
      ..title = 'Money Mover Master'
      ..description = 'Complete 50 transfers between accounts'
      ..icon = 'money-transfer'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 50
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'transfers'
      ..seriesOrder = 2,

    // ==================== RECURRING TRANSACTION ACHIEVEMENTS ====================
    'recurring_5': Achievement()
      ..key = 'recurring_5'
      ..title = 'Automation Pro'
      ..description = 'Set up 5 recurring transactions'
      ..icon = 'repeat'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 5
      ..rewardXP = 50
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'recurring'
      ..seriesOrder = 1,

    'recurring_10': Achievement()
      ..key = 'recurring_10'
      ..title = 'Subscription Tracker'
      ..description = 'Track 10 recurring transactions'
      ..icon = 'calendar'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 10
      ..rewardXP = 100
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'recurring'
      ..seriesOrder = 2,

    // ==================== TAG ACHIEVEMENTS ====================
    'tag_5': Achievement()
      ..key = 'tag_5'
      ..title = 'Tag Rookie'
      ..description = 'Use tags on 5 transactions'
      ..icon = 'tag5'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 5
      ..rewardXP = 20
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'tags'
      ..seriesOrder = 1,

    'tag_25': Achievement()
      ..key = 'tag_25'
      ..title = 'Tag Master'
      ..description = 'Use tags on 25 transactions'
      ..icon = 'tag25'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 25
      ..rewardXP = 40
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'tags'
      ..seriesOrder = 2,

    // ==================== ANALYTICS ACHIEVEMENTS ====================
    'analytics_10': Achievement()
      ..key = 'analytics_10'
      ..title = 'Data Explorer'
      ..description = 'View analytics 10 times'
      ..icon = 'pie'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 10
      ..rewardXP = 30
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'analytics'
      ..seriesOrder = 1,

    'export_first': Achievement()
      ..key = 'export_first'
      ..title = 'Insight Seeker'
      ..description = 'Export your first report'
      ..icon = 'download'
      ..category = AchievementCategory.engagement
      ..progress = 0
      ..target = 1
      ..rewardXP = 25
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'export'
      ..seriesOrder = 1,

    // ==================== TRIP ACHIEVEMENTS ====================
    'trip_first': Achievement()
      ..key = 'trip_first'
      ..title = 'Travel Tracker'
      ..description = 'Create your first trip'
      ..icon = 'plane'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 1
      ..rewardXP = 20
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'trips'
      ..seriesOrder = 1,

    'trip_5': Achievement()
      ..key = 'trip_5'
      ..title = 'Globetrotter'
      ..description = 'Track 5 trips'
      ..icon = 'map'
      ..category = AchievementCategory.tracking
      ..progress = 0
      ..target = 5
      ..rewardXP = 75
      ..rewardCoins = 0
      ..type = AchievementType.badge
      ..series = 'trips'
      ..seriesOrder = 2,

    // ==================== BACKUP ACHIEVEMENTS ====================
    'first_backup': Achievement()
      ..key = 'first_backup'
      ..title = 'Safety First'
      ..description = 'Create your first backup'
      ..icon = 'shield'
      ..category = AchievementCategory.engagement
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 1
      ..rewardXP = 25
      ..rewardCoins = 0
      ..series = 'backup'
      ..seriesOrder = 1,

    'backup_10': Achievement()
      ..key = 'backup_10'
      ..title = 'Data Guardian'
      ..description = 'Create 10 backups'
      ..icon = 'vault'
      ..category = AchievementCategory.engagement
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 10
      ..rewardXP = 75
      ..rewardCoins = 0
      ..series = 'backup'
      ..seriesOrder = 2,

// ==================== SPLIT/SETTLEMENT ACHIEVEMENTS ====================
    'first_split': Achievement()
      ..key = 'first_split'
      ..title = 'Fair Share'
      ..description = 'Split your first expense'
      ..icon = 'split'
      ..category = AchievementCategory.tracking
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 1
      ..rewardXP = 20
      ..rewardCoins = 0
      ..series = 'splits'
      ..seriesOrder = 1,

    'split_20': Achievement()
      ..key = 'split_20'
      ..title = 'Split Master'
      ..description = 'Split 20 expenses with friends'
      ..icon = 'users'
      ..category = AchievementCategory.tracking
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 20
      ..rewardXP = 75
      ..rewardCoins = 0
      ..series = 'splits'
      ..seriesOrder = 2,

// ==================== SAVINGS MILESTONES ====================
    'savings_streak_7': Achievement()
      ..key = 'savings_streak_7'
      ..title = 'Saver\'s Habit'
      ..description = 'Spend less than income for 7 days straight'
      ..icon = 'piggy'
      ..category = AchievementCategory.saving
      ..type = AchievementType.streak
      ..progress = 0
      ..target = 7
      ..rewardXP = 50
      ..rewardCoins = 0
      ..series = 'savings_streak'
      ..seriesOrder = 1,

    'savings_streak_30': Achievement()
      ..key = 'savings_streak_30'
      ..title = 'Frugal Champion'
      ..description = 'Spend less than income for 30 days straight'
      ..icon = 'trophy'
      ..category = AchievementCategory.saving
      ..type = AchievementType.streak
      ..progress = 0
      ..target = 30
      ..rewardXP = 200
      ..rewardCoins = 0
      ..series = 'savings_streak'
      ..seriesOrder = 2,

// ==================== ZERO SPEND DAY ====================
    'zero_spend_1': Achievement()
      ..key = 'zero_spend_1'
      ..title = 'No Spend Day'
      ..description = 'Have a day with zero expenses'
      ..icon = 'ban'
      ..category = AchievementCategory.saving
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 1
      ..rewardXP = 15
      ..rewardCoins = 0
      ..series = 'zero_spend'
      ..seriesOrder = 1,

    'zero_spend_10': Achievement()
      ..key = 'zero_spend_10'
      ..title = 'Minimalist'
      ..description = 'Have 10 zero-spend days'
      ..icon = 'minimalist'
      ..category = AchievementCategory.saving
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 10
      ..rewardXP = 60
      ..rewardCoins = 0
      ..series = 'zero_spend'
      ..seriesOrder = 2,

// ==================== RECONCILIATION ====================
    'reconcile_first': Achievement()
      ..key = 'reconcile_first'
      ..title = 'Balance Checker'
      ..description = 'Reconcile your first transaction'
      ..icon = 'check-circle'
      ..category = AchievementCategory.tracking
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 1
      ..rewardXP = 20
      ..rewardCoins = 0
      ..series = 'reconcile'
      ..seriesOrder = 1,

    'reconcile_50': Achievement()
      ..key = 'reconcile_50'
      ..title = 'Audit Pro'
      ..description = 'Reconcile 50 transactions'
      ..icon = 'clipboard-check'
      ..category = AchievementCategory.tracking
      ..type = AchievementType.badge
      ..progress = 0
      ..target = 50
      ..rewardXP = 100
      ..rewardCoins = 0
      ..series = 'reconcile'
      ..seriesOrder = 2,
  };
}
