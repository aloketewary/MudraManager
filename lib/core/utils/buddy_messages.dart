import 'package:mudra_manager/core/tone/tone_provider.dart';

/// Backward-compatible accessor for tone messages.
/// Delegates to the currently active [TonePack] via [Tone.current].
///
/// Usage: `BuddyMessages.txnAdded` — works everywhere, no ref needed.
/// The active tone is set by [Tone.sync] from the top-level widget.
class BuddyMessages {
  BuddyMessages._();

  // ── Transaction ──
  static String get txnAdded => Tone.l10n?.get('txnAdded') ?? Tone.current.txnAdded;
  static String get txnUpdated => Tone.l10n?.get('txnUpdated') ?? Tone.current.txnUpdated;
  static String get txnDeleted => Tone.l10n?.get('txnDeleted') ?? Tone.current.txnDeleted;
  static String get txnFailed => Tone.l10n?.get('txnFailed') ?? Tone.current.txnFailed;
  static String get txnNotFound => Tone.l10n?.get('txnNotFound') ?? Tone.current.txnNotFound;

  // ── Validation ──
  static String get enterAmount => Tone.l10n?.get('enterAmount') ?? Tone.current.enterAmount;
  static String get pickAccount => Tone.l10n?.get('pickAccount') ?? Tone.current.pickAccount;
  static String get pickCategory => Tone.l10n?.get('pickCategory') ?? Tone.current.pickCategory;
  static String get fillAllFields => Tone.l10n?.get('fillAllFields') ?? Tone.current.fillAllFields;
  static String get invalidAmount => Tone.l10n?.get('invalidAmount') ?? Tone.current.invalidAmount;
  static String get futureDate => Tone.l10n?.get('futureDate') ?? Tone.current.futureDate;
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
  static String get addParticipant => Tone.l10n?.get('addParticipant') ?? Tone.current.addParticipant;
  static String tripLimitReached(bool isTrip) =>
      Tone.current.tripLimitReached(isTrip);
  static String expenseAddedToTrip(bool isTrip) =>
      Tone.current.expenseAddedToTrip(isTrip);

  // ── Budget ──
  static String get budgetCreated => Tone.l10n?.get('budgetCreated') ?? Tone.current.budgetCreated;
  static String get budgetUpdated => Tone.l10n?.get('budgetUpdated') ?? Tone.current.budgetUpdated;
  static String get budgetDeleted => Tone.l10n?.get('budgetDeleted') ?? Tone.current.budgetDeleted;

  // ── Budget Insights ──
  static String budgetExceededBy(String amount) =>
      Tone.l10n?.getStr('budgetExceededBy', amount) ?? Tone.current.budgetExceededBy(amount);
  static String budgetSlowDown(String amount, int days) =>
      Tone.current.budgetSlowDown(amount, days);
  static String budgetSafePerDay(String amount) =>
      Tone.current.budgetSafePerDay(amount);
  static String get budgetExceededAdjust => Tone.l10n?.get('budgetExceededAdjust') ?? Tone.current.budgetExceededAdjust;
  static String budgetOnTrack(String amount) =>
      Tone.current.budgetOnTrack(amount);
  static String get budgetGreatDiscipline => Tone.l10n?.get('budgetGreatDiscipline') ?? Tone.current.budgetGreatDiscipline;
  static String budgetAlreadySpent(String amount) =>
      Tone.current.budgetAlreadySpent(amount);
  static String budgetMayExceedIn(int days) =>
      Tone.current.budgetMayExceedIn(days);
  static String budgetGettingTight(String amount, int days) =>
      Tone.current.budgetGettingTight(amount, days);
  static String budgetInControl(String amount) =>
      Tone.current.budgetInControl(amount);

  // ── Monthly Comparison ──
  static String comparisonSpentLess(String amount) =>
      Tone.current.comparisonSpentLess(amount);
  static String comparisonSpentMore(String amount) =>
      Tone.current.comparisonSpentMore(amount);
  static String get comparisonSpentSame => Tone.l10n?.get('comparisonSpentSame') ?? Tone.current.comparisonSpentSame;
  static String comparisonTopIncrease(String category, String amount) =>
      Tone.current.comparisonTopIncrease(category, amount);
  static String comparisonTopDecrease(String category, String amount) =>
      Tone.current.comparisonTopDecrease(category, amount);
  static String comparisonPrediction(String amount) =>
      Tone.current.comparisonPrediction(amount);
  static String comparisonTxnCount(int current, int last) =>
      Tone.current.comparisonTxnCount(current, last);
  static String comparisonDailyAvg(String current, String last) =>
      Tone.current.comparisonDailyAvg(current, last);
  static String comparisonByThisDay(String amount) =>
      Tone.current.comparisonByThisDay(amount);

  // ── Goal ──
  static String get goalCreated => Tone.l10n?.get('goalCreated') ?? Tone.current.goalCreated;
  static String get goalUpdated => Tone.l10n?.get('goalUpdated') ?? Tone.current.goalUpdated;
  static String get goalDeleted => Tone.l10n?.get('goalDeleted') ?? Tone.current.goalDeleted;

  // ── Goal Insights ──
  static String goalMilestone25(String goalName) =>
      Tone.current.goalMilestone25(goalName);
  static String goalMilestone50(String goalName) =>
      Tone.current.goalMilestone50(goalName);
  static String goalMilestone75(String goalName) =>
      Tone.current.goalMilestone75(goalName);
  static String goalMilestone100(String goalName) =>
      Tone.current.goalMilestone100(goalName);
  static String goalOnTrack(String goalName) =>
      Tone.current.goalOnTrack(goalName);
  static String goalBehind(String goalName) =>
      Tone.current.goalBehind(goalName);
  static String goalAhead(String goalName, String days) =>
      Tone.current.goalAhead(goalName, days);
  static String goalDailyNeeded(String amount) =>
      Tone.current.goalDailyNeeded(amount);
  static String goalPredictedDate(String date) =>
      Tone.current.goalPredictedDate(date);
  static String goalContributionThisMonth(String amount) =>
      Tone.current.goalContributionThisMonth(amount);
  static String goalNoDeadline(String goalName) =>
      Tone.current.goalNoDeadline(goalName);

  // ── Account ──
  static String get accountCreated => Tone.l10n?.get('accountCreated') ?? Tone.current.accountCreated;
  static String get accountUpdated => Tone.l10n?.get('accountUpdated') ?? Tone.current.accountUpdated;
  static String get accountDeleted => Tone.l10n?.get('accountDeleted') ?? Tone.current.accountDeleted;
  static String get accountLocked => Tone.l10n?.get('accountLocked') ?? Tone.current.accountLocked;

  // ── Category ──
  static String get categoryCreated => Tone.l10n?.get('categoryCreated') ?? Tone.current.categoryCreated;
  static String get categoryDeleted => Tone.l10n?.get('categoryDeleted') ?? Tone.current.categoryDeleted;
  static String get categoryNameRequired => Tone.l10n?.get('categoryNameRequired') ?? Tone.current.categoryNameRequired;

  // ── Bill ──
  static String get billAdded => Tone.l10n?.get('billAdded') ?? Tone.current.billAdded;
  static String get billPaid => Tone.l10n?.get('billPaid') ?? Tone.current.billPaid;
  static String get billDeleted => Tone.l10n?.get('billDeleted') ?? Tone.current.billDeleted;

  // ── Backup ──
  static String get backupSuccess => Tone.l10n?.get('backupSuccess') ?? Tone.current.backupSuccess;
  static String get backupFailed => Tone.l10n?.get('backupFailed') ?? Tone.current.backupFailed;
  static String get restoreSuccess => Tone.l10n?.get('restoreSuccess') ?? Tone.current.restoreSuccess;
  static String get restoreFailed => Tone.l10n?.get('restoreFailed') ?? Tone.current.restoreFailed;
  static String get invalidBackupFile => Tone.l10n?.get('invalidBackupFile') ?? Tone.current.invalidBackupFile;
  static String get corruptBackup => Tone.l10n?.get('corruptBackup') ?? Tone.current.corruptBackup;

  // ── Settings ──
  static String get settingsSaved => Tone.l10n?.get('settingsSaved') ?? Tone.current.settingsSaved;
  static String get reminderUpdated => Tone.l10n?.get('reminderUpdated') ?? Tone.current.reminderUpdated;
  static String toggledOn(String feature) => Tone.current.toggledOn(feature);
  static String toggledOff(String feature) => Tone.current.toggledOff(feature);

  // ── Auth ──
  static String get biometricFailed => Tone.l10n?.get('biometricFailed') ?? Tone.current.biometricFailed;
  static String get incorrectPin => Tone.l10n?.get('incorrectPin') ?? Tone.current.incorrectPin;

  // ── SMS / Auto Import ──
  static String get notificationAccessDenied =>
      Tone.current.notificationAccessDenied;
  static String get smsImportEnabled => Tone.l10n?.get('smsImportEnabled') ?? Tone.current.smsImportEnabled;

  // ── Empty States ──
  static String get noTransactions => Tone.l10n?.get('noTransactions') ?? Tone.current.noTransactions;
  static String get noBudgets => Tone.l10n?.get('noBudgets') ?? Tone.current.noBudgets;
  static String get noGoals => Tone.l10n?.get('noGoals') ?? Tone.current.noGoals;
  static String get noBills => Tone.l10n?.get('noBills') ?? Tone.current.noBills;
  static String get noAccounts => Tone.l10n?.get('noAccounts') ?? Tone.current.noAccounts;
  static String get noCategories => Tone.l10n?.get('noCategories') ?? Tone.current.noCategories;
  static String get noNotifications => Tone.l10n?.get('noNotifications') ?? Tone.current.noNotifications;
  static String noFilterResults(String filter) =>
      Tone.current.noFilterResults(filter);
  static String get noData => Tone.l10n?.get('noData') ?? Tone.current.noData;
  static String get noRecurring => Tone.l10n?.get('noRecurring') ?? Tone.current.noRecurring;

  // ── Export ──
  static String get exportSuccess => Tone.l10n?.get('exportSuccess') ?? Tone.current.exportSuccess;
  static String exportFailed(String error) => Tone.current.exportFailed(error);

  // ── Pro / Upgrade ──
  static String get purchaseFailed => Tone.l10n?.get('purchaseFailed') ?? Tone.current.purchaseFailed;
  static String get playNotAvailable => Tone.l10n?.get('playNotAvailable') ?? Tone.current.playNotAvailable;

  // ── Generic ──
  static String errorWith(String detail) => Tone.current.errorWith(detail);
  static String get genericError => Tone.l10n?.get('genericError') ?? Tone.current.genericError;

  // ── Confirmations ──
  static String get deleteTitle => Tone.l10n?.get('deleteTitle') ?? Tone.current.deleteTitle;
  static String deleteMessage(String? param) =>
      Tone.current.deleteMessage(param);
  static String get deleteConfirm => Tone.l10n?.get('deleteConfirm') ?? Tone.current.deleteConfirm;
  static String get deleteCancel => Tone.l10n?.get('deleteCancel') ?? Tone.current.deleteCancel;
  static String get logoutTitle => Tone.l10n?.get('logoutTitle') ?? Tone.current.logoutTitle;
  static String get logoutMessage => Tone.l10n?.get('logoutMessage') ?? Tone.current.logoutMessage;
  static String get logoutConfirm => Tone.l10n?.get('logoutConfirm') ?? Tone.current.logoutConfirm;

  // ── Currency ──
  static String get currencyChanged => Tone.l10n?.get('currencyChanged') ?? Tone.current.currencyChanged;
  static String currencyArchivedCount(int count, String newCurrency) =>
      Tone.current.currencyArchivedCount(count, newCurrency);
  static String get currencyChangeTitle => Tone.l10n?.get('currencyChangeTitle') ?? Tone.current.currencyChangeTitle;
  static String get currencyChangeWarning =>
      Tone.current.currencyChangeWarning;
  static String get currencyChangeConfirm =>
      Tone.current.currencyChangeConfirm;
  static String get currencyChangeCancel => Tone.l10n?.get('currencyChangeCancel') ?? Tone.current.currencyChangeCancel;
  static String get currencyPickerTitle => Tone.l10n?.get('currencyPickerTitle') ?? Tone.current.currencyPickerTitle;
  static String get currencyPickerSubtitle =>
      Tone.current.currencyPickerSubtitle;
  static String get currencyChangeIrreversible =>
      Tone.current.currencyChangeIrreversible;
  static String get archivedTransactionsTitle =>
      Tone.current.archivedTransactionsTitle;
  static String get noArchivedTransactions =>
      Tone.current.noArchivedTransactions;
  static String noTripExpenses(bool isTrip) =>
      Tone.current.noTripExpenses(isTrip);

  // ── AI Insights ──
  static String get insightBillsDueSoon => Tone.l10n?.get('insightBillsDueSoon') ?? Tone.current.insightBillsDueSoon;
  static String insightBillsDueMessage(int count) =>
      Tone.l10n?.getInt('insightBillsDueMessage', count) ?? Tone.current.insightBillsDueMessage(count);
  static String get insightOverBudget => Tone.l10n?.get('insightOverBudget') ?? Tone.current.insightOverBudget;
  static String insightOverBudgetMessage(int count) =>
      Tone.l10n?.getInt('insightOverBudgetMessage', count) ?? Tone.current.insightOverBudgetMessage(count);
  static String get insightNearBudget => Tone.l10n?.get('insightNearBudget') ?? Tone.current.insightNearBudget;
  static String insightNearBudgetMessage(int count) =>
      Tone.l10n?.getInt('insightNearBudgetMessage', count) ?? Tone.current.insightNearBudgetMessage(count);
  static String get insightOverspending => Tone.l10n?.get('insightOverspending') ?? Tone.current.insightOverspending;
  static String insightOverspendingMessage(String amount) =>
      Tone.l10n?.getStr('insightOverspendingMessage', amount) ?? Tone.current.insightOverspendingMessage(amount);
  static String get insightSpendingSpike => Tone.l10n?.get('insightSpendingSpike') ?? Tone.current.insightSpendingSpike;
  static String insightSpendingSpikeMessage(String avg, String today) =>
      Tone.l10n?.getStr2('insightSpendingSpikeMessage', avg, today) ?? Tone.current.insightSpendingSpikeMessage(avg, today);
  static String get insightWeekendAlert => Tone.l10n?.get('insightWeekendAlert') ?? Tone.current.insightWeekendAlert;
  static String insightWeekendAlertMessage(String avg, String current) =>
      Tone.l10n?.getStr2('insightWeekendAlertMessage', avg, current) ?? Tone.current.insightWeekendAlertMessage(avg, current);
  static String insightMoneyLeak(String category, int count, String total) =>
      Tone.l10n?.getSIS('insightMoneyLeak', category, count, total) ?? Tone.current.insightMoneyLeak(category, count, total);
  static String insightBestDay(
    String worst,
    String wAvg,
    String best,
    String bAvg,
    String saving,
  ) =>
      Tone.l10n?.getS5('insightBestDay', worst, wAvg, best, bAvg, saving) ??
      Tone.current.insightBestDay(worst, wAvg, best, bAvg, saving);
  static String get insightGetStarted => Tone.l10n?.get('insightGetStarted') ?? Tone.current.insightGetStarted;
  static String get insightGetStartedMessage =>
      Tone.l10n?.get('insightGetStartedMessage') ?? Tone.current.insightGetStartedMessage;

  // ── Dashboard Greetings ──
  static String greetingMorning(String name) =>
      Tone.current.greetingMorning(name);
  static String greetingAfternoon(String name) =>
      Tone.current.greetingAfternoon(name);
  static String greetingEvening(String name) =>
      Tone.current.greetingEvening(name);
  static String get dashboardWelcomeBack => Tone.l10n?.get('dashboardWelcomeBack') ?? Tone.current.dashboardWelcomeBack;
  static String get dashboardAllCaughtUp => Tone.l10n?.get('dashboardAllCaughtUp') ?? Tone.current.dashboardAllCaughtUp;
  static String streakMessage(int days) => Tone.l10n?.getInt('streakMessage', days) ?? Tone.current.streakMessage(days);
  static String get dailySummaryEmpty => Tone.l10n?.get('dailySummaryEmpty') ?? Tone.current.dailySummaryEmpty;
}
