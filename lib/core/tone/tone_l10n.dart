import 'dart:math';

import 'package:mudra_manager/core/l10n/app_localizations.dart';

final _rng = Random();

String _pick(String piped) {
  final parts = piped.split('|');
  return parts[_rng.nextInt(parts.length)];
}

/// Resolves localized tone messages from ARB keys via a dictionary.
///
/// At construction, builds a `Map<String, String>` from all simple tone
/// getters for the active tone. Parameterized messages use small dedicated maps.
/// To add a new key: just add it to the ARB + the `_buildDict` method.
class ToneL10n {
  final Map<String, String> _dict;
  final Map<String, String Function(int)> _intDict;
  final Map<String, String Function(String)> _strDict;
  final Map<String, String Function(String, String)> _str2Dict;
  final Map<String, String Function(String, int, String)> _sisDict;
  final Map<String, String Function(String, String, String, String, String)> _s5Dict;

  ToneL10n._(this._dict, this._intDict, this._strDict, this._str2Dict, this._sisDict, this._s5Dict);

  factory ToneL10n(AppLocalizations l, String tone) {
    final dict = <String, String>{};
    final intDict = <String, String Function(int)>{};
    final strDict = <String, String Function(String)>{};
    final str2Dict = <String, String Function(String, String)>{};
    final sisDict = <String, String Function(String, int, String)>{};
    final s5Dict = <String, String Function(String, String, String, String, String)>{};

    // Pick the right getter set based on tone
    switch (tone) {
      case 'professional':
        _fillProfessional(l, dict, intDict, strDict, str2Dict, sisDict, s5Dict);
      case 'motivational':
        _fillMotivational(l, dict, intDict, strDict, str2Dict, sisDict, s5Dict);
      case 'calm':
        _fillCalm(l, dict, intDict, strDict, str2Dict, sisDict, s5Dict);
      default:
        _fillFriendly(l, dict, intDict, strDict, str2Dict, sisDict, s5Dict);
    }

    return ToneL10n._(dict, intDict, strDict, str2Dict, sisDict, s5Dict);
  }

  // ── Public API ──

  String? get(String key) {
    final v = _dict[key];
    return v != null ? _pick(v) : null;
  }

  String? getInt(String key, int val) {
    final fn = _intDict[key];
    return fn != null ? _pick(fn(val)) : null;
  }

  String? getStr(String key, String val) {
    final fn = _strDict[key];
    return fn != null ? _pick(fn(val)) : null;
  }

  String? getStr2(String key, String a, String b) {
    final fn = _str2Dict[key];
    return fn != null ? _pick(fn(a, b)) : null;
  }

  String? getSIS(String key, String a, int b, String c) {
    final fn = _sisDict[key];
    return fn != null ? _pick(fn(a, b, c)) : null;
  }

  String? getS5(String key, String a, String b, String c, String d, String e) {
    final fn = _s5Dict[key];
    return fn != null ? _pick(fn(a, b, c, d, e)) : null;
  }

  // ── Fill methods per tone ──
  // Each method populates all dictionaries from AppLocalizations getters.
  // Adding a new ARB key = add one line here per tone.

  static void _fillFriendly(
    AppLocalizations l,
    Map<String, String> d,
    Map<String, String Function(int)> di,
    Map<String, String Function(String)> ds,
    Map<String, String Function(String, String)> ds2,
    Map<String, String Function(String, int, String)> dsis,
    Map<String, String Function(String, String, String, String, String)> ds5,
  ) {
    d['txnAdded'] = l.tone_friendly_txnAdded;
    d['txnUpdated'] = l.tone_friendly_txnUpdated;
    d['txnDeleted'] = l.tone_friendly_txnDeleted;
    d['txnFailed'] = l.tone_friendly_txnFailed;
    d['enterAmount'] = l.tone_friendly_enterAmount;
    d['pickAccount'] = l.tone_friendly_pickAccount;
    d['pickCategory'] = l.tone_friendly_pickCategory;
    d['fillAllFields'] = l.tone_friendly_fillAllFields;
    d['invalidAmount'] = l.tone_friendly_invalidAmount;
    d['budgetCreated'] = l.tone_friendly_budgetCreated;
    d['budgetUpdated'] = l.tone_friendly_budgetUpdated;
    d['budgetDeleted'] = l.tone_friendly_budgetDeleted;
    d['goalCreated'] = l.tone_friendly_goalCreated;
    d['goalUpdated'] = l.tone_friendly_goalUpdated;
    d['goalDeleted'] = l.tone_friendly_goalDeleted;
    d['accountCreated'] = l.tone_friendly_accountCreated;
    d['billAdded'] = l.tone_friendly_billAdded;
    d['billPaid'] = l.tone_friendly_billPaid;
    d['backupSuccess'] = l.tone_friendly_backupSuccess;
    d['restoreSuccess'] = l.tone_friendly_restoreSuccess;
    d['noTransactions'] = l.tone_friendly_noTransactions;
    d['noBudgets'] = l.tone_friendly_noBudgets;
    d['noGoals'] = l.tone_friendly_noGoals;
    d['genericError'] = l.tone_friendly_genericError;
    d['smsImportEnabled'] = l.tone_friendly_smsImportEnabled;
    d['dashboardAllCaughtUp'] = l.tone_friendly_dashboardAllCaughtUp;
    d['dailySummaryEmpty'] = l.tone_friendly_dailySummaryEmpty;
    d['insightBillsDueSoon'] = l.tone_friendly_insightBillsDueSoon;
    d['insightOverBudget'] = l.tone_friendly_insightOverBudget;
    d['insightNearBudget'] = l.tone_friendly_insightNearBudget;
    d['insightOverspending'] = l.tone_friendly_insightOverspending;
    d['insightSpendingSpike'] = l.tone_friendly_insightSpendingSpike;
    d['insightWeekendAlert'] = l.tone_friendly_insightWeekendAlert;
    d['insightGetStarted'] = l.tone_friendly_insightGetStarted;
    d['insightGetStartedMessage'] = l.tone_friendly_insightGetStartedMessage;
    d['txnNotFound'] = l.tone_friendly_txnNotFound;
    d['futureDate'] = l.tone_friendly_futureDate;
    d['selectAccountAndCategory'] = l.tone_friendly_selectAccountAndCategory;
    d['addParticipant'] = l.tone_friendly_addParticipant;
    d['budgetExceededAdjust'] = l.tone_friendly_budgetExceededAdjust;
    d['budgetGreatDiscipline'] = l.tone_friendly_budgetGreatDiscipline;
    d['comparisonSpentSame'] = l.tone_friendly_comparisonSpentSame;
    d['accountUpdated'] = l.tone_friendly_accountUpdated;
    d['accountDeleted'] = l.tone_friendly_accountDeleted;
    d['accountLocked'] = l.tone_friendly_accountLocked;
    d['categoryCreated'] = l.tone_friendly_categoryCreated;
    d['categoryDeleted'] = l.tone_friendly_categoryDeleted;
    d['categoryNameRequired'] = l.tone_friendly_categoryNameRequired;
    d['billDeleted'] = l.tone_friendly_billDeleted;
    d['backupFailed'] = l.tone_friendly_backupFailed;
    d['restoreFailed'] = l.tone_friendly_restoreFailed;
    d['invalidBackupFile'] = l.tone_friendly_invalidBackupFile;
    d['corruptBackup'] = l.tone_friendly_corruptBackup;
    d['settingsSaved'] = l.tone_friendly_settingsSaved;
    d['reminderUpdated'] = l.tone_friendly_reminderUpdated;
    d['biometricFailed'] = l.tone_friendly_biometricFailed;
    d['incorrectPin'] = l.tone_friendly_incorrectPin;
    d['notificationAccessDenied'] = l.tone_friendly_notificationAccessDenied;
    d['noBills'] = l.tone_friendly_noBills;
    d['noAccounts'] = l.tone_friendly_noAccounts;
    d['noCategories'] = l.tone_friendly_noCategories;
    d['noNotifications'] = l.tone_friendly_noNotifications;
    d['noData'] = l.tone_friendly_noData;
    d['noRecurring'] = l.tone_friendly_noRecurring;
    d['exportSuccess'] = l.tone_friendly_exportSuccess;
    d['purchaseFailed'] = l.tone_friendly_purchaseFailed;
    d['playNotAvailable'] = l.tone_friendly_playNotAvailable;
    d['deleteTitle'] = l.tone_friendly_deleteTitle;
    d['deleteCancel'] = l.tone_friendly_deleteCancel;
    d['deleteConfirm'] = l.tone_friendly_deleteConfirm;
    d['logoutTitle'] = l.tone_friendly_logoutTitle;
    d['logoutMessage'] = l.tone_friendly_logoutMessage;
    d['logoutConfirm'] = l.tone_friendly_logoutConfirm;
    d['currencyChanged'] = l.tone_friendly_currencyChanged;
    d['currencyChangeTitle'] = l.tone_friendly_currencyChangeTitle;
    d['currencyChangeCancel'] = l.tone_friendly_currencyChangeCancel;
    d['currencyPickerTitle'] = l.tone_friendly_currencyPickerTitle;
    d['dashboardWelcomeBack'] = l.tone_friendly_dashboardWelcomeBack;
    di['streakMessage'] = (days) => l.tone_friendly_streakMessage(days);
    di['insightBillsDueMessage'] = (c) => l.tone_friendly_insightBillsDueMessage(c);
    di['insightOverBudgetMessage'] = (c) => l.tone_friendly_insightOverBudgetMessage(c);
    di['insightNearBudgetMessage'] = (c) => l.tone_friendly_insightNearBudgetMessage(c);
    ds['budgetExceededBy'] = (a) => l.tone_friendly_budgetExceededBy(a);
    ds['insightOverspendingMessage'] = (a) => l.tone_friendly_insightOverspendingMessage(a);
    ds2['insightSpendingSpikeMessage'] = (a, b) => l.tone_friendly_insightSpendingSpikeMessage(a, b);
    ds2['insightWeekendAlertMessage'] = (a, b) => l.tone_friendly_insightWeekendAlertMessage(a, b);
    dsis['insightMoneyLeak'] = (a, b, c) => l.tone_friendly_insightMoneyLeak(a, b, c);
    ds5['insightBestDay'] = (a, b, c, d, e) => l.tone_friendly_insightBestDay(a, b, c, d, e);
  }

  static void _fillProfessional(
    AppLocalizations l,
    Map<String, String> d,
    Map<String, String Function(int)> di,
    Map<String, String Function(String)> ds,
    Map<String, String Function(String, String)> ds2,
    Map<String, String Function(String, int, String)> dsis,
    Map<String, String Function(String, String, String, String, String)> ds5,
  ) {
    d['txnAdded'] = l.tone_professional_txnAdded;
    d['txnUpdated'] = l.tone_professional_txnUpdated;
    d['txnDeleted'] = l.tone_professional_txnDeleted;
    d['txnFailed'] = l.tone_professional_txnFailed;
    d['enterAmount'] = l.tone_professional_enterAmount;
    d['pickAccount'] = l.tone_professional_pickAccount;
    d['pickCategory'] = l.tone_professional_pickCategory;
    d['fillAllFields'] = l.tone_professional_fillAllFields;
    d['invalidAmount'] = l.tone_professional_invalidAmount;
    d['budgetCreated'] = l.tone_professional_budgetCreated;
    d['budgetUpdated'] = l.tone_professional_budgetUpdated;
    d['budgetDeleted'] = l.tone_professional_budgetDeleted;
    d['goalCreated'] = l.tone_professional_goalCreated;
    d['goalUpdated'] = l.tone_professional_goalUpdated;
    d['goalDeleted'] = l.tone_professional_goalDeleted;
    d['accountCreated'] = l.tone_professional_accountCreated;
    d['billAdded'] = l.tone_professional_billAdded;
    d['billPaid'] = l.tone_professional_billPaid;
    d['backupSuccess'] = l.tone_professional_backupSuccess;
    d['restoreSuccess'] = l.tone_professional_restoreSuccess;
    d['noTransactions'] = l.tone_professional_noTransactions;
    d['noBudgets'] = l.tone_professional_noBudgets;
    d['noGoals'] = l.tone_professional_noGoals;
    d['genericError'] = l.tone_professional_genericError;
    d['smsImportEnabled'] = l.tone_professional_smsImportEnabled;
    d['dashboardAllCaughtUp'] = l.tone_professional_dashboardAllCaughtUp;
    d['dailySummaryEmpty'] = l.tone_professional_dailySummaryEmpty;
    d['insightBillsDueSoon'] = l.tone_professional_insightBillsDueSoon;
    d['insightOverBudget'] = l.tone_professional_insightOverBudget;
    d['insightNearBudget'] = l.tone_professional_insightNearBudget;
    d['insightOverspending'] = l.tone_professional_insightOverspending;
    d['insightSpendingSpike'] = l.tone_professional_insightSpendingSpike;
    d['insightWeekendAlert'] = l.tone_professional_insightWeekendAlert;
    d['insightGetStarted'] = l.tone_professional_insightGetStarted;
    d['insightGetStartedMessage'] = l.tone_professional_insightGetStartedMessage;
    d['txnNotFound'] = l.tone_professional_txnNotFound;
    d['futureDate'] = l.tone_professional_futureDate;
    d['selectAccountAndCategory'] = l.tone_professional_selectAccountAndCategory;
    d['addParticipant'] = l.tone_professional_addParticipant;
    d['budgetExceededAdjust'] = l.tone_professional_budgetExceededAdjust;
    d['budgetGreatDiscipline'] = l.tone_professional_budgetGreatDiscipline;
    d['comparisonSpentSame'] = l.tone_professional_comparisonSpentSame;
    d['accountUpdated'] = l.tone_professional_accountUpdated;
    d['accountDeleted'] = l.tone_professional_accountDeleted;
    d['accountLocked'] = l.tone_professional_accountLocked;
    d['categoryCreated'] = l.tone_professional_categoryCreated;
    d['categoryDeleted'] = l.tone_professional_categoryDeleted;
    d['categoryNameRequired'] = l.tone_professional_categoryNameRequired;
    d['billDeleted'] = l.tone_professional_billDeleted;
    d['backupFailed'] = l.tone_professional_backupFailed;
    d['restoreFailed'] = l.tone_professional_restoreFailed;
    d['invalidBackupFile'] = l.tone_professional_invalidBackupFile;
    d['corruptBackup'] = l.tone_professional_corruptBackup;
    d['settingsSaved'] = l.tone_professional_settingsSaved;
    d['reminderUpdated'] = l.tone_professional_reminderUpdated;
    d['biometricFailed'] = l.tone_professional_biometricFailed;
    d['incorrectPin'] = l.tone_professional_incorrectPin;
    d['notificationAccessDenied'] = l.tone_professional_notificationAccessDenied;
    d['noBills'] = l.tone_professional_noBills;
    d['noAccounts'] = l.tone_professional_noAccounts;
    d['noCategories'] = l.tone_professional_noCategories;
    d['noNotifications'] = l.tone_professional_noNotifications;
    d['noData'] = l.tone_professional_noData;
    d['noRecurring'] = l.tone_professional_noRecurring;
    d['exportSuccess'] = l.tone_professional_exportSuccess;
    d['purchaseFailed'] = l.tone_professional_purchaseFailed;
    d['playNotAvailable'] = l.tone_professional_playNotAvailable;
    d['deleteTitle'] = l.tone_professional_deleteTitle;
    d['deleteCancel'] = l.tone_professional_deleteCancel;
    d['deleteConfirm'] = l.tone_professional_deleteConfirm;
    d['logoutTitle'] = l.tone_professional_logoutTitle;
    d['logoutMessage'] = l.tone_professional_logoutMessage;
    d['logoutConfirm'] = l.tone_professional_logoutConfirm;
    d['currencyChanged'] = l.tone_professional_currencyChanged;
    d['currencyChangeTitle'] = l.tone_professional_currencyChangeTitle;
    d['currencyChangeCancel'] = l.tone_professional_currencyChangeCancel;
    d['currencyPickerTitle'] = l.tone_professional_currencyPickerTitle;
    d['dashboardWelcomeBack'] = l.tone_professional_dashboardWelcomeBack;
    di['streakMessage'] = (days) => l.tone_professional_streakMessage(days);
    di['insightBillsDueMessage'] = (c) => l.tone_professional_insightBillsDueMessage(c);
    di['insightOverBudgetMessage'] = (c) => l.tone_professional_insightOverBudgetMessage(c);
    di['insightNearBudgetMessage'] = (c) => l.tone_professional_insightNearBudgetMessage(c);
    ds['budgetExceededBy'] = (a) => l.tone_professional_budgetExceededBy(a);
    ds['insightOverspendingMessage'] = (a) => l.tone_professional_insightOverspendingMessage(a);
    ds2['insightSpendingSpikeMessage'] = (a, b) => l.tone_professional_insightSpendingSpikeMessage(a, b);
    ds2['insightWeekendAlertMessage'] = (a, b) => l.tone_professional_insightWeekendAlertMessage(a, b);
    dsis['insightMoneyLeak'] = (a, b, c) => l.tone_professional_insightMoneyLeak(a, b, c);
    ds5['insightBestDay'] = (a, b, c, d, e) => l.tone_professional_insightBestDay(a, b, c, d, e);
  }

  static void _fillMotivational(
    AppLocalizations l,
    Map<String, String> d,
    Map<String, String Function(int)> di,
    Map<String, String Function(String)> ds,
    Map<String, String Function(String, String)> ds2,
    Map<String, String Function(String, int, String)> dsis,
    Map<String, String Function(String, String, String, String, String)> ds5,
  ) {
    d['txnAdded'] = l.tone_motivational_txnAdded;
    d['txnUpdated'] = l.tone_motivational_txnUpdated;
    d['txnDeleted'] = l.tone_motivational_txnDeleted;
    d['txnFailed'] = l.tone_motivational_txnFailed;
    d['enterAmount'] = l.tone_motivational_enterAmount;
    d['pickAccount'] = l.tone_motivational_pickAccount;
    d['pickCategory'] = l.tone_motivational_pickCategory;
    d['fillAllFields'] = l.tone_motivational_fillAllFields;
    d['invalidAmount'] = l.tone_motivational_invalidAmount;
    d['budgetCreated'] = l.tone_motivational_budgetCreated;
    d['budgetUpdated'] = l.tone_motivational_budgetUpdated;
    d['budgetDeleted'] = l.tone_motivational_budgetDeleted;
    d['goalCreated'] = l.tone_motivational_goalCreated;
    d['goalUpdated'] = l.tone_motivational_goalUpdated;
    d['goalDeleted'] = l.tone_motivational_goalDeleted;
    d['accountCreated'] = l.tone_motivational_accountCreated;
    d['billAdded'] = l.tone_motivational_billAdded;
    d['billPaid'] = l.tone_motivational_billPaid;
    d['backupSuccess'] = l.tone_motivational_backupSuccess;
    d['restoreSuccess'] = l.tone_motivational_restoreSuccess;
    d['noTransactions'] = l.tone_motivational_noTransactions;
    d['noBudgets'] = l.tone_motivational_noBudgets;
    d['noGoals'] = l.tone_motivational_noGoals;
    d['genericError'] = l.tone_motivational_genericError;
    d['smsImportEnabled'] = l.tone_motivational_smsImportEnabled;
    d['dashboardAllCaughtUp'] = l.tone_motivational_dashboardAllCaughtUp;
    d['dailySummaryEmpty'] = l.tone_motivational_dailySummaryEmpty;
    d['insightBillsDueSoon'] = l.tone_motivational_insightBillsDueSoon;
    d['insightOverBudget'] = l.tone_motivational_insightOverBudget;
    d['insightNearBudget'] = l.tone_motivational_insightNearBudget;
    d['insightOverspending'] = l.tone_motivational_insightOverspending;
    d['insightSpendingSpike'] = l.tone_motivational_insightSpendingSpike;
    d['insightWeekendAlert'] = l.tone_motivational_insightWeekendAlert;
    d['insightGetStarted'] = l.tone_motivational_insightGetStarted;
    d['insightGetStartedMessage'] = l.tone_motivational_insightGetStartedMessage;
    d['txnNotFound'] = l.tone_motivational_txnNotFound;
    d['futureDate'] = l.tone_motivational_futureDate;
    d['selectAccountAndCategory'] = l.tone_motivational_selectAccountAndCategory;
    d['addParticipant'] = l.tone_motivational_addParticipant;
    d['budgetExceededAdjust'] = l.tone_motivational_budgetExceededAdjust;
    d['budgetGreatDiscipline'] = l.tone_motivational_budgetGreatDiscipline;
    d['comparisonSpentSame'] = l.tone_motivational_comparisonSpentSame;
    d['accountUpdated'] = l.tone_motivational_accountUpdated;
    d['accountDeleted'] = l.tone_motivational_accountDeleted;
    d['accountLocked'] = l.tone_motivational_accountLocked;
    d['categoryCreated'] = l.tone_motivational_categoryCreated;
    d['categoryDeleted'] = l.tone_motivational_categoryDeleted;
    d['categoryNameRequired'] = l.tone_motivational_categoryNameRequired;
    d['billDeleted'] = l.tone_motivational_billDeleted;
    d['backupFailed'] = l.tone_motivational_backupFailed;
    d['restoreFailed'] = l.tone_motivational_restoreFailed;
    d['invalidBackupFile'] = l.tone_motivational_invalidBackupFile;
    d['corruptBackup'] = l.tone_motivational_corruptBackup;
    d['settingsSaved'] = l.tone_motivational_settingsSaved;
    d['reminderUpdated'] = l.tone_motivational_reminderUpdated;
    d['biometricFailed'] = l.tone_motivational_biometricFailed;
    d['incorrectPin'] = l.tone_motivational_incorrectPin;
    d['notificationAccessDenied'] = l.tone_motivational_notificationAccessDenied;
    d['noBills'] = l.tone_motivational_noBills;
    d['noAccounts'] = l.tone_motivational_noAccounts;
    d['noCategories'] = l.tone_motivational_noCategories;
    d['noNotifications'] = l.tone_motivational_noNotifications;
    d['noData'] = l.tone_motivational_noData;
    d['noRecurring'] = l.tone_motivational_noRecurring;
    d['exportSuccess'] = l.tone_motivational_exportSuccess;
    d['purchaseFailed'] = l.tone_motivational_purchaseFailed;
    d['playNotAvailable'] = l.tone_motivational_playNotAvailable;
    d['deleteTitle'] = l.tone_motivational_deleteTitle;
    d['deleteCancel'] = l.tone_motivational_deleteCancel;
    d['deleteConfirm'] = l.tone_motivational_deleteConfirm;
    d['logoutTitle'] = l.tone_motivational_logoutTitle;
    d['logoutMessage'] = l.tone_motivational_logoutMessage;
    d['logoutConfirm'] = l.tone_motivational_logoutConfirm;
    d['currencyChanged'] = l.tone_motivational_currencyChanged;
    d['currencyChangeTitle'] = l.tone_motivational_currencyChangeTitle;
    d['currencyChangeCancel'] = l.tone_motivational_currencyChangeCancel;
    d['currencyPickerTitle'] = l.tone_motivational_currencyPickerTitle;
    d['dashboardWelcomeBack'] = l.tone_motivational_dashboardWelcomeBack;
    di['streakMessage'] = (days) => l.tone_motivational_streakMessage(days);
    di['insightBillsDueMessage'] = (c) => l.tone_motivational_insightBillsDueMessage(c);
    di['insightOverBudgetMessage'] = (c) => l.tone_motivational_insightOverBudgetMessage(c);
    di['insightNearBudgetMessage'] = (c) => l.tone_motivational_insightNearBudgetMessage(c);
    ds['budgetExceededBy'] = (a) => l.tone_motivational_budgetExceededBy(a);
    ds['insightOverspendingMessage'] = (a) => l.tone_motivational_insightOverspendingMessage(a);
    ds2['insightSpendingSpikeMessage'] = (a, b) => l.tone_motivational_insightSpendingSpikeMessage(a, b);
    ds2['insightWeekendAlertMessage'] = (a, b) => l.tone_motivational_insightWeekendAlertMessage(a, b);
    dsis['insightMoneyLeak'] = (a, b, c) => l.tone_motivational_insightMoneyLeak(a, b, c);
    ds5['insightBestDay'] = (a, b, c, d, e) => l.tone_motivational_insightBestDay(a, b, c, d, e);
  }

  static void _fillCalm(
    AppLocalizations l,
    Map<String, String> d,
    Map<String, String Function(int)> di,
    Map<String, String Function(String)> ds,
    Map<String, String Function(String, String)> ds2,
    Map<String, String Function(String, int, String)> dsis,
    Map<String, String Function(String, String, String, String, String)> ds5,
  ) {
    d['txnAdded'] = l.tone_calm_txnAdded;
    d['txnUpdated'] = l.tone_calm_txnUpdated;
    d['txnDeleted'] = l.tone_calm_txnDeleted;
    d['txnFailed'] = l.tone_calm_txnFailed;
    d['enterAmount'] = l.tone_calm_enterAmount;
    d['pickAccount'] = l.tone_calm_pickAccount;
    d['pickCategory'] = l.tone_calm_pickCategory;
    d['fillAllFields'] = l.tone_calm_fillAllFields;
    d['invalidAmount'] = l.tone_calm_invalidAmount;
    d['budgetCreated'] = l.tone_calm_budgetCreated;
    d['budgetUpdated'] = l.tone_calm_budgetUpdated;
    d['budgetDeleted'] = l.tone_calm_budgetDeleted;
    d['goalCreated'] = l.tone_calm_goalCreated;
    d['goalUpdated'] = l.tone_calm_goalUpdated;
    d['goalDeleted'] = l.tone_calm_goalDeleted;
    d['accountCreated'] = l.tone_calm_accountCreated;
    d['billAdded'] = l.tone_calm_billAdded;
    d['billPaid'] = l.tone_calm_billPaid;
    d['backupSuccess'] = l.tone_calm_backupSuccess;
    d['restoreSuccess'] = l.tone_calm_restoreSuccess;
    d['noTransactions'] = l.tone_calm_noTransactions;
    d['noBudgets'] = l.tone_calm_noBudgets;
    d['noGoals'] = l.tone_calm_noGoals;
    d['genericError'] = l.tone_calm_genericError;
    d['smsImportEnabled'] = l.tone_calm_smsImportEnabled;
    d['dashboardAllCaughtUp'] = l.tone_calm_dashboardAllCaughtUp;
    d['dailySummaryEmpty'] = l.tone_calm_dailySummaryEmpty;
    d['insightBillsDueSoon'] = l.tone_calm_insightBillsDueSoon;
    d['insightOverBudget'] = l.tone_calm_insightOverBudget;
    d['insightNearBudget'] = l.tone_calm_insightNearBudget;
    d['insightOverspending'] = l.tone_calm_insightOverspending;
    d['insightSpendingSpike'] = l.tone_calm_insightSpendingSpike;
    d['insightWeekendAlert'] = l.tone_calm_insightWeekendAlert;
    d['insightGetStarted'] = l.tone_calm_insightGetStarted;
    d['insightGetStartedMessage'] = l.tone_calm_insightGetStartedMessage;
    d['txnNotFound'] = l.tone_calm_txnNotFound;
    d['futureDate'] = l.tone_calm_futureDate;
    d['selectAccountAndCategory'] = l.tone_calm_selectAccountAndCategory;
    d['addParticipant'] = l.tone_calm_addParticipant;
    d['budgetExceededAdjust'] = l.tone_calm_budgetExceededAdjust;
    d['budgetGreatDiscipline'] = l.tone_calm_budgetGreatDiscipline;
    d['comparisonSpentSame'] = l.tone_calm_comparisonSpentSame;
    d['accountUpdated'] = l.tone_calm_accountUpdated;
    d['accountDeleted'] = l.tone_calm_accountDeleted;
    d['accountLocked'] = l.tone_calm_accountLocked;
    d['categoryCreated'] = l.tone_calm_categoryCreated;
    d['categoryDeleted'] = l.tone_calm_categoryDeleted;
    d['categoryNameRequired'] = l.tone_calm_categoryNameRequired;
    d['billDeleted'] = l.tone_calm_billDeleted;
    d['backupFailed'] = l.tone_calm_backupFailed;
    d['restoreFailed'] = l.tone_calm_restoreFailed;
    d['invalidBackupFile'] = l.tone_calm_invalidBackupFile;
    d['corruptBackup'] = l.tone_calm_corruptBackup;
    d['settingsSaved'] = l.tone_calm_settingsSaved;
    d['reminderUpdated'] = l.tone_calm_reminderUpdated;
    d['biometricFailed'] = l.tone_calm_biometricFailed;
    d['incorrectPin'] = l.tone_calm_incorrectPin;
    d['notificationAccessDenied'] = l.tone_calm_notificationAccessDenied;
    d['noBills'] = l.tone_calm_noBills;
    d['noAccounts'] = l.tone_calm_noAccounts;
    d['noCategories'] = l.tone_calm_noCategories;
    d['noNotifications'] = l.tone_calm_noNotifications;
    d['noData'] = l.tone_calm_noData;
    d['noRecurring'] = l.tone_calm_noRecurring;
    d['exportSuccess'] = l.tone_calm_exportSuccess;
    d['purchaseFailed'] = l.tone_calm_purchaseFailed;
    d['playNotAvailable'] = l.tone_calm_playNotAvailable;
    d['deleteTitle'] = l.tone_calm_deleteTitle;
    d['deleteCancel'] = l.tone_calm_deleteCancel;
    d['deleteConfirm'] = l.tone_calm_deleteConfirm;
    d['logoutTitle'] = l.tone_calm_logoutTitle;
    d['logoutMessage'] = l.tone_calm_logoutMessage;
    d['logoutConfirm'] = l.tone_calm_logoutConfirm;
    d['currencyChanged'] = l.tone_calm_currencyChanged;
    d['currencyChangeTitle'] = l.tone_calm_currencyChangeTitle;
    d['currencyChangeCancel'] = l.tone_calm_currencyChangeCancel;
    d['currencyPickerTitle'] = l.tone_calm_currencyPickerTitle;
    d['dashboardWelcomeBack'] = l.tone_calm_dashboardWelcomeBack;
    di['streakMessage'] = (days) => l.tone_calm_streakMessage(days);
    di['insightBillsDueMessage'] = (c) => l.tone_calm_insightBillsDueMessage(c);
    di['insightOverBudgetMessage'] = (c) => l.tone_calm_insightOverBudgetMessage(c);
    di['insightNearBudgetMessage'] = (c) => l.tone_calm_insightNearBudgetMessage(c);
    ds['budgetExceededBy'] = (a) => l.tone_calm_budgetExceededBy(a);
    ds['insightOverspendingMessage'] = (a) => l.tone_calm_insightOverspendingMessage(a);
    ds2['insightSpendingSpikeMessage'] = (a, b) => l.tone_calm_insightSpendingSpikeMessage(a, b);
    ds2['insightWeekendAlertMessage'] = (a, b) => l.tone_calm_insightWeekendAlertMessage(a, b);
    dsis['insightMoneyLeak'] = (a, b, c) => l.tone_calm_insightMoneyLeak(a, b, c);
    ds5['insightBestDay'] = (a, b, c, d, e) => l.tone_calm_insightBestDay(a, b, c, d, e);
  }
}
