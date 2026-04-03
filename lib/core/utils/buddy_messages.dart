import 'package:mudra_manager/core/tone/tone_provider.dart';

/// Backward-compatible accessor for tone messages.
/// Delegates to the currently active [TonePack] via [Tone.current].
///
/// Usage: `BuddyMessages.txnAdded` — works everywhere, no ref needed.
/// The active tone is set by [Tone.sync] from the top-level widget.
class BuddyMessages {
  BuddyMessages._();

  // ── Transaction ──
  static String get txnAdded => Tone.current.txnAdded;
  static String get txnUpdated => Tone.current.txnUpdated;
  static String get txnDeleted => Tone.current.txnDeleted;
  static String get txnFailed => Tone.current.txnFailed;
  static String get txnNotFound => Tone.current.txnNotFound;

  // ── Validation ──
  static String get enterAmount => Tone.current.enterAmount;
  static String get pickAccount => Tone.current.pickAccount;
  static String get pickCategory => Tone.current.pickCategory;
  static String get fillAllFields => Tone.current.fillAllFields;
  static String get invalidAmount => Tone.current.invalidAmount;
  static String get futureDate => Tone.current.futureDate;
  static String get selectAccountAndCategory =>
      Tone.current.selectAccountAndCategory;

  // ── Trip & Split ──
  static String tripCreated(bool isTrip) => Tone.current.tripCreated(isTrip);
  static String tripUpdated(bool isTrip) => Tone.current.tripUpdated(isTrip);
  static String tripDeleted(bool isTrip) => Tone.current.tripDeleted(isTrip);
  static String tripFinalized(bool isTrip) =>
      Tone.current.tripFinalized(isTrip);
  static String tripNameRequired(bool isTrip) =>
      Tone.current.tripNameRequired(isTrip);
  static String get addParticipant => Tone.current.addParticipant;
  static String tripLimitReached(bool isTrip) =>
      Tone.current.tripLimitReached(isTrip);
  static String expenseAddedToTrip(bool isTrip) =>
      Tone.current.expenseAddedToTrip(isTrip);

  // ── Budget ──
  static String get budgetCreated => Tone.current.budgetCreated;
  static String get budgetUpdated => Tone.current.budgetUpdated;
  static String get budgetDeleted => Tone.current.budgetDeleted;

  // ── Goal ──
  static String get goalCreated => Tone.current.goalCreated;
  static String get goalUpdated => Tone.current.goalUpdated;
  static String get goalDeleted => Tone.current.goalDeleted;

  // ── Account ──
  static String get accountCreated => Tone.current.accountCreated;
  static String get accountUpdated => Tone.current.accountUpdated;
  static String get accountDeleted => Tone.current.accountDeleted;
  static String get accountLocked => Tone.current.accountLocked;

  // ── Category ──
  static String get categoryCreated => Tone.current.categoryCreated;
  static String get categoryDeleted => Tone.current.categoryDeleted;
  static String get categoryNameRequired => Tone.current.categoryNameRequired;

  // ── Bill ──
  static String get billAdded => Tone.current.billAdded;
  static String get billPaid => Tone.current.billPaid;
  static String get billDeleted => Tone.current.billDeleted;

  // ── Backup ──
  static String get backupSuccess => Tone.current.backupSuccess;
  static String get backupFailed => Tone.current.backupFailed;
  static String get restoreSuccess => Tone.current.restoreSuccess;
  static String get restoreFailed => Tone.current.restoreFailed;
  static String get invalidBackupFile => Tone.current.invalidBackupFile;
  static String get corruptBackup => Tone.current.corruptBackup;

  // ── Settings ──
  static String get settingsSaved => Tone.current.settingsSaved;
  static String get reminderUpdated => Tone.current.reminderUpdated;
  static String toggledOn(String feature) => Tone.current.toggledOn(feature);
  static String toggledOff(String feature) => Tone.current.toggledOff(feature);

  // ── Auth ──
  static String get biometricFailed => Tone.current.biometricFailed;
  static String get incorrectPin => Tone.current.incorrectPin;

  // ── SMS / Auto Import ──
  static String get notificationAccessDenied =>
      Tone.current.notificationAccessDenied;
  static String get smsImportEnabled => Tone.current.smsImportEnabled;

  // ── Empty States ──
  static String get noTransactions => Tone.current.noTransactions;
  static String get noBudgets => Tone.current.noBudgets;
  static String get noGoals => Tone.current.noGoals;
  static String get noBills => Tone.current.noBills;
  static String get noAccounts => Tone.current.noAccounts;
  static String get noCategories => Tone.current.noCategories;
  static String get noNotifications => Tone.current.noNotifications;
  static String noFilterResults(String filter) =>
      Tone.current.noFilterResults(filter);
  static String get noData => Tone.current.noData;
  static String get noRecurring => Tone.current.noRecurring;

  // ── Export ──
  static String get exportSuccess => Tone.current.exportSuccess;
  static String exportFailed(String error) => Tone.current.exportFailed(error);

  // ── Pro / Upgrade ──
  static String get purchaseFailed => Tone.current.purchaseFailed;
  static String get playNotAvailable => Tone.current.playNotAvailable;

  // ── Generic ──
  static String errorWith(String detail) => Tone.current.errorWith(detail);
  static String get genericError => Tone.current.genericError;

  // ── Confirmations ──
  static String get deleteTitle => Tone.current.deleteTitle;
  static String deleteMessage(String? param) =>
      Tone.current.deleteMessage(param);
  static String get deleteConfirm => Tone.current.deleteConfirm;
  static String get deleteCancel => Tone.current.deleteCancel;
  static String get logoutTitle => Tone.current.logoutTitle;
  static String get logoutMessage => Tone.current.logoutMessage;
  static String get logoutConfirm => Tone.current.logoutConfirm;

  // ── AI Insights ──
  static String get insightBillsDueSoon => Tone.current.insightBillsDueSoon;
  static String insightBillsDueMessage(int count) =>
      Tone.current.insightBillsDueMessage(count);
  static String get insightOverBudget => Tone.current.insightOverBudget;
  static String insightOverBudgetMessage(int count) =>
      Tone.current.insightOverBudgetMessage(count);
  static String get insightNearBudget => Tone.current.insightNearBudget;
  static String insightNearBudgetMessage(int count) =>
      Tone.current.insightNearBudgetMessage(count);
  static String get insightOverspending => Tone.current.insightOverspending;
  static String insightOverspendingMessage(String amount) =>
      Tone.current.insightOverspendingMessage(amount);
  static String get insightSpendingSpike => Tone.current.insightSpendingSpike;
  static String insightSpendingSpikeMessage(String avg, String today) =>
      Tone.current.insightSpendingSpikeMessage(avg, today);
  static String get insightWeekendAlert => Tone.current.insightWeekendAlert;
  static String insightWeekendAlertMessage(String avg, String current) =>
      Tone.current.insightWeekendAlertMessage(avg, current);
  static String insightMoneyLeak(String category, int count, String total) =>
      Tone.current.insightMoneyLeak(category, count, total);
  static String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      Tone.current.insightBestDay(worst, wAvg, best, bAvg, saving);
  static String get insightGetStarted => Tone.current.insightGetStarted;
  static String get insightGetStartedMessage =>
      Tone.current.insightGetStartedMessage;

  // ── Dashboard Greetings ──
  static String greetingMorning(String name) =>
      Tone.current.greetingMorning(name);
  static String greetingAfternoon(String name) =>
      Tone.current.greetingAfternoon(name);
  static String greetingEvening(String name) =>
      Tone.current.greetingEvening(name);
  static String get dashboardWelcomeBack => Tone.current.dashboardWelcomeBack;
  static String get dashboardAllCaughtUp => Tone.current.dashboardAllCaughtUp;
  static String streakMessage(int days) => Tone.current.streakMessage(days);
}
