import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_bo.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_de.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_si.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('as'),
    Locale('bn'),
    Locale('bo'),
    Locale('brx'),
    Locale('de'),
    Locale('doi'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('kn'),
    Locale('ko'),
    Locale('kok'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ms'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('pt'),
    Locale('sat'),
    Locale('sd'),
    Locale('si'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
  ];

  /// Manage your money smartly & effortlessly.
  ///
  /// In en, this message translates to:
  /// **'100% offline. Your data never leaves your device.'**
  String get onboard_manageYourMoneyDescription;

  /// Welcome to Application
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String onboard_welcomeToApp(Object appName);

  /// Track your Transactions
  ///
  /// In en, this message translates to:
  /// **'Auto-track from Bank SMS'**
  String get onboard_TrackYourTransactions;

  /// See where your money goes, every day.
  ///
  /// In en, this message translates to:
  /// **'Auto-import from bank SMS & notifications. Works with 50+ banks.'**
  String get onboard_SeeWhereYourMoneyGoes;

  /// Set Budgets and Goals
  ///
  /// In en, this message translates to:
  /// **'Budgets, Goals & Smart Alerts'**
  String get onboard_SetBudgetsAndGoals;

  /// Stay on track and achieve your dreams.
  ///
  /// In en, this message translates to:
  /// **'Get warnings before you overspend. Save for what matters.'**
  String get onboard_stayOnTrackAndAchieveYourDream;

  /// Get Started!
  ///
  /// In en, this message translates to:
  /// **'Get Started!'**
  String get onboard_GetStarted;

  /// Let's set up your account.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your account.'**
  String get onboard_letsSetupYourAccount;

  /// How should we call you?
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get onboard_howShouldWeCallYou;

  /// Enter your name to personalize your experience.
  ///
  /// In en, this message translates to:
  /// **'Enter your name to personalize your experience.'**
  String get onboard_enterYourNameToPersonalizeYourExperience;

  /// Enter your name
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get onboard_enterYourName;

  /// Setup Your First Account
  ///
  /// In en, this message translates to:
  /// **'Setup Your First Account'**
  String get onboard_setupYourFirstAccount;

  /// Let's start managing your money wisely.
  ///
  /// In en, this message translates to:
  /// **'Let\'s create your first account (let say: Cash).'**
  String get onboard_letsCreateYourFirstAccount;

  /// Account Name
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get onboard_accountName;

  /// Initial Balance
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get onboard_initialBalance;

  /// You can update other details later as well.
  ///
  /// In en, this message translates to:
  /// **'You can update other details later as well.'**
  String get onboard_youCanUpdateOtherDetailsLaterAsWell;

  /// Please fill the
  ///
  /// In en, this message translates to:
  /// **'Please fill the \"{inputName}\"'**
  String onboard_pleaseFillThe(Object inputName);

  /// Please enter a valid number for
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number for \"{hintText}\"'**
  String onboard_pleaseEnterAValidNumberFor(Object hintText);

  /// You're all set!
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboard_youAreAllSet;

  /// Let's start managing your money wisely.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start managing your money wisely.'**
  String get onboard_letsStartManagingYourMoneyWisely;

  /// This is title of screen page
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get app_settings_appbar_title;

  /// This is title of Choose Language page
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get language_settings_appbar_title;

  /// This is title of Language tile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get app_settings_language_title;

  /// This is subtitle of Language tile
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get app_settings_language_subtitle;

  /// This is title of Theme Mode tile
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get app_settings_theme_mode_title;

  /// This is text of Theme Mode light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get app_settings_theme_mode_light;

  /// This is text of Theme Mode dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get app_settings_theme_mode_dark;

  /// This is text of Theme Mode system default
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get app_settings_theme_mode_system_default;

  /// This is text of Theme Mode AMOLED dark
  ///
  /// In en, this message translates to:
  /// **'AMOLED'**
  String get app_settings_theme_mode_amoled;

  /// This is subtitle of Theme Mode tile
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme'**
  String get app_settings_theme_mode_subtitle;

  /// This is text of Daily reminder title
  ///
  /// In en, this message translates to:
  /// **'Daily Expense Reminder'**
  String get app_settings_daily_reminder_title;

  /// This is title of Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_screen_title;

  /// This is title of Activity screen
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get transaction_screen_title;

  /// This is title of Statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics_screen_title;

  /// This is title of Profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_screen_title;

  /// This is title of Add Transaction screen
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get add_edit_transaction_screen_title;

  /// This is title of Transaction List screen
  ///
  /// In en, this message translates to:
  /// **'Transaction List'**
  String get transaction_list_screen_title;

  /// This is text of Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get transaction_listViewGroupTodayLabel;

  /// This is text of Yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get transaction_listViewGroupYesterdayLabel;

  /// This is text of Good Morning
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greeting_good_morning_text;

  /// This is text of Good Afternoon
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greeting_good_afternoon_text;

  /// This is text of Good Evening
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greeting_good_evening_text;

  /// This is text of Good Night
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get greeting_good_night_text;

  /// This is text of Hello
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting_hello_text;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transaction_type_income;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transaction_type_expense;

  /// This is text of add transaction button
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get dashboard_add_transaction_text;

  /// This is text of add Transfer button
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get dashboard_add_transfer_text;

  /// This is text of Cash Flow
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get dashboard_cash_flow_text;

  /// This is text of Day
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get cash_flow_filter_type_day;

  /// This is text of Week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get cash_flow_filter_type_week;

  /// This is text of Month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get cash_flow_filter_type_month;

  /// This is text of Year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get cash_flow_filter_type_year;

  /// This is text of Budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get dashboard_mini_budget_text;

  /// This is text of budget not found
  ///
  /// In en, this message translates to:
  /// **'No Budgets Defined, Add One!'**
  String get dashboard_mini_budget_not_found_text;

  /// This is text of add budget
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get dashboard_mini_budget_add_text;

  /// This is title of Transactions List from cash flow screen
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transaction_list_cash_flow_screen_title;

  /// This is text of All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transaction_list_filter_all;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transaction_list_filter_income;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transaction_list_filter_expense;

  /// This is text of pending transaction message
  ///
  /// In en, this message translates to:
  /// **'⚡ New transactions found! Review now'**
  String get transaction_list_pending_transaction_message_text;

  /// This is text of pending transaction message action
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get transaction_listPendingTransactionMessageActionLabel;

  /// This is text of no transaction found
  ///
  /// In en, this message translates to:
  /// **'No transactions found.'**
  String get transaction_noTransactionFoundText;

  /// This is text of Delete Transaction
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction?'**
  String get transaction_deleteAlertTitleText;

  /// This is text of Delete Transaction body
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get transaction_deleteAlertBodyText;

  /// This is text of Delete Transaction action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transaction_deleteButtonActionText;

  /// This is text of Cancel Transaction action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transaction_cancelButtonActionText;

  /// This is text of Filter Category
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get transaction_filterCategoryText;

  /// This is text of note description
  ///
  /// In en, this message translates to:
  /// **'note: {description}'**
  String transaction_noteDescriptionText(Object description);

  /// This is text of Monday initial
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get calendar_week_monday_initial_text;

  /// This is text of Tuesday initial
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendar_week_tuesday_initial_text;

  /// This is text of Wednesday initial
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get calendar_week_wednesday_initial_text;

  /// This is text of Thursday initial
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendar_week_thursday_initial_text;

  /// This is text of Friday initial
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get calendar_week_friday_initial_text;

  /// This is text of Saturday initial
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendar_week_saturday_initial_text;

  /// This is text of Sunday initial
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendar_week_sunday_initial_text;

  /// This is title of Net Worth
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get dashboard_netWorthTitle;

  /// This is title of Budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget_dashboardMiniCardBudgetTitleText;

  /// This is title of Spent
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budget_dashboardMiniCardSpentTitleText;

  /// This is title of Budgets Details
  ///
  /// In en, this message translates to:
  /// **'Budgets Details'**
  String get budget_dashboardPageTitle;

  /// This is text of budget not found
  ///
  /// In en, this message translates to:
  /// **'No Budgets Defined, Add One!'**
  String get budget_dashboardNotFoundText;

  /// This is text of add budget
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get budget_dashboardAddBudgetText;

  /// This is text of categories title
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budget_categoriesTitle;

  /// This is text of pie chart label
  ///
  /// In en, this message translates to:
  /// **'{title} ({totalPercent} of Total, {spentPercent}of Spent)'**
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent);

  /// This is text of delete title
  ///
  /// In en, this message translates to:
  /// **'Delete Budget?'**
  String get budget_buttonDeleteTitleText;

  /// This is text of delete body
  ///
  /// In en, this message translates to:
  /// **'This will remove the Budget and its allocations, this action cannot be undone.'**
  String get budget_buttonDeleteBodyText;

  /// This is text of delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budget_buttonDeleteActionText;

  /// This is text of cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get budget_buttonCancelActionText;

  /// This is text of add budget
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get budget_buttonAddText;

  /// This is text of edit budget
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budget_buttonEditText;

  /// This is text of Budget Name title
  ///
  /// In en, this message translates to:
  /// **'Budget Name'**
  String get budget_budgetNameControllerText;

  /// This is text of Total Amount title
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get budget_budgetAmountControllerText;

  /// This is text of Recurrence title
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get budget_recurrenceControllerText;

  /// This is text of Budget name is required text
  ///
  /// In en, this message translates to:
  /// **'Budget name is required'**
  String get budget_nameRequiredHintText;

  /// This is text of Amount is required text
  ///
  /// In en, this message translates to:
  /// **'Valid Amount is required'**
  String get budget_amountRequiredHintText;

  /// This is text of Select Start Date
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get budget_selectStartDateText;

  /// This is text of Select End Date
  ///
  /// In en, this message translates to:
  /// **'Start: {startDate}'**
  String budget_selectedStartDateText(Object startDate);

  /// This is text of Select End Date
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get budget_selectEndDateText;

  /// This is text of Select End Date
  ///
  /// In en, this message translates to:
  /// **'End: {endDate}'**
  String budget_selectedEndDateText(Object endDate);

  /// This is text of Select Categories & Allocations title
  ///
  /// In en, this message translates to:
  /// **'Select Categories & Allocations'**
  String get budget_categoryTitle;

  /// This is text of Allocate Amount
  ///
  /// In en, this message translates to:
  /// **'Allocate Amount'**
  String get budget_allocateAmountText;

  /// This is text of category message info
  ///
  /// In en, this message translates to:
  /// **'You can manually enter category allocations, or leave them blank to auto-distribute the remaining amount equally.'**
  String get budget_categoryMessageInfoText;

  /// This is text of Total Allocated
  ///
  /// In en, this message translates to:
  /// **'Total Allocated: {totalAlloc}'**
  String budget_totalAllocatedBudgetText(Object totalAlloc);

  /// This is text of Recurrence text
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get budget_recurrenceText;

  /// This is text of None text
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get budget_recurrenceNoneText;

  /// This is text of Daily text
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budget_recurrenceDailyText;

  /// This is text of Weekly text
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budget_recurrenceWeeklyText;

  /// This is text of Monthly text
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budget_recurrenceMonthlyText;

  /// This is text of Yearly text
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budget_recurrenceYearlyText;

  /// This is text of save button
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get budget_saveButtonText;

  /// This is text of update button
  ///
  /// In en, this message translates to:
  /// **'update'**
  String get budget_updateButtonText;

  /// This is text of Pick both dates
  ///
  /// In en, this message translates to:
  /// **'Pick both dates'**
  String get budget_pickBothDatesErrorText;

  /// This is text of Select at least one category
  ///
  /// In en, this message translates to:
  /// **'Select at least one category'**
  String get budget_selectAtLeastOneCategoryErrorText;

  /// This is text of Allocated amount exceeds total budget
  ///
  /// In en, this message translates to:
  /// **'Allocated amount exceeds total budget'**
  String get budget_allocatedAmountExceedsTotalBudgetText;

  /// This is text of Amount title
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transaction_amountControllerText;

  /// This is text of Description title
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get transaction_descriptionControllerText;

  /// This is text of Enter amount title
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get transaction_amountControllerErrorText;

  /// This is text of Select Account
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get transaction_selectAccountLabel;

  /// This is text of Select Category
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get transaction_selectCategoryLabel;

  /// This is text of Select Tag
  ///
  /// In en, this message translates to:
  /// **'Select Tag'**
  String get transaction_selectTagLabel;

  /// This is text of Add New Category
  ///
  /// In en, this message translates to:
  /// **'Add New \nCategory'**
  String get transaction_addNewCategoryText;

  /// This is text of Add New Tag
  ///
  /// In en, this message translates to:
  /// **'Add New Tag'**
  String get transaction_addNewTagText;

  /// This is text of Tag Name
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get transaction_tagNameControllerText;

  /// This is text of Save Tag
  ///
  /// In en, this message translates to:
  /// **'Save Tag'**
  String get transaction_saveTagButtonLabel;

  /// This is text of Save Transaction
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get transaction_saveTransactionButtonLabel;

  /// This is text of Select one Account
  ///
  /// In en, this message translates to:
  /// **'Select at least one Account'**
  String get transaction_selectOneAccountErrorText;

  /// This is text of Select one Category
  ///
  /// In en, this message translates to:
  /// **'Select at least one Category'**
  String get transaction_selectOneCategoryErrorText;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'INCOME'**
  String get transaction_incomeButtonLabel;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'EXPENSE'**
  String get transaction_expenseButtonLabel;

  /// This is text of We trim down decimal places, please round off if required.
  ///
  /// In en, this message translates to:
  /// **'We trim down decimal places, please round off if required.'**
  String get statistics_weTrimDownDecimalInfoText;

  /// This is text of Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statistics_selectPeriodTodayText;

  /// This is text of Week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statistics_selectPeriodWeekText;

  /// This is text of Month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statistics_selectPeriodMonthText;

  /// This is text of Year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statistics_selectPeriodYearText;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get statistics_chartLineIncomeText;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get statistics_chartLineExpenseText;

  /// This is text of h
  ///
  /// In en, this message translates to:
  /// **'{hour}h'**
  String statistics_chartLineTodayHourText(Object hour);

  /// This is text of Category not present
  ///
  /// In en, this message translates to:
  /// **'Category not present.'**
  String get statistics_categoryNotPresentText;

  /// This is text of Transactions not present.
  ///
  /// In en, this message translates to:
  /// **'Transactions not present.'**
  String get statistics_transactionNotPresentText;

  /// This is text of By Category
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get statistics_byCategoryTitleText;

  /// This is text of Recent Transactions
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get statistics_recentTransactionsTitleText;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get statistics_metricIncomeText;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get statistics_metricExpenseText;

  /// This is text of Net
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get statistics_metricNetText;

  /// This is text of Show All
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get statistics_showAllButtonText;

  /// This is text of Export to PDF
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get statistics_exportToPdfButtonText;

  /// This is text of Export to Excel
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get statistics_exportToExcelButtonText;

  /// This is text of User Profile
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profile_userProfileTitleText;

  /// This is text of User Profile subtitle
  ///
  /// In en, this message translates to:
  /// **'Change profile image, name, and email'**
  String get profile_userProfileSubtitleText;

  /// This is text of Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_nameControllerText;

  /// This is text of Enter your name
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profile_nameControllerHintText;

  /// This is text of Name is required
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profile_nameRequiredHintText;

  /// This is text of Email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_emailControllerText;

  /// This is text of Enter your name
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get profile_emailControllerHintText;

  /// This is text of Phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profile_phoneControllerText;

  /// This is text of Enter your phone number
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get profile_phoneControllerHintText;

  /// This is text of We are not storing
  ///
  /// In en, this message translates to:
  /// **'All your data lives on this device. No servers, no cloud, no tracking.'**
  String get profile_weAreNotStoringInfoText;

  /// This is text of save button
  ///
  /// In en, this message translates to:
  /// **'save'**
  String get profile_saveButtonText;

  /// This is text of Edit User Profile
  ///
  /// In en, this message translates to:
  /// **'Edit User Profile'**
  String get profile_editUserProfileAppTitle;

  /// This is title of Review Pending Transactions
  ///
  /// In en, this message translates to:
  /// **'Pending Transactions'**
  String get pendingTranx_reviewPendingTransactionsScreenTitle;

  /// This is title of Quick Overview section
  ///
  /// In en, this message translates to:
  /// **'Quick Overview'**
  String get statistics_quickOverviewTitle;

  /// This is title of Insights section
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get statistics_insightsTitle;

  /// This is title of Detailed Analysis section
  ///
  /// In en, this message translates to:
  /// **'Detailed Analysis'**
  String get statistics_detailedAnalysisTitle;

  /// This is subtitle for category breakdown
  ///
  /// In en, this message translates to:
  /// **'View category breakdown'**
  String get statistics_categoryBreakdownSubtitle;

  /// This is title for expense trends
  ///
  /// In en, this message translates to:
  /// **'Expense Trends'**
  String get statistics_expenseTrendsTitle;

  /// This is subtitle for expense trends
  ///
  /// In en, this message translates to:
  /// **'Last 12 months trends'**
  String get statistics_expenseTrendsSubtitle;

  /// This is subtitle for recent transactions
  ///
  /// In en, this message translates to:
  /// **'Last 5 transactions'**
  String get statistics_recentTransactionsSubtitle;

  /// This is title for category breakdown modal
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get statistics_categoryBreakdownTitle;

  /// This is title for recent transactions modal
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get statistics_recentTransactionsModalTitle;

  /// This is title of Transfer screen
  ///
  /// In en, this message translates to:
  /// **'Transfer Funds'**
  String get transfer_screenTitle;

  /// This is tooltip for reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get transfer_resetTooltip;

  /// This is label for select accounts section
  ///
  /// In en, this message translates to:
  /// **'SELECT ACCOUNTS'**
  String get transfer_selectAccountsLabel;

  /// This is label for from account
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get transfer_fromLabel;

  /// This is label for to account
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get transfer_toLabel;

  /// This is label for transfer details section
  ///
  /// In en, this message translates to:
  /// **'TRANSFER DETAILS'**
  String get transfer_detailsLabel;

  /// This is label for amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transfer_amountLabel;

  /// This is validation error for amount field
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get transfer_amountValidationError;

  /// This is label for date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transfer_dateLabel;

  /// This is label for note field
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get transfer_noteLabel;

  /// This is label for transfer button
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer_buttonLabel;

  /// This is label for update transfer button
  ///
  /// In en, this message translates to:
  /// **'Update Transfer'**
  String get transfer_updateButtonLabel;

  /// This is error message for loading accounts
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get transfer_errorLoadingAccounts;

  /// This is title for theme mode modal
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get app_settings_themeModeModalTitle;

  /// This is label for expense category type
  ///
  /// In en, this message translates to:
  /// **'EXPENSE'**
  String get category_expenseLabel;

  /// This is label for income category type
  ///
  /// In en, this message translates to:
  /// **'INCOME'**
  String get category_incomeLabel;

  /// This is title for add category screen
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get category_addTitle;

  /// This is title for edit category screen
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get category_editTitle;

  /// This is instruction to change icon
  ///
  /// In en, this message translates to:
  /// **'Tap to change icon'**
  String get category_tapToChangeIcon;

  /// This is label for category name field
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_nameLabel;

  /// This is validation message for required field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get category_nameRequired;

  /// This is label for category type
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get category_typeLabel;

  /// This is label for color selection
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get category_colorLabel;

  /// This is instruction to change color
  ///
  /// In en, this message translates to:
  /// **'TAP TO CHANGE COLOR'**
  String get category_tapToChangeColor;

  /// This is label for save category button
  ///
  /// In en, this message translates to:
  /// **'SAVE CATEGORY'**
  String get category_saveButton;

  /// This is label for update category button
  ///
  /// In en, this message translates to:
  /// **'UPDATE CATEGORY'**
  String get category_updateButton;

  /// This is label for income in dashboard
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboard_incomeLabel;

  /// This is label for spent in dashboard
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get dashboard_spentLabel;

  /// This is label when no data is available
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get dashboard_noDataLabel;

  /// This is label for edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dashboard_editLabel;

  /// This is label for archive action
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get dashboard_archiveLabel;

  /// Short form for crore (10 million)
  ///
  /// In en, this message translates to:
  /// **'Cr'**
  String get currency_crore_short;

  /// Short form for lakh (100 thousand)
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get currency_lakh_short;

  /// Short form for thousand
  ///
  /// In en, this message translates to:
  /// **'K'**
  String get currency_thousand_short;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String common_errorText(Object error);

  /// Short form for Expense
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get statistics_expenseShort;

  /// Short form for Income
  ///
  /// In en, this message translates to:
  /// **'Inc'**
  String get statistics_incomeShort;

  /// Label for category filter
  ///
  /// In en, this message translates to:
  /// **'Category Filter'**
  String get transaction_categoryFilter;

  /// Label for date filter
  ///
  /// In en, this message translates to:
  /// **'Date Filter'**
  String get transaction_dateFilter;

  /// Label for all categories option
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get transaction_allCategories;

  /// Label for apply filters button
  ///
  /// In en, this message translates to:
  /// **'APPLY FILTERS'**
  String get transaction_applyFilters;

  /// Title for SMS transaction selection
  ///
  /// In en, this message translates to:
  /// **'Select Transactions'**
  String get sms_selectTransactions;

  /// Generic add label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_addLabel;

  /// Label for remove action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dashboard_removeLabel;

  /// Label for view all action
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboard_viewAllLabel;

  /// Message when no accounts are available
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get common_noAccountsYet;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_editLabel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_deleteLabel;

  /// From label for transfers
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get common_fromLabel;

  /// To label for transfers
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get common_toLabel;

  /// Title for theme picker screen
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get theme_chooseThemeTitle;

  /// Label for apply theme button
  ///
  /// In en, this message translates to:
  /// **'Apply Theme'**
  String get theme_applyThemeLabel;

  /// Success message when theme is applied
  ///
  /// In en, this message translates to:
  /// **'Theme applied!'**
  String get theme_themeAppliedMessage;

  /// Title for backup and restore screen
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backup_backupRestoreTitle;

  /// Title for backup data option
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backup_backupDataTitle;

  /// Subtitle for backup data option
  ///
  /// In en, this message translates to:
  /// **'Export all database and settings'**
  String get backup_backupDataSubtitle;

  /// Title for restore backup option
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backup_restoreBackupTitle;

  /// Subtitle for restore backup option
  ///
  /// In en, this message translates to:
  /// **'Import database and settings'**
  String get backup_restoreBackupSubtitle;

  /// Title for include attachments dialog
  ///
  /// In en, this message translates to:
  /// **'Include Attachments?'**
  String get backup_includeAttachmentsTitle;

  /// Message for include attachments dialog
  ///
  /// In en, this message translates to:
  /// **'Include receipt images in backup? This will increase file size.'**
  String get backup_includeAttachmentsMessage;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get backup_yesLabel;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get backup_noLabel;

  /// Success message when backup is completed
  ///
  /// In en, this message translates to:
  /// **'Backup completed'**
  String get backup_completedMessage;

  /// Success message when restore is successful
  ///
  /// In en, this message translates to:
  /// **'Restore successful'**
  String get backup_restoreSuccessMessage;

  /// Label showing last backup date
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backup_lastBackupLabel(Object date);

  /// Label when no backup is found
  ///
  /// In en, this message translates to:
  /// **'No backup found'**
  String get backup_noBackupFoundLabel;

  /// Title for manage categories screen
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get categories_manageCategoriesTitle;

  /// Message when no categories are found
  ///
  /// In en, this message translates to:
  /// **'No categories found.'**
  String get categories_noCategoriesFound;

  /// Transaction count for category
  ///
  /// In en, this message translates to:
  /// **'{count} transaction{plural}'**
  String categories_transactionCount(Object count, Object plural);

  /// Label for add category button
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categories_addCategoryLabel;

  /// Title for delete category dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get categories_deleteCategoryTitle;

  /// Message for delete category dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?\nAll associated transactions will also be removed.'**
  String get categories_deleteCategoryMessage;

  /// Success message when category is deleted
  ///
  /// In en, this message translates to:
  /// **'Category and its transactions deleted'**
  String get categories_categoryDeletedMessage;

  /// Title for manage accounts screen
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get accounts_manageAccountsTitle;

  /// Message when no accounts are added
  ///
  /// In en, this message translates to:
  /// **'No accounts added yet'**
  String get accounts_noAccountsAddedYet;

  /// Label for add account button
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accounts_addAccountLabel;

  /// Title for delete account dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accounts_deleteAccountTitle;

  /// Message for delete account dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{accountName}\"?'**
  String accounts_deleteAccountMessage(Object accountName);

  /// Title for archive account dialog
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get accounts_archiveAccountTitle;

  /// Message for archive account dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive \"{accountName}\"?'**
  String accounts_archiveAccountMessage(Object accountName);

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accounts_cancelLabel;

  /// Archive button label
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accounts_archiveLabel;

  /// Success message when account is archived
  ///
  /// In en, this message translates to:
  /// **'\"{accountName}\" archived'**
  String accounts_accountArchivedMessage(Object accountName);

  /// Warning message when trying to delete the last account
  ///
  /// In en, this message translates to:
  /// **'At least 1 account required to continue'**
  String get accounts_atLeastOneAccountRequired;

  /// Label for trip transactions
  ///
  /// In en, this message translates to:
  /// **'TRIP'**
  String get transaction_tripLabel;

  /// Message indicating transaction is part of trips
  ///
  /// In en, this message translates to:
  /// **'This transaction is part of below trip(s)'**
  String get transaction_tripPartOfMessage;

  /// Tooltip for auto add button
  ///
  /// In en, this message translates to:
  /// **'Auto Add'**
  String get sms_autoAddTooltip;

  /// Tooltip for clear all button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get sms_clearAllTooltip;

  /// Description for auto imported transactions
  ///
  /// In en, this message translates to:
  /// **'Auto-imported'**
  String get sms_importedFromSmsDescription;

  /// Warning message to select at least one transaction
  ///
  /// In en, this message translates to:
  /// **'Please select at least one transaction'**
  String get sms_selectAtLeastOneMessage;

  /// Label for all time period
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get dashboard_allTimeLabel;

  /// Title for edit transaction screen
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transaction_editTransactionTitle;

  /// Label for date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transaction_dateLabel;

  /// Hint text for note field
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get transaction_addNoteHint;

  /// Error message for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get transaction_enterValidAmountError;

  /// Message when no pending transactions
  ///
  /// In en, this message translates to:
  /// **'No pending transactions'**
  String get sms_noPendingTransactions;

  /// Label for approve action
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get sms_approveLabel;

  /// Title for approve transaction dialog
  ///
  /// In en, this message translates to:
  /// **'Approve Transaction'**
  String get sms_approveTransactionTitle;

  /// Auto-detect bank SMS transactions
  ///
  /// In en, this message translates to:
  /// **'Smart SMS Tracking'**
  String get onboard_SmartSmsTracking;

  /// Description for SMS tracking onboarding page
  ///
  /// In en, this message translates to:
  /// **'Automatically detect and import transactions from your bank SMS messages.'**
  String get onboard_SmartSmsTrackingDesc;

  /// Financial insights and analytics
  ///
  /// In en, this message translates to:
  /// **'Insights & Analytics'**
  String get onboard_InsightsAndAnalytics;

  /// Description for insights onboarding page
  ///
  /// In en, this message translates to:
  /// **'Understand your spending habits with detailed charts, trends, and smart insights.'**
  String get onboard_InsightsAndAnalyticsDesc;

  /// Data security and privacy
  ///
  /// In en, this message translates to:
  /// **'Secure & Private'**
  String get onboard_SecureAndPrivate;

  /// Description for security onboarding page
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your device. No cloud, no tracking — just encrypted local storage.'**
  String get onboard_SecureAndPrivateDesc;

  /// Auto-detect transactions from notifications
  ///
  /// In en, this message translates to:
  /// **'Smart Auto Tracking'**
  String get onboard_SmartAutoTracking;

  /// Description for auto tracking onboarding page
  ///
  /// In en, this message translates to:
  /// **'Automatically detect and import transactions from your bank notifications.'**
  String get onboard_SmartAutoTrackingDesc;

  /// No description provided for @nav_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get nav_activity;

  /// No description provided for @nav_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get nav_manage;

  /// No description provided for @nav_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get nav_insights;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get common_undo;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get common_archive;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get common_update;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset;

  /// No description provided for @common_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get common_noData;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get common_error;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @title_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get title_budgets;

  /// No description provided for @title_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get title_goals;

  /// No description provided for @title_bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get title_bills;

  /// No description provided for @title_groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get title_groups;

  /// No description provided for @title_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get title_trips;

  /// No description provided for @title_shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get title_shared;

  /// No description provided for @title_achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get title_achievements;

  /// No description provided for @title_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get title_notifications;

  /// No description provided for @title_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get title_appearance;

  /// No description provided for @title_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get title_currency;

  /// No description provided for @title_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get title_security;

  /// No description provided for @title_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get title_about;

  /// No description provided for @title_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get title_analytics;

  /// No description provided for @title_netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get title_netWorth;

  /// No description provided for @title_financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get title_financialHealth;

  /// No description provided for @title_spendingPersonality.
  ///
  /// In en, this message translates to:
  /// **'Spending Personality'**
  String get title_spendingPersonality;

  /// No description provided for @title_monthlyRecap.
  ///
  /// In en, this message translates to:
  /// **'Monthly Recap'**
  String get title_monthlyRecap;

  /// No description provided for @title_compareMonths.
  ///
  /// In en, this message translates to:
  /// **'Compare Months'**
  String get title_compareMonths;

  /// No description provided for @title_smsImport.
  ///
  /// In en, this message translates to:
  /// **'SMS Import'**
  String get title_smsImport;

  /// No description provided for @title_backupShare.
  ///
  /// In en, this message translates to:
  /// **'Backup & Share'**
  String get title_backupShare;

  /// No description provided for @title_exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get title_exchangeRates;

  /// No description provided for @title_recurringTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recurring Transactions'**
  String get title_recurringTransactions;

  /// No description provided for @title_billControlCenter.
  ///
  /// In en, this message translates to:
  /// **'Bill Control Center'**
  String get title_billControlCenter;

  /// No description provided for @title_plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get title_plugins;

  /// No description provided for @title_editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get title_editCategory;

  /// No description provided for @title_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get title_allCategories;

  /// No description provided for @title_exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get title_exportOptions;

  /// No description provided for @title_dashboardLayout.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Layout'**
  String get title_dashboardLayout;

  /// No description provided for @section_activeMoney.
  ///
  /// In en, this message translates to:
  /// **'Active Money'**
  String get section_activeMoney;

  /// No description provided for @section_planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get section_planning;

  /// No description provided for @section_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get section_insights;

  /// No description provided for @section_coreSettings.
  ///
  /// In en, this message translates to:
  /// **'Core Settings'**
  String get section_coreSettings;

  /// No description provided for @section_appData.
  ///
  /// In en, this message translates to:
  /// **'App & Data'**
  String get section_appData;

  /// No description provided for @section_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get section_appearance;

  /// No description provided for @section_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get section_advanced;

  /// No description provided for @section_supportLegal.
  ///
  /// In en, this message translates to:
  /// **'Support & Legal'**
  String get section_supportLegal;

  /// No description provided for @section_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get section_active;

  /// No description provided for @section_ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get section_ongoing;

  /// No description provided for @section_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get section_archive;

  /// No description provided for @label_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get label_income;

  /// No description provided for @label_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get label_expense;

  /// No description provided for @label_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get label_balance;

  /// No description provided for @label_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get label_savings;

  /// No description provided for @label_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get label_total;

  /// No description provided for @label_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get label_amount;

  /// No description provided for @label_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get label_date;

  /// No description provided for @label_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get label_category;

  /// No description provided for @label_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get label_account;

  /// No description provided for @label_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get label_description;

  /// No description provided for @label_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get label_type;

  /// No description provided for @label_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get label_transfer;

  /// No description provided for @label_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get label_from;

  /// No description provided for @label_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get label_to;

  /// No description provided for @label_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get label_all;

  /// No description provided for @label_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get label_today;

  /// No description provided for @label_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get label_yesterday;

  /// No description provided for @label_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get label_thisWeek;

  /// No description provided for @label_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get label_thisMonth;

  /// No description provided for @label_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get label_thisYear;

  /// No description provided for @label_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get label_custom;

  /// No description provided for @label_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get label_daily;

  /// No description provided for @label_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get label_weekly;

  /// No description provided for @label_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get label_monthly;

  /// No description provided for @label_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get label_yearly;

  /// No description provided for @label_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get label_none;

  /// No description provided for @label_frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get label_frequency;

  /// No description provided for @label_repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get label_repeatEvery;

  /// No description provided for @label_days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get label_days;

  /// No description provided for @label_weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get label_weeks;

  /// No description provided for @label_months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get label_months;

  /// No description provided for @label_years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get label_years;

  /// No description provided for @trip_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get trip_expenses;

  /// No description provided for @trip_settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get trip_settlements;

  /// No description provided for @trip_balances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get trip_balances;

  /// No description provided for @trip_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get trip_report;

  /// No description provided for @trip_createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get trip_createTrip;

  /// No description provided for @trip_createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Shared Group'**
  String get trip_createGroup;

  /// No description provided for @trip_editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get trip_editTrip;

  /// No description provided for @trip_editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get trip_editGroup;

  /// No description provided for @trip_archiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Archive Trip'**
  String get trip_archiveTrip;

  /// No description provided for @trip_archiveGroup.
  ///
  /// In en, this message translates to:
  /// **'Archive Group'**
  String get trip_archiveGroup;

  /// No description provided for @trip_allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled up!'**
  String get trip_allSettled;

  /// No description provided for @trip_archiveToSettle.
  ///
  /// In en, this message translates to:
  /// **'Archive to settle up'**
  String get trip_archiveToSettle;

  /// No description provided for @trip_trackTravel.
  ///
  /// In en, this message translates to:
  /// **'Track travel expenses with dates & budget'**
  String get trip_trackTravel;

  /// No description provided for @trip_splitBills.
  ///
  /// In en, this message translates to:
  /// **'Split bills with friends'**
  String get trip_splitBills;

  /// No description provided for @trip_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get trip_live;

  /// No description provided for @budget_spendingLimits.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get budget_spendingLimits;

  /// No description provided for @budget_savingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Savings progress'**
  String get budget_savingsProgress;

  /// No description provided for @budget_upcomingRecurring.
  ///
  /// In en, this message translates to:
  /// **'Upcoming & recurring'**
  String get budget_upcomingRecurring;

  /// No description provided for @budget_tripsAndSplits.
  ///
  /// In en, this message translates to:
  /// **'Trips & splits'**
  String get budget_tripsAndSplits;

  /// No description provided for @import_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing {count} transactions...'**
  String import_importing(int count);

  /// No description provided for @import_dontClose.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t close the app'**
  String get import_dontClose;

  /// No description provided for @import_complete.
  ///
  /// In en, this message translates to:
  /// **'Import Complete!'**
  String get import_complete;

  /// No description provided for @import_failed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get import_failed;

  /// No description provided for @import_imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get import_imported;

  /// No description provided for @import_duplicatesSkipped.
  ///
  /// In en, this message translates to:
  /// **'Duplicates skipped'**
  String get import_duplicatesSkipped;

  /// No description provided for @import_errorsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Errors/skipped'**
  String get import_errorsSkipped;

  /// No description provided for @import_categoriesCreated.
  ///
  /// In en, this message translates to:
  /// **'Categories created'**
  String get import_categoriesCreated;

  /// No description provided for @import_previewImport.
  ///
  /// In en, this message translates to:
  /// **'Preview Import'**
  String get import_previewImport;

  /// No description provided for @recap_yourMonthAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Your month at a glance'**
  String get recap_yourMonthAtGlance;

  /// No description provided for @recap_trackProgressOverTime.
  ///
  /// In en, this message translates to:
  /// **'Track progress over time'**
  String get recap_trackProgressOverTime;

  /// No description provided for @recap_transactions.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String recap_transactions(int count);

  /// No description provided for @recap_downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get recap_downloadPdf;

  /// No description provided for @comparison_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get comparison_current;

  /// No description provided for @comparison_byDay.
  ///
  /// In en, this message translates to:
  /// **'By day {day}'**
  String comparison_byDay(int day);

  /// No description provided for @comparison_topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get comparison_topCategories;

  /// No description provided for @comparison_categoryImpact.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY IMPACT'**
  String get comparison_categoryImpact;

  /// No description provided for @comparison_dailySpendingPace.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending Pace'**
  String get comparison_dailySpendingPace;

  /// No description provided for @comparison_projected.
  ///
  /// In en, this message translates to:
  /// **'Projected: {amount} this month'**
  String comparison_projected(String amount);

  /// No description provided for @utility_customizeUtilities.
  ///
  /// In en, this message translates to:
  /// **'Customize Utilities'**
  String get utility_customizeUtilities;

  /// No description provided for @utility_addUtilities.
  ///
  /// In en, this message translates to:
  /// **'Add Utilities'**
  String get utility_addUtilities;

  /// No description provided for @profile_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get profile_accounts;

  /// No description provided for @profile_manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage your accounts'**
  String get profile_manageAccounts;

  /// No description provided for @profile_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get profile_categories;

  /// No description provided for @profile_manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage your categories'**
  String get profile_manageCategories;

  /// No description provided for @profile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// No description provided for @profile_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profile_notifications;

  /// No description provided for @profile_dailyWeeklySummaries.
  ///
  /// In en, this message translates to:
  /// **'Daily & weekly summaries'**
  String get profile_dailyWeeklySummaries;

  /// No description provided for @profile_autoImport.
  ///
  /// In en, this message translates to:
  /// **'Auto Import'**
  String get profile_autoImport;

  /// No description provided for @profile_autoImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-import from bank notifications'**
  String get profile_autoImportDesc;

  /// No description provided for @profile_importExport.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get profile_importExport;

  /// No description provided for @profile_importExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Excel import & export'**
  String get profile_importExportDesc;

  /// No description provided for @profile_backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get profile_backupRestore;

  /// No description provided for @profile_manageData.
  ///
  /// In en, this message translates to:
  /// **'Manage your data'**
  String get profile_manageData;

  /// No description provided for @profile_themeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Theme, tone & display'**
  String get profile_themeDisplay;

  /// No description provided for @profile_customizeWidgets.
  ///
  /// In en, this message translates to:
  /// **'Customize widgets & cards'**
  String get profile_customizeWidgets;

  /// No description provided for @profile_manageExtensions.
  ///
  /// In en, this message translates to:
  /// **'Manage extensions'**
  String get profile_manageExtensions;

  /// No description provided for @profile_helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profile_helpSupport;

  /// No description provided for @profile_faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs and feature guides'**
  String get profile_faqs;

  /// No description provided for @profile_aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get profile_aboutApp;

  /// No description provided for @profile_versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version & Info'**
  String get profile_versionInfo;

  /// No description provided for @profile_pinFingerprint.
  ///
  /// In en, this message translates to:
  /// **'PIN or Fingerprint'**
  String get profile_pinFingerprint;

  /// No description provided for @profile_upgradePro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get profile_upgradePro;

  /// No description provided for @profile_unlimitedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlimited accounts, analytics & more'**
  String get profile_unlimitedFeatures;

  /// No description provided for @profile_freeTier.
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get profile_freeTier;

  /// No description provided for @profile_fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get profile_fullAccess;

  /// No description provided for @profile_proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get profile_proActive;

  /// No description provided for @profile_yourAchievements.
  ///
  /// In en, this message translates to:
  /// **'Your Achievements'**
  String get profile_yourAchievements;

  /// No description provided for @profile_bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get profile_bestStreak;

  /// No description provided for @trips_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get trips_active;

  /// No description provided for @trips_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get trips_live;

  /// No description provided for @trips_allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get trips_allSettled;

  /// No description provided for @tone_friendly_txnAdded.
  ///
  /// In en, this message translates to:
  /// **'Done! Transaction saved ✨|Got it! All logged 👍|Saved! You\'re on top of it ✨|Noted! One more tracked 📝'**
  String get tone_friendly_txnAdded;

  /// No description provided for @tone_friendly_txnUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated! Looking good 👍|Changes saved! ✓|All updated! 👌'**
  String get tone_friendly_txnUpdated;

  /// No description provided for @tone_friendly_txnDeleted.
  ///
  /// In en, this message translates to:
  /// **'Gone! Transaction removed 🗑️|Deleted! One less to track|Removed! Clean slate 🗑️'**
  String get tone_friendly_txnDeleted;

  /// No description provided for @tone_friendly_txnFailed.
  ///
  /// In en, this message translates to:
  /// **'Hmm, couldn\'t save that. Try again?'**
  String get tone_friendly_txnFailed;

  /// No description provided for @tone_friendly_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'How much was it? Enter an amount'**
  String get tone_friendly_enterAmount;

  /// No description provided for @tone_friendly_pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Which account? Pick one to continue'**
  String get tone_friendly_pickAccount;

  /// No description provided for @tone_friendly_pickCategory.
  ///
  /// In en, this message translates to:
  /// **'What was it for? Choose a category'**
  String get tone_friendly_pickCategory;

  /// No description provided for @tone_friendly_fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Almost there — fill in all the fields'**
  String get tone_friendly_fillAllFields;

  /// No description provided for @tone_friendly_invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look right — enter a valid amount'**
  String get tone_friendly_invalidAmount;

  /// No description provided for @tone_friendly_budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget set! Let\'s stay on track 💪|Budget locked in! You\'re planning ahead 💪|Nice! Budget is ready to roll 📊'**
  String get tone_friendly_budgetCreated;

  /// No description provided for @tone_friendly_budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated!'**
  String get tone_friendly_budgetUpdated;

  /// No description provided for @tone_friendly_budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get tone_friendly_budgetDeleted;

  /// No description provided for @tone_friendly_goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Goal set! You got this 🎯|New goal! Let\'s make it happen 🎯|Goal locked in! Eyes on the prize 🎯'**
  String get tone_friendly_goalCreated;

  /// No description provided for @tone_friendly_goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal updated!'**
  String get tone_friendly_goalUpdated;

  /// No description provided for @tone_friendly_goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal removed'**
  String get tone_friendly_goalDeleted;

  /// No description provided for @tone_friendly_accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account added! 🏦'**
  String get tone_friendly_accountCreated;

  /// No description provided for @tone_friendly_billAdded.
  ///
  /// In en, this message translates to:
  /// **'Bill tracked! I\'ll remind you 🔔'**
  String get tone_friendly_billAdded;

  /// No description provided for @tone_friendly_billPaid.
  ///
  /// In en, this message translates to:
  /// **'Nice, bill marked as paid! ✅|Bill done! One less to worry about ✅|Paid! That\'s a relief ✅'**
  String get tone_friendly_billPaid;

  /// No description provided for @tone_friendly_backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup done! Your data is safe 🛡️'**
  String get tone_friendly_backupSuccess;

  /// No description provided for @tone_friendly_restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored! Welcome back 🎉'**
  String get tone_friendly_restoreSuccess;

  /// No description provided for @tone_friendly_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet\nAdd your first transaction to get started|Empty for now\nStart tracking — it only takes a sec|No transactions yet\nYour financial journey starts with one entry'**
  String get tone_friendly_noTransactions;

  /// No description provided for @tone_friendly_noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet\nSet one up to track your spending'**
  String get tone_friendly_noBudgets;

  /// No description provided for @tone_friendly_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet\nDream big — set your first goal!'**
  String get tone_friendly_noGoals;

  /// No description provided for @tone_friendly_genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again?'**
  String get tone_friendly_genericError;

  /// No description provided for @tone_friendly_smsImportEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto import is on! I\'ll track your transactions 📩'**
  String get tone_friendly_smsImportEnabled;

  /// No description provided for @tone_friendly_dashboardAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! 🎉|Nothing needs your attention — nice! ✨|All good here! Enjoy your day 🎉'**
  String get tone_friendly_dashboardAllCaughtUp;

  /// No description provided for @tone_friendly_dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yesterday — either a zero-spend win or time to catch up!|Quiet day yesterday — your wallet thanks you!|No transactions yesterday — fresh start today!'**
  String get tone_friendly_dailySummaryEmpty;

  /// No description provided for @tone_friendly_streakMessage.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak! Keep it going! 🔥'**
  String tone_friendly_streakMessage(int days);

  /// No description provided for @tone_friendly_budgetExceededBy.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your budget by {amount} 😬'**
  String tone_friendly_budgetExceededBy(String amount);

  /// No description provided for @tone_professional_txnAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction recorded.|Entry saved successfully.|Transaction logged.'**
  String get tone_professional_txnAdded;

  /// No description provided for @tone_professional_txnUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated.|Changes applied.|Record updated successfully.'**
  String get tone_professional_txnUpdated;

  /// No description provided for @tone_professional_txnDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted.|Record removed.|Entry deleted successfully.'**
  String get tone_professional_txnDeleted;

  /// No description provided for @tone_professional_txnFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save transaction. Please retry.'**
  String get tone_professional_txnFailed;

  /// No description provided for @tone_professional_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get tone_professional_enterAmount;

  /// No description provided for @tone_professional_pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select an account.'**
  String get tone_professional_pickAccount;

  /// No description provided for @tone_professional_pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get tone_professional_pickCategory;

  /// No description provided for @tone_professional_fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'All required fields must be completed.'**
  String get tone_professional_fillAllFields;

  /// No description provided for @tone_professional_invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount entered.'**
  String get tone_professional_invalidAmount;

  /// No description provided for @tone_professional_budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget created.|Budget configured successfully.|New budget is active.'**
  String get tone_professional_budgetCreated;

  /// No description provided for @tone_professional_budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated.'**
  String get tone_professional_budgetUpdated;

  /// No description provided for @tone_professional_budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted.'**
  String get tone_professional_budgetDeleted;

  /// No description provided for @tone_professional_goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Goal created.|Savings goal configured.|New goal is active.'**
  String get tone_professional_goalCreated;

  /// No description provided for @tone_professional_goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal updated.'**
  String get tone_professional_goalUpdated;

  /// No description provided for @tone_professional_goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted.'**
  String get tone_professional_goalDeleted;

  /// No description provided for @tone_professional_accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account added.'**
  String get tone_professional_accountCreated;

  /// No description provided for @tone_professional_billAdded.
  ///
  /// In en, this message translates to:
  /// **'Bill added. Reminders will be sent.'**
  String get tone_professional_billAdded;

  /// No description provided for @tone_professional_billPaid.
  ///
  /// In en, this message translates to:
  /// **'Bill marked as paid.|Payment recorded.|Bill settled.'**
  String get tone_professional_billPaid;

  /// No description provided for @tone_professional_backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully.'**
  String get tone_professional_backupSuccess;

  /// No description provided for @tone_professional_restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully.'**
  String get tone_professional_restoreSuccess;

  /// No description provided for @tone_professional_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded.\nAdd your first entry.|No records found.\nBegin by adding a transaction.|Transaction history is empty.\nStart recording.'**
  String get tone_professional_noTransactions;

  /// No description provided for @tone_professional_noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets configured.'**
  String get tone_professional_noBudgets;

  /// No description provided for @tone_professional_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals set.'**
  String get tone_professional_noGoals;

  /// No description provided for @tone_professional_genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get tone_professional_genericError;

  /// No description provided for @tone_professional_smsImportEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-import enabled.'**
  String get tone_professional_smsImportEnabled;

  /// No description provided for @tone_professional_dashboardAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All items are up to date.|No pending actions.|Everything is current.'**
  String get tone_professional_dashboardAllCaughtUp;

  /// No description provided for @tone_professional_dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yesterday.|Yesterday had no recorded activity.|No entries for the previous day.'**
  String get tone_professional_dailySummaryEmpty;

  /// No description provided for @tone_professional_streakMessage.
  ///
  /// In en, this message translates to:
  /// **'{days} consecutive days of tracking.'**
  String tone_professional_streakMessage(int days);

  /// No description provided for @tone_professional_budgetExceededBy.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded by {amount}.'**
  String tone_professional_budgetExceededBy(String amount);

  /// No description provided for @tone_motivational_txnAdded.
  ///
  /// In en, this message translates to:
  /// **'Great move! Transaction saved! 💪|Logged! You\'re on a roll 💪|Another one tracked! Keep the momentum! ✨|Saved! Every entry is a step forward! 🚀'**
  String get tone_motivational_txnAdded;

  /// No description provided for @tone_motivational_txnUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nice update! Staying sharp! ✨|Updated! Precision matters! ✨|Changes saved! You\'re on it! 👍'**
  String get tone_motivational_txnUpdated;

  /// No description provided for @tone_motivational_txnDeleted.
  ///
  /// In en, this message translates to:
  /// **'Cleared out! One less to worry about|Removed! Keeping things clean! 💪|Gone! Focus on what matters'**
  String get tone_motivational_txnDeleted;

  /// No description provided for @tone_motivational_txnFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t go through — give it another shot!'**
  String get tone_motivational_txnFailed;

  /// No description provided for @tone_motivational_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Every rupee counts — enter the amount!'**
  String get tone_motivational_enterAmount;

  /// No description provided for @tone_motivational_pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick an account to keep things organized!'**
  String get tone_motivational_pickAccount;

  /// No description provided for @tone_motivational_pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Categorize it — you\'ll thank yourself later!'**
  String get tone_motivational_pickCategory;

  /// No description provided for @tone_motivational_fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Fill in everything to continue'**
  String get tone_motivational_fillAllFields;

  /// No description provided for @tone_motivational_invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'That amount doesn\'t look right — try again!'**
  String get tone_motivational_invalidAmount;

  /// No description provided for @tone_motivational_budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Smart move! Budget is set! 💪|Budget locked in! You\'re taking control! 💪|That\'s discipline! Budget ready! 📊'**
  String get tone_motivational_budgetCreated;

  /// No description provided for @tone_motivational_budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget adjusted — staying flexible!'**
  String get tone_motivational_budgetUpdated;

  /// No description provided for @tone_motivational_budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get tone_motivational_budgetDeleted;

  /// No description provided for @tone_motivational_goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Love the ambition! Goal set! 🎯|Big dreams start here! Goal locked in! 🎯|That\'s the spirit! New goal ready! 🚀'**
  String get tone_motivational_goalCreated;

  /// No description provided for @tone_motivational_goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal refined — keep pushing!'**
  String get tone_motivational_goalUpdated;

  /// No description provided for @tone_motivational_goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal removed — new priorities, new plans'**
  String get tone_motivational_goalDeleted;

  /// No description provided for @tone_motivational_accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account added! You\'re getting organized! 🏦'**
  String get tone_motivational_accountCreated;

  /// No description provided for @tone_motivational_billAdded.
  ///
  /// In en, this message translates to:
  /// **'Bill tracked! You\'re staying ahead! 🔔'**
  String get tone_motivational_billAdded;

  /// No description provided for @tone_motivational_billPaid.
  ///
  /// In en, this message translates to:
  /// **'Bill paid! One less thing to worry about! ✅|Crushed it! Bill is done! ✅|Paid and done! You\'re ahead of the game! 💪'**
  String get tone_motivational_billPaid;

  /// No description provided for @tone_motivational_backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backed up! Your progress is safe! 🛡️'**
  String get tone_motivational_backupSuccess;

  /// No description provided for @tone_motivational_restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored! Right back on track! 🎉'**
  String get tone_motivational_restoreSuccess;

  /// No description provided for @tone_motivational_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'Fresh start! 🌟\nAdd your first transaction — every journey begins with one step|Empty slate! 🌟\nYour first entry is waiting — let\'s go!|Nothing yet! 💪\nOne transaction and you\'re on your way!'**
  String get tone_motivational_noTransactions;

  /// No description provided for @tone_motivational_noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet\nSet one up — your future self will thank you! 💪'**
  String get tone_motivational_noBudgets;

  /// No description provided for @tone_motivational_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet\nDream big — set your first goal! 🎯'**
  String get tone_motivational_noGoals;

  /// No description provided for @tone_motivational_genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — try again!'**
  String get tone_motivational_genericError;

  /// No description provided for @tone_motivational_smsImportEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-import on! Your finances track themselves now! 📩'**
  String get tone_motivational_smsImportEnabled;

  /// No description provided for @tone_motivational_dashboardAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up — you\'re ahead of the game! 🏆|Nothing pending — you\'re on top of it 💪|All clear! Keep this energy going 🏆'**
  String get tone_motivational_dashboardAllCaughtUp;

  /// No description provided for @tone_motivational_dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Zero spend yesterday — your wallet thanks you! ✨|Nothing spent yesterday — that\'s willpower! 💪|A no-spend day! That\'s a win! 🏆'**
  String get tone_motivational_dailySummaryEmpty;

  /// No description provided for @tone_motivational_streakMessage.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak! Unstoppable! 🔥'**
  String tone_motivational_streakMessage(int days);

  /// No description provided for @tone_motivational_budgetExceededBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount} — you can course-correct! 💪'**
  String tone_motivational_budgetExceededBy(String amount);

  /// No description provided for @tone_calm_txnAdded.
  ///
  /// In en, this message translates to:
  /// **'Noted.|Recorded.|Saved quietly.'**
  String get tone_calm_txnAdded;

  /// No description provided for @tone_calm_txnUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated.|Adjusted.|Changes saved.'**
  String get tone_calm_txnUpdated;

  /// No description provided for @tone_calm_txnDeleted.
  ///
  /// In en, this message translates to:
  /// **'Released.|Removed.|Let go.'**
  String get tone_calm_txnDeleted;

  /// No description provided for @tone_calm_txnFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t land. Try once more.'**
  String get tone_calm_txnFailed;

  /// No description provided for @tone_calm_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'An amount is needed.'**
  String get tone_calm_enterAmount;

  /// No description provided for @tone_calm_pickAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose where this belongs.'**
  String get tone_calm_pickAccount;

  /// No description provided for @tone_calm_pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Give it a purpose.'**
  String get tone_calm_pickCategory;

  /// No description provided for @tone_calm_fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'A few things are still empty.'**
  String get tone_calm_fillAllFields;

  /// No description provided for @tone_calm_invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'The amount needs adjusting.'**
  String get tone_calm_invalidAmount;

  /// No description provided for @tone_calm_budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Boundary set.|Budget in place.|Limits defined.'**
  String get tone_calm_budgetCreated;

  /// No description provided for @tone_calm_budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Adjusted.'**
  String get tone_calm_budgetUpdated;

  /// No description provided for @tone_calm_budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Released.'**
  String get tone_calm_budgetDeleted;

  /// No description provided for @tone_calm_goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Intention set.|A new direction.|Goal planted.'**
  String get tone_calm_goalCreated;

  /// No description provided for @tone_calm_goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Refined.'**
  String get tone_calm_goalUpdated;

  /// No description provided for @tone_calm_goalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Released.'**
  String get tone_calm_goalDeleted;

  /// No description provided for @tone_calm_accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account opened.'**
  String get tone_calm_accountCreated;

  /// No description provided for @tone_calm_billAdded.
  ///
  /// In en, this message translates to:
  /// **'Noted. You\'ll be reminded.'**
  String get tone_calm_billAdded;

  /// No description provided for @tone_calm_billPaid.
  ///
  /// In en, this message translates to:
  /// **'Settled.|Paid. One less.|Done. Peace of mind.'**
  String get tone_calm_billPaid;

  /// No description provided for @tone_calm_backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Safely stored.'**
  String get tone_calm_backupSuccess;

  /// No description provided for @tone_calm_restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored. Welcome back.'**
  String get tone_calm_restoreSuccess;

  /// No description provided for @tone_calm_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'A clean slate.\nBegin when you\'re ready.|Nothing here yet.\nStart gently.|Empty.\nA fresh beginning awaits.'**
  String get tone_calm_noTransactions;

  /// No description provided for @tone_calm_noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No boundaries yet.\nSet one when it feels right.'**
  String get tone_calm_noBudgets;

  /// No description provided for @tone_calm_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No intentions yet.\nSet one when you\'re ready.'**
  String get tone_calm_noGoals;

  /// No description provided for @tone_calm_genericError.
  ///
  /// In en, this message translates to:
  /// **'Something shifted. Try again.'**
  String get tone_calm_genericError;

  /// No description provided for @tone_calm_smsImportEnabled.
  ///
  /// In en, this message translates to:
  /// **'Quietly watching your transactions.'**
  String get tone_calm_smsImportEnabled;

  /// No description provided for @tone_calm_dashboardAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'Everything is in order.|Nothing needs attention.|All is well.'**
  String get tone_calm_dashboardAllCaughtUp;

  /// No description provided for @tone_calm_dailySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'A quiet day. Nothing recorded.|Yesterday was still. No entries.|Nothing spent. A restful day.'**
  String get tone_calm_dailySummaryEmpty;

  /// No description provided for @tone_calm_streakMessage.
  ///
  /// In en, this message translates to:
  /// **'{days} days of mindful tracking.'**
  String tone_calm_streakMessage(int days);

  /// No description provided for @tone_calm_budgetExceededBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}. A moment to reflect.'**
  String tone_calm_budgetExceededBy(String amount);

  /// No description provided for @tone_friendly_insightBillsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Heads up — bills incoming'**
  String get tone_friendly_insightBillsDueSoon;

  /// No description provided for @tone_friendly_insightOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get tone_friendly_insightOverBudget;

  /// No description provided for @tone_friendly_insightNearBudget.
  ///
  /// In en, this message translates to:
  /// **'Getting close...'**
  String get tone_friendly_insightNearBudget;

  /// No description provided for @tone_friendly_insightOverspending.
  ///
  /// In en, this message translates to:
  /// **'Spending outpacing income'**
  String get tone_friendly_insightOverspending;

  /// No description provided for @tone_friendly_insightSpendingSpike.
  ///
  /// In en, this message translates to:
  /// **'Spending spike today'**
  String get tone_friendly_insightSpendingSpike;

  /// No description provided for @tone_friendly_insightWeekendAlert.
  ///
  /// In en, this message translates to:
  /// **'Weekend spending alert'**
  String get tone_friendly_insightWeekendAlert;

  /// No description provided for @tone_friendly_insightGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started! 🚀'**
  String get tone_friendly_insightGetStarted;

  /// No description provided for @tone_friendly_insightGetStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction — it only takes a sec'**
  String get tone_friendly_insightGetStartedMessage;

  /// No description provided for @tone_friendly_insightBillsDueMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due soon, don\'t forget!'**
  String tone_friendly_insightBillsDueMessage(int count);

  /// No description provided for @tone_friendly_insightOverBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) went over this month — worth a look'**
  String tone_friendly_insightOverBudgetMessage(int count);

  /// No description provided for @tone_friendly_insightNearBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) past 80% — still time to rein it in'**
  String tone_friendly_insightNearBudgetMessage(int count);

  /// No description provided for @tone_friendly_insightOverspendingMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re {amount} over your income this month — might want to slow down'**
  String tone_friendly_insightOverspendingMessage(String amount);

  /// No description provided for @tone_friendly_insightSpendingSpikeMessage.
  ///
  /// In en, this message translates to:
  /// **'You usually spend {avg}/day. Today\'s already {today}.'**
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today);

  /// No description provided for @tone_friendly_insightWeekendAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'You usually spend {avg} on weekends. This one\'s already {current}.'**
  String tone_friendly_insightWeekendAlertMessage(String avg, String current);

  /// No description provided for @tone_professional_insightBillsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bills'**
  String get tone_professional_insightBillsDueSoon;

  /// No description provided for @tone_professional_insightOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get tone_professional_insightOverBudget;

  /// No description provided for @tone_professional_insightNearBudget.
  ///
  /// In en, this message translates to:
  /// **'Approaching budget limit'**
  String get tone_professional_insightNearBudget;

  /// No description provided for @tone_professional_insightOverspending.
  ///
  /// In en, this message translates to:
  /// **'Expenses exceed income'**
  String get tone_professional_insightOverspending;

  /// No description provided for @tone_professional_insightSpendingSpike.
  ///
  /// In en, this message translates to:
  /// **'Elevated spending today'**
  String get tone_professional_insightSpendingSpike;

  /// No description provided for @tone_professional_insightWeekendAlert.
  ///
  /// In en, this message translates to:
  /// **'Weekend spending elevated'**
  String get tone_professional_insightWeekendAlert;

  /// No description provided for @tone_professional_insightGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get tone_professional_insightGetStarted;

  /// No description provided for @tone_professional_insightGetStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Record your first transaction to begin tracking.'**
  String get tone_professional_insightGetStartedMessage;

  /// No description provided for @tone_professional_insightBillsDueMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due within the next few days.'**
  String tone_professional_insightBillsDueMessage(int count);

  /// No description provided for @tone_professional_insightOverBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded this month.'**
  String tone_professional_insightOverBudgetMessage(int count);

  /// No description provided for @tone_professional_insightNearBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) above 80% utilization.'**
  String tone_professional_insightNearBudgetMessage(int count);

  /// No description provided for @tone_professional_insightOverspendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Expenditure exceeds income by {amount} this month.'**
  String tone_professional_insightOverspendingMessage(String amount);

  /// No description provided for @tone_professional_insightSpendingSpikeMessage.
  ///
  /// In en, this message translates to:
  /// **'Daily average: {avg}. Today: {today}.'**
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today);

  /// No description provided for @tone_professional_insightWeekendAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Weekend average: {avg}. Current: {current}.'**
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current);

  /// No description provided for @tone_motivational_insightBillsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Bills coming up! 📋'**
  String get tone_motivational_insightBillsDueSoon;

  /// No description provided for @tone_motivational_insightOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget — time to regroup'**
  String get tone_motivational_insightOverBudget;

  /// No description provided for @tone_motivational_insightNearBudget.
  ///
  /// In en, this message translates to:
  /// **'Almost at the limit'**
  String get tone_motivational_insightNearBudget;

  /// No description provided for @tone_motivational_insightOverspending.
  ///
  /// In en, this message translates to:
  /// **'Spending exceeding income'**
  String get tone_motivational_insightOverspending;

  /// No description provided for @tone_motivational_insightSpendingSpike.
  ///
  /// In en, this message translates to:
  /// **'Spending spike today'**
  String get tone_motivational_insightSpendingSpike;

  /// No description provided for @tone_motivational_insightWeekendAlert.
  ///
  /// In en, this message translates to:
  /// **'Weekend spending alert'**
  String get tone_motivational_insightWeekendAlert;

  /// No description provided for @tone_motivational_insightGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build something great! 🚀'**
  String get tone_motivational_insightGetStarted;

  /// No description provided for @tone_motivational_insightGetStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction — you\'re one step away!'**
  String get tone_motivational_insightGetStartedMessage;

  /// No description provided for @tone_motivational_insightBillsDueMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due soon — stay ahead!'**
  String tone_motivational_insightBillsDueMessage(int count);

  /// No description provided for @tone_motivational_insightOverBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded — you can course-correct!'**
  String tone_motivational_insightOverBudgetMessage(int count);

  /// No description provided for @tone_motivational_insightNearBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) past 80% — you\'ve got this, stay mindful!'**
  String tone_motivational_insightNearBudgetMessage(int count);

  /// No description provided for @tone_motivational_insightOverspendingMessage.
  ///
  /// In en, this message translates to:
  /// **'{amount} over income — small adjustments make a big difference!'**
  String tone_motivational_insightOverspendingMessage(String amount);

  /// No description provided for @tone_motivational_insightSpendingSpikeMessage.
  ///
  /// In en, this message translates to:
  /// **'Usually {avg}/day. Today\'s {today} — be intentional!'**
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today);

  /// No description provided for @tone_motivational_insightWeekendAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Weekend avg: {avg}. This one\'s {current} — stay aware!'**
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current);

  /// No description provided for @tone_calm_insightBillsDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Bills approaching'**
  String get tone_calm_insightBillsDueSoon;

  /// No description provided for @tone_calm_insightOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over the line'**
  String get tone_calm_insightOverBudget;

  /// No description provided for @tone_calm_insightNearBudget.
  ///
  /// In en, this message translates to:
  /// **'Nearing the edge'**
  String get tone_calm_insightNearBudget;

  /// No description provided for @tone_calm_insightOverspending.
  ///
  /// In en, this message translates to:
  /// **'Outflow exceeds inflow'**
  String get tone_calm_insightOverspending;

  /// No description provided for @tone_calm_insightSpendingSpike.
  ///
  /// In en, this message translates to:
  /// **'A heavier day'**
  String get tone_calm_insightSpendingSpike;

  /// No description provided for @tone_calm_insightWeekendAlert.
  ///
  /// In en, this message translates to:
  /// **'Weekend spending'**
  String get tone_calm_insightWeekendAlert;

  /// No description provided for @tone_calm_insightGetStarted.
  ///
  /// In en, this message translates to:
  /// **'A fresh start'**
  String get tone_calm_insightGetStarted;

  /// No description provided for @tone_calm_insightGetStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Begin with your first transaction.'**
  String get tone_calm_insightGetStartedMessage;

  /// No description provided for @tone_calm_insightBillsDueMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) arriving soon.'**
  String tone_calm_insightBillsDueMessage(int count);

  /// No description provided for @tone_calm_insightOverBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded. Reflect and adjust.'**
  String tone_calm_insightOverBudgetMessage(int count);

  /// No description provided for @tone_calm_insightNearBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) past 80%. Mindful spending helps.'**
  String tone_calm_insightNearBudgetMessage(int count);

  /// No description provided for @tone_calm_insightOverspendingMessage.
  ///
  /// In en, this message translates to:
  /// **'{amount} more spent than earned. A moment to pause.'**
  String tone_calm_insightOverspendingMessage(String amount);

  /// No description provided for @tone_calm_insightSpendingSpikeMessage.
  ///
  /// In en, this message translates to:
  /// **'Usually {avg}/day. Today, {today}.'**
  String tone_calm_insightSpendingSpikeMessage(String avg, String today);

  /// No description provided for @tone_calm_insightWeekendAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Usually {avg}. This weekend, {current}.'**
  String tone_calm_insightWeekendAlertMessage(String avg, String current);

  /// No description provided for @tone_friendly_insightMoneyLeak.
  ///
  /// In en, this message translates to:
  /// **'{category}: {count} times this month, {total} total — small hits add up'**
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total);

  /// No description provided for @tone_friendly_insightBestDay.
  ///
  /// In en, this message translates to:
  /// **'{wAvg} avg on {worst}s vs {bAvg} on {best}s — that\'s {saving} you could keep'**
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving);

  /// No description provided for @tone_professional_insightMoneyLeak.
  ///
  /// In en, this message translates to:
  /// **'{category}: {count} transactions, {total} total this month.'**
  String tone_professional_insightMoneyLeak(
      String category, int count, String total);

  /// No description provided for @tone_professional_insightBestDay.
  ///
  /// In en, this message translates to:
  /// **'{wAvg} avg on {worst}s vs {bAvg} on {best}s. Potential saving: {saving}.'**
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving);

  /// No description provided for @tone_motivational_insightMoneyLeak.
  ///
  /// In en, this message translates to:
  /// **'{category}: {count} times, {total} — small wins add up if you cut back!'**
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total);

  /// No description provided for @tone_motivational_insightBestDay.
  ///
  /// In en, this message translates to:
  /// **'{wAvg} on {worst}s vs {bAvg} on {best}s — {saving} potential savings!'**
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving);

  /// No description provided for @tone_calm_insightMoneyLeak.
  ///
  /// In en, this message translates to:
  /// **'{category}: {count} times, {total}. Small streams form rivers.'**
  String tone_calm_insightMoneyLeak(String category, int count, String total);

  /// No description provided for @tone_calm_insightBestDay.
  ///
  /// In en, this message translates to:
  /// **'{worst}s: {wAvg}. {best}s: {bAvg}. {saving} to keep.'**
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving);

  /// No description provided for @tone_friendly_txnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find that transaction'**
  String get tone_friendly_txnNotFound;

  /// No description provided for @tone_friendly_futureDate.
  ///
  /// In en, this message translates to:
  /// **'Pick today or earlier'**
  String get tone_friendly_futureDate;

  /// No description provided for @tone_friendly_selectAccountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick an account & category first'**
  String get tone_friendly_selectAccountAndCategory;

  /// No description provided for @tone_friendly_addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add at least one person to split with'**
  String get tone_friendly_addParticipant;

  /// No description provided for @tone_friendly_budgetExceededAdjust.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded this budget. Maybe ease up a bit?'**
  String get tone_friendly_budgetExceededAdjust;

  /// No description provided for @tone_friendly_budgetGreatDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Great discipline! You\'re well within your budget ✨'**
  String get tone_friendly_budgetGreatDiscipline;

  /// No description provided for @tone_friendly_comparisonSpentSame.
  ///
  /// In en, this message translates to:
  /// **'Spending is about the same as last month — steady!'**
  String get tone_friendly_comparisonSpentSame;

  /// No description provided for @tone_friendly_accountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated!'**
  String get tone_friendly_accountUpdated;

  /// No description provided for @tone_friendly_accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account removed'**
  String get tone_friendly_accountDeleted;

  /// No description provided for @tone_friendly_accountLocked.
  ///
  /// In en, this message translates to:
  /// **'This account is locked — upgrade to Pro to use it 🔒'**
  String get tone_friendly_accountLocked;

  /// No description provided for @tone_friendly_categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Category added!'**
  String get tone_friendly_categoryCreated;

  /// No description provided for @tone_friendly_categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category removed'**
  String get tone_friendly_categoryDeleted;

  /// No description provided for @tone_friendly_categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name!'**
  String get tone_friendly_categoryNameRequired;

  /// No description provided for @tone_friendly_billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bill removed'**
  String get tone_friendly_billDeleted;

  /// No description provided for @tone_friendly_backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup didn\'t work — try again?'**
  String get tone_friendly_backupFailed;

  /// No description provided for @tone_friendly_restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed — is the file okay?'**
  String get tone_friendly_restoreFailed;

  /// No description provided for @tone_friendly_invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid backup file'**
  String get tone_friendly_invalidBackupFile;

  /// No description provided for @tone_friendly_corruptBackup.
  ///
  /// In en, this message translates to:
  /// **'This backup looks corrupted 😕'**
  String get tone_friendly_corruptBackup;

  /// No description provided for @tone_friendly_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved! ✓'**
  String get tone_friendly_settingsSaved;

  /// No description provided for @tone_friendly_reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated ⏰'**
  String get tone_friendly_reminderUpdated;

  /// No description provided for @tone_friendly_biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed — try again'**
  String get tone_friendly_biometricFailed;

  /// No description provided for @tone_friendly_incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN — give it another shot'**
  String get tone_friendly_incorrectPin;

  /// No description provided for @tone_friendly_notificationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Need notification access to auto-import transactions'**
  String get tone_friendly_notificationAccessDenied;

  /// No description provided for @tone_friendly_noBills.
  ///
  /// In en, this message translates to:
  /// **'No bills tracked\\nAdd recurring bills so you never miss a payment'**
  String get tone_friendly_noBills;

  /// No description provided for @tone_friendly_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet\\nAdd one to start tracking'**
  String get tone_friendly_noAccounts;

  /// No description provided for @tone_friendly_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get tone_friendly_noCategories;

  /// No description provided for @tone_friendly_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'All quiet here\\nNo notifications yet'**
  String get tone_friendly_noNotifications;

  /// No description provided for @tone_friendly_noData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet\\nKeep tracking to unlock insights'**
  String get tone_friendly_noData;

  /// No description provided for @tone_friendly_noRecurring.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions\\nAdd bills to auto-track them'**
  String get tone_friendly_noRecurring;

  /// No description provided for @tone_friendly_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported! 📄'**
  String get tone_friendly_exportSuccess;

  /// No description provided for @tone_friendly_purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase didn\'t go through — try again?'**
  String get tone_friendly_purchaseFailed;

  /// No description provided for @tone_friendly_playNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play isn\'t available on this device'**
  String get tone_friendly_playNotAvailable;

  /// No description provided for @tone_friendly_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get tone_friendly_deleteTitle;

  /// No description provided for @tone_friendly_deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get tone_friendly_deleteCancel;

  /// No description provided for @tone_friendly_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tone_friendly_deleteConfirm;

  /// No description provided for @tone_friendly_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaving already?'**
  String get tone_friendly_logoutTitle;

  /// No description provided for @tone_friendly_logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'All your data will be cleared from this device.'**
  String get tone_friendly_logoutMessage;

  /// No description provided for @tone_friendly_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tone_friendly_logoutConfirm;

  /// No description provided for @tone_friendly_currencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Base currency updated! 💱'**
  String get tone_friendly_currencyChanged;

  /// No description provided for @tone_friendly_currencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change base currency?'**
  String get tone_friendly_currencyChangeTitle;

  /// No description provided for @tone_friendly_currencyChangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get tone_friendly_currencyChangeCancel;

  /// No description provided for @tone_friendly_currencyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Currency'**
  String get tone_friendly_currencyPickerTitle;

  /// No description provided for @tone_friendly_dashboardWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Let\'s see where you stand'**
  String get tone_friendly_dashboardWelcomeBack;

  /// No description provided for @tone_professional_txnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found.'**
  String get tone_professional_txnNotFound;

  /// No description provided for @tone_professional_futureDate.
  ///
  /// In en, this message translates to:
  /// **'Future dates are not permitted.'**
  String get tone_professional_futureDate;

  /// No description provided for @tone_professional_selectAccountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Account and category are required.'**
  String get tone_professional_selectAccountAndCategory;

  /// No description provided for @tone_professional_addParticipant.
  ///
  /// In en, this message translates to:
  /// **'At least one participant is required.'**
  String get tone_professional_addParticipant;

  /// No description provided for @tone_professional_budgetExceededAdjust.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded. Review spending or adjust the limit.'**
  String get tone_professional_budgetExceededAdjust;

  /// No description provided for @tone_professional_budgetGreatDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Well within budget. Good financial discipline.'**
  String get tone_professional_budgetGreatDiscipline;

  /// No description provided for @tone_professional_comparisonSpentSame.
  ///
  /// In en, this message translates to:
  /// **'Spending is consistent with last month.'**
  String get tone_professional_comparisonSpentSame;

  /// No description provided for @tone_professional_accountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated.'**
  String get tone_professional_accountUpdated;

  /// No description provided for @tone_professional_accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account removed.'**
  String get tone_professional_accountDeleted;

  /// No description provided for @tone_professional_accountLocked.
  ///
  /// In en, this message translates to:
  /// **'Account locked. Pro subscription required.'**
  String get tone_professional_accountLocked;

  /// No description provided for @tone_professional_categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Category added.'**
  String get tone_professional_categoryCreated;

  /// No description provided for @tone_professional_categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category removed.'**
  String get tone_professional_categoryDeleted;

  /// No description provided for @tone_professional_categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required.'**
  String get tone_professional_categoryNameRequired;

  /// No description provided for @tone_professional_billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bill removed.'**
  String get tone_professional_billDeleted;

  /// No description provided for @tone_professional_backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Please try again.'**
  String get tone_professional_backupFailed;

  /// No description provided for @tone_professional_restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Verify the backup file.'**
  String get tone_professional_restoreFailed;

  /// No description provided for @tone_professional_invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file format.'**
  String get tone_professional_invalidBackupFile;

  /// No description provided for @tone_professional_corruptBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup file is corrupted.'**
  String get tone_professional_corruptBackup;

  /// No description provided for @tone_professional_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get tone_professional_settingsSaved;

  /// No description provided for @tone_professional_reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder time updated.'**
  String get tone_professional_reminderUpdated;

  /// No description provided for @tone_professional_biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get tone_professional_biometricFailed;

  /// No description provided for @tone_professional_incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN.'**
  String get tone_professional_incorrectPin;

  /// No description provided for @tone_professional_notificationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification access is required for auto-import.'**
  String get tone_professional_notificationAccessDenied;

  /// No description provided for @tone_professional_noBills.
  ///
  /// In en, this message translates to:
  /// **'No recurring bills.'**
  String get tone_professional_noBills;

  /// No description provided for @tone_professional_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts configured.'**
  String get tone_professional_noAccounts;

  /// No description provided for @tone_professional_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories defined.'**
  String get tone_professional_noCategories;

  /// No description provided for @tone_professional_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications.'**
  String get tone_professional_noNotifications;

  /// No description provided for @tone_professional_noData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data.\\nContinue recording transactions.'**
  String get tone_professional_noData;

  /// No description provided for @tone_professional_noRecurring.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions configured.'**
  String get tone_professional_noRecurring;

  /// No description provided for @tone_professional_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported.'**
  String get tone_professional_exportSuccess;

  /// No description provided for @tone_professional_purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please retry.'**
  String get tone_professional_purchaseFailed;

  /// No description provided for @tone_professional_playNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play Services unavailable.'**
  String get tone_professional_playNotAvailable;

  /// No description provided for @tone_professional_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get tone_professional_deleteTitle;

  /// No description provided for @tone_professional_deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tone_professional_deleteCancel;

  /// No description provided for @tone_professional_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tone_professional_deleteConfirm;

  /// No description provided for @tone_professional_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get tone_professional_logoutTitle;

  /// No description provided for @tone_professional_logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'All local data will be erased.'**
  String get tone_professional_logoutMessage;

  /// No description provided for @tone_professional_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tone_professional_logoutConfirm;

  /// No description provided for @tone_professional_currencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Base currency updated.'**
  String get tone_professional_currencyChanged;

  /// No description provided for @tone_professional_currencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Base Currency'**
  String get tone_professional_currencyChangeTitle;

  /// No description provided for @tone_professional_currencyChangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tone_professional_currencyChangeCancel;

  /// No description provided for @tone_professional_currencyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get tone_professional_currencyPickerTitle;

  /// No description provided for @tone_professional_dashboardWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Here is your summary.'**
  String get tone_professional_dashboardWelcomeBack;

  /// No description provided for @tone_motivational_txnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find that one — it may have been removed'**
  String get tone_motivational_txnNotFound;

  /// No description provided for @tone_motivational_futureDate.
  ///
  /// In en, this message translates to:
  /// **'Let\'s stay in the present — pick today or earlier'**
  String get tone_motivational_futureDate;

  /// No description provided for @tone_motivational_selectAccountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Account & category first — you\'re almost done!'**
  String get tone_motivational_selectAccountAndCategory;

  /// No description provided for @tone_motivational_addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add at least one person to split with!'**
  String get tone_motivational_addParticipant;

  /// No description provided for @tone_motivational_budgetExceededAdjust.
  ///
  /// In en, this message translates to:
  /// **'Over budget — but every day is a chance to reset! 💪'**
  String get tone_motivational_budgetExceededAdjust;

  /// No description provided for @tone_motivational_budgetGreatDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Amazing discipline! You\'re way ahead! 🏆'**
  String get tone_motivational_budgetGreatDiscipline;

  /// No description provided for @tone_motivational_comparisonSpentSame.
  ///
  /// In en, this message translates to:
  /// **'Holding steady! Consistent spending shows control 💪'**
  String get tone_motivational_comparisonSpentSame;

  /// No description provided for @tone_motivational_accountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated!'**
  String get tone_motivational_accountUpdated;

  /// No description provided for @tone_motivational_accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account removed'**
  String get tone_motivational_accountDeleted;

  /// No description provided for @tone_motivational_accountLocked.
  ///
  /// In en, this message translates to:
  /// **'This account is locked — Go Pro to unlock! 🔒'**
  String get tone_motivational_accountLocked;

  /// No description provided for @tone_motivational_categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'New category added!'**
  String get tone_motivational_categoryCreated;

  /// No description provided for @tone_motivational_categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category removed'**
  String get tone_motivational_categoryDeleted;

  /// No description provided for @tone_motivational_categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name!'**
  String get tone_motivational_categoryNameRequired;

  /// No description provided for @tone_motivational_billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bill removed'**
  String get tone_motivational_billDeleted;

  /// No description provided for @tone_motivational_backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup didn\'t work — try again!'**
  String get tone_motivational_backupFailed;

  /// No description provided for @tone_motivational_restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed — check the file and retry'**
  String get tone_motivational_restoreFailed;

  /// No description provided for @tone_motivational_invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid backup'**
  String get tone_motivational_invalidBackupFile;

  /// No description provided for @tone_motivational_corruptBackup.
  ///
  /// In en, this message translates to:
  /// **'This backup seems damaged'**
  String get tone_motivational_corruptBackup;

  /// No description provided for @tone_motivational_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved! ✓'**
  String get tone_motivational_settingsSaved;

  /// No description provided for @tone_motivational_reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder set! ⏰'**
  String get tone_motivational_reminderUpdated;

  /// No description provided for @tone_motivational_biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed — try again!'**
  String get tone_motivational_biometricFailed;

  /// No description provided for @tone_motivational_incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN — you\'ve got this, try again!'**
  String get tone_motivational_incorrectPin;

  /// No description provided for @tone_motivational_notificationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Need notification access to auto-track transactions'**
  String get tone_motivational_notificationAccessDenied;

  /// No description provided for @tone_motivational_noBills.
  ///
  /// In en, this message translates to:
  /// **'No bills tracked\\nStay ahead by adding your recurring bills'**
  String get tone_motivational_noBills;

  /// No description provided for @tone_motivational_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet\\nAdd one to start your financial journey!'**
  String get tone_motivational_noAccounts;

  /// No description provided for @tone_motivational_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get tone_motivational_noCategories;

  /// No description provided for @tone_motivational_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'All clear!\\nNo notifications — you\'re on top of things'**
  String get tone_motivational_noNotifications;

  /// No description provided for @tone_motivational_noData.
  ///
  /// In en, this message translates to:
  /// **'Keep going! 📈\\nMore data means better insights'**
  String get tone_motivational_noData;

  /// No description provided for @tone_motivational_noRecurring.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions\\nAutomate your bills to stay ahead!'**
  String get tone_motivational_noRecurring;

  /// No description provided for @tone_motivational_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported! 📄'**
  String get tone_motivational_exportSuccess;

  /// No description provided for @tone_motivational_purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase didn\'t go through — try again!'**
  String get tone_motivational_purchaseFailed;

  /// No description provided for @tone_motivational_playNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play isn\'t available on this device'**
  String get tone_motivational_playNotAvailable;

  /// No description provided for @tone_motivational_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get tone_motivational_deleteTitle;

  /// No description provided for @tone_motivational_deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get tone_motivational_deleteCancel;

  /// No description provided for @tone_motivational_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tone_motivational_deleteConfirm;

  /// No description provided for @tone_motivational_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Heading out?'**
  String get tone_motivational_logoutTitle;

  /// No description provided for @tone_motivational_logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'All data on this device will be cleared.'**
  String get tone_motivational_logoutMessage;

  /// No description provided for @tone_motivational_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tone_motivational_logoutConfirm;

  /// No description provided for @tone_motivational_currencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Currency switched! New chapter! 💱'**
  String get tone_motivational_currencyChanged;

  /// No description provided for @tone_motivational_currencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to switch?'**
  String get tone_motivational_currencyChangeTitle;

  /// No description provided for @tone_motivational_currencyChangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get tone_motivational_currencyChangeCancel;

  /// No description provided for @tone_motivational_currencyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick Your Currency! 🌍'**
  String get tone_motivational_currencyPickerTitle;

  /// No description provided for @tone_motivational_dashboardWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'You\'re back! Let\'s keep the progress going! 🚀'**
  String get tone_motivational_dashboardWelcomeBack;

  /// No description provided for @tone_calm_txnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found. It may have moved on.'**
  String get tone_calm_txnNotFound;

  /// No description provided for @tone_calm_futureDate.
  ///
  /// In en, this message translates to:
  /// **'Stay in the present.'**
  String get tone_calm_futureDate;

  /// No description provided for @tone_calm_selectAccountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Account and category, please.'**
  String get tone_calm_selectAccountAndCategory;

  /// No description provided for @tone_calm_addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add someone to share with.'**
  String get tone_calm_addParticipant;

  /// No description provided for @tone_calm_budgetExceededAdjust.
  ///
  /// In en, this message translates to:
  /// **'Past the boundary. Pause and reconsider.'**
  String get tone_calm_budgetExceededAdjust;

  /// No description provided for @tone_calm_budgetGreatDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Well within bounds. Peaceful.'**
  String get tone_calm_budgetGreatDiscipline;

  /// No description provided for @tone_calm_comparisonSpentSame.
  ///
  /// In en, this message translates to:
  /// **'Spending flows at the same pace.'**
  String get tone_calm_comparisonSpentSame;

  /// No description provided for @tone_calm_accountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Adjusted.'**
  String get tone_calm_accountUpdated;

  /// No description provided for @tone_calm_accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Closed.'**
  String get tone_calm_accountDeleted;

  /// No description provided for @tone_calm_accountLocked.
  ///
  /// In en, this message translates to:
  /// **'This one is resting. Pro unlocks it.'**
  String get tone_calm_accountLocked;

  /// No description provided for @tone_calm_categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Added.'**
  String get tone_calm_categoryCreated;

  /// No description provided for @tone_calm_categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed.'**
  String get tone_calm_categoryDeleted;

  /// No description provided for @tone_calm_categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A name, please.'**
  String get tone_calm_categoryNameRequired;

  /// No description provided for @tone_calm_billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Released.'**
  String get tone_calm_billDeleted;

  /// No description provided for @tone_calm_backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again gently.'**
  String get tone_calm_backupFailed;

  /// No description provided for @tone_calm_restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore. Check the file.'**
  String get tone_calm_restoreFailed;

  /// No description provided for @tone_calm_invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t feel right.'**
  String get tone_calm_invalidBackupFile;

  /// No description provided for @tone_calm_corruptBackup.
  ///
  /// In en, this message translates to:
  /// **'The file seems damaged.'**
  String get tone_calm_corruptBackup;

  /// No description provided for @tone_calm_settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get tone_calm_settingsSaved;

  /// No description provided for @tone_calm_reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder adjusted.'**
  String get tone_calm_reminderUpdated;

  /// No description provided for @tone_calm_biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Not recognized. Try again.'**
  String get tone_calm_biometricFailed;

  /// No description provided for @tone_calm_incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get tone_calm_incorrectPin;

  /// No description provided for @tone_calm_notificationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission needed for quiet tracking.'**
  String get tone_calm_notificationAccessDenied;

  /// No description provided for @tone_calm_noBills.
  ///
  /// In en, this message translates to:
  /// **'Nothing recurring.\\nPeaceful.'**
  String get tone_calm_noBills;

  /// No description provided for @tone_calm_noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.\\nStart simply.'**
  String get tone_calm_noAccounts;

  /// No description provided for @tone_calm_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get tone_calm_noCategories;

  /// No description provided for @tone_calm_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'Silence.\\nNothing needs attention.'**
  String get tone_calm_noNotifications;

  /// No description provided for @tone_calm_noData.
  ///
  /// In en, this message translates to:
  /// **'Not enough yet.\\nIt will come with time.'**
  String get tone_calm_noData;

  /// No description provided for @tone_calm_noRecurring.
  ///
  /// In en, this message translates to:
  /// **'Nothing recurring.\\nAdd when ready.'**
  String get tone_calm_noRecurring;

  /// No description provided for @tone_calm_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported.'**
  String get tone_calm_exportSuccess;

  /// No description provided for @tone_calm_purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase didn\'t complete. Try again.'**
  String get tone_calm_purchaseFailed;

  /// No description provided for @tone_calm_playNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Play Store not available here.'**
  String get tone_calm_playNotAvailable;

  /// No description provided for @tone_calm_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Let go?'**
  String get tone_calm_deleteTitle;

  /// No description provided for @tone_calm_deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Hold on'**
  String get tone_calm_deleteCancel;

  /// No description provided for @tone_calm_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get tone_calm_deleteConfirm;

  /// No description provided for @tone_calm_logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving on?'**
  String get tone_calm_logoutTitle;

  /// No description provided for @tone_calm_logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data here will be cleared.'**
  String get tone_calm_logoutMessage;

  /// No description provided for @tone_calm_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get tone_calm_logoutConfirm;

  /// No description provided for @tone_calm_currencyChanged.
  ///
  /// In en, this message translates to:
  /// **'Currency shifted.'**
  String get tone_calm_currencyChanged;

  /// No description provided for @tone_calm_currencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'A new currency?'**
  String get tone_calm_currencyChangeTitle;

  /// No description provided for @tone_calm_currencyChangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get tone_calm_currencyChangeCancel;

  /// No description provided for @tone_calm_currencyPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get tone_calm_currencyPickerTitle;

  /// No description provided for @tone_calm_dashboardWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get tone_calm_dashboardWelcomeBack;

  /// No description provided for @notif_quietDayTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Quiet day yesterday'**
  String get notif_quietDayTitle;

  /// No description provided for @notif_heresYesterdayTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Here\'s yesterday'**
  String get notif_heresYesterdayTitle;

  /// No description provided for @notif_weekInReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Week in review'**
  String get notif_weekInReviewTitle;

  /// No description provided for @notif_yourWeekInReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Your week in review'**
  String get notif_yourWeekInReviewTitle;

  /// No description provided for @notif_niceOneTitle.
  ///
  /// In en, this message translates to:
  /// **'🏆 Nice one!'**
  String get notif_niceOneTitle;

  /// No description provided for @notif_streakDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days} days straight!'**
  String notif_streakDaysTitle(int days);

  /// No description provided for @notif_levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Level {level}!'**
  String notif_levelUpTitle(int level);

  /// No description provided for @notif_budgetsOverLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 {count} budget(s) over limit'**
  String notif_budgetsOverLimitTitle(int count);

  /// No description provided for @notif_budgetsGettingTightTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ {count} budget(s) getting tight'**
  String notif_budgetsGettingTightTitle(int count);

  /// No description provided for @notif_billDueTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 {name} is due {label}'**
  String notif_billDueTitle(String name, String label);

  /// No description provided for @notif_fundsGettingLowTitle.
  ///
  /// In en, this message translates to:
  /// **'📉 Funds getting low'**
  String get notif_fundsGettingLowTitle;

  /// No description provided for @notif_categoryCreepingUpTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 {category} is creeping up'**
  String notif_categoryCreepingUpTitle(String category);

  /// No description provided for @notif_bigDayTitle.
  ///
  /// In en, this message translates to:
  /// **'📈 Whoa, big day'**
  String get notif_bigDayTitle;

  /// No description provided for @notif_smsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'📱 {count} SMS transactions found'**
  String notif_smsFoundTitle(int count);

  /// No description provided for @notif_smallSpendsTitle.
  ///
  /// In en, this message translates to:
  /// **'💧 Small spends adding up'**
  String get notif_smallSpendsTitle;

  /// No description provided for @notif_missYouTitle.
  ///
  /// In en, this message translates to:
  /// **'👋 We miss you'**
  String get notif_missYouTitle;

  /// No description provided for @notif_daysUntrackedTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 {days} days untracked'**
  String notif_daysUntrackedTitle(int days);

  /// No description provided for @notif_streakEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'💔 {days}-day streak ended'**
  String notif_streakEndedTitle(int days);

  /// No description provided for @notif_fewDaysUntrackedTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 A few days untracked'**
  String get notif_fewDaysUntrackedTitle;

  /// No description provided for @notif_budgetExceededBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is over budget — time to review'**
  String notif_budgetExceededBody(String name);

  /// No description provided for @notif_budgetExceededBodyMulti.
  ///
  /// In en, this message translates to:
  /// **'{names} are over budget'**
  String notif_budgetExceededBodyMulti(String names);

  /// No description provided for @notif_budgetWarningBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is nearing the limit'**
  String notif_budgetWarningBody(String name);

  /// No description provided for @notif_budgetWarningBodyMulti.
  ///
  /// In en, this message translates to:
  /// **'{names} are nearing their limits'**
  String notif_budgetWarningBodyMulti(String names);

  /// No description provided for @notif_budgetWarningPctBody.
  ///
  /// In en, this message translates to:
  /// **'{name}: {pct}% used'**
  String notif_budgetWarningPctBody(String name, String pct);

  /// No description provided for @notif_billPaidAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ {name} — auto-matched'**
  String notif_billPaidAutoTitle(String name);

  /// No description provided for @notif_billPaidRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ {name} — recorded'**
  String notif_billPaidRecordedTitle(String name);

  /// No description provided for @notif_smsLoggedTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ Transaction logged'**
  String get notif_smsLoggedTitle;

  /// No description provided for @notif_smsNeedsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'👀 Needs your review'**
  String get notif_smsNeedsReviewTitle;

  /// No description provided for @notif_smsLoggedBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} from {sender} — auto-saved'**
  String notif_smsLoggedBody(String amount, String sender);

  /// No description provided for @notif_smsLoggedBodyNoAmount.
  ///
  /// In en, this message translates to:
  /// **'From {sender} — auto-saved'**
  String notif_smsLoggedBodyNoAmount(String sender);

  /// No description provided for @notif_smsNeedsReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Transaction from {sender} — tap to review'**
  String notif_smsNeedsReviewBody(String sender);

  /// No description provided for @notif_smsGotItTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ Got it!'**
  String get notif_smsGotItTitle;

  /// No description provided for @notif_smsAllCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ All caught up!'**
  String get notif_smsAllCaughtUpTitle;

  /// No description provided for @notif_smsAlmostThereTitle.
  ///
  /// In en, this message translates to:
  /// **'📋 Almost there!'**
  String get notif_smsAlmostThereTitle;

  /// No description provided for @notif_smsNeedHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'👋 Hey, need your help!'**
  String get notif_smsNeedHelpTitle;

  /// No description provided for @notif_streakOnLineTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days}-day streak on the line!'**
  String notif_streakOnLineTitle(int days);

  /// No description provided for @notif_quickActionTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ 5 seconds is all it takes'**
  String get notif_quickActionTitle;

  /// No description provided for @notif_dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Your day in numbers'**
  String get notif_dailyReminderTitle;

  /// No description provided for @notif_dailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how yesterday went — take a quick look'**
  String get notif_dailyReminderBody;

  /// No description provided for @notif_weeklyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'📅 Your week wrapped up'**
  String get notif_weeklyReminderTitle;

  /// No description provided for @notif_weeklyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see how the week went — tap to check'**
  String get notif_weeklyReminderBody;

  /// No description provided for @notif_goalStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'🎯 Monthly Goal Status'**
  String get notif_goalStatusTitle;

  /// No description provided for @notif_goalStatusBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} active goals. {name} is {pct}% complete!'**
  String notif_goalStatusBody(int count, String name, String pct);

  /// No description provided for @notif_streakCountingTitle.
  ///
  /// In en, this message translates to:
  /// **'🔥 {days} days and counting!'**
  String notif_streakCountingTitle(int days);

  /// No description provided for @notif_achievementBody.
  ///
  /// In en, this message translates to:
  /// **'{title} — that\'s +{xp} XP for you'**
  String notif_achievementBody(String title, int xp);

  /// No description provided for @notif_levelUpBody.
  ///
  /// In en, this message translates to:
  /// **'You just leveled up — keep going!'**
  String get notif_levelUpBody;

  /// No description provided for @notif_streakMilestoneBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s dedication — your streak is on fire'**
  String get notif_streakMilestoneBody;

  /// No description provided for @notif_weeklyZeroBody.
  ///
  /// In en, this message translates to:
  /// **'Zero expenses this week — that\'s impressive 💪'**
  String get notif_weeklyZeroBody;

  /// No description provided for @insight_moneyLeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet money leak 💧'**
  String get insight_moneyLeakTitle;

  /// No description provided for @insight_bestDayTitle.
  ///
  /// In en, this message translates to:
  /// **'{day}s cost you the most'**
  String insight_bestDayTitle(String day);

  /// No description provided for @bills_howBillsWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'How Bills Work'**
  String get bills_howBillsWorkTitle;

  /// No description provided for @bills_howBillsWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'Track recurring bills like rent, subscriptions, and utilities. Get reminders before due dates and mark bills as paid.'**
  String get bills_howBillsWorkDesc;

  /// No description provided for @bills_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get bills_gotIt;

  /// No description provided for @bills_addBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get bills_addBill;

  /// No description provided for @bills_markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get bills_markAsPaid;

  /// No description provided for @bills_deleteBill.
  ///
  /// In en, this message translates to:
  /// **'Delete Bill'**
  String get bills_deleteBill;

  /// No description provided for @bills_addNewBill.
  ///
  /// In en, this message translates to:
  /// **'Add New Bill'**
  String get bills_addNewBill;

  /// No description provided for @bills_billName.
  ///
  /// In en, this message translates to:
  /// **'Bill Name'**
  String get bills_billName;

  /// No description provided for @bills_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get bills_amount;

  /// No description provided for @bills_frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get bills_frequency;

  /// No description provided for @bills_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get bills_monthly;

  /// No description provided for @bills_quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get bills_quarterly;

  /// No description provided for @bills_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get bills_yearly;

  /// No description provided for @bills_dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get bills_dueDate;

  /// No description provided for @goal_deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal?'**
  String get goal_deleteGoalTitle;

  /// No description provided for @goal_editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get goal_editGoal;

  /// No description provided for @goal_deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get goal_deleteGoal;

  /// No description provided for @goal_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get goal_saved;

  /// No description provided for @goal_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goal_target;

  /// No description provided for @goal_quickDeposit.
  ///
  /// In en, this message translates to:
  /// **'Quick Deposit'**
  String get goal_quickDeposit;

  /// No description provided for @goal_targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target Date'**
  String get goal_targetDate;

  /// No description provided for @goal_milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get goal_milestones;

  /// No description provided for @goal_recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get goal_recentActivity;

  /// No description provided for @goal_addToGoal.
  ///
  /// In en, this message translates to:
  /// **'Add to Goal'**
  String get goal_addToGoal;

  /// No description provided for @goal_goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached!'**
  String get goal_goalReached;

  /// No description provided for @goal_whatsThisAbout.
  ///
  /// In en, this message translates to:
  /// **'What\'s this goal about?'**
  String get goal_whatsThisAbout;

  /// No description provided for @goal_icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goal_icon;

  /// No description provided for @goal_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get goal_color;

  /// No description provided for @dashboard_enableCards.
  ///
  /// In en, this message translates to:
  /// **'Enable Cards'**
  String get dashboard_enableCards;

  /// No description provided for @recurring_fixedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Fixed Expenses'**
  String get recurring_fixedExpenses;

  /// No description provided for @goal_freePlanLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows up to 2 goals. Upgrade to Pro for unlimited.'**
  String get goal_freePlanLimit;

  /// No description provided for @goal_editGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get goal_editGoalTitle;

  /// No description provided for @goal_newGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get goal_newGoalTitle;

  /// No description provided for @goal_yourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your Goal'**
  String get goal_yourGoal;

  /// No description provided for @goal_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get goal_appearance;

  /// No description provided for @goal_goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goal_goalName;

  /// No description provided for @goal_giveGoalName.
  ///
  /// In en, this message translates to:
  /// **'Give your goal a name'**
  String get goal_giveGoalName;

  /// No description provided for @goal_targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get goal_targetAmount;

  /// No description provided for @goal_enterValidTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target amount'**
  String get goal_enterValidTarget;

  /// No description provided for @goal_alreadySaved.
  ///
  /// In en, this message translates to:
  /// **'Already Saved'**
  String get goal_alreadySaved;

  /// No description provided for @goal_targetDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Date'**
  String get goal_targetDateLabel;

  /// No description provided for @goal_setTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Set a target date (optional)'**
  String get goal_setTargetDate;

  /// No description provided for @goal_smartInsight.
  ///
  /// In en, this message translates to:
  /// **'Smart Insight'**
  String get goal_smartInsight;

  /// No description provided for @goal_onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get goal_onTrack;

  /// No description provided for @goal_onTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'This goal is very achievable 👍'**
  String get goal_onTrackDesc;

  /// No description provided for @goal_needsEffort.
  ///
  /// In en, this message translates to:
  /// **'Needs Effort'**
  String get goal_needsEffort;

  /// No description provided for @goal_needsEffortDesc.
  ///
  /// In en, this message translates to:
  /// **'Needs a bit more saving discipline'**
  String get goal_needsEffortDesc;

  /// No description provided for @goal_ambitious.
  ///
  /// In en, this message translates to:
  /// **'Ambitious'**
  String get goal_ambitious;

  /// No description provided for @goal_ambitiousDesc.
  ///
  /// In en, this message translates to:
  /// **'Consider extending the deadline'**
  String get goal_ambitiousDesc;

  /// No description provided for @goal_addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get goal_addNote;

  /// No description provided for @goal_note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get goal_note;

  /// No description provided for @goal_updateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get goal_updateGoal;

  /// No description provided for @goal_createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get goal_createGoal;

  /// No description provided for @profile_developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode Activated! 🚀'**
  String get profile_developerMode;

  /// No description provided for @profile_couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get profile_couldNotOpenLink;

  /// No description provided for @profile_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_about;

  /// No description provided for @profile_unableToCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Unable to check for updates'**
  String get profile_unableToCheckUpdates;

  /// No description provided for @profile_openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get profile_openSourceLicenses;

  /// No description provided for @account_totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get account_totalValue;

  /// No description provided for @account_gainLoss.
  ///
  /// In en, this message translates to:
  /// **'Gain/Loss'**
  String get account_gainLoss;

  /// No description provided for @account_holdings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get account_holdings;

  /// No description provided for @account_addHolding.
  ///
  /// In en, this message translates to:
  /// **'Add Holding'**
  String get account_addHolding;

  /// No description provided for @account_addMissingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Missing Transaction'**
  String get account_addMissingTransaction;

  /// No description provided for @account_whatWasThisFor.
  ///
  /// In en, this message translates to:
  /// **'What was this transaction for?'**
  String get account_whatWasThisFor;

  /// No description provided for @budget_used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get budget_used;

  /// No description provided for @budget_selectAtLeastOneTag.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one tag'**
  String get budget_selectAtLeastOneTag;

  /// No description provided for @budget_over.
  ///
  /// In en, this message translates to:
  /// **'over'**
  String get budget_over;

  /// No description provided for @budget_left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get budget_left;

  /// No description provided for @budget_breakdown.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get budget_breakdown;

  /// No description provided for @budget_basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get budget_basicInfo;

  /// No description provided for @budget_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get budget_duration;

  /// No description provided for @budget_budgetType.
  ///
  /// In en, this message translates to:
  /// **'Budget Type'**
  String get budget_budgetType;

  /// No description provided for @budget_selectType.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get budget_selectType;

  /// No description provided for @budget_categoryAllocation.
  ///
  /// In en, this message translates to:
  /// **'Category Allocation'**
  String get budget_categoryAllocation;

  /// No description provided for @budget_totalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get budget_totalBudget;

  /// No description provided for @budget_allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get budget_allocated;

  /// No description provided for @budget_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budget_remaining;

  /// No description provided for @budget_overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get budget_overBudget;

  /// No description provided for @budget_safeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend'**
  String get budget_safeToSpend;

  /// No description provided for @budget_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get budget_startDate;

  /// No description provided for @budget_endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get budget_endDate;

  /// No description provided for @budget_selectTags.
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get budget_selectTags;

  /// No description provided for @budget_tagInfo.
  ///
  /// In en, this message translates to:
  /// **'All expenses with selected tags will count towards this budget.'**
  String get budget_tagInfo;

  /// No description provided for @budget_noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Add tags to your transactions first.'**
  String get budget_noTags;

  /// No description provided for @budget_freePlanLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows up to 2 budgets. Upgrade to Pro for unlimited.'**
  String get budget_freePlanLimit;

  /// No description provided for @budget_daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String budget_daysRemaining(Object count);

  /// No description provided for @budget_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budget_delete;

  /// No description provided for @budget_emotionUnderControl.
  ///
  /// In en, this message translates to:
  /// **'Spending under control 💪'**
  String get budget_emotionUnderControl;

  /// No description provided for @budget_emotionHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway through the month ✨'**
  String get budget_emotionHalfway;

  /// No description provided for @budget_emotionAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Getting tight, stay careful ⚠️'**
  String get budget_emotionAlmostThere;

  /// No description provided for @budget_emotionExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded, time to adjust 🔴'**
  String get budget_emotionExceeded;

  /// No description provided for @budget_highlightLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get budget_highlightLabel;

  /// No description provided for @budget_overBudgetSection.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budget_overBudgetSection;

  /// No description provided for @budget_activeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Active budgets'**
  String get budget_activeBudgets;

  /// No description provided for @budget_onTrackSection.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budget_onTrackSection;

  /// No description provided for @budget_spendingPace.
  ///
  /// In en, this message translates to:
  /// **'Spending pace'**
  String get budget_spendingPace;

  /// No description provided for @budget_dailyActual.
  ///
  /// In en, this message translates to:
  /// **'{amount}/day actual'**
  String budget_dailyActual(Object amount);

  /// No description provided for @budget_dailyAllowed.
  ///
  /// In en, this message translates to:
  /// **'{amount}/day allowed'**
  String budget_dailyAllowed(Object amount);

  /// No description provided for @budget_stepNote0.
  ///
  /// In en, this message translates to:
  /// **'Give your budget a name and set how much you want to spend.'**
  String get budget_stepNote0;

  /// No description provided for @budget_stepNote1.
  ///
  /// In en, this message translates to:
  /// **'Choose how often this budget repeats and pick the dates.'**
  String get budget_stepNote1;

  /// No description provided for @budget_stepNote2.
  ///
  /// In en, this message translates to:
  /// **'Pick which categories or tags this budget should track.'**
  String get budget_stepNote2;

  /// No description provided for @budget_autoDistributed.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get budget_autoDistributed;

  /// No description provided for @budget_categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 category} other{{count} categories}}'**
  String budget_categoriesCount(num count);

  /// No description provided for @budget_tagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag} other{{count} tags}}'**
  String budget_tagsCount(num count);

  /// No description provided for @budget_typeCategoryWise.
  ///
  /// In en, this message translates to:
  /// **'Category-wise'**
  String get budget_typeCategoryWise;

  /// No description provided for @budget_typeTagWise.
  ///
  /// In en, this message translates to:
  /// **'Tag-wise'**
  String get budget_typeTagWise;

  /// No description provided for @budget_typeDayWise.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budget_typeDayWise;

  /// No description provided for @budget_typeFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get budget_typeFestival;

  /// No description provided for @budget_typeTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get budget_typeTravel;

  /// No description provided for @budget_typeDescCategoryWise.
  ///
  /// In en, this message translates to:
  /// **'Set budgets for specific spending categories'**
  String get budget_typeDescCategoryWise;

  /// No description provided for @budget_typeDescTagWise.
  ///
  /// In en, this message translates to:
  /// **'Set budgets for specific tags'**
  String get budget_typeDescTagWise;

  /// No description provided for @budget_typeDescDayWise.
  ///
  /// In en, this message translates to:
  /// **'Set a daily spending limit'**
  String get budget_typeDescDayWise;

  /// No description provided for @budget_typeDescFestival.
  ///
  /// In en, this message translates to:
  /// **'Budget for festivals and special events'**
  String get budget_typeDescFestival;

  /// No description provided for @budget_typeDescTravel.
  ///
  /// In en, this message translates to:
  /// **'Budget for travel expenses'**
  String get budget_typeDescTravel;

  /// No description provided for @budget_reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Save'**
  String get budget_reviewTitle;

  /// No description provided for @budget_selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get budget_selectCategories;

  /// No description provided for @budget_noActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'No active trip. Start a trip first to use travel budget.'**
  String get budget_noActiveTrip;

  /// No description provided for @budget_stepNote3.
  ///
  /// In en, this message translates to:
  /// **'Review everything before saving. Tap any section to edit.'**
  String get budget_stepNote3;

  /// No description provided for @budget_categoryDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This category is used in {count} budget(s). Deleting it will affect budget tracking.'**
  String budget_categoryDeleteWarning(Object count);

  /// No description provided for @budget_invalidCategories.
  ///
  /// In en, this message translates to:
  /// **'Some categories were deleted. Edit this budget to fix.'**
  String get budget_invalidCategories;

  /// No description provided for @budget_pastBudgets.
  ///
  /// In en, this message translates to:
  /// **'{count} past {count, plural, =1{budget} other{budgets}}'**
  String budget_pastBudgets(int count);

  /// No description provided for @category_categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_categoryName;

  /// No description provided for @category_keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords (comma-separated)'**
  String get category_keywords;

  /// No description provided for @category_noneTopLevel.
  ///
  /// In en, this message translates to:
  /// **'None (Top-level)'**
  String get category_noneTopLevel;

  /// No description provided for @common_searchCurrency.
  ///
  /// In en, this message translates to:
  /// **'Search currency...'**
  String get common_searchCurrency;

  /// No description provided for @common_selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get common_selectCategory;

  /// No description provided for @common_noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get common_noDescription;

  /// No description provided for @common_errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get common_errors;

  /// No description provided for @dashboard_enableCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable dashboard cards to see your financial overview'**
  String get dashboard_enableCardsDesc;

  /// No description provided for @dashboard_customizeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Customize Dashboard'**
  String get dashboard_customizeDashboard;

  /// No description provided for @dashboard_newToApp.
  ///
  /// In en, this message translates to:
  /// **'New to Mudra Manager?'**
  String get dashboard_newToApp;

  /// No description provided for @dashboard_tapToExploreHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap to explore the help guide'**
  String get dashboard_tapToExploreHelp;

  /// No description provided for @dashboard_tapToReviewTxn.
  ///
  /// In en, this message translates to:
  /// **'Tap to review transactions'**
  String get dashboard_tapToReviewTxn;

  /// No description provided for @dashboard_autoImportPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto Import Paused'**
  String get dashboard_autoImportPaused;

  /// No description provided for @dashboard_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get dashboard_enable;

  /// No description provided for @dashboard_enableAutoImport.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Import'**
  String get dashboard_enableAutoImport;

  /// No description provided for @dashboard_autoTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-track transactions from bank notifications'**
  String get dashboard_autoTrackDesc;

  /// No description provided for @profile_awesomeUser.
  ///
  /// In en, this message translates to:
  /// **'Awesome User'**
  String get profile_awesomeUser;

  /// No description provided for @profile_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profile_logout;

  /// No description provided for @profile_proActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get profile_proActiveLabel;

  /// No description provided for @profile_freeTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get profile_freeTierLabel;

  /// No description provided for @profile_fullAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get profile_fullAccessLabel;

  /// No description provided for @profile_upgradeToProLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get profile_upgradeToProLabel;

  /// No description provided for @profile_fullAccessEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Full access — enjoy all features!'**
  String get profile_fullAccessEnjoy;

  /// No description provided for @profile_fullAccessDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Full access — {days} days remaining'**
  String profile_fullAccessDaysRemaining(int days);

  /// No description provided for @profile_fullAccessEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Full access ends in {days} days'**
  String profile_fullAccessEndsIn(int days);

  /// No description provided for @profile_trialEnded.
  ///
  /// In en, this message translates to:
  /// **'Trial ended — upgrade to keep all features'**
  String get profile_trialEnded;

  /// No description provided for @profile_unlimitedDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited accounts, analytics & more'**
  String get profile_unlimitedDesc;

  /// No description provided for @profile_expiredRenew.
  ///
  /// In en, this message translates to:
  /// **'Expired — tap to renew'**
  String get profile_expiredRenew;

  /// No description provided for @profile_expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get profile_expiresToday;

  /// No description provided for @profile_renewsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Renews tomorrow'**
  String get profile_renewsTomorrow;

  /// No description provided for @profile_renewsInDays.
  ///
  /// In en, this message translates to:
  /// **'Renews in {days} days'**
  String profile_renewsInDays(int days);

  /// No description provided for @profile_activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active subscription'**
  String get profile_activeSubscription;

  /// No description provided for @profile_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profile_unknown;

  /// No description provided for @profile_accountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get profile_accountsLabel;

  /// No description provided for @profile_categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get profile_categoriesLabel;

  /// No description provided for @profile_budgetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get profile_budgetsLabel;

  /// No description provided for @profile_bestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get profile_bestStreakLabel;

  /// No description provided for @profile_yourAchievementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Achievements'**
  String get profile_yourAchievementsLabel;

  /// No description provided for @profile_aboutMudra.
  ///
  /// In en, this message translates to:
  /// **'About Mudra Manager'**
  String get profile_aboutMudra;

  /// No description provided for @profile_aboutMudraDesc.
  ///
  /// In en, this message translates to:
  /// **'Your personal finance companion. Track expenses, manage budgets, and gain insights into your spending habits.'**
  String get profile_aboutMudraDesc;

  /// No description provided for @txnList_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get txnList_searchHint;

  /// No description provided for @txnList_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txnList_category;

  /// No description provided for @txnList_dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get txnList_dateRange;

  /// No description provided for @txnList_tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get txnList_tag;

  /// No description provided for @txnList_allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get txnList_allTransactions;

  /// No description provided for @txnList_tapStartEnd.
  ///
  /// In en, this message translates to:
  /// **'Tap start and end date'**
  String get txnList_tapStartEnd;

  /// No description provided for @txnList_scrollToLoad.
  ///
  /// In en, this message translates to:
  /// **'Scroll to load more'**
  String get txnList_scrollToLoad;

  /// No description provided for @txnList_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get txnList_month;

  /// No description provided for @txnList_previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get txnList_previousMonth;

  /// No description provided for @txnList_resetToCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'Reset to Current Month'**
  String get txnList_resetToCurrentMonth;

  /// No description provided for @txnList_selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get txnList_selectMonth;

  /// No description provided for @txnList_nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get txnList_nextMonth;

  /// No description provided for @txnList_monthView.
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get txnList_monthView;

  /// No description provided for @txnList_subscriptionTagRemoved.
  ///
  /// In en, this message translates to:
  /// **'Subscription tag removed'**
  String get txnList_subscriptionTagRemoved;

  /// No description provided for @txnList_filterByTag.
  ///
  /// In en, this message translates to:
  /// **'Filter by Tag'**
  String get txnList_filterByTag;

  /// No description provided for @txnList_noTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Add tags to your transactions first.'**
  String get txnList_noTagsYet;

  /// No description provided for @txnList_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get txnList_clear;

  /// No description provided for @txnList_filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get txnList_filterOptions;

  /// No description provided for @txnList_transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get txnList_transactionType;

  /// No description provided for @txnList_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get txnList_allCategories;

  /// No description provided for @txnList_selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get txnList_selectDateRange;

  /// No description provided for @txnList_clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear Date Range'**
  String get txnList_clearDateRange;

  /// No description provided for @stats_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get stats_today;

  /// No description provided for @stats_week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get stats_week;

  /// No description provided for @stats_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get stats_month;

  /// No description provided for @stats_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get stats_year;

  /// No description provided for @stats_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get stats_custom;

  /// No description provided for @stats_unableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load statistics'**
  String get stats_unableToLoad;

  /// No description provided for @stats_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get stats_overview;

  /// No description provided for @stats_trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get stats_trends;

  /// No description provided for @stats_spendingByDay.
  ///
  /// In en, this message translates to:
  /// **'Spending by Day'**
  String get stats_spendingByDay;

  /// No description provided for @stats_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get stats_insights;

  /// No description provided for @stats_nextMonthForecast.
  ///
  /// In en, this message translates to:
  /// **'Next Month Forecast'**
  String get stats_nextMonthForecast;

  /// No description provided for @stats_topSpending.
  ///
  /// In en, this message translates to:
  /// **'Top Spending'**
  String get stats_topSpending;

  /// No description provided for @stats_12MonthTrend.
  ///
  /// In en, this message translates to:
  /// **'12-Month Trend'**
  String get stats_12MonthTrend;

  /// No description provided for @stats_trendUp.
  ///
  /// In en, this message translates to:
  /// **'{category} is trending up — {percent}% of total spending'**
  String stats_trendUp(Object category, Object percent);

  /// No description provided for @stats_trendDown.
  ///
  /// In en, this message translates to:
  /// **'{category} is trending down this month 📉'**
  String stats_trendDown(Object category);

  /// No description provided for @stats_topCategory.
  ///
  /// In en, this message translates to:
  /// **'{category} is your top category — {percent}% of spending'**
  String stats_topCategory(Object category, Object percent);

  /// No description provided for @stats_weekendPeak.
  ///
  /// In en, this message translates to:
  /// **'You spend more on weekends — {day} is your peak day'**
  String stats_weekendPeak(Object day);

  /// No description provided for @stats_weekdayPeak.
  ///
  /// In en, this message translates to:
  /// **'Weekdays cost more — {day} is your biggest day'**
  String stats_weekdayPeak(Object day);

  /// No description provided for @stats_peakAndQuiet.
  ///
  /// In en, this message translates to:
  /// **'{peak} is your peak spending day, {quiet} is the quietest'**
  String stats_peakAndQuiet(Object peak, Object quiet);

  /// No description provided for @stats_categoryTrends.
  ///
  /// In en, this message translates to:
  /// **'Category Trends'**
  String get stats_categoryTrends;

  /// No description provided for @stats_spendingByTag.
  ///
  /// In en, this message translates to:
  /// **'Spending by Tag'**
  String get stats_spendingByTag;

  /// No description provided for @stats_netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get stats_netWorth;

  /// No description provided for @stats_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get stats_savings;

  /// No description provided for @stats_categoryImpact.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY IMPACT'**
  String get stats_categoryImpact;

  /// No description provided for @stats_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get stats_income;

  /// No description provided for @stats_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get stats_expense;

  /// No description provided for @stats_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get stats_net;

  /// No description provided for @stats_dailySpendingPace.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending Pace'**
  String get stats_dailySpendingPace;

  /// No description provided for @stats_topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get stats_topCategories;

  /// No description provided for @stats_projectedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Projected: {amount} this month'**
  String stats_projectedThisMonth(Object amount);

  /// No description provided for @stats_byDay.
  ///
  /// In en, this message translates to:
  /// **'By day {day}: {amount} in {month}'**
  String stats_byDay(Object day, Object amount, Object month);

  /// No description provided for @stats_steadyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Steady as she goes'**
  String get stats_steadyHeadline;

  /// No description provided for @stats_steadyDetail.
  ///
  /// In en, this message translates to:
  /// **'Your spending is consistent — that\'s discipline.'**
  String get stats_steadyDetail;

  /// No description provided for @stats_doingGreatHeadline.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great 🌟'**
  String get stats_doingGreatHeadline;

  /// No description provided for @stats_spendingUpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Heads up — spending is up'**
  String get stats_spendingUpHeadline;

  /// No description provided for @stats_downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get stats_downloadPdf;

  /// No description provided for @stats_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get stats_generating;

  /// No description provided for @recap_belowAvg.
  ///
  /// In en, this message translates to:
  /// **'Below avg'**
  String get recap_belowAvg;

  /// No description provided for @recap_aboveAvg.
  ///
  /// In en, this message translates to:
  /// **'Above avg'**
  String get recap_aboveAvg;

  /// No description provided for @recap_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recap_recurring;

  /// No description provided for @recap_oneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get recap_oneTime;

  /// No description provided for @recap_recapTitle.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get recap_recapTitle;

  /// No description provided for @notifSettings_dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get notifSettings_dailySummary;

  /// No description provided for @notifSettings_weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get notifSettings_weeklySummary;

  /// No description provided for @notifSettings_comeBackNudges.
  ///
  /// In en, this message translates to:
  /// **'Come-back Nudges'**
  String get notifSettings_comeBackNudges;

  /// No description provided for @notifSettings_streakReminder.
  ///
  /// In en, this message translates to:
  /// **'Streak Reminder'**
  String get notifSettings_streakReminder;

  /// No description provided for @notifSettings_smartAlerts.
  ///
  /// In en, this message translates to:
  /// **'Smart Alerts'**
  String get notifSettings_smartAlerts;

  /// No description provided for @notifSettings_selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get notifSettings_selectDay;

  /// No description provided for @notifSettings_summariesDesc.
  ///
  /// In en, this message translates to:
  /// **'Summaries show spending, income, top category & balance'**
  String get notifSettings_summariesDesc;

  /// No description provided for @notifSettings_reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get notifSettings_reminderTime;

  /// No description provided for @notifSettings_sendTestNotif.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get notifSettings_sendTestNotif;

  /// No description provided for @notifSettings_testNotifSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get notifSettings_testNotifSent;

  /// No description provided for @notifSettings_dailyNudgeStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily nudge to keep your streak'**
  String get notifSettings_dailyNudgeStreak;

  /// No description provided for @notifSettings_summaryDay.
  ///
  /// In en, this message translates to:
  /// **'Summary Day'**
  String get notifSettings_summaryDay;

  /// No description provided for @notifSettings_gentleReminders.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders if you haven\'t opened the app'**
  String get notifSettings_gentleReminders;

  /// No description provided for @notifSettings_budgetWarningsDesc.
  ///
  /// In en, this message translates to:
  /// **'Budget warnings, spending spikes, bill reminders'**
  String get notifSettings_budgetWarningsDesc;

  /// No description provided for @notifSettings_localNotifDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Notifications are delivered locally on your device. No data is sent to any server.'**
  String get notifSettings_localNotifDisclaimer;

  /// No description provided for @smsImport_autoImport.
  ///
  /// In en, this message translates to:
  /// **'Auto Import'**
  String get smsImport_autoImport;

  /// No description provided for @smsImport_permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get smsImport_permissions;

  /// No description provided for @smsImport_notifAccess.
  ///
  /// In en, this message translates to:
  /// **'Notification Access'**
  String get smsImport_notifAccess;

  /// No description provided for @smsImport_notifAccessEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notification access enabled'**
  String get smsImport_notifAccessEnabled;

  /// No description provided for @smsImport_allowReadingNotif.
  ///
  /// In en, this message translates to:
  /// **'Allow reading bank notifications'**
  String get smsImport_allowReadingNotif;

  /// No description provided for @smsImport_autoDetectTxn.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect transactions from notifications'**
  String get smsImport_autoDetectTxn;

  /// No description provided for @smsImport_privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Notifications are read locally on your device to detect transactions. Nothing is uploaded or shared — ever.'**
  String get smsImport_privacyNote;

  /// No description provided for @smsImport_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get smsImport_tools;

  /// No description provided for @smsImport_txnActivity.
  ///
  /// In en, this message translates to:
  /// **'Transaction Activity'**
  String get smsImport_txnActivity;

  /// No description provided for @smsImport_viewDetectedTxn.
  ///
  /// In en, this message translates to:
  /// **'View all detected transactions'**
  String get smsImport_viewDetectedTxn;

  /// No description provided for @smsImport_clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Processing History'**
  String get smsImport_clearHistory;

  /// No description provided for @smsImport_resetDetection.
  ///
  /// In en, this message translates to:
  /// **'Reset detection history'**
  String get smsImport_resetDetection;

  /// No description provided for @smsImport_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get smsImport_howItWorks;

  /// No description provided for @smsImport_readsBankNotif.
  ///
  /// In en, this message translates to:
  /// **'Reads bank & wallet notifications'**
  String get smsImport_readsBankNotif;

  /// No description provided for @smsImport_dataStaysOnDevice.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device'**
  String get smsImport_dataStaysOnDevice;

  /// No description provided for @smsImport_autoCreatesTxn.
  ///
  /// In en, this message translates to:
  /// **'Automatically creates transactions'**
  String get smsImport_autoCreatesTxn;

  /// No description provided for @smsImport_personalIgnored.
  ///
  /// In en, this message translates to:
  /// **'Personal notifications are ignored'**
  String get smsImport_personalIgnored;

  /// No description provided for @smsImport_noDataSent.
  ///
  /// In en, this message translates to:
  /// **'No data sent to any server'**
  String get smsImport_noDataSent;

  /// No description provided for @smsImport_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get smsImport_active;

  /// No description provided for @smsImport_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get smsImport_inactive;

  /// No description provided for @smsImport_grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant notification access to get started'**
  String get smsImport_grantAccess;

  /// No description provided for @smsImport_notAvailableIos.
  ///
  /// In en, this message translates to:
  /// **'Not Available on iOS'**
  String get smsImport_notAvailableIos;

  /// No description provided for @smsImport_enableAccessFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable notification access first'**
  String get smsImport_enableAccessFirst;

  /// No description provided for @smsImport_notifAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification Access Required'**
  String get smsImport_notifAccessRequired;

  /// No description provided for @smsImport_notifAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Mudra Manager needs notification access to automatically detect transactions from your bank and wallet apps.'**
  String get smsImport_notifAccessDesc;

  /// No description provided for @smsImport_onlyBankRead.
  ///
  /// In en, this message translates to:
  /// **'Only bank/wallet notifications are read'**
  String get smsImport_onlyBankRead;

  /// No description provided for @smsImport_personalNeverRead.
  ///
  /// In en, this message translates to:
  /// **'Personal messages are never read'**
  String get smsImport_personalNeverRead;

  /// No description provided for @smsImport_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get smsImport_openSettings;

  /// No description provided for @smsImport_clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Processing History?'**
  String get smsImport_clearHistoryConfirm;

  /// No description provided for @smsImport_clearHistoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Previously detected notifications will be processed again, which may create duplicate transactions.'**
  String get smsImport_clearHistoryWarning;

  /// No description provided for @smsImport_tapAgainSettings.
  ///
  /// In en, this message translates to:
  /// **'Tap again to open system settings'**
  String get smsImport_tapAgainSettings;

  /// No description provided for @upgrade_purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get upgrade_purchaseFailed;

  /// No description provided for @upgrade_purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Purchase pending. Pro will activate once payment completes.'**
  String get upgrade_purchasePending;

  /// No description provided for @upgrade_welcomePro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get upgrade_welcomePro;

  /// No description provided for @upgrade_allFeaturesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'All features are now unlocked. Thank you for your support!'**
  String get upgrade_allFeaturesUnlocked;

  /// No description provided for @upgrade_startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get upgrade_startExploring;

  /// No description provided for @upgrade_yourProFeatures.
  ///
  /// In en, this message translates to:
  /// **'Your Pro features'**
  String get upgrade_yourProFeatures;

  /// No description provided for @upgrade_manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'To manage your subscription, go to Google Play Store > Subscriptions.'**
  String get upgrade_manageSubscription;

  /// No description provided for @upgrade_everythingInPro.
  ///
  /// In en, this message translates to:
  /// **'Everything in Pro'**
  String get upgrade_everythingInPro;

  /// No description provided for @upgrade_chooseYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get upgrade_chooseYourPlan;

  /// No description provided for @upgrade_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get upgrade_yearly;

  /// No description provided for @upgrade_save43.
  ///
  /// In en, this message translates to:
  /// **'Save 43%'**
  String get upgrade_save43;

  /// No description provided for @upgrade_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get upgrade_monthly;

  /// No description provided for @upgrade_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get upgrade_continue;

  /// No description provided for @upgrade_restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get upgrade_restorePurchases;

  /// No description provided for @upgrade_renewsToday.
  ///
  /// In en, this message translates to:
  /// **'Renews today'**
  String get upgrade_renewsToday;

  /// No description provided for @upgrade_mudraManagerPro.
  ///
  /// In en, this message translates to:
  /// **'Mudra Manager Pro'**
  String get upgrade_mudraManagerPro;

  /// No description provided for @upgrade_unlockFullPower.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full power of your finances'**
  String get upgrade_unlockFullPower;

  /// No description provided for @day_monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get day_monday;

  /// No description provided for @day_tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get day_tuesday;

  /// No description provided for @day_wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get day_wednesday;

  /// No description provided for @day_thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get day_thursday;

  /// No description provided for @day_friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get day_friday;

  /// No description provided for @day_saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get day_saturday;

  /// No description provided for @day_sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get day_sunday;

  /// No description provided for @recap_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get recap_income;

  /// No description provided for @recap_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get recap_expense;

  /// No description provided for @recap_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get recap_saved;

  /// No description provided for @recap_dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending'**
  String get recap_dailySpending;

  /// No description provided for @recap_spendingPace.
  ///
  /// In en, this message translates to:
  /// **'Spending Pace'**
  String get recap_spendingPace;

  /// No description provided for @recap_recurringVsOneTime.
  ///
  /// In en, this message translates to:
  /// **'Recurring vs One-time'**
  String get recap_recurringVsOneTime;

  /// No description provided for @recap_topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get recap_topCategories;

  /// No description provided for @recap_mostFrequent.
  ///
  /// In en, this message translates to:
  /// **'Most Frequent'**
  String get recap_mostFrequent;

  /// No description provided for @recap_incomeSources.
  ///
  /// In en, this message translates to:
  /// **'Income Sources'**
  String get recap_incomeSources;

  /// No description provided for @recap_byAccount.
  ///
  /// In en, this message translates to:
  /// **'By Account'**
  String get recap_byAccount;

  /// No description provided for @recap_budgetHealth.
  ///
  /// In en, this message translates to:
  /// **'Budget Health'**
  String get recap_budgetHealth;

  /// No description provided for @recap_biggestExpenses.
  ///
  /// In en, this message translates to:
  /// **'Biggest Expenses'**
  String get recap_biggestExpenses;

  /// No description provided for @recap_biggestIncome.
  ///
  /// In en, this message translates to:
  /// **'Biggest Income'**
  String get recap_biggestIncome;

  /// No description provided for @recap_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get recap_generating;

  /// No description provided for @recap_avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg/Day'**
  String get recap_avgPerDay;

  /// No description provided for @recap_weekdayAvg.
  ///
  /// In en, this message translates to:
  /// **'Weekday Avg'**
  String get recap_weekdayAvg;

  /// No description provided for @recap_weekendAvg.
  ///
  /// In en, this message translates to:
  /// **'Weekend Avg'**
  String get recap_weekendAvg;

  /// No description provided for @recap_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get recap_budgets;

  /// No description provided for @recap_badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get recap_badges;

  /// No description provided for @recap_streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get recap_streak;

  /// No description provided for @recap_best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get recap_best;

  /// No description provided for @recap_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get recap_savings;

  /// No description provided for @about_developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode Activated!'**
  String get about_developerMode;

  /// No description provided for @about_couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get about_couldNotOpenLink;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_privacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your device. No accounts, no cloud, no data collection. Your finances are yours alone.'**
  String get about_privacyDesc;

  /// No description provided for @about_legalTransparency.
  ///
  /// In en, this message translates to:
  /// **'Legal & Transparency'**
  String get about_legalTransparency;

  /// No description provided for @about_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get about_privacyPolicy;

  /// No description provided for @about_privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get about_privacyPolicyDesc;

  /// No description provided for @about_termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get about_termsOfService;

  /// No description provided for @about_termsDesc.
  ///
  /// In en, this message translates to:
  /// **'App usage terms and conditions'**
  String get about_termsDesc;

  /// No description provided for @about_openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get about_openSourceLicenses;

  /// No description provided for @about_openSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Third-party libraries we use'**
  String get about_openSourceDesc;

  /// No description provided for @about_supportConnect.
  ///
  /// In en, this message translates to:
  /// **'Support & Connect'**
  String get about_supportConnect;

  /// No description provided for @about_checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get about_checkForUpdates;

  /// No description provided for @about_checkForUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manually check app version'**
  String get about_checkForUpdatesDesc;

  /// No description provided for @about_latestVersion.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version'**
  String get about_latestVersion;

  /// No description provided for @about_unableToCheck.
  ///
  /// In en, this message translates to:
  /// **'Unable to check for updates'**
  String get about_unableToCheck;

  /// No description provided for @about_officialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Official Website'**
  String get about_officialWebsite;

  /// No description provided for @about_visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit mudramanager.com'**
  String get about_visitWebsite;

  /// No description provided for @about_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get about_contactSupport;

  /// No description provided for @about_contactSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help or report issues'**
  String get about_contactSupportDesc;

  /// No description provided for @about_rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get about_rateApp;

  /// No description provided for @about_rateAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your experience on the store'**
  String get about_rateAppDesc;

  /// No description provided for @about_developerModeSection.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get about_developerModeSection;

  /// No description provided for @about_mudraManager.
  ///
  /// In en, this message translates to:
  /// **'Mudra Manager'**
  String get about_mudraManager;

  /// No description provided for @about_secureFinancial.
  ///
  /// In en, this message translates to:
  /// **'Secure Financial Command'**
  String get about_secureFinancial;

  /// No description provided for @about_loadingLicenses.
  ///
  /// In en, this message translates to:
  /// **'Loading licenses...'**
  String get about_loadingLicenses;

  /// No description provided for @appearance_title.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance_title;

  /// No description provided for @appearance_themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get appearance_themeMode;

  /// No description provided for @appearance_display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get appearance_display;

  /// No description provided for @appearance_toneVoice.
  ///
  /// In en, this message translates to:
  /// **'Tone & Voice'**
  String get appearance_toneVoice;

  /// No description provided for @appearance_changesApplyInstantly.
  ///
  /// In en, this message translates to:
  /// **'Theme and display changes apply instantly.'**
  String get appearance_changesApplyInstantly;

  /// No description provided for @appearance_darkAppearance.
  ///
  /// In en, this message translates to:
  /// **'Dark appearance'**
  String get appearance_darkAppearance;

  /// No description provided for @appearance_lightAppearance.
  ///
  /// In en, this message translates to:
  /// **'Light appearance'**
  String get appearance_lightAppearance;

  /// No description provided for @appearance_accountStyle.
  ///
  /// In en, this message translates to:
  /// **'Account Style'**
  String get appearance_accountStyle;

  /// No description provided for @appearance_cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get appearance_cards;

  /// No description provided for @appearance_stack.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get appearance_stack;

  /// No description provided for @appearance_bento.
  ///
  /// In en, this message translates to:
  /// **'Bento'**
  String get appearance_bento;

  /// No description provided for @appearance_highContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get appearance_highContrast;

  /// No description provided for @appearance_highContrastDesc.
  ///
  /// In en, this message translates to:
  /// **'Improves readability for low vision'**
  String get appearance_highContrastDesc;

  /// No description provided for @appearance_guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get appearance_guestMode;

  /// No description provided for @appearance_guestModeOnDesc.
  ///
  /// In en, this message translates to:
  /// **'Real amounts are hidden'**
  String get appearance_guestModeOnDesc;

  /// No description provided for @appearance_guestModeOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide sensitive financial data'**
  String get appearance_guestModeOffDesc;

  /// No description provided for @appearance_lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get appearance_lightMode;

  /// No description provided for @appearance_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get appearance_darkMode;

  /// No description provided for @appearance_systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get appearance_systemDefault;

  /// No description provided for @analytics_financialHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Financial Health Score'**
  String get analytics_financialHealthScore;

  /// No description provided for @analytics_savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get analytics_savingsRate;

  /// No description provided for @analytics_expenseRatio.
  ///
  /// In en, this message translates to:
  /// **'Expense Ratio'**
  String get analytics_expenseRatio;

  /// No description provided for @analytics_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get analytics_insights;

  /// No description provided for @analytics_spendingPrediction.
  ///
  /// In en, this message translates to:
  /// **'Spending Prediction'**
  String get analytics_spendingPrediction;

  /// No description provided for @analytics_nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get analytics_nextMonth;

  /// No description provided for @analytics_basedOnAvg.
  ///
  /// In en, this message translates to:
  /// **'Based on last 3 months average'**
  String get analytics_basedOnAvg;

  /// No description provided for @analytics_categoryTrends.
  ///
  /// In en, this message translates to:
  /// **'Category Trends'**
  String get analytics_categoryTrends;

  /// No description provided for @analytics_spendingByDay.
  ///
  /// In en, this message translates to:
  /// **'Spending by Day'**
  String get analytics_spendingByDay;

  /// No description provided for @trip_notFound.
  ///
  /// In en, this message translates to:
  /// **'Trip Not Found'**
  String get trip_notFound;

  /// No description provided for @trip_notFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get trip_notFoundMsg;

  /// No description provided for @trip_tripLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip_tripLabel;

  /// No description provided for @trip_groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get trip_groupLabel;

  /// No description provided for @trip_archiveTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Trip'**
  String get trip_archiveTripTitle;

  /// No description provided for @trip_archiveMsg.
  ///
  /// In en, this message translates to:
  /// **'This trip will be moved to archive. All data and settlements will be preserved.'**
  String get trip_archiveMsg;

  /// No description provided for @trip_archiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get trip_archiveConfirm;

  /// No description provided for @trip_totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get trip_totalSpent;

  /// No description provided for @trip_splitExpense.
  ///
  /// In en, this message translates to:
  /// **'Split Expense'**
  String get trip_splitExpense;

  /// No description provided for @trip_allPeople.
  ///
  /// In en, this message translates to:
  /// **'All People'**
  String get trip_allPeople;

  /// No description provided for @trip_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get trip_allCategories;

  /// No description provided for @trip_uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get trip_uncategorized;

  /// No description provided for @trip_removeExpense.
  ///
  /// In en, this message translates to:
  /// **'Remove Expense'**
  String get trip_removeExpense;

  /// No description provided for @trip_removeFromTrip.
  ///
  /// In en, this message translates to:
  /// **'Remove this expense from the trip?'**
  String get trip_removeFromTrip;

  /// No description provided for @trip_removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove this expense from the group?'**
  String get trip_removeFromGroup;

  /// No description provided for @trip_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get trip_removeConfirm;

  /// No description provided for @trip_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get trip_unknown;

  /// No description provided for @trip_youPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get trip_youPaid;

  /// No description provided for @trip_noPendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'No pending settlements for this trip'**
  String get trip_noPendingSettlements;

  /// No description provided for @trip_everyoneSquare.
  ///
  /// In en, this message translates to:
  /// **'Everyone is square'**
  String get trip_everyoneSquare;

  /// No description provided for @trip_archiveGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Group'**
  String get trip_archiveGroupTitle;

  /// No description provided for @trip_archiveGroupMsg.
  ///
  /// In en, this message translates to:
  /// **'This group will be moved to archive. All data and settlements will be preserved.'**
  String get trip_archiveGroupMsg;

  /// No description provided for @editTrip_addParticipant.
  ///
  /// In en, this message translates to:
  /// **'Add Participant'**
  String get editTrip_addParticipant;

  /// No description provided for @editTrip_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editTrip_name;

  /// No description provided for @editTrip_enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter participant name'**
  String get editTrip_enterName;

  /// No description provided for @editTrip_finalizeTrip.
  ///
  /// In en, this message translates to:
  /// **'Finalize Trip'**
  String get editTrip_finalizeTrip;

  /// No description provided for @editTrip_closeGroup.
  ///
  /// In en, this message translates to:
  /// **'Close Group'**
  String get editTrip_closeGroup;

  /// No description provided for @editTrip_finalizeMsg.
  ///
  /// In en, this message translates to:
  /// **'This will mark the trip as ended. You cannot add expenses after this.'**
  String get editTrip_finalizeMsg;

  /// No description provided for @editTrip_closeGroupMsg.
  ///
  /// In en, this message translates to:
  /// **'This will close the group. You cannot add expenses after this.'**
  String get editTrip_closeGroupMsg;

  /// No description provided for @editTrip_finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get editTrip_finalize;

  /// No description provided for @editTrip_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get editTrip_close;

  /// No description provided for @editTrip_groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group Not Found'**
  String get editTrip_groupNotFound;

  /// No description provided for @editTrip_groupNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get editTrip_groupNotFoundMsg;

  /// No description provided for @editTrip_editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get editTrip_editTrip;

  /// No description provided for @editTrip_editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editTrip_editGroup;

  /// No description provided for @editTrip_editSplitGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Split Group'**
  String get editTrip_editSplitGroup;

  /// No description provided for @editTrip_createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get editTrip_createTrip;

  /// No description provided for @editTrip_createSplitGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Split Group'**
  String get editTrip_createSplitGroup;

  /// No description provided for @editTrip_travelTrip.
  ///
  /// In en, this message translates to:
  /// **'Travel Trip'**
  String get editTrip_travelTrip;

  /// No description provided for @editTrip_splitGroup.
  ///
  /// In en, this message translates to:
  /// **'Split Group'**
  String get editTrip_splitGroup;

  /// No description provided for @editTrip_tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get editTrip_tripDetails;

  /// No description provided for @editTrip_groupDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get editTrip_groupDetails;

  /// No description provided for @editTrip_tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get editTrip_tripName;

  /// No description provided for @editTrip_groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get editTrip_groupName;

  /// No description provided for @editTrip_descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get editTrip_descriptionOptional;

  /// No description provided for @editTrip_tripHint.
  ///
  /// In en, this message translates to:
  /// **'Beach vacation with friends'**
  String get editTrip_tripHint;

  /// No description provided for @editTrip_groupHint.
  ///
  /// In en, this message translates to:
  /// **'Split expenses with friends'**
  String get editTrip_groupHint;

  /// No description provided for @editTrip_budgetOptional.
  ///
  /// In en, this message translates to:
  /// **'Budget (Optional)'**
  String get editTrip_budgetOptional;

  /// No description provided for @editTrip_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get editTrip_currency;

  /// No description provided for @editTrip_baseCurrencyDefault.
  ///
  /// In en, this message translates to:
  /// **'Base currency (default)'**
  String get editTrip_baseCurrencyDefault;

  /// No description provided for @editTrip_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get editTrip_duration;

  /// No description provided for @editTrip_warningDateChange.
  ///
  /// In en, this message translates to:
  /// **'Warning: Date Change'**
  String get editTrip_warningDateChange;

  /// No description provided for @expense_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get expense_notFound;

  /// No description provided for @expense_notFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'Expense not found'**
  String get expense_notFoundMsg;

  /// No description provided for @expense_details.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expense_details;

  /// No description provided for @expense_paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get expense_paidBy;

  /// No description provided for @expense_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get expense_you;

  /// No description provided for @expense_yourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get expense_yourShare;

  /// No description provided for @expense_noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expense_noteLabel;

  /// No description provided for @expense_editSplit.
  ///
  /// In en, this message translates to:
  /// **'Edit Split'**
  String get expense_editSplit;

  /// No description provided for @expense_splitType.
  ///
  /// In en, this message translates to:
  /// **'Split Type'**
  String get expense_splitType;

  /// No description provided for @expense_equal.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get expense_equal;

  /// No description provided for @expense_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get expense_custom;

  /// No description provided for @expense_participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get expense_participants;

  /// No description provided for @expense_autoFillRemaining.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill remaining'**
  String get expense_autoFillRemaining;

  /// No description provided for @expense_deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get expense_deleteExpense;

  /// No description provided for @expense_deleteExpenseMsg.
  ///
  /// In en, this message translates to:
  /// **'This will adjust everyones balance. Continue?'**
  String get expense_deleteExpenseMsg;

  /// No description provided for @billCenter_overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billCenter_overdue;

  /// No description provided for @billCenter_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get billCenter_thisWeek;

  /// No description provided for @billCenter_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get billCenter_thisMonth;

  /// No description provided for @billCenter_later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get billCenter_later;

  /// No description provided for @billCenter_totalUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Total upcoming'**
  String get billCenter_totalUpcoming;

  /// No description provided for @billCenter_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get billCenter_today;

  /// No description provided for @billCenter_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get billCenter_tomorrow;

  /// No description provided for @billCenter_afterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'After upcoming bills'**
  String get billCenter_afterUpcoming;

  /// No description provided for @billCenter_dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get billCenter_dueToday;

  /// No description provided for @billCenter_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billCenter_paid;

  /// No description provided for @billCenter_pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get billCenter_pay;

  /// No description provided for @billCenter_existingTxnFound.
  ///
  /// In en, this message translates to:
  /// **'Existing Transaction Found'**
  String get billCenter_existingTxnFound;

  /// No description provided for @billCenter_linkTransaction.
  ///
  /// In en, this message translates to:
  /// **'Link This Transaction'**
  String get billCenter_linkTransaction;

  /// No description provided for @billCenter_createNewEntry.
  ///
  /// In en, this message translates to:
  /// **'Create New Entry'**
  String get billCenter_createNewEntry;

  /// No description provided for @comparison_steady.
  ///
  /// In en, this message translates to:
  /// **'Steady as she goes'**
  String get comparison_steady;

  /// No description provided for @comparison_steadyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your spending is consistent — that is discipline.'**
  String get comparison_steadyDesc;

  /// No description provided for @comparison_doingGreat.
  ///
  /// In en, this message translates to:
  /// **'You are doing great'**
  String get comparison_doingGreat;

  /// No description provided for @comparison_headsUp.
  ///
  /// In en, this message translates to:
  /// **'Heads up — spending is up'**
  String get comparison_headsUp;

  /// No description provided for @reconcile_title.
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get reconcile_title;

  /// No description provided for @reconcile_info.
  ///
  /// In en, this message translates to:
  /// **'Enter the current balance shown in your bank app or passbook. We\'ll adjust the difference automatically.'**
  String get reconcile_info;

  /// No description provided for @reconcile_balanceInApp.
  ///
  /// In en, this message translates to:
  /// **'Balance in App'**
  String get reconcile_balanceInApp;

  /// No description provided for @reconcile_actualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual Bank Balance'**
  String get reconcile_actualBalance;

  /// No description provided for @reconcile_balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced!'**
  String get reconcile_balanced;

  /// No description provided for @reconcile_difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get reconcile_difference;

  /// No description provided for @reconcile_incomeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'An income adjustment of {amount} will be added.'**
  String reconcile_incomeAdjustment(String amount);

  /// No description provided for @reconcile_expenseAdjustment.
  ///
  /// In en, this message translates to:
  /// **'An expense adjustment of {amount} will be added.'**
  String reconcile_expenseAdjustment(String amount);

  /// No description provided for @balanceHistory_currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get balanceHistory_currentBalance;

  /// No description provided for @balanceHistory_highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get balanceHistory_highest;

  /// No description provided for @balanceHistory_lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get balanceHistory_lowest;

  /// No description provided for @balanceHistory_average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get balanceHistory_average;

  /// No description provided for @common_errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get common_errorLoading;

  /// No description provided for @balanceHistory_trend.
  ///
  /// In en, this message translates to:
  /// **'30-Day Trend'**
  String get balanceHistory_trend;

  /// No description provided for @balanceHistory_growing.
  ///
  /// In en, this message translates to:
  /// **'Your balance is growing 📈'**
  String get balanceHistory_growing;

  /// No description provided for @balanceHistory_declining.
  ///
  /// In en, this message translates to:
  /// **'Balance has dipped — let\'s recover 💪'**
  String get balanceHistory_declining;

  /// No description provided for @balanceHistory_steady.
  ///
  /// In en, this message translates to:
  /// **'Holding steady ⚖️'**
  String get balanceHistory_steady;

  /// No description provided for @account_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get account_editTitle;

  /// No description provided for @account_newTitle.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get account_newTitle;

  /// No description provided for @account_name.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get account_name;

  /// No description provided for @account_typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get account_typeLabel;

  /// No description provided for @account_detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get account_detailsLabel;

  /// No description provided for @account_colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get account_colorLabel;

  /// No description provided for @account_currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get account_currencyLabel;

  /// No description provided for @account_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get account_balance;

  /// No description provided for @account_outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get account_outstanding;

  /// No description provided for @account_last4.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get account_last4;

  /// No description provided for @account_last4Helper.
  ///
  /// In en, this message translates to:
  /// **'For SMS auto-matching'**
  String get account_last4Helper;

  /// No description provided for @account_initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get account_initialBalance;

  /// No description provided for @account_cardPaidOff.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 if card is paid off'**
  String get account_cardPaidOff;

  /// No description provided for @account_min4.
  ///
  /// In en, this message translates to:
  /// **'At least 4 digits'**
  String get account_min4;

  /// No description provided for @account_max4.
  ///
  /// In en, this message translates to:
  /// **'Only last 4 digits'**
  String get account_max4;

  /// No description provided for @iconPicker_title.
  ///
  /// In en, this message translates to:
  /// **'Pick an Icon'**
  String get iconPicker_title;

  /// No description provided for @iconPicker_search.
  ///
  /// In en, this message translates to:
  /// **'Search icons...'**
  String get iconPicker_search;

  /// No description provided for @iconPicker_noResults.
  ///
  /// In en, this message translates to:
  /// **'No icons found'**
  String get iconPicker_noResults;

  /// No description provided for @colorPicker_title.
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get colorPicker_title;

  /// No description provided for @color_red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get color_red;

  /// No description provided for @color_pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get color_pink;

  /// No description provided for @color_purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get color_purple;

  /// No description provided for @color_indigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get color_indigo;

  /// No description provided for @color_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get color_blue;

  /// No description provided for @color_cyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get color_cyan;

  /// No description provided for @color_teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get color_teal;

  /// No description provided for @color_green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get color_green;

  /// No description provided for @color_orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get color_orange;

  /// No description provided for @color_brown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get color_brown;

  /// No description provided for @color_grey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get color_grey;

  /// No description provided for @accounts_totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get accounts_totalBalance;

  /// No description provided for @accounts_accountsCount.
  ///
  /// In en, this message translates to:
  /// **'accounts'**
  String get accounts_accountsCount;

  /// No description provided for @accounts_archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get accounts_archived;

  /// No description provided for @accounts_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How Accounts Work'**
  String get accounts_howItWorks;

  /// No description provided for @accounts_howItWorksDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage all your bank accounts, wallets, and cash in one place. Track balances and transactions across multiple accounts.'**
  String get accounts_howItWorksDesc;

  /// No description provided for @accounts_primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get accounts_primary;

  /// No description provided for @categories_label.
  ///
  /// In en, this message translates to:
  /// **'categories'**
  String get categories_label;

  /// No description provided for @categories_transactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'transactions'**
  String get categories_transactionsLabel;

  /// No description provided for @categories_deleteWithTransactions.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\" and {count} linked transactions. This action cannot be undone.'**
  String categories_deleteWithTransactions(String name, int count);

  /// No description provided for @categories_deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get categories_deleteAll;

  /// No description provided for @categories_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categories_edit;

  /// No description provided for @categories_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get categories_delete;

  /// No description provided for @categories_deleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes all linked transactions'**
  String get categories_deleteSubtitle;

  /// No description provided for @category_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get category_save;

  /// No description provided for @category_detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get category_detailsLabel;

  /// No description provided for @category_parentLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get category_parentLabel;

  /// No description provided for @category_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_nameHint;

  /// No description provided for @category_keywordsHint.
  ///
  /// In en, this message translates to:
  /// **'Keywords (comma-separated)'**
  String get category_keywordsHint;

  /// No description provided for @category_keywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'For SMS auto-detection (e.g. swiggy, zomato)'**
  String get category_keywordsHelper;

  /// No description provided for @currency_title.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency_title;

  /// No description provided for @currency_baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get currency_baseCurrency;

  /// No description provided for @currency_baseDescription.
  ///
  /// In en, this message translates to:
  /// **'All totals, budgets, and analytics use this currency.'**
  String get currency_baseDescription;

  /// No description provided for @currency_exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get currency_exchangeRates;

  /// No description provided for @currency_exchangeRatesDesc.
  ///
  /// In en, this message translates to:
  /// **'View and edit conversion rates'**
  String get currency_exchangeRatesDesc;

  /// No description provided for @currency_archivedDesc.
  ///
  /// In en, this message translates to:
  /// **'View transactions from previous currencies'**
  String get currency_archivedDesc;

  /// No description provided for @exchange_unitInfo.
  ///
  /// In en, this message translates to:
  /// **'unit of foreign currency = X {base}. Tap any rate to edit.'**
  String exchange_unitInfo(String base);

  /// No description provided for @exchange_search.
  ///
  /// In en, this message translates to:
  /// **'Search currency...'**
  String get exchange_search;

  /// No description provided for @exchange_rateUpdated.
  ///
  /// In en, this message translates to:
  /// **'{code} rate updated'**
  String exchange_rateUpdated(String code);

  /// No description provided for @exchange_editRate.
  ///
  /// In en, this message translates to:
  /// **'Edit {code} Rate'**
  String exchange_editRate(String code);

  /// No description provided for @exchange_rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get exchange_rateLabel;

  /// No description provided for @exchange_invalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate'**
  String get exchange_invalidRate;

  /// No description provided for @archived_transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get archived_transaction;

  /// No description provided for @currency_changingCurrency.
  ///
  /// In en, this message translates to:
  /// **'Changing currency...'**
  String get currency_changingCurrency;

  /// No description provided for @currency_pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Archiving transactions and updating settings'**
  String get currency_pleaseWait;

  /// No description provided for @security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security_title;

  /// No description provided for @security_unprotected.
  ///
  /// In en, this message translates to:
  /// **'Unprotected'**
  String get security_unprotected;

  /// No description provided for @security_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get security_basic;

  /// No description provided for @security_strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get security_strong;

  /// No description provided for @security_unprotectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN or biometrics to protect your data'**
  String get security_unprotectedDesc;

  /// No description provided for @security_protectionsActive.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} protections active'**
  String security_protectionsActive(int count, int total);

  /// No description provided for @security_authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get security_authentication;

  /// No description provided for @security_pinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN Lock'**
  String get security_pinLock;

  /// No description provided for @security_pinActive.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN active'**
  String get security_pinActive;

  /// No description provided for @security_pinSet.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN'**
  String get security_pinSet;

  /// No description provided for @security_biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get security_biometric;

  /// No description provided for @security_biometricDesc.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or Face ID'**
  String get security_biometricDesc;

  /// No description provided for @security_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get security_manage;

  /// No description provided for @security_changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get security_changePin;

  /// No description provided for @security_changePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your 4-digit PIN'**
  String get security_changePinDesc;

  /// No description provided for @security_enablePinFirst.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN first'**
  String get security_enablePinFirst;

  /// No description provided for @security_biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric enabled'**
  String get security_biometricEnabled;

  /// No description provided for @security_biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric disabled'**
  String get security_biometricDisabled;

  /// No description provided for @security_infoText.
  ///
  /// In en, this message translates to:
  /// **'Your PIN is stored securely on this device — it never touches a server. Digits are randomized on entry for extra protection.'**
  String get security_infoText;

  /// No description provided for @notifSettings_activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 active'**
  String notifSettings_activeCount(int count);

  /// No description provided for @notifSettings_summaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Summaries show spending, income, top category & balance'**
  String get notifSettings_summaryDesc;

  /// No description provided for @notifSettings_dailySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s spending overview'**
  String get notifSettings_dailySummaryDesc;

  /// No description provided for @notifSettings_weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Every {day} at 9:00 AM'**
  String notifSettings_weeklySchedule(String day);

  /// No description provided for @smsImport_autoImporting.
  ///
  /// In en, this message translates to:
  /// **'Transactions are being imported automatically'**
  String get smsImport_autoImporting;

  /// No description provided for @smsImport_enableToStart.
  ///
  /// In en, this message translates to:
  /// **'Enable auto import to start tracking'**
  String get smsImport_enableToStart;

  /// No description provided for @smsImport_iosRestriction.
  ///
  /// In en, this message translates to:
  /// **'Auto import is only available on Android due to iOS platform restrictions.'**
  String get smsImport_iosRestriction;

  /// No description provided for @common_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get common_change;

  /// No description provided for @goal_whatSavingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you saving for?'**
  String get goal_whatSavingFor;

  /// No description provided for @netWorth_totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Net Worth'**
  String get netWorth_totalLabel;

  /// No description provided for @netWorth_notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get netWorth_notEnoughData;

  /// No description provided for @netWorth_assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get netWorth_assets;

  /// No description provided for @netWorth_liabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get netWorth_liabilities;

  /// No description provided for @netWorth_composition.
  ///
  /// In en, this message translates to:
  /// **'Wealth Composition'**
  String get netWorth_composition;

  /// No description provided for @goal_milestoneStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get goal_milestoneStarted;

  /// No description provided for @goal_milestoneStartedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your journey began'**
  String get goal_milestoneStartedDesc;

  /// No description provided for @goal_milestone25.
  ///
  /// In en, this message translates to:
  /// **'25%'**
  String get goal_milestone25;

  /// No description provided for @goal_milestone25Desc.
  ///
  /// In en, this message translates to:
  /// **'Quarter way there'**
  String get goal_milestone25Desc;

  /// No description provided for @goal_milestone50.
  ///
  /// In en, this message translates to:
  /// **'50%'**
  String get goal_milestone50;

  /// No description provided for @goal_milestone50Desc.
  ///
  /// In en, this message translates to:
  /// **'Halfway done!'**
  String get goal_milestone50Desc;

  /// No description provided for @goal_milestone75.
  ///
  /// In en, this message translates to:
  /// **'75%'**
  String get goal_milestone75;

  /// No description provided for @goal_milestone75Desc.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get goal_milestone75Desc;

  /// No description provided for @goal_milestone100.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get goal_milestone100;

  /// No description provided for @goal_milestone100Desc.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get goal_milestone100Desc;

  /// No description provided for @goal_flexibleTimeline.
  ///
  /// In en, this message translates to:
  /// **'Flexible timeline'**
  String get goal_flexibleTimeline;

  /// No description provided for @goal_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get goal_amount;

  /// No description provided for @goal_emotionReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get goal_emotionReached;

  /// No description provided for @goal_emotionProgress.
  ///
  /// In en, this message translates to:
  /// **'Great progress ✨'**
  String get goal_emotionProgress;

  /// No description provided for @goal_emotionMoreToGo.
  ///
  /// In en, this message translates to:
  /// **'Just {amount} more to go 💪'**
  String goal_emotionMoreToGo(Object amount);

  /// No description provided for @goal_emotionSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Set your target 🎯'**
  String get goal_emotionSetTarget;

  /// No description provided for @goal_emotionWhatSaving.
  ///
  /// In en, this message translates to:
  /// **'What are you saving for?'**
  String get goal_emotionWhatSaving;

  /// No description provided for @goal_exceededTarget.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your target! 🎉'**
  String get goal_exceededTarget;

  /// No description provided for @goal_alreadyReached.
  ///
  /// In en, this message translates to:
  /// **'Goal already reached! 🎉'**
  String get goal_alreadyReached;

  /// No description provided for @goal_progressLeft.
  ///
  /// In en, this message translates to:
  /// **'{percent}% there • {amount} left'**
  String goal_progressLeft(Object percent, Object amount);

  /// No description provided for @goal_paceDaily.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you need {daily}/day to reach your goal.\nThat\'s {monthly}/month.'**
  String goal_paceDaily(Object daily, Object monthly);

  /// No description provided for @goal_daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String goal_daysRemaining(Object count);

  /// No description provided for @goal_daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String goal_daysLeft(Object count);

  /// No description provided for @goal_startSaving.
  ///
  /// In en, this message translates to:
  /// **'Start saving {amount}'**
  String goal_startSaving(Object amount);

  /// No description provided for @goal_goalsInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 goal in progress} other{{count} goals in progress}}'**
  String goal_goalsInProgress(num count);

  /// No description provided for @goal_completedSection.
  ///
  /// In en, this message translates to:
  /// **'Completed 🎉'**
  String get goal_completedSection;

  /// No description provided for @goal_emotionAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there 🚀'**
  String get goal_emotionAlmost;

  /// No description provided for @goal_emotionHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway there 💪'**
  String get goal_emotionHalfway;

  /// No description provided for @goal_emotionEvery.
  ///
  /// In en, this message translates to:
  /// **'Every bit counts 🌱'**
  String get goal_emotionEvery;

  /// No description provided for @goal_emotionHalfwayDone.
  ///
  /// In en, this message translates to:
  /// **'Halfway done ✨'**
  String get goal_emotionHalfwayDone;

  /// No description provided for @goal_emotionKeepPushing.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing 🔥'**
  String get goal_emotionKeepPushing;

  /// No description provided for @goal_emotionJustStarted.
  ///
  /// In en, this message translates to:
  /// **'Just getting started 🌱'**
  String get goal_emotionJustStarted;

  /// No description provided for @goal_closestToCompletion.
  ///
  /// In en, this message translates to:
  /// **'Closest to completion'**
  String get goal_closestToCompletion;

  /// No description provided for @goal_acrossGoals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{across 1 goal} other{across {count} goals}}'**
  String goal_acrossGoals(num count);

  /// No description provided for @goal_suffixSaved.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get goal_suffixSaved;

  /// No description provided for @goal_suffixLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get goal_suffixLeft;

  /// No description provided for @goal_suffixDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get goal_suffixDone;

  /// No description provided for @goal_suffixAchieved.
  ///
  /// In en, this message translates to:
  /// **'achieved'**
  String get goal_suffixAchieved;

  /// No description provided for @goal_suffixToGo.
  ///
  /// In en, this message translates to:
  /// **'to go'**
  String get goal_suffixToGo;

  /// No description provided for @goal_needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention ⚠️'**
  String get goal_needsAttention;

  /// No description provided for @goal_aheadOfSchedule.
  ///
  /// In en, this message translates to:
  /// **'Ahead of schedule 🎯'**
  String get goal_aheadOfSchedule;

  /// No description provided for @goal_monthsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} months left'**
  String goal_monthsLeft(Object count);

  /// No description provided for @goal_emotionDidIt.
  ///
  /// In en, this message translates to:
  /// **'You did it! 🎉'**
  String get goal_emotionDidIt;

  /// No description provided for @goal_emotionSoClose.
  ///
  /// In en, this message translates to:
  /// **'So close, keep going! 💪'**
  String get goal_emotionSoClose;

  /// No description provided for @goal_emotionMomentum.
  ///
  /// In en, this message translates to:
  /// **'Building momentum 🔥'**
  String get goal_emotionMomentum;

  /// No description provided for @goal_emotionCatchUp.
  ///
  /// In en, this message translates to:
  /// **'Let\'s catch up ⚡'**
  String get goal_emotionCatchUp;

  /// No description provided for @goal_finishGoal.
  ///
  /// In en, this message translates to:
  /// **'Finish this goal! 🚀'**
  String get goal_finishGoal;

  /// No description provided for @goal_onTrackStatus.
  ///
  /// In en, this message translates to:
  /// **'On Track ✅'**
  String get goal_onTrackStatus;

  /// No description provided for @goal_behindPace.
  ///
  /// In en, this message translates to:
  /// **'Behind pace ⚠️'**
  String get goal_behindPace;

  /// No description provided for @goal_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String goal_daysAgo(Object count);

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get common_yesterday;

  /// No description provided for @common_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get common_amount;

  /// No description provided for @accounts_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get accounts_edit;

  /// No description provided for @accounts_balanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Balance History'**
  String get accounts_balanceHistory;

  /// No description provided for @accounts_matchBank.
  ///
  /// In en, this message translates to:
  /// **'Match with bank statement'**
  String get accounts_matchBank;

  /// No description provided for @accounts_viewPortfolio.
  ///
  /// In en, this message translates to:
  /// **'View Portfolio'**
  String get accounts_viewPortfolio;

  /// No description provided for @accounts_setAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get accounts_setAsPrimary;

  /// No description provided for @accounts_primaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Default account for splits & trips'**
  String get accounts_primaryDesc;

  /// No description provided for @accounts_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accounts_archive;

  /// No description provided for @accounts_archiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide from active accounts'**
  String get accounts_archiveDesc;

  /// No description provided for @accounts_unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get accounts_unarchive;

  /// No description provided for @accounts_unarchiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore to active accounts'**
  String get accounts_unarchiveDesc;

  /// No description provided for @accounts_deleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove account'**
  String get accounts_deleteDesc;

  /// No description provided for @smsActivity_title.
  ///
  /// In en, this message translates to:
  /// **'Transaction Activity'**
  String get smsActivity_title;

  /// No description provided for @smsActivity_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get smsActivity_approved;

  /// No description provided for @smsActivity_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get smsActivity_pending;

  /// No description provided for @smsActivity_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get smsActivity_rejected;

  /// No description provided for @smsActivity_needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get smsActivity_needsReview;

  /// No description provided for @smsActivity_duplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get smsActivity_duplicates;

  /// No description provided for @smsActivity_filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get smsActivity_filterByStatus;

  /// No description provided for @smsActivity_transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Transactions'**
  String smsActivity_transactionCount(Object count);

  /// No description provided for @smsActivity_needsAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} needs attention'**
  String smsActivity_needsAttention(Object count);

  /// No description provided for @smsActivity_resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String smsActivity_resultCount(Object count);

  /// No description provided for @smsActivity_noActivities.
  ///
  /// In en, this message translates to:
  /// **'No matching activities'**
  String get smsActivity_noActivities;

  /// No description provided for @smsActivity_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get smsActivity_status;

  /// No description provided for @smsActivity_confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get smsActivity_confidence;

  /// No description provided for @smsActivity_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get smsActivity_account;

  /// No description provided for @smsActivity_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get smsActivity_bank;

  /// No description provided for @smsActivity_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get smsActivity_type;

  /// No description provided for @smsActivity_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get smsActivity_merchant;

  /// No description provided for @smsActivity_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get smsActivity_balance;

  /// No description provided for @smsActivity_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get smsActivity_reference;

  /// No description provided for @smsActivity_duplicateLabel.
  ///
  /// In en, this message translates to:
  /// **'DUPLICATE'**
  String get smsActivity_duplicateLabel;

  /// No description provided for @smsActivity_transferLabel.
  ///
  /// In en, this message translates to:
  /// **'TRANSFER'**
  String get smsActivity_transferLabel;

  /// No description provided for @smsActivity_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get smsActivity_reject;

  /// No description provided for @smsActivity_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get smsActivity_approve;

  /// No description provided for @smsActivity_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get smsActivity_transfer;

  /// No description provided for @smsActivity_addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add A/C'**
  String get smsActivity_addAccount;

  /// No description provided for @smsActivity_duplicateWarning.
  ///
  /// In en, this message translates to:
  /// **'This may be a duplicate transaction. Review carefully before approving.'**
  String get smsActivity_duplicateWarning;

  /// No description provided for @smsActivity_noAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'No account found matching \"{account}\". Add one to approve.'**
  String smsActivity_noAccountWarning(Object account);

  /// No description provided for @smsActivity_transferWarning.
  ///
  /// In en, this message translates to:
  /// **'This looks like a transfer between your accounts. Approving will open the transfer screen.'**
  String get smsActivity_transferWarning;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @backup_lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backup_lastBackup;

  /// No description provided for @backup_noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backup_noBackups;

  /// No description provided for @backup_createFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first backup to protect your data'**
  String get backup_createFirst;

  /// No description provided for @backup_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get backup_actions;

  /// No description provided for @backup_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get backup_history;

  /// No description provided for @backup_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No backup history'**
  String get backup_noHistory;

  /// No description provided for @backup_infoText.
  ///
  /// In en, this message translates to:
  /// **'Backups are encrypted with your password and saved as .mudra files. Keep your password safe — it cannot be recovered.'**
  String get backup_infoText;

  /// No description provided for @backup_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get backup_justNow;

  /// No description provided for @backup_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String backup_minutesAgo(int count);

  /// No description provided for @backup_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String backup_hoursAgo(int count);

  /// No description provided for @backup_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String backup_daysAgo(int count);

  /// No description provided for @backup_recordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String backup_recordCount(int count);

  /// No description provided for @account_changeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change Currency?'**
  String get account_changeCurrency;

  /// No description provided for @account_resetTo.
  ///
  /// In en, this message translates to:
  /// **'Reset to {code}'**
  String account_resetTo(String code);

  /// No description provided for @account_baseCurrencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Transactions in this account use your base currency.'**
  String get account_baseCurrencyInfo;

  /// No description provided for @account_foreignCurrencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Transactions will be recorded in {code} and converted to {base} for totals.'**
  String account_foreignCurrencyInfo(String code, String base);

  /// No description provided for @account_warningNoConvert.
  ///
  /// In en, this message translates to:
  /// **'Existing balances will NOT be converted automatically.'**
  String get account_warningNoConvert;

  /// No description provided for @account_warningNewCurrency.
  ///
  /// In en, this message translates to:
  /// **'New transactions will use the new currency.'**
  String get account_warningNewCurrency;

  /// No description provided for @account_warningManualAdjust.
  ///
  /// In en, this message translates to:
  /// **'You may need to manually adjust the balance.'**
  String get account_warningManualAdjust;

  /// No description provided for @category_selectParent.
  ///
  /// In en, this message translates to:
  /// **'Select Parent Category'**
  String get category_selectParent;

  /// No description provided for @appearance_colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get appearance_colorTheme;

  /// No description provided for @appearance_amoledMode.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Mode'**
  String get appearance_amoledMode;

  /// No description provided for @appearance_toneActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} tone activated'**
  String appearance_toneActivated(String name);

  /// No description provided for @dashboard_cardsActive.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total} cards active'**
  String dashboard_cardsActive(int visible, int total);

  /// No description provided for @dashboard_dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder, toggle to show or hide'**
  String get dashboard_dragToReorder;

  /// No description provided for @dashboard_smartOrdering.
  ///
  /// In en, this message translates to:
  /// **'Smart ordering'**
  String get dashboard_smartOrdering;

  /// No description provided for @dashboard_catEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get dashboard_catEssential;

  /// No description provided for @dashboard_catFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get dashboard_catFinance;

  /// No description provided for @dashboard_catAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get dashboard_catAnalytics;

  /// No description provided for @dashboard_catActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get dashboard_catActions;

  /// No description provided for @dashboard_catAI.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get dashboard_catAI;

  /// No description provided for @dashboard_catContextual.
  ///
  /// In en, this message translates to:
  /// **'Contextual'**
  String get dashboard_catContextual;

  /// No description provided for @importExport_title.
  ///
  /// In en, this message translates to:
  /// **'Import & Export'**
  String get importExport_title;

  /// No description provided for @importExport_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get importExport_export;

  /// No description provided for @importExport_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importExport_import;

  /// No description provided for @importExport_exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Transactions'**
  String get importExport_exportTitle;

  /// No description provided for @importExport_exportDesc.
  ///
  /// In en, this message translates to:
  /// **'Download your transactions as an Excel file.'**
  String get importExport_exportDesc;

  /// No description provided for @importExport_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get importExport_exporting;

  /// No description provided for @importExport_exportAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get importExport_exportAsExcel;

  /// No description provided for @importExport_importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Excel'**
  String get importExport_importTitle;

  /// No description provided for @importExport_importDesc.
  ///
  /// In en, this message translates to:
  /// **'Import transactions from an .xlsx file. You\'ll be able to preview and map columns before importing.'**
  String get importExport_importDesc;

  /// No description provided for @importExport_excelFormat.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx)'**
  String get importExport_excelFormat;

  /// No description provided for @importExport_bankStatement.
  ///
  /// In en, this message translates to:
  /// **'Bank Statement'**
  String get importExport_bankStatement;

  /// No description provided for @importExport_otherApps.
  ///
  /// In en, this message translates to:
  /// **'Other Apps'**
  String get importExport_otherApps;

  /// No description provided for @importExport_pickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick Excel File'**
  String get importExport_pickFile;

  /// No description provided for @importExport_infoText.
  ///
  /// In en, this message translates to:
  /// **'Export creates an Excel file with all transaction details. Import supports .xlsx files from other finance apps or manual spreadsheets.'**
  String get importExport_infoText;

  /// No description provided for @plugins_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Extend Mudra Manager with powerful plugins'**
  String get plugins_subtitle;

  /// No description provided for @plugins_official.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get plugins_official;

  /// No description provided for @plugins_enabled.
  ///
  /// In en, this message translates to:
  /// **'{name} enabled'**
  String plugins_enabled(String name);

  /// No description provided for @plugins_disabled.
  ///
  /// In en, this message translates to:
  /// **'{name} disabled'**
  String plugins_disabled(String name);

  /// No description provided for @plugins_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure Plugin'**
  String get plugins_configure;

  /// No description provided for @plugins_activeCount.
  ///
  /// In en, this message translates to:
  /// **'{active} of {total} active'**
  String plugins_activeCount(int active, int total);

  /// No description provided for @plugins_toggleDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle plugins to extend app features'**
  String get plugins_toggleDesc;

  /// No description provided for @plugins_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get plugins_default;

  /// No description provided for @plugins_configureSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure plugin settings'**
  String get plugins_configureSettings;

  /// No description provided for @plugins_creditCardReminders.
  ///
  /// In en, this message translates to:
  /// **'Credit Card Reminders'**
  String get plugins_creditCardReminders;

  /// No description provided for @plugins_remindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me before (days)'**
  String get plugins_remindBefore;

  /// No description provided for @plugins_noCreditCards.
  ///
  /// In en, this message translates to:
  /// **'No credit card accounts found. Add one first.'**
  String get plugins_noCreditCards;

  /// No description provided for @plugins_creditCardAccounts.
  ///
  /// In en, this message translates to:
  /// **'Credit Card Accounts'**
  String get plugins_creditCardAccounts;

  /// No description provided for @plugins_billDay.
  ///
  /// In en, this message translates to:
  /// **'Bill Day (1-31)'**
  String get plugins_billDay;

  /// No description provided for @plugins_remindersConfigured.
  ///
  /// In en, this message translates to:
  /// **'Credit card reminders configured'**
  String get plugins_remindersConfigured;

  /// No description provided for @plugins_infoText.
  ///
  /// In en, this message translates to:
  /// **'Plugins extend app features. Some plugins require additional permissions or configuration.'**
  String get plugins_infoText;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help_title;

  /// No description provided for @help_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search help topics...'**
  String get help_searchHint;

  /// No description provided for @help_heroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get help_heroTitle;

  /// No description provided for @help_heroDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse guides or search for a topic'**
  String get help_heroDesc;

  /// No description provided for @help_topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get help_topics;

  /// No description provided for @help_tryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get help_tryDifferent;

  /// No description provided for @help_howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get help_howToUse;

  /// No description provided for @help_tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get help_tips;

  /// No description provided for @help_articleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} articles'**
  String help_articleCount(int count);

  /// No description provided for @help_resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String help_resultCount(int count);

  /// No description provided for @help_infoText.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find what you need? Visit About → Contact Support for direct help.'**
  String get help_infoText;

  /// No description provided for @about_legalCount.
  ///
  /// In en, this message translates to:
  /// **'3 items'**
  String get about_legalCount;

  /// No description provided for @about_supportCount.
  ///
  /// In en, this message translates to:
  /// **'4 items'**
  String get about_supportCount;

  /// No description provided for @about_packageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open source packages'**
  String about_packageCount(int count);

  /// No description provided for @onboard_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboard_continue;

  /// No description provided for @onboard_restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get onboard_restoreFromBackup;

  /// No description provided for @onboard_accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account name is required'**
  String get onboard_accountNameRequired;

  /// No description provided for @onboard_balanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Balance is required'**
  String get onboard_balanceRequired;

  /// No description provided for @onboard_enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get onboard_enterValidNumber;

  /// No description provided for @onboard_accountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cash, Bank'**
  String get onboard_accountHint;

  /// No description provided for @onboard_browseAllCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Browse all currencies'**
  String get onboard_browseAllCurrencies;

  /// No description provided for @onboard_toneTitle.
  ///
  /// In en, this message translates to:
  /// **'How should Mudra talk to you?'**
  String get onboard_toneTitle;

  /// No description provided for @onboard_toneDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a personality. You can change this anytime.'**
  String get onboard_toneDesc;

  /// No description provided for @onboard_categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Categories'**
  String get onboard_categoriesTitle;

  /// No description provided for @onboard_categoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick packs that match your lifestyle. You can change these later.'**
  String get onboard_categoriesDesc;

  /// No description provided for @onboard_startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get onboard_startFresh;

  /// No description provided for @onboard_startFreshDesc.
  ///
  /// In en, this message translates to:
  /// **'No categories — add your own later'**
  String get onboard_startFreshDesc;

  /// No description provided for @onboard_currencyWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing base currency later will archive existing transactions.'**
  String get onboard_currencyWarning;

  /// No description provided for @statistics_topCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get statistics_topCategory;

  /// No description provided for @statistics_dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get statistics_dailyAverage;

  /// No description provided for @statistics_perDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get statistics_perDay;

  /// No description provided for @statistics_percentOfExpenses.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of expenses'**
  String statistics_percentOfExpenses(String percent);

  /// No description provided for @sms_infoTitle.
  ///
  /// In en, this message translates to:
  /// **'How SMS Import Works'**
  String get sms_infoTitle;

  /// No description provided for @sms_infoOnlyScans.
  ///
  /// In en, this message translates to:
  /// **'Only scans bank and wallet SMS'**
  String get sms_infoOnlyScans;

  /// No description provided for @sms_infoStaysOnDevice.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device'**
  String get sms_infoStaysOnDevice;

  /// No description provided for @sms_infoAutoCreates.
  ///
  /// In en, this message translates to:
  /// **'Automatically creates transactions'**
  String get sms_infoAutoCreates;

  /// No description provided for @sms_infoNoPersonal.
  ///
  /// In en, this message translates to:
  /// **'No personal messages are read'**
  String get sms_infoNoPersonal;

  /// No description provided for @dashboard_totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get dashboard_totalBalance;

  /// No description provided for @dashboard_netWorthLink.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get dashboard_netWorthLink;

  /// No description provided for @dashboard_showAccounts.
  ///
  /// In en, this message translates to:
  /// **'Show accounts'**
  String get dashboard_showAccounts;

  /// No description provided for @dashboard_hideAccounts.
  ///
  /// In en, this message translates to:
  /// **'Hide accounts'**
  String get dashboard_hideAccounts;

  /// No description provided for @dashboard_accountsTapExpand.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts · Tap to expand'**
  String dashboard_accountsTapExpand(int count);

  /// No description provided for @notif_lowBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Low Balance Alert'**
  String get notif_lowBalanceTitle;

  /// No description provided for @notif_lowBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'Your balance in {account} is {amount}'**
  String notif_lowBalanceBody(String account, String amount);

  /// No description provided for @achieve_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achieve_unlocked;

  /// No description provided for @achieve_inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get achieve_inProgress;

  /// No description provided for @achieve_trophyShelf.
  ///
  /// In en, this message translates to:
  /// **'Trophy Shelf'**
  String get achieve_trophyShelf;

  /// No description provided for @achieve_streaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get achieve_streaks;

  /// No description provided for @achieve_totalXP.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get achieve_totalXP;

  /// No description provided for @achieve_dailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get achieve_dailyCheckIn;

  /// No description provided for @achieve_budgetAdherence.
  ///
  /// In en, this message translates to:
  /// **'Budget Adherence'**
  String get achieve_budgetAdherence;

  /// No description provided for @achieve_bestDays.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} days'**
  String achieve_bestDays(int count);

  /// No description provided for @achieve_noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No {category} badges yet'**
  String achieve_noBadgesYet(String category);

  /// No description provided for @achieve_levelUpSnack.
  ///
  /// In en, this message translates to:
  /// **'🎉 Level Up! You are now Level {level}!'**
  String achieve_levelUpSnack(int level);

  /// No description provided for @achieve_levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String achieve_levelLabel(int level);

  /// No description provided for @achieve_catBudgeting.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get achieve_catBudgeting;

  /// No description provided for @achieve_catSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get achieve_catSavings;

  /// No description provided for @achieve_catTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get achieve_catTracking;

  /// No description provided for @achieve_catMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get achieve_catMilestones;

  /// No description provided for @achieve_catEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get achieve_catEngagement;

  /// No description provided for @achieve_catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achieve_catAll;

  /// No description provided for @alert_actionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action Needed'**
  String get alert_actionNeeded;

  /// No description provided for @alert_billsDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due tomorrow'**
  String alert_billsDueTomorrow(int count);

  /// No description provided for @alert_upcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get alert_upcomingBills;

  /// No description provided for @alert_billsDueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s) due in 2 days'**
  String alert_billsDueInDays(int count);

  /// No description provided for @alert_budgetAlert.
  ///
  /// In en, this message translates to:
  /// **'Budget Alert'**
  String get alert_budgetAlert;

  /// No description provided for @alert_budgetsExceeded.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) exceeded'**
  String alert_budgetsExceeded(int count);

  /// No description provided for @alert_budgetWarning.
  ///
  /// In en, this message translates to:
  /// **'Budget Warning'**
  String get alert_budgetWarning;

  /// No description provided for @alert_budgetsNearLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} budget(s) near limit'**
  String alert_budgetsNearLimit(int count);

  /// No description provided for @alert_goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get alert_goalProgress;

  /// No description provided for @alert_goalsAlmostComplete.
  ///
  /// In en, this message translates to:
  /// **'{count} goal(s) almost complete!'**
  String alert_goalsAlmostComplete(int count);

  /// No description provided for @analytics_cashFlowForecast.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow Forecast'**
  String get analytics_cashFlowForecast;

  /// No description provided for @analytics_thisMonthProjected.
  ///
  /// In en, this message translates to:
  /// **'This month (projected)'**
  String get analytics_thisMonthProjected;

  /// No description provided for @analytics_savingOnAverage.
  ///
  /// In en, this message translates to:
  /// **'You are saving on average'**
  String get analytics_savingOnAverage;

  /// No description provided for @analytics_spendingExceedsIncome.
  ///
  /// In en, this message translates to:
  /// **'Spending exceeds income'**
  String get analytics_spendingExceedsIncome;

  /// No description provided for @recap_vsLastYear.
  ///
  /// In en, this message translates to:
  /// **'vs Last Year'**
  String get recap_vsLastYear;

  /// No description provided for @common_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get common_income;

  /// No description provided for @common_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get common_expense;

  /// No description provided for @common_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get common_transactions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'as',
        'bn',
        'bo',
        'brx',
        'de',
        'doi',
        'en',
        'es',
        'fr',
        'gu',
        'hi',
        'id',
        'ja',
        'kn',
        'ko',
        'kok',
        'mai',
        'ml',
        'mni',
        'mr',
        'ms',
        'ne',
        'or',
        'pa',
        'pt',
        'sat',
        'sd',
        'si',
        'sw',
        'ta',
        'te',
        'th',
        'tr',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'bo':
      return AppLocalizationsBo();
    case 'brx':
      return AppLocalizationsBrx();
    case 'de':
      return AppLocalizationsDe();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'kok':
      return AppLocalizationsKok();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pt':
      return AppLocalizationsPt();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'si':
      return AppLocalizationsSi();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
