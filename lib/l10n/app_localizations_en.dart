// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription => 'Manage your money smartly & effortlessly.';

  @override
  String onboard_welcomeToApp(Object appName) {
    return 'Welcome to $appName';
  }

  @override
  String get onboard_TrackYourTransactions => 'Track your Transactions';

  @override
  String get onboard_SeeWhereYourMoneyGoes => 'See where your money goes, every day.';

  @override
  String get onboard_SetBudgetsAndGoals => 'Set Budgets and Goals';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream => 'Stay on track and achieve your dreams.';

  @override
  String get onboard_GetStarted => 'Get Started!';

  @override
  String get onboard_letsSetupYourAccount => 'Let\'s set up your account.';

  @override
  String get onboard_howShouldWeCallYou => 'How should we call you?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience => 'Enter your name to personalize your experience.';

  @override
  String get onboard_enterYourName => 'Enter your name';

  @override
  String get onboard_setupYourFirstAccount => 'Setup Your First Account';

  @override
  String get onboard_letsCreateYourFirstAccount => 'Let\'s create your first account (let say: Cash).';

  @override
  String get onboard_accountName => 'Account Name';

  @override
  String get onboard_initialBalance => 'Initial Balance';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell => 'You can update other details later as well.';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'Please fill the \"$inputName\"';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'Please enter a valid number for \"$hintText\"';
  }

  @override
  String get onboard_youAreAllSet => 'You\'re all set!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely => 'Let\'s start managing your money wisely.';

  @override
  String get app_settings_appbar_title => 'App Settings';

  @override
  String get language_settings_appbar_title => 'Choose Language';

  @override
  String get app_settings_language_title => 'Language';

  @override
  String get app_settings_language_subtitle => 'Choose your language';

  @override
  String get app_settings_theme_mode_title => 'Theme Mode';

  @override
  String get app_settings_theme_mode_light => 'Light';

  @override
  String get app_settings_theme_mode_dark => 'Dark';

  @override
  String get app_settings_theme_mode_system_default => 'System Default';

  @override
  String get app_settings_daily_reminder_title => 'Daily Expense Reminder';

  @override
  String get home_screen_title => 'Home';

  @override
  String get transaction_screen_title => 'Activity';

  @override
  String get statistics_screen_title => 'Statistics';

  @override
  String get profile_screen_title => 'Profile';

  @override
  String get add_edit_transaction_screen_title => 'Add Transaction';

  @override
  String get transaction_list_screen_title => 'Transaction List';

  @override
  String get transaction_listViewGroupTodayLabel => 'Today';

  @override
  String get transaction_listViewGroupYesterdayLabel => 'Yesterday';

  @override
  String get greeting_good_morning_text => 'Good Morning';

  @override
  String get greeting_good_afternoon_text => 'Good Afternoon';

  @override
  String get greeting_good_evening_text => 'Good Evening';

  @override
  String get greeting_good_night_text => 'Good Night';

  @override
  String get greeting_hello_text => 'Hello';

  @override
  String get transaction_type_income => 'Income';

  @override
  String get transaction_type_expense => 'Expense';

  @override
  String get dashboard_add_transaction_text => 'Add transaction';

  @override
  String get dashboard_add_transfer_text => 'Transfer';

  @override
  String get dashboard_cash_flow_text => 'Cash Flow';

  @override
  String get cash_flow_filter_type_day => 'Day';

  @override
  String get cash_flow_filter_type_week => 'Week';

  @override
  String get cash_flow_filter_type_month => 'Month';

  @override
  String get cash_flow_filter_type_year => 'Year';

  @override
  String get dashboard_mini_budget_text => 'Budget';

  @override
  String get dashboard_mini_budget_not_found_text => 'No Budgets Defined, Add One!';

  @override
  String get dashboard_mini_budget_add_text => 'Add Budget';

  @override
  String get transaction_list_cash_flow_screen_title => 'Transactions';

  @override
  String get transaction_list_filter_all => 'All';

  @override
  String get transaction_list_filter_income => 'Income';

  @override
  String get transaction_list_filter_expense => 'Expense';

  @override
  String get transaction_list_pending_transaction_message_text => '⚡ New transactions found! Review now';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'Review';

  @override
  String get transaction_noTransactionFoundText => 'No transactions found.';

  @override
  String get transaction_deleteAlertTitleText => 'Delete Transaction?';

  @override
  String get transaction_deleteAlertBodyText => 'This action cannot be undone.';

  @override
  String get transaction_deleteButtonActionText => 'Delete';

  @override
  String get transaction_cancelButtonActionText => 'Cancel';

  @override
  String get transaction_filterCategoryText => 'Filter Transactions';

  @override
  String transaction_noteDescriptionText(Object description) {
    return 'note: $description';
  }

  @override
  String get calendar_week_monday_initial_text => 'M';

  @override
  String get calendar_week_tuesday_initial_text => 'T';

  @override
  String get calendar_week_wednesday_initial_text => 'W';

  @override
  String get calendar_week_thursday_initial_text => 'T';

  @override
  String get calendar_week_friday_initial_text => 'F';

  @override
  String get calendar_week_saturday_initial_text => 'S';

  @override
  String get calendar_week_sunday_initial_text => 'S';

  @override
  String get dashboard_netWorthTitle => 'Net Worth';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'Budget';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'Spent';

  @override
  String get budget_dashboardPageTitle => 'Budgets Details';

  @override
  String get budget_dashboardNotFoundText => 'No Budgets Defined, Add One!';

  @override
  String get budget_dashboardAddBudgetText => 'Add Budget';

  @override
  String get budget_categoriesTitle => 'Categories';

  @override
  String budget_dashboardPieChartLabelText(Object spentPercent, Object title, Object totalPercent) {
    return '$title ($totalPercent of Total, ${spentPercent}of Spent)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'Delete Budget?';

  @override
  String get budget_buttonDeleteBodyText => 'This will remove the Budget and its allocations, this action cannot be undone.';

  @override
  String get budget_buttonDeleteActionText => 'Delete';

  @override
  String get budget_buttonCancelActionText => 'Cancel';

  @override
  String get budget_buttonAddText => 'Add Budget';

  @override
  String get budget_buttonEditText => 'Edit Budget';

  @override
  String get budget_budgetNameControllerText => 'Budget Name';

  @override
  String get budget_budgetAmountControllerText => 'Total Amount';

  @override
  String get budget_recurrenceControllerText => 'Recurrence';

  @override
  String get budget_nameRequiredHintText => 'Budget name is required';

  @override
  String get budget_amountRequiredHintText => 'Valid Amount is required';

  @override
  String get budget_selectStartDateText => 'Select Start Date';

  @override
  String budget_selectedStartDateText(Object startDate) {
    return 'Start: $startDate';
  }

  @override
  String get budget_selectEndDateText => 'Select End Date';

  @override
  String budget_selectedEndDateText(Object endDate) {
    return 'End: $endDate';
  }

  @override
  String get budget_categoryTitle => 'Select Categories & Allocations';

  @override
  String get budget_allocateAmountText => 'Allocate Amount';

  @override
  String get budget_categoryMessageInfoText => 'You can manually enter category allocations, or leave them blank to auto-distribute the remaining amount equally.';

  @override
  String budget_totalAllocatedBudgetText(Object totalAlloc) {
    return 'Total Allocated: $totalAlloc';
  }

  @override
  String get budget_recurrenceText => 'Recurrence';

  @override
  String get budget_recurrenceNoneText => 'None';

  @override
  String get budget_recurrenceDailyText => 'Daily';

  @override
  String get budget_recurrenceWeeklyText => 'Weekly';

  @override
  String get budget_recurrenceMonthlyText => 'Monthly';

  @override
  String get budget_recurrenceYearlyText => 'Yearly';

  @override
  String get budget_saveButtonText => 'save';

  @override
  String get budget_updateButtonText => 'update';

  @override
  String get budget_pickBothDatesErrorText => 'Pick both dates';

  @override
  String get budget_selectAtLeastOneCategoryErrorText => 'Select at least one category';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText => 'Allocated amount exceeds total budget';

  @override
  String get transaction_amountControllerText => 'Amount';

  @override
  String get transaction_descriptionControllerText => 'Description (optional)';

  @override
  String get transaction_amountControllerErrorText => 'Enter amount';

  @override
  String get transaction_selectAccountLabel => 'Select Account';

  @override
  String get transaction_selectCategoryLabel => 'Select Category';

  @override
  String get transaction_selectTagLabel => 'Select Tag';

  @override
  String get transaction_addNewCategoryText => 'Add New \nCategory';

  @override
  String get transaction_addNewTagText => 'Add New Tag';

  @override
  String get transaction_tagNameControllerText => 'Tag Name';

  @override
  String get transaction_saveTagButtonLabel => 'Save Tag';

  @override
  String get transaction_saveTransactionButtonLabel => 'Save Transaction';

  @override
  String get transaction_selectOneAccountErrorText => 'Select at least one Account';

  @override
  String get transaction_selectOneCategoryErrorText => 'Select at least one Category';

  @override
  String get transaction_incomeButtonLabel => 'INCOME';

  @override
  String get transaction_expenseButtonLabel => 'EXPENSE';

  @override
  String get statistics_weTrimDownDecimalInfoText => 'We trim down decimal places, please round off if required.';

  @override
  String get statistics_selectPeriodTodayText => 'Today';

  @override
  String get statistics_selectPeriodWeekText => 'Week';

  @override
  String get statistics_selectPeriodMonthText => 'Month';

  @override
  String get statistics_selectPeriodYearText => 'Year';

  @override
  String get statistics_chartLineIncomeText => 'Income';

  @override
  String get statistics_chartLineExpenseText => 'Expense';

  @override
  String statistics_chartLineTodayHourText(Object hour) {
    return '${hour}h';
  }

  @override
  String get statistics_categoryNotPresentText => 'Category not present.';

  @override
  String get statistics_transactionNotPresentText => 'Transactions not present.';

  @override
  String get statistics_byCategoryTitleText => 'By Category';

  @override
  String get statistics_recentTransactionsTitleText => 'Recent Transactions';

  @override
  String get statistics_metricIncomeText => 'Income';

  @override
  String get statistics_metricExpenseText => 'Expense';

  @override
  String get statistics_metricNetText => 'Net';

  @override
  String get statistics_showAllButtonText => 'Show All';

  @override
  String get statistics_exportToPdfButtonText => 'Export to PDF';

  @override
  String get statistics_exportToExcelButtonText => 'Export to Excel';

  @override
  String get profile_userProfileTitleText => 'User Profile';

  @override
  String get profile_userProfileSubtitleText => 'Change profile image, name, and email';

  @override
  String get profile_nameControllerText => 'Name';

  @override
  String get profile_nameControllerHintText => 'Enter your name';

  @override
  String get profile_nameRequiredHintText => 'Name is required';

  @override
  String get profile_emailControllerText => 'Email';

  @override
  String get profile_emailControllerHintText => 'Enter your email';

  @override
  String get profile_phoneControllerText => 'Phone';

  @override
  String get profile_phoneControllerHintText => 'Enter your phone number';

  @override
  String get profile_weAreNotStoringInfoText => 'We are not storing any data, all data is in your device!';

  @override
  String get profile_saveButtonText => 'save';

  @override
  String get profile_editUserProfileAppTitle => 'Edit User Profile';
}
