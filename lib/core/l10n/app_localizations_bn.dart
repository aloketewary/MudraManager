// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      'আপনার অর্থ স্মার্ট এবং অনায়াসে পরিচালনা করুন।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return '$appName e স্বাগতম ';
  }

  @override
  String get onboard_TrackYourTransactions => 'আপনার লেনদেন ট্র্যাক করুন';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'আপনার টাকা প্রতিদিন কোথায় যায় দেখুন।';

  @override
  String get onboard_SetBudgetsAndGoals => 'বাজেট এবং লক্ষ্য নির্ধারণ করুন';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'সঠিক পথে থাকুন এবং আপনার স্বপ্ন অর্জন করুন।';

  @override
  String get onboard_GetStarted => 'এবার শুরু করা যাক!';

  @override
  String get onboard_letsSetupYourAccount =>
      'চলুন আপনার অ্যাকাউন্ট সেট আপ করি।';

  @override
  String get onboard_howShouldWeCallYou => 'আমরা আপনাকে কী নামে ডাকব?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'আপনার অভিজ্ঞতা ব্যক্তিগতকৃত করতে আপনার নাম লিখুন।';

  @override
  String get onboard_enterYourName => 'আপনার নাম লিখুন';

  @override
  String get onboard_setupYourFirstAccount =>
      'আপনার প্রথম অ্যাকাউন্ট সেটআপ করুন';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'আসুন আপনার প্রথম অ্যাকাউন্ট তৈরি করি (যেমন: ক্যাশ)।';

  @override
  String get onboard_accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get onboard_initialBalance => 'প্রাথমিক ব্যালেন্স';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'আপনি অন্যান্য বিবরণ পরেও আপডেট করতে পারবেন।';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'অনুগ্রহ করে \"$inputName\" পূরণ করুন';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'অনুগ্রহ করে \"$hintText\" এর জন্য একটি বৈধ সংখ্যা লিখুন';
  }

  @override
  String get onboard_youAreAllSet => 'আপনি পুরোপুরি তৈরি!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'আসুন আপনার অর্থ বিচক্ষণতার সাথে পরিচালনা করা শুরু করি।';

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
  String get app_settings_theme_mode_light => 'আলো';

  @override
  String get app_settings_theme_mode_dark => 'ডার্ক';

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
      'কোনো বাজেট সংজ্ঞায়িত নেই, একটি যোগ করুন!';

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
      '⚡ নতুন লেনদেন পাওয়া গেছে! এখনই পর্যালোচনা করুন';

  @override
  String get transaction_listPendingTransactionMessageActionLabel =>
      'পর্যালোচনা';

  @override
  String get transaction_noTransactionFoundText => 'কোনো লেনদেন পাওয়া যায়নি।';

  @override
  String get transaction_deleteAlertTitleText => 'লেনদেন মুছবেন?';

  @override
  String get transaction_deleteAlertBodyText => 'এই কাজটি আর ফেরানো যাবে না।';

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
  String get dashboard_netWorthTitle => 'নিট মূল্য';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'বাজেট';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'খরচ হয়েছে';

  @override
  String get budget_dashboardPageTitle => 'বাজেটের বিবরণ';

  @override
  String get budget_dashboardNotFoundText =>
      'কোনো বাজেট সংজ্ঞায়িত নেই, একটি যোগ করুন!';

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
      'এটি বাজেট এবং এর বরাদ্দগুলি সরিয়ে ফেলবে, এই পদক্ষেপটি আর ফেরানো যাবে না।';

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
      'আপনি ম্যানুয়ালি ক্যাটাগরি বরাদ্দগুলি প্রবেশ করতে পারেন, অথবা অবশিষ্ট পরিমাণ সমানভাবে স্বয়ংক্রিয়ভাবে বিতরণ করার জন্য সেগুলিকে ফাঁকা রাখতে পারেন।';

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
      'আপনার সমস্ত ডেটা এই ডিভাইসেই সংরক্ষিত থাকে। কোনো সার্ভার নেই, কোনো ক্লাউড নেই, কোনো ট্র্যাকিংও নেই।';

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
  String get transfer_screenTitle => 'তহবিল স্থানান্তর';

  @override
  String get transfer_resetTooltip => 'রিসেট';

  @override
  String get transfer_selectAccountsLabel => 'অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get transfer_fromLabel => 'থেকে';

  @override
  String get transfer_toLabel => 'এ';

  @override
  String get transfer_detailsLabel => 'স্থানান্তরের বিবরণ';

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
  String get transfer_errorLoadingAccounts => 'অ্যাকাউন্ট লোড করতে ত্রুটি';

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
  String get common_loading => 'লোড হচ্ছে';

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
  String get onboard_SmartSmsTracking => 'স্মার্ট SMS ট্র্যাকিং';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'ব্যাংক SMS থেকে স্বয়ংক্রিয়ভাবে লেনদেন শনাক্ত ও আমদানি করুন।';

  @override
  String get onboard_InsightsAndAnalytics => 'ইনসাইটস ও অ্যানালিটিক্স';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'বিস্তারিত চার্ট, ট্রেন্ড এবং স্মার্ট ইনসাইটস দিয়ে আপনার খরচের অভ্যাস বুঝুন।';

  @override
  String get onboard_SecureAndPrivate => 'সুরক্ষিত ও ব্যক্তিগত';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'আপনার ডেটা আপনার ডিভাইসে থাকে। কোনো ক্লাউড নেই, কোনো ট্র্যাকিং নেই।';

  @override
  String get onboard_SmartAutoTracking => 'Smart Auto Tracking';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Automatically detect and import transactions from your bank notifications.';
}
