// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      '100% offline। Hindi, Bengali, English। India-র জন্য তৈরি।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return '$appName-এ স্বাগতম';
  }

  @override
  String get onboard_TrackYourTransactions => 'Bank SMS থেকে Auto-track';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      '50+ Indian bank support। HDFC, SBI, ICICI, Paytm, GPay — auto-import।';

  @override
  String get onboard_SetBudgetsAndGoals => 'Budget, Goals ও Smart Alerts';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'Overspend-এর আগে warning। যা দরকার তার জন্য save করুন।';

  @override
  String get onboard_GetStarted => 'চলুন শুরু করি!';

  @override
  String get onboard_letsSetupYourAccount => 'চলুন আপনার account সেট আপ করি।';

  @override
  String get onboard_howShouldWeCallYou => 'আপনাকে কী নামে ডাকব?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'নাম দিন, app আপনার মতো হয়ে যাবে।';

  @override
  String get onboard_enterYourName => 'আপনার নাম লিখুন';

  @override
  String get onboard_setupYourFirstAccount => 'প্রথম Account বানান';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'চলুন প্রথম account তৈরি করি (যেমন: Cash)।';

  @override
  String get onboard_accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get onboard_initialBalance => 'প্রাথমিক ব্যালেন্স';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'বাকি details পরেও update করতে পারবেন।';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'অনুগ্রহ করে \"$inputName\" পূরণ করুন';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'অনুগ্রহ করে \"$hintText\" এর জন্য একটি বৈধ সংখ্যা লিখুন';
  }

  @override
  String get onboard_youAreAllSet => 'ব্যস, সব তৈরি!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'এবার টাকা-পয়সা বুঝে-শুনে manage করুন।';

  @override
  String get app_settings_appbar_title => 'অ্যাপ সেটিংস';

  @override
  String get language_settings_appbar_title => 'ভাষা নির্বাচন করুন';

  @override
  String get app_settings_language_title => 'ভাষা';

  @override
  String get app_settings_language_subtitle => 'আপনার ভাষা নির্বাচন করুন';

  @override
  String get app_settings_theme_mode_title => 'থিম মোড';

  @override
  String get app_settings_theme_mode_light => 'Light';

  @override
  String get app_settings_theme_mode_dark => 'Dark';

  @override
  String get app_settings_theme_mode_system_default => 'সিস্টেম ডিফল্ট';

  @override
  String get app_settings_theme_mode_amoled => 'AMOLED ডার্ক';

  @override
  String get app_settings_theme_mode_subtitle =>
      'আপনার পছন্দের থিম নির্বাচন করুন';

  @override
  String get app_settings_daily_reminder_title => 'দৈনিক ব্যয়ের অনুস্মারক';

  @override
  String get home_screen_title => 'হোম';

  @override
  String get transaction_screen_title => 'ক্রিয়াকলাপ';

  @override
  String get statistics_screen_title => 'পরিসংখ্যান';

  @override
  String get profile_screen_title => 'প্রোফাইল';

  @override
  String get add_edit_transaction_screen_title => 'লেনদেন যোগ করুন';

  @override
  String get transaction_list_screen_title => 'লেনদেনের তালিকা';

  @override
  String get transaction_listViewGroupTodayLabel => 'আজ';

  @override
  String get transaction_listViewGroupYesterdayLabel => 'গতকাল';

  @override
  String get greeting_good_morning_text => 'শুভ সকাল';

  @override
  String get greeting_good_afternoon_text => 'শুভ অপরাহ্ন';

  @override
  String get greeting_good_evening_text => 'শুভ সন্ধ্যা';

  @override
  String get greeting_good_night_text => 'শুভ রাত্রি';

  @override
  String get greeting_hello_text => 'হ্যালো';

  @override
  String get transaction_type_income => 'আয়';

  @override
  String get transaction_type_expense => 'ব্যয়';

  @override
  String get dashboard_add_transaction_text => 'লেনদেন যোগ করুন';

  @override
  String get dashboard_add_transfer_text => 'ট্রান্সফার';

  @override
  String get dashboard_cash_flow_text => 'ক্যাশ ফ্লো';

  @override
  String get cash_flow_filter_type_day => 'দিন';

  @override
  String get cash_flow_filter_type_week => 'সপ্তাহ';

  @override
  String get cash_flow_filter_type_month => 'মাস';

  @override
  String get cash_flow_filter_type_year => 'বছর';

  @override
  String get dashboard_mini_budget_text => 'বাজেট';

  @override
  String get dashboard_mini_budget_not_found_text =>
      'কোনো Budget নেই, একটা বানান!';

  @override
  String get dashboard_mini_budget_add_text => 'বাজেট যোগ করুন';

  @override
  String get transaction_list_cash_flow_screen_title => 'লেনদেন';

  @override
  String get transaction_list_filter_all => 'সব';

  @override
  String get transaction_list_filter_income => 'আয়';

  @override
  String get transaction_list_filter_expense => 'ব্যয়';

  @override
  String get transaction_list_pending_transaction_message_text =>
      '⚡ নতুন transactions পাওয়া গেছে! দেখুন';

  @override
  String get transaction_listPendingTransactionMessageActionLabel =>
      'পর্যালোচনা';

  @override
  String get transaction_noTransactionFoundText => 'কোনো transaction নেই।';

  @override
  String get transaction_deleteAlertTitleText => 'লেনদেন মুছবেন?';

  @override
  String get transaction_deleteAlertBodyText => 'এটা আর ফেরানো যাবে না।';

  @override
  String get transaction_deleteButtonActionText => 'মুছে ফেলুন';

  @override
  String get transaction_cancelButtonActionText => 'বাতিল করুন';

  @override
  String get transaction_filterCategoryText => 'লেনদেন ফিল্টার করুন';

  @override
  String transaction_noteDescriptionText(Object description) {
    return 'নোট: $description';
  }

  @override
  String get calendar_week_monday_initial_text => 'সোম';

  @override
  String get calendar_week_tuesday_initial_text => 'মঙ্গল';

  @override
  String get calendar_week_wednesday_initial_text => 'বুধ';

  @override
  String get calendar_week_thursday_initial_text => 'বৃহঃ';

  @override
  String get calendar_week_friday_initial_text => 'শুক্র';

  @override
  String get calendar_week_saturday_initial_text => 'শনি';

  @override
  String get calendar_week_sunday_initial_text => 'রবি';

  @override
  String get dashboard_netWorthTitle => 'মোট সম্পদ';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'বাজেট';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'খরচ হয়েছে';

  @override
  String get budget_dashboardPageTitle => 'বাজেটের বিবরণ';

  @override
  String get budget_dashboardNotFoundText => 'কোনো Budget নেই, একটা বানান!';

  @override
  String get budget_dashboardAddBudgetText => 'বাজেট যোগ করুন';

  @override
  String get budget_categoriesTitle => 'ক্যাটাগরি';

  @override
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent) {
    return '$title (মোট $totalPercent, ব্যয়িত $spentPercent)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'বাজেট মুছবেন?';

  @override
  String get budget_buttonDeleteBodyText =>
      'Budget আর তার allocations মুছে যাবে, এটা আর ফেরানো যাবে না।';

  @override
  String get budget_buttonDeleteActionText => 'মুছে ফেলুন';

  @override
  String get budget_buttonCancelActionText => 'বাতিল করুন';

  @override
  String get budget_buttonAddText => 'বাজেট যোগ করুন';

  @override
  String get budget_buttonEditText => 'বাজেট সম্পাদনা করুন';

  @override
  String get budget_budgetNameControllerText => 'বাজেটের নাম';

  @override
  String get budget_budgetAmountControllerText => 'মোট পরিমাণ';

  @override
  String get budget_recurrenceControllerText => 'পুনরাবৃত্তি';

  @override
  String get budget_nameRequiredHintText => 'বাজেটের নাম আবশ্যক';

  @override
  String get budget_amountRequiredHintText => 'বৈধ পরিমাণ আবশ্যক';

  @override
  String get budget_selectStartDateText => 'শুরুর তারিখ নির্বাচন করুন';

  @override
  String budget_selectedStartDateText(Object startDate) {
    return 'শুরু: $startDate';
  }

  @override
  String get budget_selectEndDateText => 'শেষের তারিখ নির্বাচন করুন';

  @override
  String budget_selectedEndDateText(Object endDate) {
    return 'শেষ: $endDate';
  }

  @override
  String get budget_categoryTitle => 'ক্যাটাগরি এবং বরাদ্দ নির্বাচন করুন';

  @override
  String get budget_allocateAmountText => 'বরাদ্দ পরিমাণ';

  @override
  String get budget_categoryMessageInfoText =>
      'Category-র amount নিজে দিন, অথবা ফাঁকা রাখুন — বাকিটা সমান ভাগ হয়ে যাবে।';

  @override
  String budget_totalAllocatedBudgetText(Object totalAlloc) {
    return 'মোট বরাদ্দ: $totalAlloc';
  }

  @override
  String get budget_recurrenceText => 'পুনরাবৃত্তি';

  @override
  String get budget_recurrenceNoneText => 'নেই';

  @override
  String get budget_recurrenceDailyText => 'দৈনিক';

  @override
  String get budget_recurrenceWeeklyText => 'সাপ্তাহিক';

  @override
  String get budget_recurrenceMonthlyText => 'মাসিক';

  @override
  String get budget_recurrenceYearlyText => 'বার্ষিক';

  @override
  String get budget_saveButtonText => 'সংরক্ষণ করুন';

  @override
  String get budget_updateButtonText => 'আপডেট করুন';

  @override
  String get budget_pickBothDatesErrorText => 'উভয় তারিখ নির্বাচন করুন';

  @override
  String get budget_selectAtLeastOneCategoryErrorText =>
      'অন্তত একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText =>
      'বরাদ্দ করা পরিমাণ মোট বাজেট অতিক্রম করেছে';

  @override
  String get transaction_amountControllerText => 'পরিমাণ';

  @override
  String get transaction_descriptionControllerText => 'বিবরণ (ঐচ্ছিক)';

  @override
  String get transaction_amountControllerErrorText => 'পরিমাণ লিখুন';

  @override
  String get transaction_selectAccountLabel => 'অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get transaction_selectCategoryLabel => 'ক্যাটাগরি নির্বাচন করুন';

  @override
  String get transaction_selectTagLabel => 'ট্যাগ নির্বাচন করুন';

  @override
  String get transaction_addNewCategoryText => 'নতুন ক্যাটাগরি\\nযোগ করুন';

  @override
  String get transaction_addNewTagText => 'নতুন ট্যাগ যোগ করুন';

  @override
  String get transaction_tagNameControllerText => 'ট্যাগের নাম';

  @override
  String get transaction_saveTagButtonLabel => 'ট্যাগ সংরক্ষণ করুন';

  @override
  String get transaction_saveTransactionButtonLabel => 'লেনদেন সংরক্ষণ করুন';

  @override
  String get transaction_selectOneAccountErrorText =>
      'অন্তত একটি অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get transaction_selectOneCategoryErrorText =>
      'অন্তত একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get transaction_incomeButtonLabel => 'আয়';

  @override
  String get transaction_expenseButtonLabel => 'ব্যয়';

  @override
  String get statistics_weTrimDownDecimalInfoText =>
      'আমরা দশমিক স্থান কমিয়ে দেই, প্রয়োজনে রাউন্ড অফ করুন।';

  @override
  String get statistics_selectPeriodTodayText => 'আজ';

  @override
  String get statistics_selectPeriodWeekText => 'সপ্তাহ';

  @override
  String get statistics_selectPeriodMonthText => 'মাস';

  @override
  String get statistics_selectPeriodYearText => 'বছর';

  @override
  String get statistics_chartLineIncomeText => 'আয়';

  @override
  String get statistics_chartLineExpenseText => 'ব্যয়';

  @override
  String statistics_chartLineTodayHourText(Object hour) {
    return '$hourঘঃ';
  }

  @override
  String get statistics_categoryNotPresentText => 'ক্যাটাগরি বিদ্যমান নেই।';

  @override
  String get statistics_transactionNotPresentText => 'লেনদেন বিদ্যমান নেই।';

  @override
  String get statistics_byCategoryTitleText => 'ক্যাটাগরি অনুযায়ী';

  @override
  String get statistics_recentTransactionsTitleText => 'সাম্প্রতিক লেনদেন';

  @override
  String get statistics_metricIncomeText => 'আয়';

  @override
  String get statistics_metricExpenseText => 'ব্যয়';

  @override
  String get statistics_metricNetText => 'নিট';

  @override
  String get statistics_showAllButtonText => 'সব দেখান';

  @override
  String get statistics_exportToPdfButtonText => 'পিডিএফ-এ এক্সপোর্ট করুন';

  @override
  String get statistics_exportToExcelButtonText => 'এক্সেল-এ এক্সপোর্ট করুন';

  @override
  String get profile_userProfileTitleText => 'ব্যবহারকারী প্রোফাইল';

  @override
  String get profile_userProfileSubtitleText =>
      'প্রোফাইলের ছবি, নাম এবং ইমেল পরিবর্তন করুন';

  @override
  String get profile_nameControllerText => 'নাম';

  @override
  String get profile_nameControllerHintText => 'আপনার নাম লিখুন';

  @override
  String get profile_nameRequiredHintText => 'নাম আবশ্যক';

  @override
  String get profile_emailControllerText => 'ইমেল';

  @override
  String get profile_emailControllerHintText => 'আপনার ইমেল লিখুন';

  @override
  String get profile_phoneControllerText => 'ফোন';

  @override
  String get profile_phoneControllerHintText => 'আপনার ফোন নম্বর লিখুন';

  @override
  String get profile_weAreNotStoringInfoText =>
      'আপনার সব data এই phone-এই আছে। কোনো server নেই, cloud নেই, tracking নেই।';

  @override
  String get profile_saveButtonText => 'সংরক্ষণ করুন';

  @override
  String get profile_editUserProfileAppTitle =>
      'ব্যবহারকারী প্রোফাইল সম্পাদনা করুন';

  @override
  String get pendingTranx_reviewPendingTransactionsScreenTitle =>
      'মুলতুবি লেনদেন';

  @override
  String get statistics_quickOverviewTitle => 'দ্রুত পরিদর্শন';

  @override
  String get statistics_insightsTitle => 'অন্তর্দৃষ্টি';

  @override
  String get statistics_detailedAnalysisTitle => 'বিস্তারিত বিশ্লেষণ';

  @override
  String get statistics_categoryBreakdownSubtitle => 'ক্যাটাগরি ভাঙ্গন দেখুন';

  @override
  String get statistics_expenseTrendsTitle => 'ব্যয়ের ধারা';

  @override
  String get statistics_expenseTrendsSubtitle => 'গত ১২ মাসের ধারা';

  @override
  String get statistics_recentTransactionsSubtitle => 'গত ৫টি লেনদেন';

  @override
  String get statistics_categoryBreakdownTitle => 'ক্যাটাগরি ভাঙ্গন';

  @override
  String get statistics_recentTransactionsModalTitle => 'সাম্প্রতিক লেনদেন';

  @override
  String get transfer_screenTitle => 'টাকা Transfer করুন';

  @override
  String get transfer_resetTooltip => 'রিসেট';

  @override
  String get transfer_selectAccountsLabel => 'অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get transfer_fromLabel => 'থেকে';

  @override
  String get transfer_toLabel => 'এ';

  @override
  String get transfer_detailsLabel => 'TRANSFER বিবরণ';

  @override
  String get transfer_amountLabel => 'পরিমাণ';

  @override
  String get transfer_amountValidationError => 'বৈধ পরিমাণ লিখুন';

  @override
  String get transfer_dateLabel => 'তারিখ';

  @override
  String get transfer_noteLabel => 'নোট (ঐচ্ছিক)';

  @override
  String get transfer_buttonLabel => 'স্থানান্তর';

  @override
  String get transfer_updateButtonLabel => 'স্থানান্তর আপডেট করুন';

  @override
  String get transfer_errorLoadingAccounts => 'Accounts load হচ্ছে না';

  @override
  String get app_settings_themeModeModalTitle => 'থিম মোড';

  @override
  String get category_expenseLabel => 'ব্যয়';

  @override
  String get category_incomeLabel => 'আয়';

  @override
  String get category_addTitle => 'ক্যাটাগরি যোগ করুন';

  @override
  String get category_editTitle => 'ক্যাটাগরি সম্পাদনা করুন';

  @override
  String get category_tapToChangeIcon => 'আইকন পরিবর্তন করতে ট্যাপ করুন';

  @override
  String get category_nameLabel => 'ক্যাটাগরির নাম';

  @override
  String get category_nameRequired => 'আবশ্যক';

  @override
  String get category_typeLabel => 'ক্যাটাগরির ধরন';

  @override
  String get category_colorLabel => 'রঙ';

  @override
  String get category_tapToChangeColor => 'রঙ পরিবর্তন করতে ট্যাপ করুন';

  @override
  String get category_saveButton => 'ক্যাটাগরি সংরক্ষণ করুন';

  @override
  String get category_updateButton => 'ক্যাটাগরি আপডেট করুন';

  @override
  String get dashboard_incomeLabel => 'আয়';

  @override
  String get dashboard_spentLabel => 'খরচ হয়েছে';

  @override
  String get dashboard_noDataLabel => 'কোনো ডেটা নেই';

  @override
  String get dashboard_editLabel => 'সম্পাদনা';

  @override
  String get dashboard_archiveLabel => 'আর্কাইভ';

  @override
  String get currency_crore_short => 'কো';

  @override
  String get currency_lakh_short => 'ল';

  @override
  String get currency_thousand_short => 'হা';

  @override
  String common_errorText(Object error) {
    return 'ত্রুটি: $error';
  }

  @override
  String get statistics_expenseShort => 'ব্যয়';

  @override
  String get statistics_incomeShort => 'আয়';

  @override
  String get transaction_categoryFilter => 'ক্যাটাগরি ফিল্টার';

  @override
  String get transaction_dateFilter => 'তারিখ ফিল্টার';

  @override
  String get transaction_allCategories => 'সব ক্যাটাগরি';

  @override
  String get transaction_applyFilters => 'ফিল্টার প্রয়োগ করুন';

  @override
  String get sms_selectTransactions => 'লেনদেন নির্বাচন করুন';

  @override
  String get common_addLabel => 'যোগ করুন';

  @override
  String get dashboard_removeLabel => 'সরান';

  @override
  String get dashboard_viewAllLabel => 'সব দেখুন';

  @override
  String get common_noAccountsYet => 'অভী পর্যন্ত কোনো অ্যাকাউন্ট নেই';

  @override
  String get common_loading => 'লোড হচ্ছে...';

  @override
  String get common_editLabel => 'সম্পাদনা';

  @override
  String get common_deleteLabel => 'মুছে ফেলুন';

  @override
  String get common_fromLabel => 'থেকে';

  @override
  String get common_toLabel => 'এ';

  @override
  String get theme_chooseThemeTitle => 'থিম নির্বাচন করুন';

  @override
  String get theme_applyThemeLabel => 'থিম প্রয়োগ করুন';

  @override
  String get theme_themeAppliedMessage => 'থিম প্রয়োগ করা হয়েছে!';

  @override
  String get backup_backupRestoreTitle => 'ব্যাকআপ ও রিস্টোর';

  @override
  String get backup_backupDataTitle => 'ডেটা ব্যাকআপ করুন';

  @override
  String get backup_backupDataSubtitle => 'সব ডেটাবেস ও সেটিংস এক্সপোর্ট করুন';

  @override
  String get backup_restoreBackupTitle => 'ব্যাকআপ রিস্টোর করুন';

  @override
  String get backup_restoreBackupSubtitle => 'ডেটাবেস ও সেটিংস আমদানি করুন';

  @override
  String get backup_includeAttachmentsTitle =>
      'অ্যাটাচমেন্ট অন্তর্ভুক্ত করবেন?';

  @override
  String get backup_includeAttachmentsMessage =>
      'ব্যাকআপে রসিদের ছবি অন্তর্ভুক্ত করবেন? এটি ফাইলের আকার বাড়়াবে।';

  @override
  String get backup_yesLabel => 'হ্যাঁ';

  @override
  String get backup_noLabel => 'না';

  @override
  String get backup_completedMessage => 'ব্যাকআপ সম্পন্ন';

  @override
  String get backup_restoreSuccessMessage => 'রিস্টোর সফল';

  @override
  String backup_lastBackupLabel(Object date) {
    return 'শেষ ব্যাকআপ: $date';
  }

  @override
  String get backup_noBackupFoundLabel => 'কোনো ব্যাকআপ পাওয়া যায়নি';

  @override
  String get categories_manageCategoriesTitle => 'ক্যাটাগরি পরিচালনা করুন';

  @override
  String get categories_noCategoriesFound => 'কোনো ক্যাটাগরি পাওয়া যায়নি।';

  @override
  String categories_transactionCount(Object count, Object plural) {
    return '$countটি লেনদেন$plural';
  }

  @override
  String get categories_addCategoryLabel => 'ক্যাটাগরি যোগ করুন';

  @override
  String get categories_deleteCategoryTitle => 'ক্যাটাগরি মুছে ফেলুন';

  @override
  String get categories_deleteCategoryMessage =>
      'আপনি কি নিশ্চিত এই ক্যাটাগরি মুছে ফেলতে চান?\\nসব সংশ্লিষ্ট লেনদেনও সরিয়ে দেওয়া হবে।';

  @override
  String get categories_categoryDeletedMessage =>
      'ক্যাটাগরি ও এর লেনদেন মুছে দেওয়া হয়েছে';

  @override
  String get accounts_manageAccountsTitle => 'অ্যাকাউন্ট পরিচালনা করুন';

  @override
  String get accounts_noAccountsAddedYet =>
      'অভী পর্যন্ত কোনো অ্যাকাউন্ট যোগ করা হয়নি';

  @override
  String get accounts_addAccountLabel => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get accounts_deleteAccountTitle => 'অ্যাকাউন্ট মুছে ফেলুন';

  @override
  String accounts_deleteAccountMessage(Object accountName) {
    return 'আপনি কি নিশ্চিত \"$accountName\" মুছে ফেলতে চান?';
  }

  @override
  String get accounts_archiveAccountTitle => 'অ্যাকাউন্ট আর্কাইভ করুন';

  @override
  String accounts_archiveAccountMessage(Object accountName) {
    return 'আপনি কি নিশ্চিত \"$accountName\" আর্কাইভ করতে চান?';
  }

  @override
  String get accounts_cancelLabel => 'বাতিল করুন';

  @override
  String get accounts_archiveLabel => 'আর্কাইভ';

  @override
  String accounts_accountArchivedMessage(Object accountName) {
    return '\"$accountName\" আর্কাইভ করা হয়েছে';
  }

  @override
  String get accounts_atLeastOneAccountRequired =>
      'চালু রাখতে কমপক্ষে ১টি অ্যাকাউন্ট প্রয়োজন';

  @override
  String get transaction_tripLabel => 'ভ্রমণ';

  @override
  String get transaction_tripPartOfMessage =>
      'এই লেনদেন নিচের ভ্রমণ(গুলি)র অংশ';

  @override
  String get sms_autoAddTooltip => 'স্বয়ংক্রিয় যোগ';

  @override
  String get sms_clearAllTooltip => 'সব সাফ করুন';

  @override
  String get sms_importedFromSmsDescription => 'SMS থেকে আমদানি করা';

  @override
  String get sms_selectAtLeastOneMessage =>
      'অনুগ্রহ করে কমপক্ষে একটি SMS নির্বাচন করুন';

  @override
  String get dashboard_allTimeLabel => 'সব সময়';

  @override
  String get transaction_editTransactionTitle => 'লেনদেন সম্পাদনা করুন';

  @override
  String get transaction_dateLabel => 'তারিখ';

  @override
  String get transaction_addNoteHint => 'একটি নোট যোগ করুন';

  @override
  String get transaction_enterValidAmountError =>
      'অনুগ্রহ করে একটি বৈধ পরিমাণ লিখুন।';

  @override
  String get sms_noPendingTransactions => 'কোনো মুলতুবি লেনদেন নেই';

  @override
  String get sms_approveLabel => 'অনুমোদন';

  @override
  String get sms_approveTransactionTitle => 'লেনদেন অনুমোদন করুন';

  @override
  String get onboard_SmartSmsTracking => 'Smart SMS Tracking';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'Bank SMS থেকে transactions নিজে থেকেই ধরা আর import হবে।';

  @override
  String get onboard_InsightsAndAnalytics => 'Insights ও Analytics';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'Charts, trends আর smart insights দিয়ে খরচের অভ্যাস বুঝুন।';

  @override
  String get onboard_SecureAndPrivate => 'Safe ও Private';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'Data আপনার phone-এই থাকে। কোনো cloud নেই, tracking নেই।';

  @override
  String get onboard_SmartAutoTracking => 'Smart Auto Tracking';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Bank notifications থেকে transactions নিজে থেকেই ধরা আর import হবে।';

  @override
  String get nav_activity => 'কার্যকলাপ';

  @override
  String get nav_manage => 'পরিচালনা';

  @override
  String get nav_insights => 'বিশ্লেষণ';

  @override
  String get common_save => 'সেভ করুন';

  @override
  String get common_cancel => 'বাতিল';

  @override
  String get common_next => 'পরেরটা';

  @override
  String get common_back => 'পেছনে';

  @override
  String get common_undo => 'ফিরিয়ে আনুন';

  @override
  String get common_delete => 'মুছুন';

  @override
  String get common_edit => 'সম্পাদনা';

  @override
  String get common_add => 'যোগ করুন';

  @override
  String get common_done => 'হয়ে গেছে';

  @override
  String get common_close => 'বন্ধ';

  @override
  String get common_confirm => 'নিশ্চিত';

  @override
  String get common_archive => 'আর্কাইভ';

  @override
  String get common_create => 'তৈরি করুন';

  @override
  String get common_update => 'আপডেট';

  @override
  String get common_remove => 'সরান';

  @override
  String get common_search => 'খুঁজুন';

  @override
  String get common_filter => 'ফিল্টার';

  @override
  String get common_reset => 'রিসেট';

  @override
  String get common_apply => 'প্রযোগ';

  @override
  String get common_yes => 'হ্যাঁ';

  @override
  String get common_no => 'না';

  @override
  String get common_ok => 'ঠিক আছে';

  @override
  String get common_retry => 'পুনরায়';

  @override
  String get common_noData => 'কোনো তথ্য নেই';

  @override
  String get common_error => 'কিছু একটা গণ্ডগোল হয়েছে';

  @override
  String get common_required => 'আবশ্যক';

  @override
  String get title_budgets => 'বাজেট';

  @override
  String get title_goals => 'Goals';

  @override
  String get title_bills => 'বিল';

  @override
  String get title_groups => 'গ্রুপ';

  @override
  String get title_trips => 'ভ্রমণ';

  @override
  String get title_shared => 'ভাগাভাগি';

  @override
  String get title_achievements => 'অর্জন';

  @override
  String get title_notifications => 'বিজ্ঞপ্তি';

  @override
  String get title_appearance => 'চেহারা';

  @override
  String get title_currency => 'মুদ্রা';

  @override
  String get title_security => 'নিরাপত্তা';

  @override
  String get title_about => 'সম্পর্কে';

  @override
  String get title_analytics => 'বিশ্লেষণ';

  @override
  String get title_netWorth => 'মোট সম্পদ';

  @override
  String get title_financialHealth => 'আর্থিক স্বাস্থ্য';

  @override
  String get title_spendingPersonality => 'খরচের ধরন';

  @override
  String get title_monthlyRecap => 'মাসিক সারসংক্ষেপ';

  @override
  String get title_compareMonths => 'মাসের তুলনা';

  @override
  String get title_smsImport => 'SMS আমদানি';

  @override
  String get title_backupShare => 'ব্যাকআপ ও শেয়ার';

  @override
  String get title_exchangeRates => 'বিনিময় হার';

  @override
  String get title_recurringTransactions => 'পুনরাবৃত্তি লেনদেন';

  @override
  String get title_billControlCenter => 'বিল নিয়ন্ত্রণ কেন্দ্র';

  @override
  String get title_plugins => 'প্লাগইন';

  @override
  String get title_editCategory => 'শ্রেণী সম্পাদনা';

  @override
  String get title_allCategories => 'সব শ্রেণী';

  @override
  String get title_exportOptions => 'রপ্তানি বিকল্প';

  @override
  String get title_dashboardLayout => 'ড্যাশবোর্ড লেআউট';

  @override
  String get section_activeMoney => 'সক্রিয় অর্থ';

  @override
  String get section_planning => 'পরিকল্পনা';

  @override
  String get section_insights => 'অন্তর্দৃষ্টি';

  @override
  String get section_coreSettings => 'মূল সেটিংস';

  @override
  String get section_appData => 'অ্যাপ ও ডেটা';

  @override
  String get section_appearance => 'চেহারা';

  @override
  String get section_advanced => 'উন্নত';

  @override
  String get section_supportLegal => 'সহায়তা ও আইন';

  @override
  String get section_active => 'সক্রিয়';

  @override
  String get section_ongoing => 'চলমান';

  @override
  String get section_archive => 'আর্কাইভ';

  @override
  String get label_income => 'আয়';

  @override
  String get label_expense => 'খরচ';

  @override
  String get label_balance => 'ব্যালেন্স';

  @override
  String get label_savings => 'সঞ্চয়';

  @override
  String get label_total => 'মোট';

  @override
  String get label_amount => 'পরিমাণ';

  @override
  String get label_date => 'তারিখ';

  @override
  String get label_category => 'শ্রেণী';

  @override
  String get label_account => 'অ্যাকাউন্ট';

  @override
  String get label_description => 'বিবরণ';

  @override
  String get label_type => 'ধরন';

  @override
  String get label_transfer => 'ট্রান্সফার';

  @override
  String get label_from => 'থেকে';

  @override
  String get label_to => 'তে';

  @override
  String get label_all => 'সব';

  @override
  String get label_today => 'আজ';

  @override
  String get label_yesterday => 'গতকাল';

  @override
  String get label_thisWeek => 'এই সপ্তাহ';

  @override
  String get label_thisMonth => 'এই মাস';

  @override
  String get label_thisYear => 'এই বছর';

  @override
  String get label_custom => 'কাস্টম';

  @override
  String get label_daily => 'দৈনিক';

  @override
  String get label_weekly => 'সাপ্তাহিক';

  @override
  String get label_monthly => 'মাসিক';

  @override
  String get label_yearly => 'বার্ষিক';

  @override
  String get label_none => 'কিছু নেই';

  @override
  String get label_frequency => 'Frequency';

  @override
  String get label_repeatEvery => 'প্রতি';

  @override
  String get label_days => 'দিন';

  @override
  String get label_weeks => 'সপ্তাহ';

  @override
  String get label_months => 'মাস';

  @override
  String get label_years => 'বছর';

  @override
  String get trip_expenses => 'খরচ';

  @override
  String get trip_settlements => 'নিষ্পত্তি';

  @override
  String get trip_balances => 'বাকি টাকা';

  @override
  String get trip_report => 'রিপোর্ট';

  @override
  String get trip_createTrip => 'ভ্রমণ তৈরি করুন';

  @override
  String get trip_createGroup => 'ভাগাভাগি গ্রুপ তৈরি করুন';

  @override
  String get trip_editTrip => 'ভ্রমণ সম্পাদনা';

  @override
  String get trip_editGroup => 'গ্রুপ সম্পাদনা';

  @override
  String get trip_archiveTrip => 'ভ্রমণ আর্কাইভ';

  @override
  String get trip_archiveGroup => 'গ্রুপ আর্কাইভ';

  @override
  String get trip_allSettled => 'সব মিটে গেছে!';

  @override
  String get trip_archiveToSettle => 'নিষ্পত্তির জন্য আর্কাইভ করুন';

  @override
  String get trip_trackTravel => 'Travel খরচ dates ও budget সহ track করুন';

  @override
  String get trip_splitBills => 'বন্ধুদের সাথে bill split করুন';

  @override
  String get trip_live => 'লাইভ';

  @override
  String get budget_spendingLimits => 'খরচের সীমা';

  @override
  String get budget_savingsProgress => 'সঞ্চয় অগ্রগতি';

  @override
  String get budget_upcomingRecurring => 'আগামী ও পুনরাবৃত্তি';

  @override
  String get budget_tripsAndSplits => 'Trips ও splits';

  @override
  String import_importing(int count) {
    return '$countটি লেনদেন আমদানি হচ্ছে...';
  }

  @override
  String get import_dontClose => 'App বন্ধ করবেন না';

  @override
  String get import_complete => 'Import হয়ে গেছে!';

  @override
  String get import_failed => 'Import হয়নি';

  @override
  String get import_imported => 'আমদানি হয়েছে';

  @override
  String get import_duplicatesSkipped => 'ডুপ্লিকেট বাদ দেওয়া হয়েছে';

  @override
  String get import_errorsSkipped => 'ত্রুটি/বাদ দেওয়া হয়েছে';

  @override
  String get import_categoriesCreated => 'শ্রেণী তৈরি হয়েছে';

  @override
  String get import_previewImport => 'আমদানি প্রিভিউ';

  @override
  String get recap_yourMonthAtGlance => 'এই মাসের হালচাল';

  @override
  String get recap_trackProgressOverTime => 'Progress track করুন';

  @override
  String recap_transactions(int count) {
    return '$countটি লেনদেন';
  }

  @override
  String get recap_downloadPdf => 'PDF ডাউনলোড';

  @override
  String get comparison_current => 'বর্তমান';

  @override
  String comparison_byDay(int day) {
    return 'দিন $day পর্যন্ত';
  }

  @override
  String get comparison_topCategories => 'শীর্ষ শ্রেণী';

  @override
  String get comparison_categoryImpact => 'শ্রেণী প্রভাব';

  @override
  String get comparison_dailySpendingPace => 'দৈনিক খরচের গতি';

  @override
  String comparison_projected(String amount) {
    return 'অনুমান: এই মাসে $amount খরচ হবে';
  }

  @override
  String get utility_customizeUtilities => 'উপযোগিতা কাস্টমাইজ';

  @override
  String get utility_addUtilities => 'উপযোগিতা যোগ করুন';

  @override
  String get utility_analyticsSubtitle => 'Health score, trends ও forecasts';

  @override
  String get utility_taxSubtitle => 'Income tax-এর আনুমানিক হিসাব';

  @override
  String get profile_accounts => 'অ্যাকাউন্ট';

  @override
  String get profile_manageAccounts => 'আপনার অ্যাকাউন্ট পরিচালনা করুন';

  @override
  String get profile_categories => 'শ্রেণী';

  @override
  String get profile_manageCategories => 'আপনার শ্রেণী পরিচালনা করুন';

  @override
  String get profile_language => 'ভাষা';

  @override
  String get profile_notifications => 'বিজ্ঞপ্তি';

  @override
  String get profile_dailyWeeklySummaries => 'দৈনিক ও সাপ্তাহিক সারসংক্ষেপ';

  @override
  String get profile_autoImport => 'অটো আমদানি';

  @override
  String get profile_autoImportDesc => 'Bank notifications থেকে auto import';

  @override
  String get profile_importExport => 'আমদানি ও রপ্তানি';

  @override
  String get profile_importExportDesc => 'Excel import ও export';

  @override
  String get profile_backupRestore => 'ব্যাকআপ ও পুনরুদ্ধার';

  @override
  String get profile_manageData => 'আপনার ডেটা পরিচালনা করুন';

  @override
  String get profile_themeDisplay => 'Theme, tone ও display';

  @override
  String get profile_customizeWidgets => 'Widgets ও cards customize করুন';

  @override
  String get profile_manageExtensions => 'এক্সটেনশন পরিচালনা';

  @override
  String get profile_helpSupport => 'সাহায্য ও সমর্থন';

  @override
  String get profile_faqs => 'FAQs ও feature guides';

  @override
  String get profile_aboutApp => 'অ্যাপ সম্পর্কে';

  @override
  String get profile_versionInfo => 'সংস্করণ ও তথ্য';

  @override
  String get profile_pinFingerprint => 'PIN বা ফিঙ্গারপ্রিন্ট';

  @override
  String get profile_upgradePro => 'Pro-তে আপগ্রেড';

  @override
  String get profile_unlimitedFeatures =>
      'Unlimited accounts, analytics ও আরও অনেক কিছু';

  @override
  String get profile_freeTier => 'ফ্রি প্ল্যান';

  @override
  String get profile_fullAccess => 'পূর্ণ অ্যাক্সেস';

  @override
  String get profile_proActive => 'Pro সক্রিয়';

  @override
  String get profile_yourAchievements => 'আপনার অর্জন';

  @override
  String get profile_bestStreak => 'সেরা স্ট্রিক';

  @override
  String get trips_active => 'সক্রিয়';

  @override
  String get trips_live => 'লাইভ';

  @override
  String get trips_allSettled => 'সব মিটে গেছে';

  @override
  String get tone_friendly_txnAdded =>
      'Done! Transaction save হয়ে গেছে ✨|বুঝেছি! সব note হয়ে গেছে 👍|Save হয়ে গেছে! আপনি track-এ আছেন ✨|Note হয়ে গেছে! আরেকটা track 📝';

  @override
  String get tone_friendly_txnUpdated =>
      'Update হয়ে গেছে! 👍|Changes save হয়ে গেছে! ✓|সব update! 👌';

  @override
  String get tone_friendly_txnDeleted =>
      'গেছে! Transaction remove 🗑️|Delete হয়ে গেছে! একটা কম|Remove! পরিষ্কার 🗑️';

  @override
  String get tone_friendly_txnFailed => 'Save হলো না, আবার try করবেন?';

  @override
  String get tone_friendly_enterAmount => 'কত ছিল? Amount দিন';

  @override
  String get tone_friendly_pickAccount => 'কোন account? একটা বেছে নিন';

  @override
  String get tone_friendly_pickCategory => 'কিসের জন্য ছিল? Category বেছে নিন';

  @override
  String get tone_friendly_fillAllFields => 'প্রায় হয়ে গেছে — সব fields ভরুন';

  @override
  String get tone_friendly_invalidAmount =>
      'এটা ঠিক লাগছে না — সঠিক amount দিন';

  @override
  String get tone_friendly_budgetCreated =>
      'Budget set! Track-এ থাকুন 💪|Budget lock! Planning ভালো হচ্ছে 💪|দারুণ! Budget ready 📊';

  @override
  String get tone_friendly_budgetUpdated => 'Budget update হয়ে গেছে!';

  @override
  String get tone_friendly_budgetDeleted => 'Budget সরিয়ে দেওয়া হয়েছে';

  @override
  String get tone_friendly_goalCreated =>
      'Goal set! আপনি পারবেন 🎯|নতুন goal! চলুন পূরণ করি 🎯|Goal lock! নজর রাখুন 🎯';

  @override
  String get tone_friendly_goalUpdated => 'Goal update হয়ে গেছে!';

  @override
  String get tone_friendly_goalDeleted => 'Goal সরিয়ে দেওয়া হয়েছে';

  @override
  String get tone_friendly_accountCreated => 'Account তৈরি হয়ে গেছে! 🏦';

  @override
  String get tone_friendly_billAdded => 'Bill track হচ্ছে! Remind করব 🔔';

  @override
  String get tone_friendly_billPaid =>
      'দারুণ, bill paid! ✅|Bill done! একটা tension কম ✅|Paid! স্বস্তি ✅';

  @override
  String get tone_friendly_backupSuccess =>
      'Backup হয়ে গেছে! Data safe আছে 🛡️';

  @override
  String get tone_friendly_restoreSuccess =>
      'Restore হয়ে গেছে! Welcome back 🎉';

  @override
  String get tone_friendly_noTransactions =>
      'এখনো কিছু নেই\nপ্রথম transaction দিয়ে শুরু করুন|এখন খালি\nTracking শুরু করুন — মাত্র এক sec|কোনো transaction নেই\nআপনার financial journey এখান থেকেই শুরু';

  @override
  String get tone_friendly_noBudgets =>
      'কোনো budget নেই\nএকটা বানান, spending track হবে';

  @override
  String get tone_friendly_noGoals =>
      'কোনো goal নেই\nবড় করে ভাবুন — প্রথম goal set করুন!';

  @override
  String get tone_friendly_genericError =>
      'কিছু একটা গণ্ডগোল হয়েছে। আবার try করবেন?';

  @override
  String get tone_friendly_smsImportEnabled =>
      'Auto import on! Transactions track হবে 📩';

  @override
  String get tone_friendly_dashboardAllCaughtUp =>
      'সব up to date! 🎉|কিছু pending নেই — মজা করুন! ✨|সব ঠিক আছে! দিনটা enjoy করুন 🎉';

  @override
  String get tone_friendly_dailySummaryEmpty =>
      'গতকাল কিছু record হয়নি — zero-spend win নাকি catch up-এর time!|গতকাল শান্ত দিন ছিল — wallet খুশি!|গতকাল কোনো transaction নেই — আজ fresh start!';

  @override
  String tone_friendly_streakMessage(int days) {
    return '$days দিনের streak! চালিয়ে যান! 🔥';
  }

  @override
  String tone_friendly_budgetExceededBy(String amount) {
    return 'Budget $amount বেশি হয়ে গেছে 😬';
  }

  @override
  String get tone_professional_txnAdded =>
      'Transaction record হয়ে গেছে।|Entry save হয়ে গেছে।|Transaction log হয়ে গেছে।';

  @override
  String get tone_professional_txnUpdated =>
      'Transaction update হয়ে গেছে।|Changes apply হয়ে গেছে।|Record update হয়ে গেছে।';

  @override
  String get tone_professional_txnDeleted =>
      'Transaction delete হয়ে গেছে।|Record remove হয়ে গেছে।|Entry delete হয়ে গেছে।';

  @override
  String get tone_professional_txnFailed =>
      'Transaction save হয়নি। আবার try করুন।';

  @override
  String get tone_professional_enterAmount => 'সঠিক amount দিন।';

  @override
  String get tone_professional_pickAccount => 'Account select করুন।';

  @override
  String get tone_professional_pickCategory => 'Category select করুন।';

  @override
  String get tone_professional_fillAllFields =>
      'সব প্রয়োজনীয় fields পূরণ করুন।';

  @override
  String get tone_professional_invalidAmount => 'ভুল amount দেওয়া হয়েছে।';

  @override
  String get tone_professional_budgetCreated =>
      'Budget তৈরি হয়ে গেছে।|Budget configure হয়ে গেছে।|নতুন budget active আছে।';

  @override
  String get tone_professional_budgetUpdated => 'Budget update হয়ে গেছে।';

  @override
  String get tone_professional_budgetDeleted => 'Budget delete হয়ে গেছে।';

  @override
  String get tone_professional_goalCreated =>
      'Goal তৈরি হয়ে গেছে।|Savings goal configure হয়ে গেছে।|নতুন goal active আছে।';

  @override
  String get tone_professional_goalUpdated => 'Goal update হয়ে গেছে।';

  @override
  String get tone_professional_goalDeleted => 'Goal delete হয়ে গেছে।';

  @override
  String get tone_professional_accountCreated => 'Account তৈরি হয়ে গেছে।';

  @override
  String get tone_professional_billAdded =>
      'Bill add হয়ে গেছে। Remind করা হবে।';

  @override
  String get tone_professional_billPaid =>
      'Bill paid mark হয়ে গেছে।|Payment record হয়ে গেছে।|Bill settle হয়ে গেছে।';

  @override
  String get tone_professional_backupSuccess => 'Backup সম্পন্ন হয়েছে।';

  @override
  String get tone_professional_restoreSuccess => 'Data restore হয়ে গেছে।';

  @override
  String get tone_professional_noTransactions =>
      'কোনো transaction record নেই।\nপ্রথম entry দিন।|কোনো record নেই।\nTransaction দিয়ে শুরু করুন।|Transaction history খালি।\nRecording শুরু করুন।';

  @override
  String get tone_professional_noBudgets => 'কোনো budget configure নেই।';

  @override
  String get tone_professional_noGoals => 'কোনো goal set নেই।';

  @override
  String get tone_professional_genericError => 'Error হয়েছে।';

  @override
  String get tone_professional_smsImportEnabled => 'Auto-import on হয়ে গেছে।';

  @override
  String get tone_professional_dashboardAllCaughtUp =>
      'সব up to date আছে।|কোনো pending action নেই।|সব current আছে।';

  @override
  String get tone_professional_dailySummaryEmpty =>
      'গতকাল কোনো transaction record হয়নি।|গতকাল কোনো activity হয়নি।|আগের দিন কোনো entry নেই।';

  @override
  String tone_professional_streakMessage(int days) {
    return 'টানা $days দিন tracking।';
  }

  @override
  String tone_professional_budgetExceededBy(String amount) {
    return 'Budget $amount exceed হয়ে গেছে।';
  }

  @override
  String get tone_motivational_txnAdded =>
      'দারুণ! Transaction save হয়ে গেছে! 💪|Log হয়ে গেছে! আপনি থামছেন না 💪|আরেকটা track! Momentum রাখুন! ✨|Save! প্রতিটা entry এক ধাপ এগিয়ে! 🚀';

  @override
  String get tone_motivational_txnUpdated =>
      'ভালো update! Sharp থাকুন! ✨|Update! Precision matters! ✨|Changes save! আপনি এটার উপর আছেন! 👍';

  @override
  String get tone_motivational_txnDeleted =>
      'পরিষ্কার! একটা tension কম|Remove! জিনিস clean রাখুন! 💪|গেছে! যেটা দরকার সেটায় focus';

  @override
  String get tone_motivational_txnFailed => 'হলো না — আরেকবার try দিন!';

  @override
  String get tone_motivational_enterAmount =>
      'প্রতিটা টাকা count হয় — amount দিন!';

  @override
  String get tone_motivational_pickAccount =>
      'Account বেছে নিন, organized থাকুন!';

  @override
  String get tone_motivational_pickCategory =>
      'Category দিন — পরে নিজেকে thank করবেন!';

  @override
  String get tone_motivational_fillAllFields => 'প্রায় হয়ে গেছে! সব ভরুন';

  @override
  String get tone_motivational_invalidAmount =>
      'এই amount ঠিক লাগছে না — আবার try!';

  @override
  String get tone_motivational_budgetCreated =>
      'Smart move! Budget set! 💪|Budget lock! Control আপনার হাতে! 💪|Discipline! Budget ready! 📊';

  @override
  String get tone_motivational_budgetUpdated =>
      'Budget adjust — flexible থাকুন!';

  @override
  String get tone_motivational_budgetDeleted => 'Budget সরিয়ে দেওয়া হয়েছে';

  @override
  String get tone_motivational_goalCreated =>
      'Ambition! Goal set! 🎯|বড় স্বপ্ন এখান থেকেই! Goal lock! 🎯|এই spirit! নতুন goal ready! 🚀';

  @override
  String get tone_motivational_goalUpdated => 'Goal refine — push করতে থাকুন!';

  @override
  String get tone_motivational_goalDeleted =>
      'Goal সরানো হলো — নতুন priorities, নতুন plans';

  @override
  String get tone_motivational_accountCreated =>
      'Account তৈরি! Organized হচ্ছেন! 🏦';

  @override
  String get tone_motivational_billAdded => 'Bill track! আপনি এগিয়ে আছেন! 🔔';

  @override
  String get tone_motivational_billPaid =>
      'Bill paid! একটা tension কম! ✅|Crush করে দিলেন! Bill done! ✅|Paid! Game-এর আগে! 💪';

  @override
  String get tone_motivational_backupSuccess =>
      'Backup হয়ে গেছে! Progress safe! 🛡️';

  @override
  String get tone_motivational_restoreSuccess => 'Restore! আবার track-এ! 🎉';

  @override
  String get tone_motivational_noTransactions =>
      'Fresh start! 🌟\nপ্রথম transaction দিন — প্রতিটা journey এক পা দিয়ে শুরু|খালি slate! 🌟\nপ্রথম entry wait করছে — চলুন!|এখনো কিছু নেই! 💪\nএকটা transaction আর আপনি রাস্তায়!';

  @override
  String get tone_motivational_noBudgets =>
      'কোনো budget নেই\nএকটা বানান — future self thank করবে! 💪';

  @override
  String get tone_motivational_noGoals =>
      'কোনো goal নেই\nবড় করে ভাবুন — প্রথম goal set করুন! 🎯';

  @override
  String get tone_motivational_genericError =>
      'কিছু গণ্ডগোল হয়েছে — আবার try!';

  @override
  String get tone_motivational_smsImportEnabled =>
      'Auto-import on! Finances নিজে থেকে track হবে! 📩';

  @override
  String get tone_motivational_dashboardAllCaughtUp =>
      'সব caught up — game-এর আগে! 🏆|কিছু pending নেই — top-এ আছেন 💪|All clear! এই energy রাখুন 🏆';

  @override
  String get tone_motivational_dailySummaryEmpty =>
      'গতকাল zero spend — wallet খুশি! ✨|গতকাল কিছু খরচ হয়নি — willpower! 💪|No-spend day! এটা win! 🏆';

  @override
  String tone_motivational_streakMessage(int days) {
    return '$days দিনের streak! থামানো যাবে না! 🔥';
  }

  @override
  String tone_motivational_budgetExceededBy(String amount) {
    return '$amount বেশি — course correct করতে পারবেন! 💪';
  }

  @override
  String get tone_calm_txnAdded =>
      'Note হয়ে গেছে।|Record হয়ে গেছে।|চুপচাপ save।';

  @override
  String get tone_calm_txnUpdated => 'Update।|Adjust।|Changes save।';

  @override
  String get tone_calm_txnDeleted =>
      'ছেড়ে দেওয়া হলো।|সরিয়ে দেওয়া হলো।|যেতে দেওয়া হলো।';

  @override
  String get tone_calm_txnFailed => 'হলো না। আরেকবার।';

  @override
  String get tone_calm_enterAmount => 'Amount দরকার।';

  @override
  String get tone_calm_pickAccount => 'এটা কোথায় belongs, বেছে নিন।';

  @override
  String get tone_calm_pickCategory => 'এটাকে একটা purpose দিন।';

  @override
  String get tone_calm_fillAllFields => 'কিছু জিনিস এখনো খালি।';

  @override
  String get tone_calm_invalidAmount => 'Amount ঠিক করতে হবে।';

  @override
  String get tone_calm_budgetCreated =>
      'সীমা ঠিক হলো।|Budget তৈরি।|Limits set।';

  @override
  String get tone_calm_budgetUpdated => 'Adjust হয়ে গেছে।';

  @override
  String get tone_calm_budgetDeleted => 'ছেড়ে দেওয়া হলো।';

  @override
  String get tone_calm_goalCreated => 'ইচ্ছা ঠিক হলো।|নতুন দিক।|Goal বোনা হলো।';

  @override
  String get tone_calm_goalUpdated => 'Refine হয়ে গেছে।';

  @override
  String get tone_calm_goalDeleted => 'ছেড়ে দেওয়া হলো।';

  @override
  String get tone_calm_accountCreated => 'Account খোলা হলো।';

  @override
  String get tone_calm_billAdded => 'Note হয়ে গেছে। Remind করব।';

  @override
  String get tone_calm_billPaid =>
      'Settle হয়ে গেছে।|Paid। একটা কম।|হয়ে গেছে। শান্তি।';

  @override
  String get tone_calm_backupSuccess => 'নিরাপদে রাখা হলো।';

  @override
  String get tone_calm_restoreSuccess => 'Restore হয়ে গেছে। Welcome back।';

  @override
  String get tone_calm_noTransactions =>
      'পরিষ্কার slate।\nতৈরি হলে শুরু করুন।|এখনো কিছু নেই।\nআস্তে আস্তে শুরু করুন।|খালি।\nনতুন শুরু অপেক্ষা করছে।';

  @override
  String get tone_calm_noBudgets => 'কোনো সীমা নেই।\nযখন ঠিক মনে হবে, বানান।';

  @override
  String get tone_calm_noGoals => 'কোনো ইচ্ছা নেই।\nতৈরি হলে set করুন।';

  @override
  String get tone_calm_genericError => 'কিছু বদলে গেছে। আবার try করুন।';

  @override
  String get tone_calm_smsImportEnabled => 'চুপচাপ transactions দেখছি।';

  @override
  String get tone_calm_dashboardAllCaughtUp =>
      'সব ঠিক আছে।|কিছু attention দরকার নেই।|সব শান্ত।';

  @override
  String get tone_calm_dailySummaryEmpty =>
      'শান্ত দিন। কিছু record হয়নি।|গতকাল স্থির ছিল। কোনো entry নেই।|কিছু খরচ হয়নি। বিশ্রামের দিন।';

  @override
  String tone_calm_streakMessage(int days) {
    return '$days দিন mindful tracking।';
  }

  @override
  String tone_calm_budgetExceededBy(String amount) {
    return '$amount বেশি। ভাবার সময়।';
  }

  @override
  String get tone_friendly_insightBillsDueSoon => 'মাথায় রাখুন — bills আসছে';

  @override
  String get tone_friendly_insightOverBudget => 'Budget পার হয়ে গেছে';

  @override
  String get tone_friendly_insightNearBudget => 'Budget-এর কাছাকাছি...';

  @override
  String get tone_friendly_insightOverspending => 'খরচ income-এর বেশি';

  @override
  String get tone_friendly_insightSpendingSpike => 'আজ খরচ বেশি হচ্ছে';

  @override
  String get tone_friendly_insightWeekendAlert => 'Weekend খরচ alert';

  @override
  String get tone_friendly_insightGetStarted => 'চলুন শুরু করি! 🚀';

  @override
  String get tone_friendly_insightGetStartedMessage =>
      'প্রথম transaction দিন — মাত্র এক sec';

  @override
  String tone_friendly_insightBillsDueMessage(int count) {
    return '$countটা bill(s) শীঘ্রই due, ভুলবেন না!';
  }

  @override
  String tone_friendly_insightOverBudgetMessage(int count) {
    return '$countটা budget(s) এই মাসে পার — একটু দেখুন';
  }

  @override
  String tone_friendly_insightNearBudgetMessage(int count) {
    return '$countটা budget(s) 80% পার — এখনো সময় আছে';
  }

  @override
  String tone_friendly_insightOverspendingMessage(String amount) {
    return 'এই মাসে income-এর চেয়ে $amount বেশি খরচ — একটু slow করুন';
  }

  @override
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today) {
    return 'রোজ $avg/day খরচ হয়। আজ ইতিমধ্যে $today।';
  }

  @override
  String tone_friendly_insightWeekendAlertMessage(String avg, String current) {
    return 'Weekend-এ সাধারণত $avg খরচ। এবার ইতিমধ্যে $current।';
  }

  @override
  String get tone_professional_insightBillsDueSoon => 'আগামী bills';

  @override
  String get tone_professional_insightOverBudget => 'Budget exceed';

  @override
  String get tone_professional_insightNearBudget => 'Budget limit-এর কাছে';

  @override
  String get tone_professional_insightOverspending => 'খরচ income-এর বেশি';

  @override
  String get tone_professional_insightSpendingSpike => 'আজ খরচ বেড়েছে';

  @override
  String get tone_professional_insightWeekendAlert => 'Weekend খরচ বেড়েছে';

  @override
  String get tone_professional_insightGetStarted => 'শুরু করুন';

  @override
  String get tone_professional_insightGetStartedMessage =>
      'Tracking শুরু করতে প্রথম transaction record করুন।';

  @override
  String tone_professional_insightBillsDueMessage(int count) {
    return '$countটা bill(s) কয়েক দিনের মধ্যে due।';
  }

  @override
  String tone_professional_insightOverBudgetMessage(int count) {
    return 'এই মাসে $countটা budget(s) exceed হয়েছে।';
  }

  @override
  String tone_professional_insightNearBudgetMessage(int count) {
    return '$countটা budget(s) 80%-এর উপরে।';
  }

  @override
  String tone_professional_insightOverspendingMessage(String amount) {
    return 'এই মাসে খরচ income-এর চেয়ে $amount বেশি।';
  }

  @override
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Daily average: $avg। আজ: $today।';
  }

  @override
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend average: $avg। এখন: $current।';
  }

  @override
  String get tone_motivational_insightBillsDueSoon => 'Bills আসছে! 📋';

  @override
  String get tone_motivational_insightOverBudget => 'Budget পার — ফিরে আসুন';

  @override
  String get tone_motivational_insightNearBudget => 'Limit-এর কাছে';

  @override
  String get tone_motivational_insightOverspending => 'খরচ income-এর বেশি';

  @override
  String get tone_motivational_insightSpendingSpike => 'আজ খরচ spike';

  @override
  String get tone_motivational_insightWeekendAlert => 'Weekend খরচ alert';

  @override
  String get tone_motivational_insightGetStarted => 'কিছু দারুণ বানাই! 🚀';

  @override
  String get tone_motivational_insightGetStartedMessage =>
      'প্রথম transaction দিন — মাত্র এক step!';

  @override
  String tone_motivational_insightBillsDueMessage(int count) {
    return '$countটা bill(s) শীঘ্রই due — এগিয়ে থাকুন!';
  }

  @override
  String tone_motivational_insightOverBudgetMessage(int count) {
    return '$countটা budget(s) exceed — course-correct করতে পারবেন!';
  }

  @override
  String tone_motivational_insightNearBudgetMessage(int count) {
    return '$countটা budget(s) 80% পার — আপনি পারবেন!';
  }

  @override
  String tone_motivational_insightOverspendingMessage(String amount) {
    return 'Income-এর চেয়ে $amount বেশি — ছোট adjustments বড় ফারাক আনে!';
  }

  @override
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'সাধারণত $avg/day। আজ $today — intentional থাকুন!';
  }

  @override
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend avg: $avg। এবার $current — aware থাকুন!';
  }

  @override
  String get tone_calm_insightBillsDueSoon => 'Bills আসছে';

  @override
  String get tone_calm_insightOverBudget => 'সীমা পার';

  @override
  String get tone_calm_insightNearBudget => 'সীমার কাছে';

  @override
  String get tone_calm_insightOverspending => 'খরচ আয়ের বেশি';

  @override
  String get tone_calm_insightSpendingSpike => 'ভারী দিন';

  @override
  String get tone_calm_insightWeekendAlert => 'Weekend খরচ';

  @override
  String get tone_calm_insightGetStarted => 'নতুন শুরু';

  @override
  String get tone_calm_insightGetStartedMessage =>
      'প্রথম transaction দিয়ে শুরু করুন।';

  @override
  String tone_calm_insightBillsDueMessage(int count) {
    return '$countটা bill(s) শীঘ্রই আসবে।';
  }

  @override
  String tone_calm_insightOverBudgetMessage(int count) {
    return '$countটা budget(s) পার। ভাবুন ও adjust করুন।';
  }

  @override
  String tone_calm_insightNearBudgetMessage(int count) {
    return '$countটা budget(s) 80% পার। সচেতন খরচ সাহায্য করে।';
  }

  @override
  String tone_calm_insightOverspendingMessage(String amount) {
    return 'আয়ের চেয়ে $amount বেশি খরচ। থামুন।';
  }

  @override
  String tone_calm_insightSpendingSpikeMessage(String avg, String today) {
    return 'সাধারণত $avg/day। আজ $today।';
  }

  @override
  String tone_calm_insightWeekendAlertMessage(String avg, String current) {
    return 'সাধারণত $avg। এই weekend $current।';
  }

  @override
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: এই মাসে $count বার, মোট $total — ছোট খরচও যোগ হয়';
  }

  @override
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s-এ avg $wAvg vs ${best}s-এ $bAvg — $saving বাঁচাতে পারেন';
  }

  @override
  String tone_professional_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $countটা transaction, মোট $total এই মাসে।';
  }

  @override
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s-এ avg $wAvg vs ${best}s-এ $bAvg। সম্ভাব্য সঞ্চয়: $saving।';
  }

  @override
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count বার, $total — ছোট জিত বড় ফারাক আনে!';
  }

  @override
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s-এ $wAvg vs ${best}s-এ $bAvg — $saving বাঁচাতে পারেন!';
  }

  @override
  String tone_calm_insightMoneyLeak(String category, int count, String total) {
    return '$category: $count বার, $total। ছোট ধারা নদী তৈরি করে।';
  }

  @override
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s: $wAvg। ${best}s: $bAvg। $saving রাখতে পারেন।';
  }

  @override
  String get tone_friendly_txnNotFound => 'Can\'t find that transaction';

  @override
  String get tone_friendly_futureDate => 'Pick today or earlier';

  @override
  String get tone_friendly_selectAccountAndCategory =>
      'Pick an account & category first';

  @override
  String get tone_friendly_addParticipant =>
      'Add at least one person to split with';

  @override
  String get tone_friendly_budgetExceededAdjust =>
      'You\'ve exceeded this budget. Maybe ease up a bit?';

  @override
  String get tone_friendly_budgetGreatDiscipline =>
      'Great discipline! You\'re well within your budget ✨';

  @override
  String get tone_friendly_comparisonSpentSame =>
      'Spending is about the same as last month — steady!';

  @override
  String get tone_friendly_accountUpdated => 'Account updated!';

  @override
  String get tone_friendly_accountDeleted => 'Account removed';

  @override
  String get tone_friendly_accountLocked =>
      'This account is locked — upgrade to Pro to use it 🔒';

  @override
  String get tone_friendly_categoryCreated => 'Category added!';

  @override
  String get tone_friendly_categoryDeleted => 'Category removed';

  @override
  String get tone_friendly_categoryNameRequired => 'Give it a name!';

  @override
  String get tone_friendly_billDeleted => 'Bill removed';

  @override
  String get tone_friendly_backupFailed => 'Backup didn\'t work — try again?';

  @override
  String get tone_friendly_restoreFailed =>
      'Restore failed — is the file okay?';

  @override
  String get tone_friendly_invalidBackupFile =>
      'That doesn\'t look like a valid backup file';

  @override
  String get tone_friendly_corruptBackup => 'This backup looks corrupted 😕';

  @override
  String get tone_friendly_settingsSaved => 'Saved! ✓';

  @override
  String get tone_friendly_reminderUpdated => 'Reminder updated ⏰';

  @override
  String get tone_friendly_biometricFailed =>
      'Authentication failed — try again';

  @override
  String get tone_friendly_incorrectPin => 'Wrong PIN — give it another shot';

  @override
  String get tone_friendly_notificationAccessDenied =>
      'Need notification access to auto-import transactions';

  @override
  String get tone_friendly_noBills =>
      'No bills tracked\\nAdd recurring bills so you never miss a payment';

  @override
  String get tone_friendly_noAccounts =>
      'No accounts yet\\nAdd one to start tracking';

  @override
  String get tone_friendly_noCategories => 'No categories yet';

  @override
  String get tone_friendly_noNotifications =>
      'All quiet here\\nNo notifications yet';

  @override
  String get tone_friendly_noData =>
      'Not enough data yet\\nKeep tracking to unlock insights';

  @override
  String get tone_friendly_noRecurring =>
      'No recurring transactions\\nAdd bills to auto-track them';

  @override
  String get tone_friendly_exportSuccess => 'Report exported! 📄';

  @override
  String get tone_friendly_purchaseFailed =>
      'Purchase didn\'t go through — try again?';

  @override
  String get tone_friendly_playNotAvailable =>
      'Google Play isn\'t available on this device';

  @override
  String get tone_friendly_deleteTitle => 'Are you sure?';

  @override
  String get tone_friendly_deleteCancel => 'Keep it';

  @override
  String get tone_friendly_deleteConfirm => 'Delete';

  @override
  String get tone_friendly_logoutTitle => 'Leaving already?';

  @override
  String get tone_friendly_logoutMessage =>
      'All your data will be cleared from this device.';

  @override
  String get tone_friendly_logoutConfirm => 'Logout';

  @override
  String get tone_friendly_currencyChanged => 'Base currency updated! 💱';

  @override
  String get tone_friendly_currencyChangeTitle => 'Change base currency?';

  @override
  String get tone_friendly_currencyChangeCancel => 'Keep it';

  @override
  String get tone_friendly_currencyPickerTitle => 'Choose Your Currency';

  @override
  String get tone_friendly_dashboardWelcomeBack =>
      'Welcome back! Let\'s see where you stand';

  @override
  String get tone_professional_txnNotFound => 'Transaction not found.';

  @override
  String get tone_professional_futureDate => 'Future dates are not permitted.';

  @override
  String get tone_professional_selectAccountAndCategory =>
      'Account and category are required.';

  @override
  String get tone_professional_addParticipant =>
      'At least one participant is required.';

  @override
  String get tone_professional_budgetExceededAdjust =>
      'Budget exceeded. Review spending or adjust the limit.';

  @override
  String get tone_professional_budgetGreatDiscipline =>
      'Well within budget. Good financial discipline.';

  @override
  String get tone_professional_comparisonSpentSame =>
      'Spending is consistent with last month.';

  @override
  String get tone_professional_accountUpdated => 'Account updated.';

  @override
  String get tone_professional_accountDeleted => 'Account removed.';

  @override
  String get tone_professional_accountLocked =>
      'Account locked. Pro subscription required.';

  @override
  String get tone_professional_categoryCreated => 'Category added.';

  @override
  String get tone_professional_categoryDeleted => 'Category removed.';

  @override
  String get tone_professional_categoryNameRequired =>
      'Category name is required.';

  @override
  String get tone_professional_billDeleted => 'Bill removed.';

  @override
  String get tone_professional_backupFailed =>
      'Backup failed. Please try again.';

  @override
  String get tone_professional_restoreFailed =>
      'Restore failed. Verify the backup file.';

  @override
  String get tone_professional_invalidBackupFile =>
      'Invalid backup file format.';

  @override
  String get tone_professional_corruptBackup => 'Backup file is corrupted.';

  @override
  String get tone_professional_settingsSaved => 'Settings saved.';

  @override
  String get tone_professional_reminderUpdated => 'Reminder time updated.';

  @override
  String get tone_professional_biometricFailed => 'Authentication failed.';

  @override
  String get tone_professional_incorrectPin => 'Incorrect PIN.';

  @override
  String get tone_professional_notificationAccessDenied =>
      'Notification access is required for auto-import.';

  @override
  String get tone_professional_noBills => 'No recurring bills.';

  @override
  String get tone_professional_noAccounts => 'No accounts configured.';

  @override
  String get tone_professional_noCategories => 'No categories defined.';

  @override
  String get tone_professional_noNotifications => 'No notifications.';

  @override
  String get tone_professional_noData =>
      'Insufficient data.\\nContinue recording transactions.';

  @override
  String get tone_professional_noRecurring =>
      'No recurring transactions configured.';

  @override
  String get tone_professional_exportSuccess => 'Report exported.';

  @override
  String get tone_professional_purchaseFailed =>
      'Purchase failed. Please retry.';

  @override
  String get tone_professional_playNotAvailable =>
      'Google Play Services unavailable.';

  @override
  String get tone_professional_deleteTitle => 'Confirm Deletion';

  @override
  String get tone_professional_deleteCancel => 'Cancel';

  @override
  String get tone_professional_deleteConfirm => 'Delete';

  @override
  String get tone_professional_logoutTitle => 'Confirm Logout';

  @override
  String get tone_professional_logoutMessage =>
      'All local data will be erased.';

  @override
  String get tone_professional_logoutConfirm => 'Logout';

  @override
  String get tone_professional_currencyChanged => 'Base currency updated.';

  @override
  String get tone_professional_currencyChangeTitle => 'Change Base Currency';

  @override
  String get tone_professional_currencyChangeCancel => 'Cancel';

  @override
  String get tone_professional_currencyPickerTitle => 'Select Currency';

  @override
  String get tone_professional_dashboardWelcomeBack =>
      'Welcome back. Here is your summary.';

  @override
  String get tone_motivational_txnNotFound =>
      'Can\'t find that one — it may have been removed';

  @override
  String get tone_motivational_futureDate =>
      'Let\'s stay in the present — pick today or earlier';

  @override
  String get tone_motivational_selectAccountAndCategory =>
      'Account & category first — you\'re almost done!';

  @override
  String get tone_motivational_addParticipant =>
      'Add at least one person to split with!';

  @override
  String get tone_motivational_budgetExceededAdjust =>
      'Over budget — but every day is a chance to reset! 💪';

  @override
  String get tone_motivational_budgetGreatDiscipline =>
      'Amazing discipline! You\'re way ahead! 🏆';

  @override
  String get tone_motivational_comparisonSpentSame =>
      'Holding steady! Consistent spending shows control 💪';

  @override
  String get tone_motivational_accountUpdated => 'Account updated!';

  @override
  String get tone_motivational_accountDeleted => 'Account removed';

  @override
  String get tone_motivational_accountLocked =>
      'This account is locked — Go Pro to unlock! 🔒';

  @override
  String get tone_motivational_categoryCreated => 'New category added!';

  @override
  String get tone_motivational_categoryDeleted => 'Category removed';

  @override
  String get tone_motivational_categoryNameRequired => 'Give it a name!';

  @override
  String get tone_motivational_billDeleted => 'Bill removed';

  @override
  String get tone_motivational_backupFailed =>
      'Backup didn\'t work — try again!';

  @override
  String get tone_motivational_restoreFailed =>
      'Restore failed — check the file and retry';

  @override
  String get tone_motivational_invalidBackupFile =>
      'That doesn\'t look like a valid backup';

  @override
  String get tone_motivational_corruptBackup => 'This backup seems damaged';

  @override
  String get tone_motivational_settingsSaved => 'Saved! ✓';

  @override
  String get tone_motivational_reminderUpdated => 'Reminder set! ⏰';

  @override
  String get tone_motivational_biometricFailed =>
      'Authentication failed — try again!';

  @override
  String get tone_motivational_incorrectPin =>
      'Wrong PIN — you\'ve got this, try again!';

  @override
  String get tone_motivational_notificationAccessDenied =>
      'Need notification access to auto-track transactions';

  @override
  String get tone_motivational_noBills =>
      'No bills tracked\\nStay ahead by adding your recurring bills';

  @override
  String get tone_motivational_noAccounts =>
      'No accounts yet\\nAdd one to start your financial journey!';

  @override
  String get tone_motivational_noCategories => 'No categories yet';

  @override
  String get tone_motivational_noNotifications =>
      'All clear!\\nNo notifications — you\'re on top of things';

  @override
  String get tone_motivational_noData =>
      'Keep going! 📈\\nMore data means better insights';

  @override
  String get tone_motivational_noRecurring =>
      'No recurring transactions\\nAutomate your bills to stay ahead!';

  @override
  String get tone_motivational_exportSuccess => 'Report exported! 📄';

  @override
  String get tone_motivational_purchaseFailed =>
      'Purchase didn\'t go through — try again!';

  @override
  String get tone_motivational_playNotAvailable =>
      'Google Play isn\'t available on this device';

  @override
  String get tone_motivational_deleteTitle => 'Are you sure?';

  @override
  String get tone_motivational_deleteCancel => 'Keep it';

  @override
  String get tone_motivational_deleteConfirm => 'Delete';

  @override
  String get tone_motivational_logoutTitle => 'Heading out?';

  @override
  String get tone_motivational_logoutMessage =>
      'All data on this device will be cleared.';

  @override
  String get tone_motivational_logoutConfirm => 'Logout';

  @override
  String get tone_motivational_currencyChanged =>
      'Currency switched! New chapter! 💱';

  @override
  String get tone_motivational_currencyChangeTitle => 'Ready to switch?';

  @override
  String get tone_motivational_currencyChangeCancel => 'Not yet';

  @override
  String get tone_motivational_currencyPickerTitle => 'Pick Your Currency! 🌍';

  @override
  String get tone_motivational_dashboardWelcomeBack =>
      'You\'re back! Let\'s keep the progress going! 🚀';

  @override
  String get tone_calm_txnNotFound => 'Not found. It may have moved on.';

  @override
  String get tone_calm_futureDate => 'Stay in the present.';

  @override
  String get tone_calm_selectAccountAndCategory =>
      'Account and category, please.';

  @override
  String get tone_calm_addParticipant => 'Add someone to share with.';

  @override
  String get tone_calm_budgetExceededAdjust =>
      'Past the boundary. Pause and reconsider.';

  @override
  String get tone_calm_budgetGreatDiscipline => 'Well within bounds. Peaceful.';

  @override
  String get tone_calm_comparisonSpentSame =>
      'Spending flows at the same pace.';

  @override
  String get tone_calm_accountUpdated => 'Adjusted.';

  @override
  String get tone_calm_accountDeleted => 'Closed.';

  @override
  String get tone_calm_accountLocked => 'This one is resting. Pro unlocks it.';

  @override
  String get tone_calm_categoryCreated => 'Added.';

  @override
  String get tone_calm_categoryDeleted => 'Removed.';

  @override
  String get tone_calm_categoryNameRequired => 'A name, please.';

  @override
  String get tone_calm_billDeleted => 'Released.';

  @override
  String get tone_calm_backupFailed => 'Couldn\'t save. Try again gently.';

  @override
  String get tone_calm_restoreFailed => 'Couldn\'t restore. Check the file.';

  @override
  String get tone_calm_invalidBackupFile => 'This file doesn\'t feel right.';

  @override
  String get tone_calm_corruptBackup => 'The file seems damaged.';

  @override
  String get tone_calm_settingsSaved => 'Saved.';

  @override
  String get tone_calm_reminderUpdated => 'Reminder adjusted.';

  @override
  String get tone_calm_biometricFailed => 'Not recognized. Try again.';

  @override
  String get tone_calm_incorrectPin => 'Not quite. Try again.';

  @override
  String get tone_calm_notificationAccessDenied =>
      'Permission needed for quiet tracking.';

  @override
  String get tone_calm_noBills => 'Nothing recurring.\\nPeaceful.';

  @override
  String get tone_calm_noAccounts => 'No accounts yet.\\nStart simply.';

  @override
  String get tone_calm_noCategories => 'No categories yet.';

  @override
  String get tone_calm_noNotifications => 'Silence.\\nNothing needs attention.';

  @override
  String get tone_calm_noData => 'Not enough yet.\\nIt will come with time.';

  @override
  String get tone_calm_noRecurring => 'Nothing recurring.\\nAdd when ready.';

  @override
  String get tone_calm_exportSuccess => 'Exported.';

  @override
  String get tone_calm_purchaseFailed =>
      'Purchase didn\'t complete. Try again.';

  @override
  String get tone_calm_playNotAvailable => 'Play Store not available here.';

  @override
  String get tone_calm_deleteTitle => 'Let go?';

  @override
  String get tone_calm_deleteCancel => 'Hold on';

  @override
  String get tone_calm_deleteConfirm => 'Release';

  @override
  String get tone_calm_logoutTitle => 'Moving on?';

  @override
  String get tone_calm_logoutMessage => 'Your data here will be cleared.';

  @override
  String get tone_calm_logoutConfirm => 'Leave';

  @override
  String get tone_calm_currencyChanged => 'Currency shifted.';

  @override
  String get tone_calm_currencyChangeTitle => 'A new currency?';

  @override
  String get tone_calm_currencyChangeCancel => 'Stay';

  @override
  String get tone_calm_currencyPickerTitle => 'Choose your currency';

  @override
  String get tone_calm_dashboardWelcomeBack => 'Welcome back.';

  @override
  String get notif_quietDayTitle => '📊 গতকাল শান্ত দিন ছিল';

  @override
  String get notif_heresYesterdayTitle => '📊 গতকালের হাল';

  @override
  String get notif_weekInReviewTitle => '📅 সপ্তাহের সারসংক্ষেপ';

  @override
  String get notif_yourWeekInReviewTitle => '📅 আপনার সপ্তাহের সারসংক্ষেপ';

  @override
  String get notif_niceOneTitle => '🏆 দারুণ!';

  @override
  String notif_streakDaysTitle(int days) {
    return '🔥 $days দিন একটানা!';
  }

  @override
  String notif_levelUpTitle(int level) {
    return '🎉 Level $level!';
  }

  @override
  String notif_budgetsOverLimitTitle(int count) {
    return '🚨 $countটি budget limit পার';
  }

  @override
  String notif_budgetsGettingTightTitle(int count) {
    return '⚠️ $countটি budget tight হচ্ছে';
  }

  @override
  String notif_billDueTitle(String name, String label) {
    return '📅 $name $label-এ দেয়';
  }

  @override
  String get notif_fundsGettingLowTitle => '📉 টাকা কমে যাচ্ছে';

  @override
  String notif_categoryCreepingUpTitle(String category) {
    return '💡 $category বাড়ছে';
  }

  @override
  String get notif_bigDayTitle => '📈 বড় দিন ছিল';

  @override
  String notif_smsFoundTitle(int count) {
    return '📱 $countটি SMS transaction পাওয়া গেছে';
  }

  @override
  String get notif_smallSpendsTitle => '💧 ছোট খরচ জমছে';

  @override
  String get notif_missYouTitle => '👋 আপনাকে মিস করছি';

  @override
  String notif_daysUntrackedTitle(int days) {
    return '📊 $days দিন untracked';
  }

  @override
  String notif_streakEndedTitle(int days) {
    return '💔 $days দিনের streak ভেঙেছে';
  }

  @override
  String get notif_fewDaysUntrackedTitle => '📊 কয়েকদিন untracked';

  @override
  String notif_budgetExceededBody(String name) {
    return '$name budget পার হয়ে গেছে — check করুন';
  }

  @override
  String notif_budgetExceededBodyMulti(String names) {
    return '$names budget পার হয়ে গেছে';
  }

  @override
  String notif_budgetWarningBody(String name) {
    return '$name limit-এর কাছাকাছি';
  }

  @override
  String notif_budgetWarningBodyMulti(String names) {
    return '$names limit-এর কাছাকাছি';
  }

  @override
  String notif_budgetWarningPctBody(String name, String pct) {
    return '$name: $pct% খরচ';
  }

  @override
  String notif_billPaidAutoTitle(String name) {
    return '✅ $name — auto-match হয়েছে';
  }

  @override
  String notif_billPaidRecordedTitle(String name) {
    return '✅ $name — record হয়েছে';
  }

  @override
  String get notif_smsLoggedTitle => '✅ Transaction save হয়েছে';

  @override
  String get notif_smsNeedsReviewTitle => '👀 Review করুন';

  @override
  String notif_smsLoggedBody(String amount, String sender) {
    return '$sender থেকে $amount — auto-save হয়েছে';
  }

  @override
  String notif_smsLoggedBodyNoAmount(String sender) {
    return '$sender থেকে — auto-save হয়েছে';
  }

  @override
  String notif_smsNeedsReviewBody(String sender) {
    return '$sender থেকে transaction — tap করে দেখুন';
  }

  @override
  String get notif_smsGotItTitle => '✅ হয়ে গেছে!';

  @override
  String get notif_smsAllCaughtUpTitle => '✅ সব হয়ে গেছে!';

  @override
  String get notif_smsAlmostThereTitle => '📋 প্রায় হয়ে গেছে!';

  @override
  String get notif_smsNeedHelpTitle => '👋 একটু help চাই!';

  @override
  String notif_streakOnLineTitle(int days) {
    return '🔥 $days দিনের streak দাঁড়ে!';
  }

  @override
  String get notif_quickActionTitle => '⚡ মাত্র 5 second-এর কাজ';

  @override
  String get notif_dailyReminderTitle => '📊 আপনার দিন numbers-এ';

  @override
  String get notif_dailyReminderBody => 'গতকাল কেমন ছিল — একটু দেখুন';

  @override
  String get notif_weeklyReminderTitle => '📅 সপ্তাহ শেষ';

  @override
  String get notif_weeklyReminderBody => 'সপ্তাহের হাল দেখুন — tap করুন';

  @override
  String get notif_goalStatusTitle => '🎯 Goal Status';

  @override
  String notif_goalStatusBody(int count, String name, String pct) {
    return 'আপনার $countটি goal active। $name $pct% complete!';
  }

  @override
  String notif_streakCountingTitle(int days) {
    return '🔥 $days দিন এবং counting!';
  }

  @override
  String notif_achievementBody(String title, int xp) {
    return '$title — +$xp XP পেলেন!';
  }

  @override
  String get notif_levelUpBody => 'Level up হয়েছে — চালিয়ে যান!';

  @override
  String get notif_streakMilestoneBody =>
      'দারুণ dedication — streak fire-এ আছে 🔥';

  @override
  String get notif_weeklyZeroBody => 'এই সপ্তাহে zero খরচ — impressive 💪';

  @override
  String get insight_moneyLeakTitle => 'চুপচাপ টাকা বেরিয়ে যাচ্ছে 💧';

  @override
  String insight_bestDayTitle(String day) {
    return '$day-তে সবচেয়ে বেশি খরচ হয়';
  }

  @override
  String get bills_howBillsWorkTitle => 'বিল কীভাবে কাজ করে';

  @override
  String get bills_howBillsWorkDesc =>
      'ভাড়া, subscription এবং utility-র মতো নিয়মিত বিল track করুন';

  @override
  String get bills_gotIt => 'বুঝেছি';

  @override
  String get bills_addBill => 'বিল যোগ করুন';

  @override
  String get bills_markAsPaid => 'পরিশোধিত';

  @override
  String get bills_deleteBill => 'বিল মুছুন';

  @override
  String get bills_addNewBill => 'নতুন বিল যোগ করুন';

  @override
  String get bills_billName => 'বিলের নাম';

  @override
  String get bills_amount => 'পরিমাণ';

  @override
  String get bills_frequency => 'পুনরাবৃত্তি';

  @override
  String get bills_monthly => 'মাসিক';

  @override
  String get bills_quarterly => 'ত্রৈমাসিক';

  @override
  String get bills_yearly => 'বার্ষিক';

  @override
  String get bills_dueDate => 'দেয় তারিখ';

  @override
  String get goal_deleteGoalTitle => 'Goal মুছবেন?';

  @override
  String get goal_editGoal => 'Goal সম্পাদনা';

  @override
  String get goal_deleteGoal => 'Goal মুছুন';

  @override
  String get goal_saved => 'সঞ্চিত';

  @override
  String get goal_target => 'লক্ষ্য';

  @override
  String get goal_quickDeposit => 'দ্রুত জমা';

  @override
  String get goal_targetDate => 'লক্ষ্য তারিখ';

  @override
  String get goal_milestones => 'মাইলফলক';

  @override
  String get goal_recentActivity => 'সাম্প্রতিক কার্যকলাপ';

  @override
  String get goal_addToGoal => 'Goal-এ যোগ করুন';

  @override
  String get goal_goalReached => 'Goal সম্পন্ন! 🎉';

  @override
  String get goal_whatsThisAbout => 'এই goal কিসের জন্য?';

  @override
  String get goal_icon => 'আইকন';

  @override
  String get goal_color => 'রঙ';

  @override
  String get dashboard_enableCards => 'Cards সক্রিয় করুন';

  @override
  String get recurring_fixedExpenses => 'নিয়মিত খরচ';

  @override
  String get goal_freePlanLimit => 'Free plan-এ ২টি goal। Pro-তে unlimited।';

  @override
  String get goal_editGoalTitle => 'Goal সম্পাদনা';

  @override
  String get goal_newGoalTitle => 'নতুন Goal';

  @override
  String get goal_yourGoal => 'আপনার Goal';

  @override
  String get goal_appearance => 'চেহারা';

  @override
  String get goal_goalName => 'Goal-এর নাম';

  @override
  String get goal_giveGoalName => 'আপনার goal-এর নাম দিন';

  @override
  String get goal_targetAmount => 'লক্ষ্য পরিমাণ';

  @override
  String get goal_enterValidTarget => 'সঠিক target পরিমাণ লিখুন';

  @override
  String get goal_alreadySaved => 'আগেই সঞ্চিত';

  @override
  String get goal_targetDateLabel => 'লক্ষ্য তারিখ';

  @override
  String get goal_setTargetDate => 'Target তারিখ সেট করুন (ঐচ্ছিক)';

  @override
  String get goal_smartInsight => 'Smart তথ্য';

  @override
  String get goal_onTrack => 'ঠিক চলছে';

  @override
  String get goal_onTrackDesc => 'এই goal সহজেই অর্জনযোগ্য 👍';

  @override
  String get goal_needsEffort => 'চেষ্টা দরকার';

  @override
  String get goal_needsEffortDesc => 'আরেকটু সঞ্চয় করতে হবে';

  @override
  String get goal_ambitious => 'উচ্চাকাঙ্ক্ষী';

  @override
  String get goal_ambitiousDesc => 'Deadline বাড়ানোর কথা ভাবুন';

  @override
  String get goal_addNote => 'নোট যোগ করুন (ঐচ্ছিক)';

  @override
  String get goal_note => 'নোট';

  @override
  String get goal_updateGoal => 'Goal আপডেট করুন';

  @override
  String get goal_createGoal => 'Goal তৈরি করুন';

  @override
  String get profile_developerMode => 'Developer Mode সক্রিয়! 🚀';

  @override
  String get profile_couldNotOpenLink => 'লিংক খোলা যায়নি';

  @override
  String get profile_about => 'সম্পর্কে';

  @override
  String get profile_unableToCheckUpdates => 'Updates check করা যায়নি';

  @override
  String get profile_openSourceLicenses => 'Open Source Licenses';

  @override
  String get account_totalValue => 'মোট মূল্য';

  @override
  String get account_gainLoss => 'লাভ/ক্ষতি';

  @override
  String get account_holdings => 'Holdings';

  @override
  String get account_addHolding => 'Holding যোগ করুন';

  @override
  String get account_addMissingTransaction => 'বাদ পড়া Transaction যোগ করুন';

  @override
  String get account_whatWasThisFor => 'এই transaction কিসের জন্য ছিল?';

  @override
  String get budget_used => 'ব্যবহৃত';

  @override
  String get budget_selectAtLeastOneTag => 'অন্তত একটি tag বেছে নিন';

  @override
  String get budget_over => 'বেশি';

  @override
  String get budget_left => 'বাকি';

  @override
  String get budget_breakdown => 'বিবরণ';

  @override
  String get budget_basicInfo => 'মৌলিক তথ্য';

  @override
  String get budget_duration => 'সময়কাল';

  @override
  String get budget_budgetType => 'Budget-এর ধরন';

  @override
  String get budget_selectType => 'ধরন বেছে নিন';

  @override
  String get budget_categoryAllocation => 'Category Allocation';

  @override
  String get budget_totalBudget => 'মোট Budget';

  @override
  String get budget_allocated => 'বরাদ্দ';

  @override
  String get budget_remaining => 'বাকি';

  @override
  String get budget_overBudget => 'Budget ছাড়িয়ে গেছে';

  @override
  String get budget_safeToSpend => 'খরচ করা যাবে';

  @override
  String get budget_startDate => 'শুরুর তারিখ';

  @override
  String get budget_endDate => 'শেষের তারিখ';

  @override
  String get budget_selectTags => 'Tags বেছে নিন';

  @override
  String get budget_tagInfo =>
      'বেছে নেওয়া tags-এর সব খরচ এই budget-এ গণনা হবে।';

  @override
  String get budget_noTags =>
      'এখনো কোনো tag নেই। আগে transactions-এ tags যোগ করুন।';

  @override
  String get budget_freePlanLimit =>
      'Free plan-এ 2টা budget বানানো যায়। আরো চাইলে Pro নিন।';

  @override
  String budget_daysRemaining(Object count) {
    return '$count দিন';
  }

  @override
  String get budget_delete => 'মুছুন';

  @override
  String get budget_emotionUnderControl => 'খরচ control-এ আছে 💪';

  @override
  String get budget_emotionHalfway => 'মাসের অর্ধেক পার ✨';

  @override
  String get budget_emotionAlmostThere => 'একটু সাবধান, নজর রাখুন ⚠️';

  @override
  String get budget_emotionExceeded => 'Budget ছাড়িয়ে গেছে, সামলান 🔴';

  @override
  String get budget_highlightLabel => 'নজর দিন';

  @override
  String get budget_overBudgetSection => 'Budget ছাড়িয়ে গেছে';

  @override
  String get budget_activeBudgets => 'Active budgets';

  @override
  String get budget_onTrackSection => 'ঠিক চলছে';

  @override
  String get budget_spendingPace => 'খরচের গতি';

  @override
  String budget_dailyActual(Object amount) {
    return '$amount/দিন খরচ';
  }

  @override
  String budget_dailyAllowed(Object amount) {
    return '$amount/দিন সীমা';
  }

  @override
  String get budget_stepNote0 =>
      'Budget-এর নাম দিন আর কত খরচ করতে চান সেট করুন।';

  @override
  String get budget_stepNote1 => 'Budget কতবার repeat হবে আর dates বেছে নিন।';

  @override
  String get budget_stepNote2 =>
      'কোন categories বা tags track করতে চান বেছে নিন।';

  @override
  String get budget_autoDistributed => 'auto';

  @override
  String budget_categoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি categories',
      one: '1টি category',
    );
    return '$_temp0';
  }

  @override
  String budget_tagsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি tags',
      one: '1টি tag',
    );
    return '$_temp0';
  }

  @override
  String get budget_typeCategoryWise => 'Category অনুসারে';

  @override
  String get budget_typeTagWise => 'Tag অনুসারে';

  @override
  String get budget_typeDayWise => 'প্রতিদিন';

  @override
  String get budget_typeFestival => 'উৎসব';

  @override
  String get budget_typeTravel => 'ভ্রমণ';

  @override
  String get budget_typeDescCategoryWise =>
      'নির্দিষ্ট categories-এর জন্য budget সেট করুন';

  @override
  String get budget_typeDescTagWise => 'নির্দিষ্ট tags-এর জন্য budget সেট করুন';

  @override
  String get budget_typeDescDayWise => 'প্রতিদিনের খরচ সীমা সেট করুন';

  @override
  String get budget_typeDescFestival => 'উৎসব ও events-এর জন্য budget';

  @override
  String get budget_typeDescTravel => 'ভ্রমণের খরচের জন্য budget';

  @override
  String get budget_reviewTitle => 'দেখে নিন ও Save করুন';

  @override
  String get budget_selectCategories => 'Categories বেছে নিন';

  @override
  String get budget_noActiveTrip =>
      'কোনো active trip নেই। Travel budget-এর জন্য আগে trip শুরু করুন।';

  @override
  String get budget_stepNote3 =>
      'Save করার আগে সব দেখে নিন। Edit করতে tap করুন।';

  @override
  String budget_categoryDeleteWarning(Object count) {
    return 'এই category $countটা budget-এ আছে। মুছলে budget tracking প্রভাবিত হবে।';
  }

  @override
  String get budget_invalidCategories =>
      'কিছু categories মুছে ফেলা হয়েছে। ঠিক করতে budget edit করুন।';

  @override
  String budget_pastBudgets(int count) {
    return '$countটি আগের budget';
  }

  @override
  String get category_categoryName => 'শ্রেণীর নাম';

  @override
  String get category_keywords => 'Keywords (কমা দিয়ে আলাদা)';

  @override
  String get category_noneTopLevel => 'কোনোটি নয় (শীর্ষ-স্তর)';

  @override
  String get common_searchCurrency => 'মুদ্রা খুঁজুন...';

  @override
  String get common_selectCategory => 'শ্রেণী বেছে নিন';

  @override
  String get common_noDescription => 'কোনো বিবরণ নেই';

  @override
  String get common_errors => 'ত্রুটি';

  @override
  String get dashboard_enableCardsDesc =>
      'আপনার আর্থিক সারসংক্ষেপ দেখতে Dashboard cards সক্রিয় করুন';

  @override
  String get dashboard_customizeDashboard => 'Dashboard customize করুন';

  @override
  String get dashboard_newToApp => 'Mudra Manager-এ নতুন?';

  @override
  String get dashboard_tapToExploreHelp => 'Help guide দেখতে ট্যাপ করুন';

  @override
  String get dashboard_tapToReviewTxn => 'Transactions review করতে ট্যাপ করুন';

  @override
  String get dashboard_autoImportPaused => 'Auto Import থেমে আছে';

  @override
  String get dashboard_enable => 'সক্রিয় করুন';

  @override
  String get dashboard_enableAutoImport => 'Auto Import সক্রিয় করুন';

  @override
  String get dashboard_autoTrackDesc =>
      'Bank notifications থেকে transactions auto-track করুন';

  @override
  String get profile_awesomeUser => 'দারুণ User';

  @override
  String get profile_logout => 'লগআউট';

  @override
  String get profile_proActiveLabel => 'Pro সক্রিয়';

  @override
  String get profile_freeTierLabel => 'Free Tier';

  @override
  String get profile_fullAccessLabel => 'পূর্ণ Access';

  @override
  String get profile_upgradeToProLabel => 'Pro-তে Upgrade করুন';

  @override
  String get profile_fullAccessEnjoy =>
      'পূর্ণ access — সব features উপভোগ করুন!';

  @override
  String profile_fullAccessDaysRemaining(int days) {
    return 'পূর্ণ access — $days দিন বাকি';
  }

  @override
  String profile_fullAccessEndsIn(int days) {
    return 'পূর্ণ access $days দিনে শেষ';
  }

  @override
  String get profile_trialEnded => 'Trial শেষ — সব features রাখতে upgrade করুন';

  @override
  String get profile_unlimitedDesc =>
      'Unlimited accounts, analytics এবং আরও অনেক কিছু';

  @override
  String get profile_expiredRenew => 'মেয়াদ শেষ — renew করতে ট্যাপ করুন';

  @override
  String get profile_expiresToday => 'আজ মেয়াদ শেষ';

  @override
  String get profile_renewsTomorrow => 'আগামীকাল renew হবে';

  @override
  String profile_renewsInDays(int days) {
    return '$days দিনে renew হবে';
  }

  @override
  String get profile_activeSubscription => 'সক্রিয় সদস্যতা';

  @override
  String get profile_unknown => 'অজানা';

  @override
  String get profile_accountsLabel => 'অ্যাকাউন্ট';

  @override
  String get profile_categoriesLabel => 'শ্রেণী';

  @override
  String get profile_budgetsLabel => 'বাজেট';

  @override
  String get profile_bestStreakLabel => 'সেরা Streak';

  @override
  String get profile_yourAchievementsLabel => 'আপনার অর্জন';

  @override
  String get profile_aboutMudra => 'Mudra Manager সম্পর্কে';

  @override
  String get profile_aboutMudraDesc =>
      'আপনার ব্যক্তিগত ফাইন্যান্স সঙ্গী। খরচ track করুন, budget সামলান';

  @override
  String get txnList_searchHint => 'Transactions খুঁজুন...';

  @override
  String get txnList_category => 'শ্রেণী';

  @override
  String get txnList_dateRange => 'তারিখ সীমা';

  @override
  String get txnList_tag => 'Tag';

  @override
  String get txnList_allTransactions => 'সব লেনদেন';

  @override
  String get txnList_tapStartEnd => 'শুরু এবং শেষ তারিখ ট্যাপ করুন';

  @override
  String get txnList_scrollToLoad => 'আরও লোড করতে scroll করুন';

  @override
  String get txnList_month => 'মাস';

  @override
  String get txnList_previousMonth => 'আগের মাস';

  @override
  String get txnList_resetToCurrentMonth => 'এই মাসে ফিরে যান';

  @override
  String get txnList_selectMonth => 'মাস বেছে নিন';

  @override
  String get txnList_nextMonth => 'পরের মাস';

  @override
  String get txnList_monthView => 'মাস দৃশ্য';

  @override
  String get txnList_subscriptionTagRemoved => 'Subscription tag সরানো হয়েছে';

  @override
  String get txnList_filterByTag => 'Tag দিয়ে filter করুন';

  @override
  String get txnList_noTagsYet =>
      'এখনো কোনো tag নেই। আগে transactions-এ tag যোগ করুন।';

  @override
  String get txnList_clear => 'মুছুন';

  @override
  String get txnList_filterOptions => 'Filter বিকল্প';

  @override
  String get txnList_transactionType => 'Transaction ধরন';

  @override
  String get txnList_allCategories => 'সব শ্রেণী';

  @override
  String get txnList_selectDateRange => 'তারিখ সীমা বেছে নিন';

  @override
  String get txnList_clearDateRange => 'তারিখ সীমা মুছুন';

  @override
  String get stats_today => 'আজ';

  @override
  String get stats_week => 'সপ্তাহ';

  @override
  String get stats_month => 'মাস';

  @override
  String get stats_year => 'বছর';

  @override
  String get stats_custom => 'কাস্টম';

  @override
  String get stats_unableToLoad => 'Statistics লোড করা যায়নি';

  @override
  String get stats_overview => 'সারসংক্ষেপ';

  @override
  String get stats_trends => 'প্রবণতা';

  @override
  String get stats_spendingByDay => 'দিন অনুযায়ী খরচ';

  @override
  String get stats_insights => 'তথ্য';

  @override
  String get stats_nextMonthForecast => 'পরের মাসের পূর্বাভাস';

  @override
  String get stats_topSpending => 'সবচেয়ে বেশি খরচ';

  @override
  String get stats_12MonthTrend => '12 মাসের Trend';

  @override
  String stats_trendUp(Object category, Object percent) {
    return '$category বাড়ছে — মোট খরচের $percent%';
  }

  @override
  String stats_trendDown(Object category) {
    return '$category এই মাসে কমেছে 📉';
  }

  @override
  String stats_topCategory(Object category, Object percent) {
    return '$category সবচেয়ে বেশি — $percent% খরচ';
  }

  @override
  String stats_weekendPeak(Object day) {
    return 'Weekend-এ বেশি খরচ — $day সবচেয়ে ভারী';
  }

  @override
  String stats_weekdayPeak(Object day) {
    return 'Weekday-এ বেশি খরচ — $day সবচেয়ে ভারী';
  }

  @override
  String stats_peakAndQuiet(Object peak, Object quiet) {
    return '$peak সবচেয়ে ভারী দিন, $quiet সবচেয়ে হালকা';
  }

  @override
  String get stats_categoryTrends => 'Category Trends';

  @override
  String get stats_spendingByTag => 'Tag অনুসারে খরচ';

  @override
  String get stats_netWorth => 'Net Worth';

  @override
  String get stats_savings => 'সঞ্চয়';

  @override
  String get stats_categoryImpact => 'CATEGORY প্রভাব';

  @override
  String get stats_income => 'আয়';

  @override
  String get stats_expense => 'খরচ';

  @override
  String get stats_net => 'নেট';

  @override
  String get stats_dailySpendingPace => 'দৈনিক খরচের গতি';

  @override
  String get stats_topCategories => 'শীর্ষ Categories';

  @override
  String stats_projectedThisMonth(Object amount) {
    return 'অনুমান: এই মাসে $amount';
  }

  @override
  String stats_byDay(Object day, Object amount, Object month) {
    return 'দিন $day পর্যন্ত: $month-এ $amount';
  }

  @override
  String get stats_steadyHeadline => 'স্থির চলছে';

  @override
  String get stats_steadyDetail => 'আপনার খরচ একসমান — এটা শৃঙ্খলা।';

  @override
  String get stats_doingGreatHeadline => 'অনেক ভালো চলছে 🌟';

  @override
  String get stats_spendingUpHeadline => 'নজর দিন — খরচ বাড়ছে';

  @override
  String get stats_downloadPdf => 'PDF Download করুন';

  @override
  String get stats_generating => 'তৈরি হচ্ছে...';

  @override
  String get recap_belowAvg => 'গড়ের নিচে';

  @override
  String get recap_aboveAvg => 'গড়ের উপরে';

  @override
  String get recap_recurring => 'Recurring';

  @override
  String get recap_oneTime => 'One-time';

  @override
  String get recap_recapTitle => 'Recap';

  @override
  String get notifSettings_dailySummary => 'দৈনিক সারসংক্ষেপ';

  @override
  String get notifSettings_weeklySummary => 'সাপ্তাহিক সারসংক্ষেপ';

  @override
  String get notifSettings_comeBackNudges => 'ফিরে আসার মনে করানো';

  @override
  String get notifSettings_streakReminder => 'Streak Reminder';

  @override
  String get notifSettings_smartAlerts => 'Smart Alerts';

  @override
  String get notifSettings_selectDay => 'দিন বেছে নিন';

  @override
  String get notifSettings_summariesDesc =>
      'সারসংক্ষেপে খরচ, আয়, শীর্ষ শ্রেণী এবং ব্যালেন্স দেখায়';

  @override
  String get notifSettings_reminderTime => 'Reminder-এর সময়';

  @override
  String get notifSettings_sendTestNotif => 'Test Notification পাঠান';

  @override
  String get notifSettings_testNotifSent => 'Test notification পাঠানো হয়েছে';

  @override
  String get notifSettings_dailyNudgeStreak =>
      'Streak ধরে রাখার দৈনিক মনে করানো';

  @override
  String get notifSettings_summaryDay => 'সারসংক্ষেপের দিন';

  @override
  String get notifSettings_gentleReminders => 'অ্যাপে ফিরে আসার মৃদু মনে করানো';

  @override
  String get notifSettings_budgetWarningsDesc =>
      'Budget সতর্কতা, খরচ spike, বিল reminder';

  @override
  String get notifSettings_localNotifDisclaimer =>
      'Notifications আপনার device-এ locally deliver হয়। কোনো data বাইরে যায় না।';

  @override
  String get smsImport_autoImport => 'Auto Import';

  @override
  String get smsImport_permissions => 'অনুমতি';

  @override
  String get smsImport_notifAccess => 'Notification Access';

  @override
  String get smsImport_notifAccessEnabled => 'Notification access সক্রিয়';

  @override
  String get smsImport_allowReadingNotif =>
      'Bank notifications পড়ার অনুমতি দিন';

  @override
  String get smsImport_autoDetectTxn =>
      'Notifications থেকে transactions auto-detect করুন';

  @override
  String get smsImport_privacyNote =>
      'Notifications are read locally on your device to detect transactions. Nothing is uploaded or shared.';

  @override
  String get smsImport_tools => 'টুলস';

  @override
  String get smsImport_txnActivity => 'Transaction Activity';

  @override
  String get smsImport_viewDetectedTxn => 'সব detect করা transactions দেখুন';

  @override
  String get smsImport_clearHistory => 'Processing History মুছুন';

  @override
  String get smsImport_resetDetection => 'Detection history reset করুন';

  @override
  String get smsImport_howItWorks => 'এটি কীভাবে কাজ করে';

  @override
  String get smsImport_readsBankNotif => 'Reads bank and wallet notifications';

  @override
  String get smsImport_dataStaysOnDevice => 'সব data আপনার device-এ থাকে';

  @override
  String get smsImport_autoCreatesTxn =>
      'Transactions স্বয়ংক্রিয়ভাবে তৈরি করে';

  @override
  String get smsImport_personalIgnored =>
      'Personal notifications উপেক্ষা করা হয়';

  @override
  String get smsImport_noDataSent => 'কোনো data কোনো server-এ পাঠানো হয় না';

  @override
  String get smsImport_active => 'সক্রিয়';

  @override
  String get smsImport_inactive => 'নিষ্ক্রিয়';

  @override
  String get smsImport_grantAccess => 'শুরু করতে notification access দিন';

  @override
  String get smsImport_notAvailableIos => 'iOS-এ পাওয়া যায় না';

  @override
  String get smsImport_enableAccessFirst =>
      'আগে notification access সক্রিয় করুন';

  @override
  String get smsImport_notifAccessRequired => 'Notification Access প্রয়োজন';

  @override
  String get smsImport_notifAccessDesc =>
      'Mudra Manager-এর transactions auto-detect করতে notification access দরকার';

  @override
  String get smsImport_onlyBankRead =>
      'শুধু bank/wallet notifications পড়া হয়';

  @override
  String get smsImport_personalNeverRead =>
      'Personal messages কখনো পড়া হয় না';

  @override
  String get smsImport_openSettings => 'Settings খুলুন';

  @override
  String get smsImport_clearHistoryConfirm => 'Processing History মুছবেন?';

  @override
  String get smsImport_clearHistoryWarning =>
      'আগে detect করা notifications আবার process হবে';

  @override
  String get smsImport_tapAgainSettings =>
      'System settings খুলতে আবার ট্যাপ করুন';

  @override
  String get upgrade_purchaseFailed => 'কেনা ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get upgrade_purchasePending =>
      'Purchase pending। Payment সম্পন্ন হলে Pro activate হবে।';

  @override
  String get upgrade_welcomePro => 'Pro-তে স্বাগতম!';

  @override
  String get upgrade_allFeaturesUnlocked =>
      'সব features unlock হয়েছে। আপনার support-এর জন্য ধন্যবাদ!';

  @override
  String get upgrade_startExploring => 'Explore শুরু করুন';

  @override
  String get upgrade_yourProFeatures => 'আপনার Pro features';

  @override
  String get upgrade_manageSubscription =>
      'Subscription manage করতে Google Play Store > Subscriptions-এ যান';

  @override
  String get upgrade_everythingInPro => 'Pro-তে সবকিছু';

  @override
  String get upgrade_chooseYourPlan => 'আপনার plan বেছে নিন';

  @override
  String get upgrade_yearly => 'বার্ষিক';

  @override
  String get upgrade_save43 => '43% বাঁচান';

  @override
  String get upgrade_monthly => 'মাসিক';

  @override
  String get upgrade_continue => 'চালিয়ে যান';

  @override
  String get upgrade_restorePurchases => 'Purchases restore করুন';

  @override
  String get upgrade_renewsToday => 'আজ renew হবে';

  @override
  String get upgrade_mudraManagerPro => 'Mudra Manager Pro';

  @override
  String get upgrade_unlockFullPower =>
      'আপনার finances-এর পূর্ণ শক্তি unlock করুন';

  @override
  String get day_monday => 'সোমবার';

  @override
  String get day_tuesday => 'মঙ্গলবার';

  @override
  String get day_wednesday => 'বুধবার';

  @override
  String get day_thursday => 'বৃহস্পতিবার';

  @override
  String get day_friday => 'শুক্রবার';

  @override
  String get day_saturday => 'শনিবার';

  @override
  String get day_sunday => 'রবিবার';

  @override
  String get recap_income => 'আয়';

  @override
  String get recap_expense => 'খরচ';

  @override
  String get recap_saved => 'সঞ্চিত';

  @override
  String get recap_dailySpending => 'দৈনিক খরচ';

  @override
  String get recap_spendingPace => 'খরচের গতি';

  @override
  String get recap_recurringVsOneTime => 'নিয়মিত vs একবারের';

  @override
  String get recap_topCategories => 'শীর্ষ শ্রেণী';

  @override
  String get recap_mostFrequent => 'সবচেয়ে ঘন ঘন';

  @override
  String get recap_incomeSources => 'আয়ের উৎস';

  @override
  String get recap_byAccount => 'অ্যাকাউন্ট অনুযায়ী';

  @override
  String get recap_budgetHealth => 'Budget স্বাস্থ্য';

  @override
  String get recap_biggestExpenses => 'সবচেয়ে বড় খরচ';

  @override
  String get recap_biggestIncome => 'সবচেয়ে বড় আয়';

  @override
  String get recap_generating => 'তৈরি হচ্ছে...';

  @override
  String get recap_avgPerDay => 'গড়/দিন';

  @override
  String get recap_weekdayAvg => 'কর্মদিবস গড়';

  @override
  String get recap_weekendAvg => 'উইকেন্ড গড়';

  @override
  String get recap_budgets => 'বাজেট';

  @override
  String get recap_badges => 'ব্যাজ';

  @override
  String get recap_streak => 'Streak';

  @override
  String get recap_best => 'সেরা';

  @override
  String get recap_savings => 'সঞ্চয়';

  @override
  String get about_developerMode => 'Developer Mode সক্রিয়!';

  @override
  String get about_couldNotOpenLink => 'লিংক খোলা যায়নি';

  @override
  String get about_title => 'সম্পর্কে';

  @override
  String get about_privacyDesc =>
      'সবকিছু আপনার device-এ থাকে। কোনো account নেই, কোনো cloud নেই।';

  @override
  String get about_legalTransparency => 'আইনি ও স্বচ্ছতা';

  @override
  String get about_privacyPolicy => 'Privacy Policy';

  @override
  String get about_privacyPolicyDesc => 'আমরা কীভাবে আপনার data সুরক্ষিত রাখি';

  @override
  String get about_termsOfService => 'সেবার শর্তাবলী';

  @override
  String get about_termsDesc => 'App ব্যবহারের শর্তাবলী';

  @override
  String get about_openSourceLicenses => 'Open Source Licenses';

  @override
  String get about_openSourceDesc => 'আমাদের ব্যবহৃত third-party libraries';

  @override
  String get about_supportConnect => 'Support ও Connect';

  @override
  String get about_checkForUpdates => 'Updates চেক করুন';

  @override
  String get about_checkForUpdatesDesc => 'App version ম্যানুয়ালি চেক করুন';

  @override
  String get about_latestVersion => 'আপনি latest version-এ আছেন';

  @override
  String get about_unableToCheck => 'Updates চেক করা যায়নি';

  @override
  String get about_officialWebsite => 'অফিসিয়াল ওয়েবসাইট';

  @override
  String get about_visitWebsite => 'mudramanager.com দেখুন';

  @override
  String get about_contactSupport => 'Support-এ যোগাযোগ করুন';

  @override
  String get about_contactSupportDesc => 'সাহায্য নিন বা সমস্যা জানান';

  @override
  String get about_rateApp => 'App-কে Rate করুন';

  @override
  String get about_rateAppDesc => 'Store-এ আপনার অভিজ্ঞতা শেয়ার করুন';

  @override
  String get about_developerModeSection => 'Developer Mode';

  @override
  String get about_mudraManager => 'Mudra Manager';

  @override
  String get about_secureFinancial => 'নিরাপদ আর্থিক নিয়ন্ত্রণ';

  @override
  String get about_loadingLicenses => 'Licenses লোড হচ্ছে...';

  @override
  String get appearance_title => 'চেহারা';

  @override
  String get appearance_themeMode => 'Theme Mode';

  @override
  String get appearance_display => 'Display';

  @override
  String get appearance_toneVoice => 'Tone ও Voice';

  @override
  String get appearance_changesApplyInstantly =>
      'Theme ও display পরিবর্তন তৎক্ষণাৎ প্রযোজ্য।';

  @override
  String get appearance_darkAppearance => 'Dark চেহারা';

  @override
  String get appearance_lightAppearance => 'Light চেহারা';

  @override
  String get appearance_accountStyle => 'Account স্টাইল';

  @override
  String get appearance_cards => 'Cards';

  @override
  String get appearance_stack => 'Stack';

  @override
  String get appearance_bento => 'Bento';

  @override
  String get appearance_highContrast => 'High Contrast';

  @override
  String get appearance_highContrastDesc =>
      'কম দৃষ্টির জন্য পাঠযোগ্যতা উন্নত করে';

  @override
  String get appearance_guestMode => 'Guest Mode';

  @override
  String get appearance_guestModeOnDesc => 'আসল পরিমাণ লুকানো আছে';

  @override
  String get appearance_guestModeOffDesc => 'সংবেদনশীল আর্থিক data লুকান';

  @override
  String get appearance_lightMode => 'Light Mode';

  @override
  String get appearance_darkMode => 'Dark Mode';

  @override
  String get appearance_systemDefault => 'System Default';

  @override
  String get analytics_financialHealthScore => 'আর্থিক স্বাস্থ্য Score';

  @override
  String get analytics_savingsRate => 'সঞ্চয় হার';

  @override
  String get analytics_expenseRatio => 'খরচ অনুপাত';

  @override
  String get analytics_insights => 'তথ্য';

  @override
  String get analytics_spendingPrediction => 'খরচের পূর্বাভাস';

  @override
  String get analytics_nextMonth => 'পরের মাস';

  @override
  String get analytics_basedOnAvg => 'গত ৩ মাসের গড়ের উপর ভিত্তি করে';

  @override
  String get analytics_categoryTrends => 'শ্রেণী প্রবণতা';

  @override
  String get analytics_spendingByDay => 'দিন অনুযায়ী খরচ';

  @override
  String get trip_notFound => 'Trip পাওয়া যায়নি';

  @override
  String get trip_notFoundMsg => 'Trip পাওয়া যায়নি';

  @override
  String get trip_tripLabel => 'Trip';

  @override
  String get trip_groupLabel => 'Group';

  @override
  String get trip_archiveTripTitle => 'Trip Archive করুন';

  @override
  String get trip_archiveMsg =>
      'এই trip archive হবে। সব data ও settlement সুরক্ষিত থাকবে।';

  @override
  String get trip_archiveConfirm => 'Archive করুন';

  @override
  String get trip_totalSpent => 'মোট খরচ';

  @override
  String get trip_splitExpense => 'খরচ ভাগ করুন';

  @override
  String get trip_allPeople => 'সবাই';

  @override
  String get trip_allCategories => 'সব শ্রেণী';

  @override
  String get trip_uncategorized => 'শ্রেণীবিহীন';

  @override
  String get trip_removeExpense => 'খরচ সরান';

  @override
  String get trip_removeFromTrip => 'এই খরচ trip থেকে সরাবেন?';

  @override
  String get trip_removeFromGroup => 'এই খরচ group থেকে সরাবেন?';

  @override
  String get trip_removeConfirm => 'সরান';

  @override
  String get trip_unknown => 'অজানা';

  @override
  String get trip_youPaid => 'আপনি দিয়েছেন';

  @override
  String get trip_noPendingSettlements =>
      'এই trip-এর জন্য কোনো pending settlement নেই';

  @override
  String get trip_everyoneSquare => 'সবার হিসাব সমান';

  @override
  String get trip_archiveGroupTitle => 'Group Archive করুন';

  @override
  String get trip_archiveGroupMsg =>
      'এই group archive হবে। সব data ও settlement সুরক্ষিত থাকবে।';

  @override
  String get editTrip_addParticipant => 'অংশগ্রহণকারী যোগ করুন';

  @override
  String get editTrip_name => 'নাম';

  @override
  String get editTrip_enterName => 'অংশগ্রহণকারীর নাম লিখুন';

  @override
  String get editTrip_finalizeTrip => 'Trip চূড়ান্ত করুন';

  @override
  String get editTrip_closeGroup => 'Group বন্ধ করুন';

  @override
  String get editTrip_finalizeMsg => 'Trip শেষ হবে। এরপর খরচ যোগ করা যাবে না।';

  @override
  String get editTrip_closeGroupMsg =>
      'এই group বন্ধ হবে। এরপর খরচ যোগ করা যাবে না।';

  @override
  String get editTrip_finalize => 'চূড়ান্ত করুন';

  @override
  String get editTrip_close => 'বন্ধ করুন';

  @override
  String get editTrip_groupNotFound => 'Group পাওয়া যায়নি';

  @override
  String get editTrip_groupNotFoundMsg => 'Group পাওয়া যায়নি';

  @override
  String get editTrip_editTrip => 'Trip সম্পাদনা';

  @override
  String get editTrip_editGroup => 'Group সম্পাদনা';

  @override
  String get editTrip_editSplitGroup => 'Split Group সম্পাদনা';

  @override
  String get editTrip_createTrip => 'Trip তৈরি করুন';

  @override
  String get editTrip_createSplitGroup => 'Split Group তৈরি করুন';

  @override
  String get editTrip_travelTrip => 'Travel Trip';

  @override
  String get editTrip_splitGroup => 'Split Group';

  @override
  String get editTrip_tripDetails => 'Trip বিবরণ';

  @override
  String get editTrip_groupDetails => 'Group বিবরণ';

  @override
  String get editTrip_tripName => 'Trip-এর নাম';

  @override
  String get editTrip_groupName => 'Group-এর নাম';

  @override
  String get editTrip_descriptionOptional => 'বিবরণ (ঐচ্ছিক)';

  @override
  String get editTrip_tripHint => 'বন্ধুদের সাথে beach vacation';

  @override
  String get editTrip_groupHint => 'বন্ধুদের সাথে খরচ ভাগ করুন';

  @override
  String get editTrip_budgetOptional => 'Budget (ঐচ্ছিক)';

  @override
  String get editTrip_currency => 'মুদ্রা';

  @override
  String get editTrip_baseCurrencyDefault => 'Base currency (default)';

  @override
  String get editTrip_duration => 'সময়কাল';

  @override
  String get editTrip_warningDateChange => 'সতর্কতা: তারিখ পরিবর্তন';

  @override
  String get expense_notFound => 'পাওয়া যায়নি';

  @override
  String get expense_notFoundMsg => 'খরচ পাওয়া যায়নি';

  @override
  String get expense_details => 'খরচের বিবরণ';

  @override
  String get expense_paidBy => 'কে দিয়েছে';

  @override
  String get expense_you => 'You';

  @override
  String get expense_yourShare => 'আপনার ভাগ';

  @override
  String get expense_noteLabel => 'নোট';

  @override
  String get expense_editSplit => 'Split সম্পাদনা';

  @override
  String get expense_splitType => 'Split ধরন';

  @override
  String get expense_equal => 'সমান';

  @override
  String get expense_custom => 'কাস্টম';

  @override
  String get expense_participants => 'অংশগ্রহণকারী';

  @override
  String get expense_autoFillRemaining => 'বাকি auto-fill করুন';

  @override
  String get expense_deleteExpense => 'খরচ মুছুন';

  @override
  String get expense_deleteExpenseMsg =>
      'এটি সবার balance পরিবর্তন করবে। চালিয়ে যাবেন?';

  @override
  String get billCenter_overdue => 'বকেয়া';

  @override
  String get billCenter_thisWeek => 'এই সপ্তাহে';

  @override
  String get billCenter_thisMonth => 'এই মাসে';

  @override
  String get billCenter_later => 'পরে';

  @override
  String get billCenter_totalUpcoming => 'মোট আসন্ন';

  @override
  String get billCenter_today => 'আজ';

  @override
  String get billCenter_tomorrow => 'আগামীকাল';

  @override
  String get billCenter_afterUpcoming => 'আসন্ন বিলের পরে';

  @override
  String get billCenter_dueToday => 'আজ দেয়';

  @override
  String get billCenter_paid => 'পরিশোধিত';

  @override
  String get billCenter_pay => 'Pay';

  @override
  String get billCenter_existingTxnFound => 'বিদ্যমান Transaction পাওয়া গেছে';

  @override
  String get billCenter_linkTransaction => 'এই Transaction যুক্ত করুন';

  @override
  String get billCenter_createNewEntry => 'নতুন Entry তৈরি করুন';

  @override
  String get comparison_steady => 'স্থির চলছে';

  @override
  String get comparison_steadyDesc =>
      'আপনার খরচ সামঞ্জস্যপূর্ণ — এটাই শৃঙ্খলা।';

  @override
  String get comparison_doingGreat => 'দারুণ করছেন';

  @override
  String get comparison_headsUp => 'সতর্কতা — খরচ বেড়েছে';

  @override
  String get reconcile_title => 'মিলিয়ে নিন';

  @override
  String get reconcile_info =>
      'আপনার ব্যাংক অ্যাপ বা পাসবইতে দেখানো বর্তমান ব্যালেন্স লিখুন। আমরা স্বয়ংক্রিয়ভাবে পার্থক্য সমন্বয় করব।';

  @override
  String get reconcile_balanceInApp => 'অ্যাপে ব্যালেন্স';

  @override
  String get reconcile_actualBalance => 'প্রকৃত ব্যাংক ব্যালেন্স';

  @override
  String get reconcile_balanced => 'সমন্বিত!';

  @override
  String get reconcile_difference => 'পার্থক্য';

  @override
  String reconcile_incomeAdjustment(String amount) {
    return '$amount এর আয় সমন্বয় যোগ করা হবে।';
  }

  @override
  String reconcile_expenseAdjustment(String amount) {
    return '$amount এর ব্যয় সমন্বয় যোগ করা হবে।';
  }

  @override
  String get balanceHistory_currentBalance => 'বর্তমান ব্যালেন্স';

  @override
  String get balanceHistory_highest => 'সর্বোচ্চ';

  @override
  String get balanceHistory_lowest => 'সর্বনিম্ন';

  @override
  String get balanceHistory_average => 'গড়';

  @override
  String get common_errorLoading => 'ডেটা লোড করতে ব্যর্থ';

  @override
  String get balanceHistory_trend => '৩০ দিনের প্রবণতা';

  @override
  String get balanceHistory_growing => 'আপনার ব্যালেন্স বাড়ছে 📈';

  @override
  String get balanceHistory_declining => 'ব্যালেন্স কমেছে — পুনরুদ্ধার করুন 💪';

  @override
  String get balanceHistory_steady => 'স্থির আছে ⚖️';

  @override
  String get account_editTitle => 'অ্যাকাউন্ট সম্পাদনা';

  @override
  String get account_newTitle => 'নতুন অ্যাকাউন্ট';

  @override
  String get account_name => 'অ্যাকাউন্টের নাম';

  @override
  String get account_typeLabel => 'অ্যাকাউন্টের ধরন';

  @override
  String get account_detailsLabel => 'বিবরণ';

  @override
  String get account_colorLabel => 'রঙ';

  @override
  String get account_currencyLabel => 'মুদ্রা';

  @override
  String get account_balance => 'ব্যালেন্স';

  @override
  String get account_outstanding => 'বকেয়া';

  @override
  String get account_last4 => 'শেষ ৪ অঙ্ক';

  @override
  String get account_last4Helper => 'SMS অটো-ম্যাচিংয়ের জন্য';

  @override
  String get account_initialBalance => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get account_cardPaidOff => 'কার্ড পরিশোধ হলে ০ লিখুন';

  @override
  String get account_min4 => 'ন্যূনতম ৪ অঙ্ক';

  @override
  String get account_max4 => 'শুধুমাত্র শেষ ৪ অঙ্ক';

  @override
  String get iconPicker_title => 'আইকন বেছে নিন';

  @override
  String get iconPicker_search => 'আইকন খুঁজুন...';

  @override
  String get iconPicker_noResults => 'কোনো আইকন পাওয়া যায়নি';

  @override
  String get colorPicker_title => 'রঙ বেছে নিন';

  @override
  String get color_red => 'লাল';

  @override
  String get color_pink => 'গোলাপি';

  @override
  String get color_purple => 'বেগুনি';

  @override
  String get color_indigo => 'নীল';

  @override
  String get color_blue => 'নীলা';

  @override
  String get color_cyan => 'সায়ান';

  @override
  String get color_teal => 'টিল';

  @override
  String get color_green => 'সবুজ';

  @override
  String get color_orange => 'কমলা';

  @override
  String get color_brown => 'বাদামি';

  @override
  String get color_grey => 'ধূসর';

  @override
  String get accounts_totalBalance => 'মোট ব্যালেন্স';

  @override
  String get accounts_accountsCount => 'অ্যাকাউন্ট';

  @override
  String get accounts_archived => 'সংগ্রহীত';

  @override
  String get accounts_howItWorks => 'অ্যাকাউন্ট কীভাবে কাজ করে';

  @override
  String get accounts_howItWorksDesc =>
      'আপনার সব ব্যাংক অ্যাকাউন্ট, ওয়ালেট এবং নগদ এক জায়গায় পরিচালনা করুন। একাধিক অ্যাকাউন্টে ব্যালেন্স এবং লেনদেন ট্র্যাক করুন।';

  @override
  String get accounts_primary => 'প্রাথমিক';

  @override
  String get categories_label => 'শ্রেণী';

  @override
  String get categories_transactionsLabel => 'লেনদেন';

  @override
  String categories_deleteWithTransactions(String name, int count) {
    return 'এটি \"$name\" এবং $count টি সংযুক্ত লেনদেন স্থায়ীভাবে মুছে দেবে। এই কাজটি ফেরানো যাবে না।';
  }

  @override
  String get categories_deleteAll => 'সব মুছুন';

  @override
  String get categories_edit => 'শ্রেণী সম্পাদনা';

  @override
  String get categories_delete => 'শ্রেণী মুছুন';

  @override
  String get categories_deleteSubtitle => 'সব সংযুক্ত লেনদেন মুছে দেয়';

  @override
  String get category_save => 'সেভ করুন';

  @override
  String get category_detailsLabel => 'বিবরণ';

  @override
  String get category_parentLabel => 'মূল শ্রেণী';

  @override
  String get category_nameHint => 'শ্রেণীর নাম';

  @override
  String get category_keywordsHint => 'কীওয়ার্ড (কমা দিয়ে আলাদা)';

  @override
  String get category_keywordsHelper => 'SMS অটো-ডিটেকশনের জন্য';

  @override
  String get currency_title => 'মুদ্রা';

  @override
  String get currency_baseCurrency => 'মূল মুদ্রা';

  @override
  String get currency_baseDescription =>
      'সব মোট, বাজেট এবং বিশ্লেষণ এই মুদ্রা ব্যবহার করে।';

  @override
  String get currency_exchangeRates => 'বিনিময় হার';

  @override
  String get currency_exchangeRatesDesc =>
      'রূপান্তর হার দেখুন এবং সম্পাদনা করুন';

  @override
  String get currency_archivedDesc => 'পূর্ববর্তী মুদ্রার লেনদেন দেখুন';

  @override
  String exchange_unitInfo(String base) {
    return 'বিদেশী মুদ্রার ১ ইউনিট = X $base। সম্পাদনা করতে ট্যাপ করুন।';
  }

  @override
  String get exchange_search => 'মুদ্রা খুঁজুন...';

  @override
  String exchange_rateUpdated(String code) {
    return '$code হার আপডেট হয়েছে';
  }

  @override
  String exchange_editRate(String code) {
    return '$code হার সম্পাদনা';
  }

  @override
  String get exchange_rateLabel => 'হার';

  @override
  String get exchange_invalidRate => 'একটি বৈধ হার লিখুন';

  @override
  String get archived_transaction => 'লেনদেন';

  @override
  String get currency_changingCurrency => 'মুদ্রা পরিবর্তন হচ্ছে...';

  @override
  String get currency_pleaseWait => 'লেনদেন সংগ্রহ এবং সেটিংস আপডেট হচ্ছে';

  @override
  String get security_title => 'নিরাপত্তা';

  @override
  String get security_unprotected => 'অসুরক্ষিত';

  @override
  String get security_basic => 'বেসিক';

  @override
  String get security_strong => 'শক্তিশালী';

  @override
  String get security_unprotectedDesc =>
      'আপনার ডেটা সুরক্ষিত করতে PIN বা বায়োমেট্রিক্স সক্রিয় করুন';

  @override
  String security_protectionsActive(int count, int total) {
    return '$total এর মধ্যে $count সুরক্ষা সক্রিয়';
  }

  @override
  String get security_authentication => 'প্রমাণীকরণ';

  @override
  String get security_pinLock => 'PIN লক';

  @override
  String get security_pinActive => '৪ অঙ্কের PIN সক্রিয়';

  @override
  String get security_pinSet => '৪ অঙ্কের PIN সেট করুন';

  @override
  String get security_biometric => 'বায়োমেট্রিক আনলক';

  @override
  String get security_biometricDesc => 'ফিঙ্গারপ্রিন্ট বা Face ID';

  @override
  String get security_manage => 'পরিচালনা';

  @override
  String get security_changePin => 'PIN পরিবর্তন';

  @override
  String get security_changePinDesc => 'আপনার ৪ অঙ্কের PIN আপডেট করুন';

  @override
  String get security_enablePinFirst => 'প্রথমে PIN সক্রিয় করুন';

  @override
  String get security_biometricEnabled => 'বায়োমেট্রিক সক্রিয়';

  @override
  String get security_biometricDisabled => 'বায়োমেট্রিক অক্ষম';

  @override
  String get security_infoText =>
      'আপনার PIN এই ডিভাইসে নিরাপদে সংরক্ষিত — এটি কখনো সার্ভারে যায় না।';

  @override
  String notifSettings_activeCount(int count) {
    return '৫ এর মধ্যে $count সক্রিয়';
  }

  @override
  String get notifSettings_summaryDesc =>
      'সারাংশে খরচ, আয়, শীর্ষ শ্রেণী এবং ব্যালেন্স দেখায়';

  @override
  String get notifSettings_dailySummaryDesc => 'গতকালের খরচের সারাংশ';

  @override
  String notifSettings_weeklySchedule(String day) {
    return 'প্রতি $day সকাল ৯:০০ টায়';
  }

  @override
  String get smsImport_autoImporting => 'লেনদেন অটোম্যাটিক import হচ্ছে';

  @override
  String get smsImport_enableToStart =>
      'Auto import সক্রিয় করুন tracking শুরু করতে';

  @override
  String get smsImport_iosRestriction =>
      'iOS প্ল্যাটফর্মের সীমাবদ্ধতার কারণে Auto import শুধুমাত্র Android-এ পাওয়া যায়।';

  @override
  String get common_change => 'পরিবর্তন';

  @override
  String get goal_whatSavingFor => 'কিসের জন্য সঞ্চয় করছেন?';

  @override
  String get netWorth_totalLabel => 'মোট Net Worth';

  @override
  String get netWorth_notEnoughData => 'এখনো পর্যাপ্ত data নেই';

  @override
  String get netWorth_assets => 'সম্পদ';

  @override
  String get netWorth_liabilities => 'দায়';

  @override
  String get netWorth_composition => 'সম্পদ কাঠামো';

  @override
  String get goal_milestoneStarted => 'শুরু';

  @override
  String get goal_milestoneStartedDesc => 'আপনার যাত্রা শুরু হয়েছে';

  @override
  String get goal_milestone25 => '25%';

  @override
  String get goal_milestone25Desc => 'এক চতুর্থাংশ সম্পন্ন';

  @override
  String get goal_milestone50 => '50%';

  @override
  String get goal_milestone50Desc => 'অর্ধেক হয়ে গেছে!';

  @override
  String get goal_milestone75 => '75%';

  @override
  String get goal_milestone75Desc => 'প্রায় পৌঁছে গেছেন';

  @override
  String get goal_milestone100 => '100%';

  @override
  String get goal_milestone100Desc => 'Goal সম্পন্ন! 🎉';

  @override
  String get goal_flexibleTimeline => 'নমনীয় সময়সীমা';

  @override
  String get goal_amount => 'রাশি';

  @override
  String get goal_emotionReached => 'Goal পূরণ হয়েছে! 🎉';

  @override
  String get goal_emotionProgress => 'ভালো progress ✨';

  @override
  String goal_emotionMoreToGo(Object amount) {
    return 'আর মাত্র $amount বাকি 💪';
  }

  @override
  String get goal_emotionSetTarget => 'Target সেট করুন 🎯';

  @override
  String get goal_emotionWhatSaving => 'কিসের জন্য সঞ্চয় করছেন?';

  @override
  String get goal_exceededTarget => 'Target ছাড়িয়ে গেছে! 🎉';

  @override
  String get goal_alreadyReached => 'Goal আগেই পূরণ হয়েছে! 🎉';

  @override
  String goal_progressLeft(Object percent, Object amount) {
    return '$percent% হয়েছে • $amount বাকি';
  }

  @override
  String goal_paceDaily(Object daily, Object monthly) {
    return 'এই গতিতে $daily/দিন লাগবে।\nমানে $monthly/মাস।';
  }

  @override
  String goal_daysRemaining(Object count) {
    return '$count দিন বাকি';
  }

  @override
  String goal_daysLeft(Object count) {
    return '$count দিন বাকি আছে';
  }

  @override
  String goal_startSaving(Object amount) {
    return '$amount সঞ্চয় শুরু করুন';
  }

  @override
  String goal_goalsInProgress(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি goals চলছে',
      one: '1টি goal চলছে',
    );
    return '$_temp0';
  }

  @override
  String get goal_completedSection => 'সম্পন্ন 🎉';

  @override
  String get goal_emotionAlmost => 'প্রায় হয়ে গেছে 🚀';

  @override
  String get goal_emotionHalfway => 'অর্ধেক পথ 💪';

  @override
  String get goal_emotionEvery => 'প্রতিটি বিট গুরুত্বপূর্ণ 🌱';

  @override
  String get goal_emotionHalfwayDone => 'অর্ধেক হয়ে গেছে ✨';

  @override
  String get goal_emotionKeepPushing => 'চালিয়ে যান 🔥';

  @override
  String get goal_emotionJustStarted => 'সবে মাত্র শুরু 🌱';

  @override
  String get goal_closestToCompletion => 'সম্পন্ন হওয়ার সবচেয়ে কাছে';

  @override
  String goal_acrossGoals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি goals-এ',
      one: '1টি goal-এ',
    );
    return '$_temp0';
  }

  @override
  String get goal_suffixSaved => 'সঞ্চিত';

  @override
  String get goal_suffixLeft => 'বাকি';

  @override
  String get goal_suffixDone => 'হয়েছে';

  @override
  String get goal_suffixAchieved => 'অর্জিত';

  @override
  String get goal_suffixToGo => 'আর চাই';

  @override
  String get goal_needsAttention => 'নজর দিন ⚠️';

  @override
  String get goal_aheadOfSchedule => 'সময়ের আগে 🎯';

  @override
  String goal_monthsLeft(Object count) {
    return '$count মাস বাকি';
  }

  @override
  String get goal_emotionDidIt => 'আপনি করে দেখিয়েছেন! 🎉';

  @override
  String get goal_emotionSoClose => 'অনেক কাছে, চালিয়ে যান! 💪';

  @override
  String get goal_emotionMomentum => 'গতি তৈরি হচ্ছে 🔥';

  @override
  String get goal_emotionCatchUp => 'চলুন ধরি 💪';

  @override
  String get goal_finishGoal => 'এই goal শেষ করুন! 🚀';

  @override
  String get goal_onTrackStatus => 'ঠিক চলছে ✅';

  @override
  String get goal_behindPace => 'পিছিয়ে পড়ছে ⚠️';

  @override
  String goal_daysAgo(Object count) {
    return '$count দিন আগে';
  }

  @override
  String get common_today => 'আজ';

  @override
  String get common_yesterday => 'গতকাল';

  @override
  String get common_amount => 'পরিমাণ';

  @override
  String get accounts_edit => 'অ্যাকাউন্ট সম্পাদনা';

  @override
  String get accounts_balanceHistory => 'ব্যালেন্স ইতিহাস';

  @override
  String get accounts_matchBank => 'Bank statement-এর সাথে মেলান';

  @override
  String get accounts_viewPortfolio => 'Portfolio দেখুন';

  @override
  String get accounts_setAsPrimary => 'প্রাথমিক করুন';

  @override
  String get accounts_primaryDesc =>
      'Splits ও trips-এর জন্য default অ্যাকাউন্ট';

  @override
  String get accounts_archive => 'Archive করুন';

  @override
  String get accounts_archiveDesc => 'সক্রিয় অ্যাকাউন্ট থেকে লুকান';

  @override
  String get accounts_unarchive => 'Unarchive করুন';

  @override
  String get accounts_unarchiveDesc => 'সক্রিয় অ্যাকাউন্টে ফিরিয়ে আনুন';

  @override
  String get accounts_deleteDesc => 'অ্যাকাউন্ট স্থায়ীভাবে মুছুন';

  @override
  String get smsActivity_title => 'Transaction Activity';

  @override
  String get smsActivity_approved => 'অনুমোদিত';

  @override
  String get smsActivity_pending => 'মুলতুবি';

  @override
  String get smsActivity_rejected => 'প্রত্যাখ্যাত';

  @override
  String get smsActivity_needsReview => 'Review দরকার';

  @override
  String get smsActivity_duplicates => 'ডুপ্লিকেট';

  @override
  String get smsActivity_filterByStatus => 'Status দিয়ে filter করুন';

  @override
  String smsActivity_transactionCount(Object count) {
    return '$countটি Transaction';
  }

  @override
  String smsActivity_needsAttention(Object count) {
    return '$countটিতে মনোযোগ দিন';
  }

  @override
  String smsActivity_resultCount(Object count) {
    return '$countটি ফলাফল';
  }

  @override
  String get smsActivity_noActivities => 'কোনো মিলে যাওয়া activity নেই';

  @override
  String get smsActivity_status => 'Status';

  @override
  String get smsActivity_confidence => 'বিশ্বাসযোগ্যতা';

  @override
  String get smsActivity_account => 'অ্যাকাউন্ট';

  @override
  String get smsActivity_bank => 'Bank';

  @override
  String get smsActivity_type => 'ধরন';

  @override
  String get smsActivity_merchant => 'Merchant';

  @override
  String get smsActivity_balance => 'ব্যালেন্স';

  @override
  String get smsActivity_reference => 'Reference';

  @override
  String get smsActivity_duplicateLabel => 'DUPLICATE';

  @override
  String get smsActivity_transferLabel => 'TRANSFER';

  @override
  String get smsActivity_reject => 'প্রত্যাখ্যান';

  @override
  String get smsActivity_approve => 'অনুমোদন';

  @override
  String get smsActivity_transfer => 'Transfer';

  @override
  String get smsActivity_addAccount => 'অ্যাকাউন্ট যোগ';

  @override
  String get smsActivity_duplicateWarning =>
      'এটি duplicate transaction হতে পারে। Approve করার আগে ভালো করে দেখুন।';

  @override
  String smsActivity_noAccountWarning(Object account) {
    return '\"$account\" এর সাথে মিলে যাওয়া অ্যাকাউন্ট পাওয়া যায়নি। Approve করতে আগে যোগ করুন।';
  }

  @override
  String get smsActivity_transferWarning =>
      'এটি আপনার অ্যাকাউন্টগুলোর মধ্যে transfer মনে হচ্ছে। Approve করলে transfer screen খুলবে।';

  @override
  String get common_all => 'সব';

  @override
  String get backup_lastBackup => 'শেষ backup';

  @override
  String get backup_noBackups => 'এখনো কোনো backup নেই';

  @override
  String get backup_createFirst =>
      'আপনার data সুরক্ষিত করতে প্রথম backup তৈরি করুন';

  @override
  String get backup_actions => 'কার্যকরী';

  @override
  String get backup_history => 'ইতিহাস';

  @override
  String get backup_noHistory => 'কোনো backup ইতিহাস নেই';

  @override
  String get backup_infoText =>
      'Backups আপনার password দিয়ে encrypt হয়ে .mudra files-এ save হয়। Password সুরক্ষিত রাখুন — এটি recover করা যায় না।';

  @override
  String get backup_justNow => 'এইমাত্র';

  @override
  String backup_minutesAgo(int count) {
    return '$count মিনিট আগে';
  }

  @override
  String backup_hoursAgo(int count) {
    return '$count ঘন্টা আগে';
  }

  @override
  String backup_daysAgo(int count) {
    return '$count দিন আগে';
  }

  @override
  String backup_recordCount(int count) {
    return '$count records';
  }

  @override
  String get account_changeCurrency => 'মুদ্রা পরিবর্তন করবেন?';

  @override
  String account_resetTo(String code) {
    return '$code-এ reset করুন';
  }

  @override
  String get account_baseCurrencyInfo =>
      'এই অ্যাকাউন্টের transactions আপনার base currency-তে।';

  @override
  String account_foreignCurrencyInfo(String code, String base) {
    return 'Transactions $code-এ record হবে এবং $base-এ convert হবে।';
  }

  @override
  String get account_warningNoConvert =>
      'বিদ্যমান balance স্বয়ংক্রিয়ভাবে convert হবে না।';

  @override
  String get account_warningNewCurrency =>
      'নতুন transactions নতুন মুদ্রায় হবে।';

  @override
  String get account_warningManualAdjust =>
      'আপনাকে balance ম্যানুয়ালি adjust করতে হতে পারে।';

  @override
  String get category_selectParent => 'মূল শ্রেণী বেছে নিন';

  @override
  String get appearance_colorTheme => 'Color Theme';

  @override
  String get appearance_amoledMode => 'AMOLED Mode';

  @override
  String appearance_toneActivated(String name) {
    return '$name tone সক্রিয়';
  }

  @override
  String dashboard_cardsActive(int visible, int total) {
    return '$total এর মধ্যে $visibleটি card সক্রিয়';
  }

  @override
  String get dashboard_dragToReorder =>
      'ক্রম পরিবর্তন করতে drag করুন, দেখাতে/লুকাতে toggle করুন';

  @override
  String get dashboard_smartOrdering => 'Smart ক্রম';

  @override
  String get dashboard_catEssential => 'অপরিহার্য';

  @override
  String get dashboard_catFinance => 'অর্থ';

  @override
  String get dashboard_catAnalytics => 'বিশ্লেষণ';

  @override
  String get dashboard_catActions => 'কার্যকরী';

  @override
  String get dashboard_catAI => 'AI তথ্য';

  @override
  String get dashboard_catContextual => 'প্রসঙ্গ ভিত্তিক';

  @override
  String get importExport_title => 'Import ও Export';

  @override
  String get importExport_export => 'Export';

  @override
  String get importExport_import => 'Import';

  @override
  String get importExport_exportTitle => 'Transactions Export করুন';

  @override
  String get importExport_exportDesc =>
      'আপনার transactions Excel file-এ download করুন।';

  @override
  String get importExport_exporting => 'Export হচ্ছে...';

  @override
  String get importExport_exportAsExcel => 'Excel-এ Export করুন';

  @override
  String get importExport_importTitle => 'Excel থেকে Import করুন';

  @override
  String get importExport_importDesc =>
      '.xlsx file থেকে transactions import করুন। Import-এর আগে preview ও column mapping করতে পারবেন।';

  @override
  String get importExport_excelFormat => 'Excel (.xlsx)';

  @override
  String get importExport_bankStatement => 'Bank Statement';

  @override
  String get importExport_otherApps => 'অন্যান্য Apps';

  @override
  String get importExport_pickFile => 'Excel File বেছে নিন';

  @override
  String get importExport_infoText =>
      'Export সব transaction details সহ Excel file তৈরি করে। Import অন্য finance apps বা manual spreadsheets থেকে .xlsx files support করে।';

  @override
  String get plugins_subtitle =>
      'Mudra Manager-কে powerful plugins দিয়ে বাড়ান';

  @override
  String get plugins_official => 'Official';

  @override
  String plugins_enabled(String name) {
    return '$name সক্রিয়';
  }

  @override
  String plugins_disabled(String name) {
    return '$name নিষ্ক্রিয়';
  }

  @override
  String get plugins_configure => 'Plugin configure করুন';

  @override
  String plugins_activeCount(int active, int total) {
    return '$total এর মধ্যে $active সক্রিয়';
  }

  @override
  String get plugins_toggleDesc => 'App features বাড়াতে plugins toggle করুন';

  @override
  String get plugins_default => 'Default';

  @override
  String get plugins_configureSettings => 'Plugin settings configure করুন';

  @override
  String get plugins_creditCardReminders => 'Credit Card Reminders';

  @override
  String get plugins_remindBefore => 'কত দিন আগে মনে করাবে';

  @override
  String get plugins_noCreditCards =>
      'কোনো credit card account পাওয়া যায়নি। আগে একটি যোগ করুন।';

  @override
  String get plugins_creditCardAccounts => 'Credit Card অ্যাকাউন্ট';

  @override
  String get plugins_billDay => 'Bill Day (1-31)';

  @override
  String get plugins_remindersConfigured => 'Credit card reminders সেট হয়েছে';

  @override
  String get plugins_infoText =>
      'Plugins app features বাড়ায়। কিছু plugins-এর অতিরিক্ত permissions বা configuration দরকার।';

  @override
  String get help_title => 'সাহায্য ও সহায়তা';

  @override
  String get help_searchHint => 'Help topics খুঁজুন...';

  @override
  String get help_heroTitle => 'আমরা কীভাবে সাহায্য করতে পারি?';

  @override
  String get help_heroDesc => 'Guides দেখুন বা কোনো topic খুঁজুন';

  @override
  String get help_topics => 'বিষয়';

  @override
  String get help_tryDifferent => 'অন্য শব্দ চেষ্টা করুন';

  @override
  String get help_howToUse => 'কীভাবে ব্যবহার করবেন';

  @override
  String get help_tips => 'পরামর্শ';

  @override
  String help_articleCount(int count) {
    return '$countটি নিবন্ধ';
  }

  @override
  String help_resultCount(int count) {
    return '$countটি ফলাফল';
  }

  @override
  String get help_infoText =>
      'যা দরকার তা পাচ্ছেন না? About → Contact Support-এ যান।';

  @override
  String get about_legalCount => '3টি আইটেম';

  @override
  String get about_supportCount => '4টি আইটেম';

  @override
  String about_packageCount(int count) {
    return '$countটি open source packages';
  }

  @override
  String get onboard_continue => 'এগিয়ে যান';

  @override
  String get onboard_restoreFromBackup => 'Backup থেকে restore করুন';

  @override
  String get onboard_accountNameRequired => 'অ্যাকাউন্টের নাম দরকার';

  @override
  String get onboard_balanceRequired => 'ব্যালেন্স দরকার';

  @override
  String get onboard_enterValidNumber => 'সঠিক নম্বর লিখুন';

  @override
  String get onboard_accountHint => 'যেমন Cash, Bank';

  @override
  String get onboard_browseAllCurrencies => 'সব মুদ্রা দেখুন';

  @override
  String get onboard_toneTitle => 'Mudra আপনার সাথে কীভাবে কথা বলবে?';

  @override
  String get onboard_toneDesc =>
      'একটি শৈলী বেছে নিন। পরে পরিবর্তন করতে পারবেন।';

  @override
  String get onboard_categoriesTitle => 'আপনার শ্রেণী বেছে নিন';

  @override
  String get onboard_categoriesDesc =>
      'আপনার জীবনধারার সাথে মিলে যায় এমন packs বেছে নিন। পরে পরিবর্তন করতে পারবেন।';

  @override
  String get onboard_startFresh => 'নতুন করে শুরু';

  @override
  String get onboard_startFreshDesc => 'কোনো শ্রেণী নেই — পরে নিজে যোগ করুন';

  @override
  String get onboard_currencyWarning =>
      'পরে base currency পরিবর্তন করলে বর্তমান transactions archive হবে।';

  @override
  String get statistics_topCategory => 'টপ Category';

  @override
  String get statistics_dailyAverage => 'দৈনিক গড়';

  @override
  String get statistics_perDay => 'প্রতিদিন';

  @override
  String statistics_percentOfExpenses(String percent) {
    return '$percent% খরচের';
  }

  @override
  String get sms_infoTitle => 'SMS Import কিভাবে কাজ করে';

  @override
  String get sms_infoOnlyScans => 'শুধু bank ও wallet SMS scan করে';

  @override
  String get sms_infoStaysOnDevice => 'সব data আপনার device-এই থাকে';

  @override
  String get sms_infoAutoCreates => 'Transactions আপনা-আপনি তৈরি হয়';

  @override
  String get sms_infoNoPersonal => 'কোনো personal message পড়া হয় না';

  @override
  String get dashboard_totalBalance => 'মোট ব্যালেন্স';

  @override
  String get dashboard_netWorthLink => 'Net Worth';

  @override
  String get dashboard_showAccounts => 'Accounts দেখান';

  @override
  String get dashboard_hideAccounts => 'Accounts লুকান';

  @override
  String dashboard_accountsTapExpand(int count) {
    return '$count accounts · Tap করুন';
  }

  @override
  String get notif_lowBalanceTitle => '⚠️ Balance কম';

  @override
  String notif_lowBalanceBody(String account, String amount) {
    return '$account-এ মাত্র $amount বাকি আছে';
  }

  @override
  String get achieve_unlocked => 'Unlock হয়েছে';

  @override
  String get achieve_inProgress => 'চলছে';

  @override
  String get achieve_trophyShelf => 'Trophy Shelf';

  @override
  String get achieve_streaks => 'Streaks';

  @override
  String get achieve_totalXP => 'Total XP';

  @override
  String get achieve_dailyCheckIn => 'Daily Check-in';

  @override
  String get achieve_budgetAdherence => 'Budget মেনে চলা';

  @override
  String achieve_bestDays(int count) {
    return 'Best: $count দিন';
  }

  @override
  String achieve_noBadgesYet(String category) {
    return 'এখনও কোনো $category badge নেই';
  }

  @override
  String achieve_levelUpSnack(int level) {
    return '🎉 Level Up! আপনি Level $level-এ!';
  }

  @override
  String achieve_levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get achieve_catBudgeting => 'Budgeting';

  @override
  String get achieve_catSavings => 'সঞ্চয়';

  @override
  String get achieve_catTracking => 'Tracking';

  @override
  String get achieve_catMilestones => 'Milestones';

  @override
  String get achieve_catEngagement => 'Engagement';

  @override
  String get achieve_catAll => 'সব';

  @override
  String get alert_actionNeeded => 'Action দরকার';

  @override
  String alert_billsDueTomorrow(int count) {
    return 'আগামীকাল $countটি bill due';
  }

  @override
  String get alert_upcomingBills => 'আসন্ন Bills';

  @override
  String alert_billsDueInDays(int count) {
    return '2 দিনে $countটি bill due';
  }

  @override
  String get alert_budgetAlert => 'Budget Alert';

  @override
  String alert_budgetsExceeded(int count) {
    return '$countটি budget পার হয়েছে';
  }

  @override
  String get alert_budgetWarning => 'Budget Warning';

  @override
  String alert_budgetsNearLimit(int count) {
    return '$countটি budget limit-এর কাছে';
  }

  @override
  String get alert_goalProgress => 'Goal Progress';

  @override
  String alert_goalsAlmostComplete(int count) {
    return '$countটি goal প্রায় শেষ!';
  }

  @override
  String get analytics_cashFlowForecast => 'Cash Flow পূর্বাভাস';

  @override
  String get analytics_thisMonthProjected => 'এই মাসে (অনুমানিত)';

  @override
  String get analytics_savingOnAverage => 'গড়ে সঞ্চয় হচ্ছে';

  @override
  String get analytics_spendingExceedsIncome => 'খরচ income-এর চেয়ে বেশি';

  @override
  String get recap_vsLastYear => 'গত বছরের তুলনায়';

  @override
  String get common_income => 'আয়';

  @override
  String get common_expense => 'খরচ';

  @override
  String get common_transactions => 'Transactions';

  @override
  String get tax_title => 'Tax Estimation';

  @override
  String get tax_projected => 'Projected (বছর এখনও চলছে)';

  @override
  String get tax_estimatedTax => 'আনুমানিক Tax';

  @override
  String get tax_effectiveRate => 'Effective Rate';

  @override
  String get tax_monthlyTax => 'Monthly';

  @override
  String tax_fyProgress(Object elapsed, Object total) {
    return '$total-এর মধ্যে $elapsed দিন';
  }

  @override
  String get tax_slabBreakdown => 'Slab Breakdown';

  @override
  String get tax_totalSlabTax => 'মোট Slab Tax';

  @override
  String get tax_computation => 'Tax Computation';

  @override
  String get tax_grossIncome => 'মোট আয়';

  @override
  String get tax_standardDeduction => 'Standard Deduction';

  @override
  String get tax_taxableIncome => 'Taxable Income';

  @override
  String get tax_baseTax => 'Income-এর উপর Tax';

  @override
  String get tax_rebate87A => 'Rebate u/s 87A';

  @override
  String get tax_cess => 'Health & Education Cess (4%)';

  @override
  String get tax_totalTax => 'মোট Tax দিতে হবে';

  @override
  String get tax_incomeBreakdown => 'Income Sources';

  @override
  String get tax_disclaimer =>
      'এটি New Tax Regime (FY 2025-26) অনুযায়ী একটি আনুমানিক হিসাব। আসল tax আলাদা হতে পারে। সঠিক filing-এর জন্য tax professional-এর সাথে কথা বলুন।';

  @override
  String get tax_noData => 'Tax estimate-এর জন্য যথেষ্ট data নেই';

  @override
  String get tax_viewDetails => 'Tax Estimate দেখুন';

  @override
  String get tax_zeroTax => 'কোনো tax নেই 🎉';

  @override
  String get tax_newRegime => 'New Regime';
}
