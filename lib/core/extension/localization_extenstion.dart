import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

extension AppLocalizationsHelper on AppLocalizations {
  String translate(String key) {
    switch (key) {
      case 'welcome_to_app':
        return onboard_welcomeToApp('Mudra Manager');
      case 'manageYourMoneyDescription':
        return onboard_manageYourMoneyDescription;
      case 'onboard_TrackYourTransactions':
        return onboard_TrackYourTransactions;
      case 'onboard_SeeWhereYourMoneyGoes':
        return onboard_SeeWhereYourMoneyGoes;
      case 'onboard_SetBudgetsAndGoals':
        return onboard_SetBudgetsAndGoals;
      case 'onboard_stayOnTrackAndAchieveYourDream':
        return onboard_stayOnTrackAndAchieveYourDream;
      case 'onboard_GetStarted':
        return onboard_GetStarted;
      case 'onboard_letsSetupYourAccount':
        return onboard_letsSetupYourAccount;
      case 'onboard_howShouldWeCallYou':
        return onboard_howShouldWeCallYou;
      case 'onboard_enterYourNameToPersonalizeYourExperience':
        return onboard_enterYourNameToPersonalizeYourExperience;
      case 'onboard_enterYourName':
        return onboard_enterYourName;
      case 'onboard_setupYourFirstAccount':
        return onboard_setupYourFirstAccount;
      case 'onboard_letsCreateYourFirstAccount':
        return onboard_letsCreateYourFirstAccount;
      case 'onboard_accountName':
        return onboard_accountName;
      case 'onboard_youAreAllSet':
        return onboard_youAreAllSet;
      case 'onboard_letsStartManagingYourMoneyWisely':
        return onboard_letsStartManagingYourMoneyWisely;
      case 'app_settings_appbar_title':
        return app_settings_appbar_title;
      case 'good_morning':
        return greeting_good_morning_text;
      case 'good_afternoon':
        return greeting_good_afternoon_text;
      case 'good_evening':
        return greeting_good_evening_text;
      case 'good_night':
        return greeting_good_night_text;
      case 'day':
        return cash_flow_filter_type_day;
      case 'week':
        return cash_flow_filter_type_week;
      case 'month':
        return cash_flow_filter_type_month;
      case 'year':
        return cash_flow_filter_type_year;
      case 'none':
        return budget_recurrenceNoneText;
      case 'daily':
        return budget_recurrenceDailyText;
      case 'weekly':
        return budget_recurrenceWeeklyText;
      case 'monthly':
        return budget_recurrenceMonthlyText;
      case 'yearly':
        return budget_recurrenceYearlyText;
      case 'Today':
        return statistics_selectPeriodTodayText;
      case 'Week':
        return statistics_selectPeriodWeekText;
      case 'Month':
        return statistics_selectPeriodMonthText;
      case 'Year':
        return statistics_selectPeriodYearText;
      case 'onboard_SmartSmsTracking':
        return onboard_SmartSmsTracking;
      case 'onboard_SmartSmsTrackingDesc':
        return onboard_SmartSmsTrackingDesc;
      case 'onboard_InsightsAndAnalytics':
        return onboard_InsightsAndAnalytics;
      case 'onboard_InsightsAndAnalyticsDesc':
        return onboard_InsightsAndAnalyticsDesc;
      case 'onboard_SecureAndPrivate':
        return onboard_SecureAndPrivate;
      case 'onboard_SecureAndPrivateDesc':
        return onboard_SecureAndPrivateDesc;
      case 'onboard_SmartAutoTracking':
        return onboard_SmartAutoTracking;
      case 'onboard_SmartAutoTrackingDesc':
        return onboard_SmartAutoTrackingDesc;
      case 'onboard_smartTrackingMergedDesc':
        return onboard_smartTrackingMergedDesc;

      // Starter transactions (onboarding step 5)
      case 'onboard_whatDidYouSpend':
        return onboard_whatDidYouSpend;
      case 'onboard_addFewToStart':
        return onboard_addFewToStart;
      case 'onboard_skipAddLater':
        return onboard_skipAddLater;
      case 'onboard_starterCoffee':
        return onboard_starterCoffee;
      case 'onboard_starterTransport':
        return onboard_starterTransport;
      case 'onboard_starterLunch':
        return onboard_starterLunch;
      case 'onboard_starterGroceries':
        return onboard_starterGroceries;

      // Dashboard zero-state
      case 'dashboard_listeningTitle':
        return dashboard_listeningTitle;
      case 'dashboard_waitingForSms':
        return dashboard_waitingForSms;
      case 'dashboard_meanwhile':
        return dashboard_meanwhile;
      case 'dashboard_addExpense':
        return dashboard_addExpense;
      case 'dashboard_setBudget':
        return dashboard_setBudget;
      case 'dashboard_createGoal':
        return dashboard_createGoal;
      case 'dashboard_addAccount':
        return dashboard_addAccount;
      case 'dashboard_testTip':
        return dashboard_testTip;
      case 'dashboard_addFirstExpense':
        return dashboard_addFirstExpense;
      case 'dashboard_addFirstExpenseDesc':
        return dashboard_addFirstExpenseDesc;

      // Quick-add compact
      case 'quickAdd_title':
        return quickAdd_title;
      case 'quickAdd_recentCategories':
        return quickAdd_recentCategories;
      case 'quickAdd_moreOptions':
        return quickAdd_moreOptions;

      // App mode
      case 'mode_simple':
        return mode_simple;
      case 'mode_full':
        return mode_full;
      case 'mode_simpleDesc':
        return mode_simpleDesc;
      case 'mode_fullDesc':
        return mode_fullDesc;
      case 'mode_switchToFull':
        return mode_switchToFull;
      case 'mode_switchToSimple':
        return mode_switchToSimple;
      case 'mode_pickTitle':
        return mode_pickTitle;
      case 'mode_pickDesc':
        return mode_pickDesc;

      // Cloud backup
      case 'backup_cloudBackup':
        return backup_cloudBackup;
      case 'backup_cloudRestore':
        return backup_cloudRestore;
      case 'backup_signInGoogle':
        return backup_signInGoogle;
      case 'backup_uploadSuccess':
        return backup_uploadSuccess;
      case 'backup_uploadFailed':
        return backup_uploadFailed;
      case 'backup_cloudBackups':
        return backup_cloudBackups;
      case 'backup_noCloudBackups':
        return backup_noCloudBackups;
      case 'backup_signInRequired':
        return backup_signInRequired;
      case 'backup_signOut':
        return backup_signOut;
      case 'backup_cloudSubtitle':
        return backup_cloudSubtitle;

      // Navigation
      case 'nav_activity':
        return nav_activity;
      case 'nav_manage':
        return nav_manage;
      case 'nav_insights':
        return nav_insights;

      // Common
      case 'common_save':
        return common_save;
      case 'common_cancel':
        return common_cancel;
      case 'common_delete':
        return common_delete;
      case 'common_edit':
        return common_edit;
      case 'common_add':
        return common_add;
      case 'common_done':
        return common_done;
      case 'common_close':
        return common_close;
      case 'common_confirm':
        return common_confirm;
      case 'common_archive':
        return common_archive;
      case 'common_create':
        return common_create;
      case 'common_update':
        return common_update;
      case 'common_remove':
        return common_remove;
      case 'common_search':
        return common_search;
      case 'common_filter':
        return common_filter;
      case 'common_reset':
        return common_reset;
      case 'common_apply':
        return common_apply;
      case 'common_yes':
        return common_yes;
      case 'common_no':
        return common_no;
      case 'common_ok':
        return common_ok;
      case 'common_retry':
        return common_retry;
      case 'common_loading':
        return common_loading;
      case 'common_noData':
        return common_noData;
      case 'common_error':
        return common_error;
      case 'common_required':
        return common_required;

      // Titles
      case 'title_budgets':
        return title_budgets;
      case 'title_goals':
        return title_goals;
      case 'title_bills':
        return title_bills;
      case 'title_groups':
        return title_groups;
      case 'title_trips':
        return title_trips;
      case 'title_shared':
        return title_shared;
      case 'title_achievements':
        return title_achievements;
      case 'title_notifications':
        return title_notifications;
      case 'title_appearance':
        return title_appearance;
      case 'title_currency':
        return title_currency;
      case 'title_security':
        return title_security;
      case 'title_about':
        return title_about;
      case 'title_analytics':
        return title_analytics;
      case 'title_netWorth':
        return title_netWorth;
      case 'title_financialHealth':
        return title_financialHealth;
      case 'title_spendingPersonality':
        return title_spendingPersonality;
      case 'title_monthlyRecap':
        return title_monthlyRecap;
      case 'title_compareMonths':
        return title_compareMonths;
      case 'title_smsImport':
        return title_smsImport;
      case 'title_backupShare':
        return title_backupShare;
      case 'title_exchangeRates':
        return title_exchangeRates;
      case 'tax_title':
        return tax_title;
      case 'title_recurringTransactions':
        return title_recurringTransactions;
      case 'title_billControlCenter':
        return title_billControlCenter;
      case 'title_plugins':
        return title_plugins;
      case 'title_editCategory':
        return title_editCategory;
      case 'title_allCategories':
        return title_allCategories;
      case 'title_exportOptions':
        return title_exportOptions;
      case 'title_dashboardLayout':
        return title_dashboardLayout;

      // Sections
      case 'section_activeMoney':
        return section_activeMoney;
      case 'section_planning':
        return section_planning;
      case 'section_insights':
        return section_insights;
      case 'section_coreSettings':
        return section_coreSettings;
      case 'section_appData':
        return section_appData;
      case 'section_appearance':
        return section_appearance;
      case 'section_advanced':
        return section_advanced;
      case 'section_supportLegal':
        return section_supportLegal;
      case 'section_active':
        return section_active;
      case 'section_ongoing':
        return section_ongoing;
      case 'section_archive':
        return section_archive;

      // Labels
      case 'label_income':
        return label_income;
      case 'label_expense':
        return label_expense;
      case 'label_balance':
        return label_balance;
      case 'label_savings':
        return label_savings;
      case 'label_total':
        return label_total;
      case 'label_amount':
        return label_amount;
      case 'label_date':
        return label_date;
      case 'label_category':
        return label_category;
      case 'label_account':
        return label_account;
      case 'label_description':
        return label_description;
      case 'label_type':
        return label_type;
      case 'label_transfer':
        return label_transfer;
      case 'label_from':
        return label_from;
      case 'label_to':
        return label_to;
      case 'label_all':
        return label_all;
      case 'label_today':
        return label_today;
      case 'label_yesterday':
        return label_yesterday;
      case 'label_thisWeek':
        return label_thisWeek;
      case 'label_thisMonth':
        return label_thisMonth;
      case 'label_thisYear':
        return label_thisYear;
      case 'label_custom':
        return label_custom;
      case 'label_daily':
        return label_daily;
      case 'label_weekly':
        return label_weekly;
      case 'label_monthly':
        return label_monthly;
      case 'label_yearly':
        return label_yearly;
      case 'label_none':
        return label_none;

      // Trip
      case 'trip_expenses':
        return trip_expenses;
      case 'trip_settlements':
        return trip_settlements;
      case 'trip_balances':
        return trip_balances;
      case 'trip_report':
        return trip_report;
      case 'trip_createTrip':
        return trip_createTrip;
      case 'trip_createGroup':
        return trip_createGroup;
      case 'trip_editTrip':
        return trip_editTrip;
      case 'trip_editGroup':
        return trip_editGroup;
      case 'trip_archiveTrip':
        return trip_archiveTrip;
      case 'trip_archiveGroup':
        return trip_archiveGroup;
      case 'trip_allSettled':
        return trip_allSettled;
      case 'trip_archiveToSettle':
        return trip_archiveToSettle;
      case 'trip_trackTravel':
        return trip_trackTravel;
      case 'trip_splitBills':
        return trip_splitBills;
      case 'trip_live':
        return trip_live;

      // Budget
      case 'budget_spendingLimits':
        return budget_spendingLimits;
      case 'budget_savingsProgress':
        return budget_savingsProgress;
      case 'budget_upcomingRecurring':
        return budget_upcomingRecurring;
      case 'budget_tripsAndSplits':
        return budget_tripsAndSplits;

      // Import
      case 'import_dontClose':
        return import_dontClose;
      case 'import_complete':
        return import_complete;
      case 'import_failed':
        return import_failed;
      case 'import_imported':
        return import_imported;
      case 'import_duplicatesSkipped':
        return import_duplicatesSkipped;
      case 'import_errorsSkipped':
        return import_errorsSkipped;
      case 'import_categoriesCreated':
        return import_categoriesCreated;
      case 'import_previewImport':
        return import_previewImport;

      // Recap
      case 'recap_yourMonthAtGlance':
        return recap_yourMonthAtGlance;
      case 'recap_trackProgressOverTime':
        return recap_trackProgressOverTime;
      case 'recap_downloadPdf':
        return recap_downloadPdf;

      // Comparison
      case 'comparison_current':
        return comparison_current;
      case 'comparison_topCategories':
        return comparison_topCategories;
      case 'comparison_categoryImpact':
        return comparison_categoryImpact;
      case 'comparison_dailySpendingPace':
        return comparison_dailySpendingPace;

      // Utility
      case 'utility_customizeUtilities':
        return utility_customizeUtilities;
      case 'utility_addUtilities':
        return utility_addUtilities;
      case 'utility_taxSubtitle':
        return utility_taxSubtitle;
      case 'utility_analyticsSubtitle':
        return utility_analyticsSubtitle;
      case 'cc_title':
        return cc_title;
      case 'cc_utilitySubtitle':
        return cc_utilitySubtitle;

      // Profile
      case 'profile_accounts':
        return profile_accounts;
      case 'profile_manageAccounts':
        return profile_manageAccounts;
      case 'profile_categories':
        return profile_categories;
      case 'profile_manageCategories':
        return profile_manageCategories;
      case 'profile_language':
        return profile_language;
      case 'profile_notifications':
        return profile_notifications;
      case 'profile_dailyWeeklySummaries':
        return profile_dailyWeeklySummaries;
      case 'profile_autoImport':
        return profile_autoImport;
      case 'profile_autoImportDesc':
        return profile_autoImportDesc;
      case 'profile_importExport':
        return profile_importExport;
      case 'profile_importExportDesc':
        return profile_importExportDesc;
      case 'profile_backupRestore':
        return profile_backupRestore;
      case 'profile_manageData':
        return profile_manageData;
      case 'profile_themeDisplay':
        return profile_themeDisplay;
      case 'profile_customizeWidgets':
        return profile_customizeWidgets;
      case 'profile_manageExtensions':
        return profile_manageExtensions;
      case 'profile_helpSupport':
        return profile_helpSupport;
      case 'profile_faqs':
        return profile_faqs;
      case 'profile_aboutApp':
        return profile_aboutApp;
      case 'profile_versionInfo':
        return profile_versionInfo;
      case 'profile_pinFingerprint':
        return profile_pinFingerprint;
      case 'profile_upgradePro':
        return profile_upgradePro;
      case 'profile_unlimitedFeatures':
        return profile_unlimitedFeatures;
      case 'profile_freeTier':
        return profile_freeTier;
      case 'profile_fullAccess':
        return profile_fullAccess;
      case 'profile_proActive':
        return profile_proActive;
      case 'profile_yourAchievements':
        return profile_yourAchievements;
      case 'profile_bestStreak':
        return profile_bestStreak;

      // Trips list
      case 'trips_active':
        return trips_active;
      case 'trips_live':
        return trips_live;
      case 'trips_allSettled':
        return trips_allSettled;

      default:
        return key;
    }
  }

  /// Always use en_IN for number formatting — Indian users expect
  /// ₹500 not ₹৫০০ regardless of UI language.
  String get _numberLocale => 'en_IN';

  NumberFormat formatLocalizedCurrency(int fixedStringLength) {
    final locale = _numberLocale;
    final format = NumberFormat.currency(
      locale: locale,
      symbol: BaseCurrency.symbol,
      decimalDigits: fixedStringLength,
      customPattern: '¤#,##,##0.00',
    );
    return format;
  }

  NumberFormat formatCompactLocalizedCurrency(int fixedStringLength) {
    final locale = _numberLocale;
    final format = NumberFormat.compactCurrency(
      locale: locale,
      symbol: '', // Or separate sign and symbol if needed
      decimalDigits: fixedStringLength,
    );
    return format;
  }

  String formatCurrencyWithSign(
    int fixedStringLength,
    double amount, {
    bool compact = false,
  }) {
    final format = compact
        ? formatCompactLocalizedCurrency(fixedStringLength)
        : formatLocalizedCurrency(fixedStringLength);
    return "${compact ? BaseCurrency.symbol : ""}${format.format(amount)}";
  }

  String formatCompactCurrency(double amount, {int fixedStringLength = 2}) {
    final s = BaseCurrency.symbol;
    if (amount.abs() >= 10000000) {
      return '$s${_trimTrailingZeros((amount / 10000000).toStringAsFixed(fixedStringLength))}$currency_crore_short';
    } else if (amount.abs() >= 100000) {
      return '$s${_trimTrailingZeros((amount / 100000).toStringAsFixed(fixedStringLength))}$currency_lakh_short';
    } else if (amount.abs() >= 10000) {
      return '$s${_trimTrailingZeros((amount / 1000).toStringAsFixed(fixedStringLength))}$currency_thousand_short';
    }
    return formatCurrencyWithSign(0, amount);
  }

  String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    var trimmed = value.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.endsWith('.')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  NumberFormat formatCompactNumber() {
    final locale = _numberLocale;
    final format = NumberFormat.compact(locale: locale, explicitSign: false);
    return format;
  }

  String formatPercentNumber(num value) {
    final locale = _numberLocale;
    final format = NumberFormat.percentPattern(locale);
    return format.format(value);
  }

  NumberFormat formatLocaleNumber() {
    final locale = _numberLocale;
    final format = NumberFormat('#,##,##0.00', locale);
    return format;
  }
}

extension LocalizationExtension on Locale {
  String displayName() {
    switch (languageCode.toUpperCase()) {
      case 'EN':
        return 'English';
      case 'HI':
        return 'हिंदी';
      case 'BN':
        return 'বাংলা';
      case 'ES':
        return 'Español';
      case 'PT':
        return 'Português';
      case 'ID':
        return 'Bahasa Indonesia';
      case 'FR':
        return 'Français';
      case 'DE':
        return 'Deutsch';
      case 'AR':
        return 'العربية';
      case 'TR':
        return 'Türkçe';
      case 'TH':
        return 'ไทย';
      case 'VI':
        return 'Tiếng Việt';
      case 'SW':
        return 'Kiswahili';
      case 'KO':
        return '한국어';
      case 'JA':
        return '日本語';
      case 'ZH':
        return '中文';
      case 'MS':
        return 'Bahasa Melayu';
      case 'TA':
        return 'தமிழ்';
      case 'TE':
        return 'తెలుగు';
      case 'MR':
        return 'मराठी';
      case 'GU':
        return 'ગુજરાતી';
      case 'KN':
        return 'ಕನ್ನಡ';
      case 'ML':
        return 'മലയാളം';
      case 'PA':
        return 'ਪੰਜਾਬੀ';
      case 'OR':
        return 'ଓଡ଼ିଆ';
      case 'AS':
        return 'অসমীয়া';
      case 'UR':
        return 'اردو';
      case 'SD':
        return 'सिन्धी';
      case 'NE':
        return 'नेपाली';
      case 'SI':
        return 'සිංහල';
      case 'BO':
        return 'བོད་སྐད་';
      case 'DOI':
        return 'डोगरी';
      case 'KOK':
        return 'कोंकणी';
      case 'MAI':
        return 'मैथिली';
      case 'MNI':
        return 'মৈতৈলোন';
      case 'SAT':
        return 'ᱥᱟᱱᱛᱟᱣᱤ';
      case 'BRX':
        return 'बोडो';
      default:
        return languageCode.toUpperCase();
    }
  }
}
