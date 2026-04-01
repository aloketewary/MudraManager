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

  // ── Goal ──
  String get goalCreated;
  String get goalUpdated;
  String get goalDeleted;

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

  // ── Export ──
  String get exportSuccess;
  String exportFailed(String error);

  // ── Pro / Upgrade ──
  String get purchaseFailed;
  String get playNotAvailable;

  // ── Generic ──
  String errorWith(String detail);
  String get genericError;

  // ── Smart Notifications (drain queue) ──
  String singleApproved(String amountStr);
  String allApproved(int count, String amountStr);
  String mixedResults(int approved, int reviewCount);
  String allNeedReview(int reviewCount);
}
