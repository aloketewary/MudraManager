import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('bn'),
    Locale('en'),
    Locale('hi')
  ];

  /// Manage your money smartly & effortlessly.
  ///
  /// In en, this message translates to:
  /// **'Manage your money smartly & effortlessly.'**
  String get onboard_manageYourMoneyDescription;

  /// Welcome to Application
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String onboard_welcomeToApp(Object appName);

  /// Track your Transactions
  ///
  /// In en, this message translates to:
  /// **'Track your Transactions'**
  String get onboard_TrackYourTransactions;

  /// See where your money goes, every day.
  ///
  /// In en, this message translates to:
  /// **'See where your money goes, every day.'**
  String get onboard_SeeWhereYourMoneyGoes;

  /// Set Budgets and Goals
  ///
  /// In en, this message translates to:
  /// **'Set Budgets and Goals'**
  String get onboard_SetBudgetsAndGoals;

  /// Stay on track and achieve your dreams.
  ///
  /// In en, this message translates to:
  /// **'Stay on track and achieve your dreams.'**
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
  /// **'We are not storing any data, all data is in your device!'**
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
  /// **'TAP TO CHANGE ICON'**
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
  /// **'Loading'**
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

  /// Description for SMS imported transactions
  ///
  /// In en, this message translates to:
  /// **'Imported from SMS'**
  String get sms_importedFromSmsDescription;

  /// Warning message to select at least one SMS
  ///
  /// In en, this message translates to:
  /// **'Please select at least one SMS'**
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
