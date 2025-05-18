// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription => 'আপনার অর্থ স্মার্ট এবং অনায়াসে পরিচালনা করুন।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return '$appName e স্বাগতম ';
  }

  @override
  String get onboard_TrackYourTransactions => 'আপনার লেনদেন ট্র্যাক করুন';

  @override
  String get onboard_SeeWhereYourMoneyGoes => 'আপনার টাকা প্রতিদিন কোথায় যায় দেখুন।';

  @override
  String get onboard_SetBudgetsAndGoals => 'বাজেট এবং লক্ষ্য নির্ধারণ করুন';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream => 'সঠিক পথে থাকুন এবং আপনার স্বপ্ন অর্জন করুন।';

  @override
  String get onboard_GetStarted => 'এবার শুরু করা যাক!';

  @override
  String get onboard_letsSetupYourAccount => 'চলুন আপনার অ্যাকাউন্ট সেট আপ করি।';

  @override
  String get onboard_howShouldWeCallYou => 'আমরা আপনাকে কী নামে ডাকব?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience => 'আপনার অভিজ্ঞতা ব্যক্তিগতকৃত করতে আপনার নাম লিখুন।';

  @override
  String get onboard_enterYourName => 'আপনার নাম লিখুন';

  @override
  String get onboard_setupYourFirstAccount => 'আপনার প্রথম অ্যাকাউন্ট সেটআপ করুন';

  @override
  String get onboard_letsCreateYourFirstAccount => 'আসুন আপনার প্রথম অ্যাকাউন্ট তৈরি করি (যেমন: ক্যাশ)।';

  @override
  String get onboard_accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get onboard_initialBalance => 'প্রাথমিক ব্যালেন্স';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell => 'আপনি অন্যান্য বিবরণ পরেও আপডেট করতে পারবেন।';

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
  String get onboard_letsStartManagingYourMoneyWisely => 'আসুন আপনার অর্থ বিচক্ষণতার সাথে পরিচালনা করা শুরু করি।';

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
  String get dashboard_mini_budget_not_found_text => 'কোনো বাজেট সংজ্ঞায়িত নেই, একটি যোগ করুন!';

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
  String get transaction_list_pending_transaction_message_text => '⚡ নতুন লেনদেন পাওয়া গেছে! এখনই পর্যালোচনা করুন';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'পর্যালোচনা';

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
  String get budget_dashboardMiniCardSpentTitleText => 'খরচ হয়েছে';

  @override
  String get budget_dashboardPageTitle => 'বাজেটের বিবরণ';

  @override
  String get budget_dashboardNotFoundText => 'কোনো বাজেট সংজ্ঞায়িত নেই, একটি যোগ করুন!';

  @override
  String get budget_dashboardAddBudgetText => 'বাজেট যোগ করুন';

  @override
  String get budget_categoriesTitle => 'ক্যাটাগরি';

  @override
  String budget_dashboardPieChartLabelText(Object spentPercent, Object title, Object totalPercent) {
    return '$title (মোট $totalPercent, ব্যয়িত $spentPercent)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'বাজেট মুছবেন?';

  @override
  String get budget_buttonDeleteBodyText => 'এটি বাজেট এবং এর বরাদ্দগুলি সরিয়ে ফেলবে, এই পদক্ষেপটি আর ফেরানো যাবে না।';

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
  String get budget_categoryMessageInfoText => 'আপনি ম্যানুয়ালি ক্যাটাগরি বরাদ্দগুলি প্রবেশ করতে পারেন, অথবা অবশিষ্ট পরিমাণ সমানভাবে স্বয়ংক্রিয়ভাবে বিতরণ করার জন্য সেগুলিকে ফাঁকা রাখতে পারেন।';

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
  String get budget_selectAtLeastOneCategoryErrorText => 'অন্তত একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText => 'বরাদ্দ করা পরিমাণ মোট বাজেট অতিক্রম করেছে';

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
  String get transaction_addNewCategoryText => 'নতুন ক্যাটাগরি\nযোগ করুন';

  @override
  String get transaction_addNewTagText => 'নতুন ট্যাগ যোগ করুন';

  @override
  String get transaction_tagNameControllerText => 'ট্যাগের নাম';

  @override
  String get transaction_saveTagButtonLabel => 'ট্যাগ সংরক্ষণ করুন';

  @override
  String get transaction_saveTransactionButtonLabel => 'Save Transaction';

  @override
  String get transaction_selectOneAccountErrorText => 'অন্তত একটি অ্যাকাউন্ট নির্বাচন করুন';

  @override
  String get transaction_selectOneCategoryErrorText => 'অন্তত একটি ক্যাটাগরি নির্বাচন করুন';

  @override
  String get transaction_incomeButtonLabel => 'আয়';

  @override
  String get transaction_expenseButtonLabel => 'ব্যয়';
}
