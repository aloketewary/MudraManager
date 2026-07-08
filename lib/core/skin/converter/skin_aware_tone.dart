import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/tone/tone_pack.dart';

/// Wraps a [TonePack] and overrides its styling values with [SkinStyle].
/// Messages/copy remain from the TonePack; only visual styling is overridden.
class SkinAwareTone extends TonePack {
  final TonePack _delegate;
  final SkinStyle _style;

  SkinAwareTone(this._delegate, this._style);

  // ── Styling overrides from skin ──
  @override
  double get borderOpacity => _style.borderOpacity;
  @override
  double get borderWidth => _style.borderWidth;
  @override
  bool get useTransparentCards => _style.dividerStyle == 'hairline';
  @override
  String get dividerStyle => _style.dividerStyle;
  @override
  String? get numberFont => _style.numberFont;
  @override
  String? get pdfFont => _style.pdfFont;

  // ── Everything else delegates to the tone pack ──
  @override
  String get id => _delegate.id;
  @override
  String get name => _delegate.name;
  @override
  String get description => _delegate.description;
  @override
  String get emoji => _delegate.emoji;
  @override
  String get txnAdded => _delegate.txnAdded;
  @override
  String get txnUpdated => _delegate.txnUpdated;
  @override
  String get txnDeleted => _delegate.txnDeleted;
  @override
  String get txnFailed => _delegate.txnFailed;
  @override
  String get txnNotFound => _delegate.txnNotFound;
  @override
  String get enterAmount => _delegate.enterAmount;
  @override
  String get pickAccount => _delegate.pickAccount;
  @override
  String get pickCategory => _delegate.pickCategory;
  @override
  String get fillAllFields => _delegate.fillAllFields;
  @override
  String get invalidAmount => _delegate.invalidAmount;
  @override
  String get futureDate => _delegate.futureDate;
  @override
  String get selectAccountAndCategory => _delegate.selectAccountAndCategory;
  @override
  String tripCreated(bool isTrip) => _delegate.tripCreated(isTrip);
  @override
  String tripUpdated(bool isTrip) => _delegate.tripUpdated(isTrip);
  @override
  String tripDeleted(bool isTrip) => _delegate.tripDeleted(isTrip);
  @override
  String tripFinalized(bool isTrip) => _delegate.tripFinalized(isTrip);
  @override
  String tripNameRequired(bool isTrip) => _delegate.tripNameRequired(isTrip);
  @override
  String get addParticipant => _delegate.addParticipant;
  @override
  String tripLimitReached(bool isTrip) => _delegate.tripLimitReached(isTrip);
  @override
  String expenseAddedToTrip(bool isTrip) =>
      _delegate.expenseAddedToTrip(isTrip);
  @override
  String get budgetCreated => _delegate.budgetCreated;
  @override
  String get budgetUpdated => _delegate.budgetUpdated;
  @override
  String get budgetDeleted => _delegate.budgetDeleted;
  @override
  String budgetExceededBy(String amount) => _delegate.budgetExceededBy(amount);
  @override
  String budgetSlowDown(String amount, int days) =>
      _delegate.budgetSlowDown(amount, days);
  @override
  String budgetSafePerDay(String amount) => _delegate.budgetSafePerDay(amount);
  @override
  String get budgetExceededAdjust => _delegate.budgetExceededAdjust;
  @override
  String budgetOnTrack(String amount) => _delegate.budgetOnTrack(amount);
  @override
  String get budgetGreatDiscipline => _delegate.budgetGreatDiscipline;
  @override
  String budgetAlreadySpent(String amount) =>
      _delegate.budgetAlreadySpent(amount);
  @override
  String budgetMayExceedIn(int days) => _delegate.budgetMayExceedIn(days);
  @override
  String budgetGettingTight(String amount, int days) =>
      _delegate.budgetGettingTight(amount, days);
  @override
  String budgetInControl(String amount) => _delegate.budgetInControl(amount);
  @override
  String comparisonSpentLess(String amount) =>
      _delegate.comparisonSpentLess(amount);
  @override
  String comparisonSpentMore(String amount) =>
      _delegate.comparisonSpentMore(amount);
  @override
  String get comparisonSpentSame => _delegate.comparisonSpentSame;
  @override
  String comparisonTopIncrease(String category, String amount) =>
      _delegate.comparisonTopIncrease(category, amount);
  @override
  String comparisonTopDecrease(String category, String amount) =>
      _delegate.comparisonTopDecrease(category, amount);
  @override
  String comparisonPrediction(String amount) =>
      _delegate.comparisonPrediction(amount);
  @override
  String comparisonTxnCount(int current, int last) =>
      _delegate.comparisonTxnCount(current, last);
  @override
  String comparisonDailyAvg(String current, String last) =>
      _delegate.comparisonDailyAvg(current, last);
  @override
  String comparisonByThisDay(String amount) =>
      _delegate.comparisonByThisDay(amount);
  @override
  String get goalCreated => _delegate.goalCreated;
  @override
  String get goalUpdated => _delegate.goalUpdated;
  @override
  String get goalDeleted => _delegate.goalDeleted;
  @override
  String goalMilestone25(String goalName) =>
      _delegate.goalMilestone25(goalName);
  @override
  String goalMilestone50(String goalName) =>
      _delegate.goalMilestone50(goalName);
  @override
  String goalMilestone75(String goalName) =>
      _delegate.goalMilestone75(goalName);
  @override
  String goalMilestone100(String goalName) =>
      _delegate.goalMilestone100(goalName);
  @override
  String goalOnTrack(String goalName) => _delegate.goalOnTrack(goalName);
  @override
  String goalBehind(String goalName) => _delegate.goalBehind(goalName);
  @override
  String goalAhead(String goalName, String days) =>
      _delegate.goalAhead(goalName, days);
  @override
  String goalDailyNeeded(String amount) => _delegate.goalDailyNeeded(amount);
  @override
  String goalPredictedDate(String date) => _delegate.goalPredictedDate(date);
  @override
  String goalContributionThisMonth(String amount) =>
      _delegate.goalContributionThisMonth(amount);
  @override
  String goalNoDeadline(String goalName) => _delegate.goalNoDeadline(goalName);
  @override
  String get accountCreated => _delegate.accountCreated;
  @override
  String get accountUpdated => _delegate.accountUpdated;
  @override
  String get accountDeleted => _delegate.accountDeleted;
  @override
  String get accountLocked => _delegate.accountLocked;
  @override
  String get categoryCreated => _delegate.categoryCreated;
  @override
  String get categoryDeleted => _delegate.categoryDeleted;
  @override
  String get categoryNameRequired => _delegate.categoryNameRequired;
  @override
  String get billAdded => _delegate.billAdded;
  @override
  String get billPaid => _delegate.billPaid;
  @override
  String get billDeleted => _delegate.billDeleted;
  @override
  String get backupSuccess => _delegate.backupSuccess;
  @override
  String get backupFailed => _delegate.backupFailed;
  @override
  String get restoreSuccess => _delegate.restoreSuccess;
  @override
  String get restoreFailed => _delegate.restoreFailed;
  @override
  String get invalidBackupFile => _delegate.invalidBackupFile;
  @override
  String get corruptBackup => _delegate.corruptBackup;
  @override
  String get settingsSaved => _delegate.settingsSaved;
  @override
  String get reminderUpdated => _delegate.reminderUpdated;
  @override
  String toggledOn(String feature) => _delegate.toggledOn(feature);
  @override
  String toggledOff(String feature) => _delegate.toggledOff(feature);
  @override
  String get biometricFailed => _delegate.biometricFailed;
  @override
  String get incorrectPin => _delegate.incorrectPin;
  @override
  String get notificationAccessDenied => _delegate.notificationAccessDenied;
  @override
  String get smsImportEnabled => _delegate.smsImportEnabled;
  @override
  String get noTransactions => _delegate.noTransactions;
  @override
  String get noBudgets => _delegate.noBudgets;
  @override
  String get noGoals => _delegate.noGoals;
  @override
  String get noBills => _delegate.noBills;
  @override
  String get noAccounts => _delegate.noAccounts;
  @override
  String get noCategories => _delegate.noCategories;
  @override
  String get noNotifications => _delegate.noNotifications;
  @override
  String noFilterResults(String filter) => _delegate.noFilterResults(filter);
  @override
  String get noData => _delegate.noData;
  @override
  String get noRecurring => _delegate.noRecurring;
  @override
  String get exportSuccess => _delegate.exportSuccess;
  @override
  String exportFailed(String error) => _delegate.exportFailed(error);
  @override
  String get purchaseFailed => _delegate.purchaseFailed;
  @override
  String get playNotAvailable => _delegate.playNotAvailable;
  @override
  String errorWith(String detail) => _delegate.errorWith(detail);
  @override
  String get genericError => _delegate.genericError;
  @override
  String get deleteTitle => _delegate.deleteTitle;
  @override
  String deleteMessage(String? param) => _delegate.deleteMessage(param);
  @override
  String get deleteConfirm => _delegate.deleteConfirm;
  @override
  String get deleteCancel => _delegate.deleteCancel;
  @override
  String get logoutTitle => _delegate.logoutTitle;
  @override
  String get logoutMessage => _delegate.logoutMessage;
  @override
  String get logoutConfirm => _delegate.logoutConfirm;
  @override
  String get currencyChanged => _delegate.currencyChanged;
  @override
  String currencyArchivedCount(int count, String newCurrency) =>
      _delegate.currencyArchivedCount(count, newCurrency);
  @override
  String get currencyChangeTitle => _delegate.currencyChangeTitle;
  @override
  String get currencyChangeWarning => _delegate.currencyChangeWarning;
  @override
  String get currencyChangeConfirm => _delegate.currencyChangeConfirm;
  @override
  String get currencyChangeCancel => _delegate.currencyChangeCancel;
  @override
  String get currencyPickerTitle => _delegate.currencyPickerTitle;
  @override
  String get currencyPickerSubtitle => _delegate.currencyPickerSubtitle;
  @override
  String get currencyChangeIrreversible => _delegate.currencyChangeIrreversible;
  @override
  String get archivedTransactionsTitle => _delegate.archivedTransactionsTitle;
  @override
  String get noArchivedTransactions => _delegate.noArchivedTransactions;
  @override
  String noTripExpenses(bool isTrip) => _delegate.noTripExpenses(isTrip);
  @override
  String get insightBillsDueSoon => _delegate.insightBillsDueSoon;
  @override
  String insightBillsDueMessage(int count) =>
      _delegate.insightBillsDueMessage(count);
  @override
  String get insightOverBudget => _delegate.insightOverBudget;
  @override
  String insightOverBudgetMessage(int count) =>
      _delegate.insightOverBudgetMessage(count);
  @override
  String get insightNearBudget => _delegate.insightNearBudget;
  @override
  String insightNearBudgetMessage(int count) =>
      _delegate.insightNearBudgetMessage(count);
  @override
  String get insightOverspending => _delegate.insightOverspending;
  @override
  String insightOverspendingMessage(String amount) =>
      _delegate.insightOverspendingMessage(amount);
  @override
  String get insightSpendingSpike => _delegate.insightSpendingSpike;
  @override
  String insightSpendingSpikeMessage(String avg, String today) =>
      _delegate.insightSpendingSpikeMessage(avg, today);
  @override
  String get insightWeekendAlert => _delegate.insightWeekendAlert;
  @override
  String insightWeekendAlertMessage(String avg, String current) =>
      _delegate.insightWeekendAlertMessage(avg, current);
  @override
  String insightMoneyLeak(String category, int count, String total) =>
      _delegate.insightMoneyLeak(category, count, total);
  @override
  String insightBestDay(
          String worst, String wAvg, String best, String bAvg, String saving,) =>
      _delegate.insightBestDay(worst, wAvg, best, bAvg, saving);
  @override
  String get insightGetStarted => _delegate.insightGetStarted;
  @override
  String get insightGetStartedMessage => _delegate.insightGetStartedMessage;
  @override
  String singleApproved(String amountStr) =>
      _delegate.singleApproved(amountStr);
  @override
  String allApproved(int count, String amountStr) =>
      _delegate.allApproved(count, amountStr);
  @override
  String mixedResults(int approved, int reviewCount) =>
      _delegate.mixedResults(approved, reviewCount);
  @override
  String allNeedReview(int reviewCount) =>
      _delegate.allNeedReview(reviewCount);
  @override
  String greetingMorning(String name) => _delegate.greetingMorning(name);
  @override
  String greetingAfternoon(String name) => _delegate.greetingAfternoon(name);
  @override
  String greetingEvening(String name) => _delegate.greetingEvening(name);
  @override
  String get dashboardWelcomeBack => _delegate.dashboardWelcomeBack;
  @override
  String get dashboardAllCaughtUp => _delegate.dashboardAllCaughtUp;
  @override
  String streakMessage(int days) => _delegate.streakMessage(days);
  @override
  String budgetExceededNotif(String name, String spent, String limit) =>
      _delegate.budgetExceededNotif(name, spent, limit);
  @override
  String budgetWarningNotif(String name, String remaining, String pct) =>
      _delegate.budgetWarningNotif(name, remaining, pct);
  @override
  String billDueNotif(String name, String amount, String when) =>
      _delegate.billDueNotif(name, amount, when);
  @override
  String billPaidNotif(String name, String amount) =>
      _delegate.billPaidNotif(name, amount);
  @override
  String balanceDropNotif(String days) => _delegate.balanceDropNotif(days);
  @override
  String savingsOpportunityNotif(String category, String amount) =>
      _delegate.savingsOpportunityNotif(category, amount);
  @override
  String unusualSpendingNotif(String today, String multiplier) =>
      _delegate.unusualSpendingNotif(today, multiplier);
  @override
  String pendingSmsNotif(int count) => _delegate.pendingSmsNotif(count);
  @override
  String moneyLeakNotif(String category, int count, String total) =>
      _delegate.moneyLeakNotif(category, count, total);
  @override
  String reEngageMissYou(int lostStreak) =>
      _delegate.reEngageMissYou(lostStreak);
  @override
  String reEngageUntracked(int days, String estimatedSpend) =>
      _delegate.reEngageUntracked(days, estimatedSpend);
  @override
  String get reEngageQuickNudge => _delegate.reEngageQuickNudge;
  @override
  String dailySummaryNotif(String spent, String earned, String topCategory) =>
      _delegate.dailySummaryNotif(spent, earned, topCategory);
  @override
  String get dailySummaryEmpty => _delegate.dailySummaryEmpty;
  @override
  String weeklySummaryNotif(String total, String topCategory, String trend) =>
      _delegate.weeklySummaryNotif(total, topCategory, trend);
  @override
  String streakAtRisk(int streak) => _delegate.streakAtRisk(streak);
  @override
  String streakLost(int streak) => _delegate.streakLost(streak);
  @override
  String morningInsightSpent(String amount, String avg) =>
      _delegate.morningInsightSpent(amount, avg);
  @override
  String morningInsightUnderAvg(String amount, String saved) =>
      _delegate.morningInsightUnderAvg(amount, saved);
  @override
  String get morningInsightZeroSpend => _delegate.morningInsightZeroSpend;
  @override
  String morningInsightTopCategory(String category, String amount) =>
      _delegate.morningInsightTopCategory(category, amount);
  @override
  String underBudgetStreakNotif(int days) =>
      _delegate.underBudgetStreakNotif(days);
  @override
  String underBudgetStreakBroken(String budget) =>
      _delegate.underBudgetStreakBroken(budget);
  @override
  String weeklyRecapNudge(String hookStat) =>
      _delegate.weeklyRecapNudge(hookStat);
  @override
  String reEngageDay2Sms(int count) => _delegate.reEngageDay2Sms(count);
  @override
  String reEngageDay3Budgets(int count) =>
      _delegate.reEngageDay3Budgets(count);
  @override
  String reEngageDay7Spend(String amount) =>
      _delegate.reEngageDay7Spend(amount);
  @override
  String weeklyRecapHookStat(String pct, String category) =>
      _delegate.weeklyRecapHookStat(pct, category);
}
