/// Base class for all tone packs.
/// Each pack provides the same set of messages in a different personality.
abstract class TonePack {
  String get id;
  String get name;
  String get description;
  String get emoji;

  // ── Transaction ──
  String get txnAdded;
  String get txnUpdated;
  String get txnDeleted;
  String get txnFailed;
  String get txnNotFound;

  // ── Validation ──
  String get enterAmount;
  String get pickAccount;
  String get pickCategory;
  String get fillAllFields;
  String get invalidAmount;
  String get futureDate;
  String get selectAccountAndCategory;

  // ── Trip & Split ──
  String tripCreated(bool isTrip);
  String tripUpdated(bool isTrip);
  String tripDeleted(bool isTrip);
  String tripFinalized(bool isTrip);
  String tripNameRequired(bool isTrip);
  String get addParticipant;
  String tripLimitReached(bool isTrip);
  String expenseAddedToTrip(bool isTrip);

  // ── Budget ──
  String get budgetCreated;
  String get budgetUpdated;
  String get budgetDeleted;

  // ── Budget Insights ──
  String budgetExceededBy(String amount);
  String budgetSlowDown(String amount, int days);
  String budgetSafePerDay(String amount);
  String get budgetExceededAdjust;
  String budgetOnTrack(String amount);
  String get budgetGreatDiscipline;
  String budgetAlreadySpent(String amount);
  String budgetMayExceedIn(int days);
  String budgetGettingTight(String amount, int days);
  String budgetInControl(String amount);

  // ── Monthly Comparison ──
  String comparisonSpentLess(String amount);
  String comparisonSpentMore(String amount);
  String get comparisonSpentSame;
  String comparisonTopIncrease(String category, String amount);
  String comparisonTopDecrease(String category, String amount);
  String comparisonPrediction(String amount);
  String comparisonTxnCount(int current, int last);
  String comparisonDailyAvg(String current, String last);
  String comparisonByThisDay(String amount);

  // ── Goal ──
  String get goalCreated;
  String get goalUpdated;
  String get goalDeleted;

  // ── Goal Insights ──
  String goalMilestone25(String goalName);
  String goalMilestone50(String goalName);
  String goalMilestone75(String goalName);
  String goalMilestone100(String goalName);
  String goalOnTrack(String goalName);
  String goalBehind(String goalName);
  String goalAhead(String goalName, String days);
  String goalDailyNeeded(String amount);
  String goalPredictedDate(String date);
  String goalContributionThisMonth(String amount);
  String goalNoDeadline(String goalName);

  // ── Account ──
  String get accountCreated;
  String get accountUpdated;
  String get accountDeleted;
  String get accountLocked;

  // ── Category ──
  String get categoryCreated;
  String get categoryDeleted;
  String get categoryNameRequired;

  // ── Bill ──
  String get billAdded;
  String get billPaid;
  String get billDeleted;

  // ── Backup ──
  String get backupSuccess;
  String get backupFailed;
  String get restoreSuccess;
  String get restoreFailed;
  String get invalidBackupFile;
  String get corruptBackup;

  // ── Settings ──
  String get settingsSaved;
  String get reminderUpdated;
  String toggledOn(String feature);
  String toggledOff(String feature);

  // ── Auth ──
  String get biometricFailed;
  String get incorrectPin;

  // ── SMS / Auto Import ──
  String get notificationAccessDenied;
  String get smsImportEnabled;

  // ── Empty States ──
  String get noTransactions;
  String get noBudgets;
  String get noGoals;
  String get noBills;
  String get noAccounts;
  String get noCategories;
  String get noNotifications;
  String noFilterResults(String filter);
  String get noData;
  String get noRecurring;

  // ── Export ──
  String get exportSuccess;
  String exportFailed(String error);

  // ── Pro / Upgrade ──
  String get purchaseFailed;
  String get playNotAvailable;

  // ── Generic ──
  String errorWith(String detail);
  String get genericError;

  // ── Confirmations ──
  String get deleteTitle;
  String deleteMessage(String? param);
  String get deleteConfirm;
  String get deleteCancel;
  String get logoutTitle;
  String get logoutMessage;
  String get logoutConfirm;

  // ── Currency ──
  String get currencyChanged;
  String currencyArchivedCount(int count, String newCurrency);
  String get currencyChangeTitle;
  String get currencyChangeWarning;
  String get currencyChangeConfirm;
  String get currencyChangeCancel;
  String get currencyPickerTitle;
  String get currencyPickerSubtitle;
  String get currencyChangeIrreversible;
  String get archivedTransactionsTitle;
  String get noArchivedTransactions;
  String noTripExpenses(bool isTrip);

  // ── AI Insights ──
  String get insightBillsDueSoon;
  String insightBillsDueMessage(int count);
  String get insightOverBudget;
  String insightOverBudgetMessage(int count);
  String get insightNearBudget;
  String insightNearBudgetMessage(int count);
  String get insightOverspending;
  String insightOverspendingMessage(String amount);
  String get insightSpendingSpike;
  String insightSpendingSpikeMessage(String avg, String today);
  String get insightWeekendAlert;
  String insightWeekendAlertMessage(String avg, String current);
  String insightMoneyLeak(String category, int count, String total);
  String insightBestDay(
      // ignore: require_trailing_commas
      String worst, String wAvg, String best, String bAvg, String saving);
  String get insightGetStarted;
  String get insightGetStartedMessage;

  // ── Smart Notifications (drain queue) ──
  String singleApproved(String amountStr);
  String allApproved(int count, String amountStr);
  String mixedResults(int approved, int reviewCount);
  String allNeedReview(int reviewCount);

  // ── Dashboard Greetings (context-aware) ──
  String greetingMorning(String name);
  String greetingAfternoon(String name);
  String greetingEvening(String name);
  String get dashboardWelcomeBack;
  String get dashboardAllCaughtUp;
  String streakMessage(int days);

  // ── Contextual Notifications ──
  String budgetExceededNotif(String name, String spent, String limit);
  String budgetWarningNotif(String name, String remaining, String pct);
  String billDueNotif(String name, String amount, String when);
  String balanceDropNotif(String days);
  String savingsOpportunityNotif(String category, String amount);
  String unusualSpendingNotif(String today, String multiplier);
  String pendingSmsNotif(int count);
  String moneyLeakNotif(String category, int count, String total);
  String reEngageMissYou(int lostStreak);
  String reEngageUntracked(int days, String estimatedSpend);
  String get reEngageQuickNudge;
  String dailySummaryNotif(String spent, String earned, String topCategory);
  String get dailySummaryEmpty;
  String weeklySummaryNotif(String total, String topCategory, String trend);
  String streakAtRisk(int streak);
  String streakLost(int streak);
}
