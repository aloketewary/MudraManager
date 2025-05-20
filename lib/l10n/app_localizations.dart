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
    Locale('hi'),
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
    Object spentPercent,
    Object title,
    Object totalPercent,
  );

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
    'that was used.',
  );
}
