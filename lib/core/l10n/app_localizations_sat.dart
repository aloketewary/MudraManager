// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Santali (`sat`).
class AppLocalizationsSat extends AppLocalizations {
  AppLocalizationsSat([String locale = 'sat']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      '100% offline. Your data never leaves your device.';

  @override
  String onboard_welcomeToApp(Object appName) {
    return 'Welcome to $appName';
  }

  @override
  String get onboard_TrackYourTransactions => 'Auto-track from Bank SMS';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'Auto-import from bank SMS & notifications. Works with 50+ banks.';

  @override
  String get onboard_SetBudgetsAndGoals => 'Budgets, Goals & Smart Alerts';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'Get warnings before you overspend. Save for what matters.';

  @override
  String get onboard_GetStarted => 'Get Started!';

  @override
  String get onboard_letsSetupYourAccount => 'Let\'s set up your account.';

  @override
  String get onboard_howShouldWeCallYou => 'How should we call you?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'Enter your name to personalize your experience.';

  @override
  String get onboard_enterYourName => 'Enter your name';

  @override
  String get onboard_setupYourFirstAccount => 'Setup Your First Account';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'Let\'s create your first account (let say: Cash).';

  @override
  String get onboard_accountName => 'Account Name';

  @override
  String get onboard_initialBalance => 'Initial Balance';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'You can update other details later as well.';

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
  String get onboard_letsStartManagingYourMoneyWisely =>
      'Let\'s start managing your money wisely.';

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
  String get app_settings_theme_mode_amoled => 'AMOLED';

  @override
  String get app_settings_theme_mode_subtitle => 'Choose your preferred theme';

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
  String get dashboard_mini_budget_not_found_text =>
      'No Budgets Defined, Add One!';

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
  String get transaction_list_pending_transaction_message_text =>
      '⚡ New transactions found! Review now';

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
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent) {
    return '$title ($totalPercent of Total, ${spentPercent}of Spent)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'Delete Budget?';

  @override
  String get budget_buttonDeleteBodyText =>
      'This will remove the Budget and its allocations, this action cannot be undone.';

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
  String get budget_categoryMessageInfoText =>
      'You can manually enter category allocations, or leave them blank to auto-distribute the remaining amount equally.';

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
  String get budget_selectAtLeastOneCategoryErrorText =>
      'Select at least one category';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText =>
      'Allocated amount exceeds total budget';

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
  String get transaction_selectOneAccountErrorText =>
      'Select at least one Account';

  @override
  String get transaction_selectOneCategoryErrorText =>
      'Select at least one Category';

  @override
  String get transaction_incomeButtonLabel => 'INCOME';

  @override
  String get transaction_expenseButtonLabel => 'EXPENSE';

  @override
  String get statistics_weTrimDownDecimalInfoText =>
      'We trim down decimal places, please round off if required.';

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
  String get statistics_transactionNotPresentText =>
      'Transactions not present.';

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
  String get profile_userProfileSubtitleText =>
      'Change profile image, name, and email';

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
  String get profile_weAreNotStoringInfoText =>
      'All your data lives on this device. No servers, no cloud, no tracking.';

  @override
  String get profile_saveButtonText => 'save';

  @override
  String get profile_editUserProfileAppTitle => 'Edit User Profile';

  @override
  String get pendingTranx_reviewPendingTransactionsScreenTitle =>
      'Pending Transactions';

  @override
  String get statistics_quickOverviewTitle => 'Quick Overview';

  @override
  String get statistics_insightsTitle => 'Insights';

  @override
  String get statistics_detailedAnalysisTitle => 'Detailed Analysis';

  @override
  String get statistics_categoryBreakdownSubtitle => 'View category breakdown';

  @override
  String get statistics_expenseTrendsTitle => 'Expense Trends';

  @override
  String get statistics_expenseTrendsSubtitle => 'Last 12 months trends';

  @override
  String get statistics_recentTransactionsSubtitle => 'Last 5 transactions';

  @override
  String get statistics_categoryBreakdownTitle => 'Category Breakdown';

  @override
  String get statistics_recentTransactionsModalTitle => 'Recent Transactions';

  @override
  String get transfer_screenTitle => 'Transfer Funds';

  @override
  String get transfer_resetTooltip => 'Reset';

  @override
  String get transfer_selectAccountsLabel => 'SELECT ACCOUNTS';

  @override
  String get transfer_fromLabel => 'FROM';

  @override
  String get transfer_toLabel => 'TO';

  @override
  String get transfer_detailsLabel => 'TRANSFER DETAILS';

  @override
  String get transfer_amountLabel => 'Amount';

  @override
  String get transfer_amountValidationError => 'Enter valid amount';

  @override
  String get transfer_dateLabel => 'Date';

  @override
  String get transfer_noteLabel => 'Note (optional)';

  @override
  String get transfer_buttonLabel => 'Transfer';

  @override
  String get transfer_updateButtonLabel => 'Update Transfer';

  @override
  String get transfer_errorLoadingAccounts => 'Error loading accounts';

  @override
  String get app_settings_themeModeModalTitle => 'Theme Mode';

  @override
  String get category_expenseLabel => 'EXPENSE';

  @override
  String get category_incomeLabel => 'INCOME';

  @override
  String get category_addTitle => 'Add Category';

  @override
  String get category_editTitle => 'Edit Category';

  @override
  String get category_tapToChangeIcon => 'Tap to change icon';

  @override
  String get category_nameLabel => 'Category Name';

  @override
  String get category_nameRequired => 'Required';

  @override
  String get category_typeLabel => 'Category Type';

  @override
  String get category_colorLabel => 'Color';

  @override
  String get category_tapToChangeColor => 'TAP TO CHANGE COLOR';

  @override
  String get category_saveButton => 'SAVE CATEGORY';

  @override
  String get category_updateButton => 'UPDATE CATEGORY';

  @override
  String get dashboard_incomeLabel => 'Income';

  @override
  String get dashboard_spentLabel => 'Spent';

  @override
  String get dashboard_noDataLabel => 'No data';

  @override
  String get dashboard_editLabel => 'Edit';

  @override
  String get dashboard_archiveLabel => 'Archive';

  @override
  String get currency_crore_short => 'Cr';

  @override
  String get currency_lakh_short => 'L';

  @override
  String get currency_thousand_short => 'K';

  @override
  String common_errorText(Object error) {
    return 'Error: $error';
  }

  @override
  String get statistics_expenseShort => 'Exp';

  @override
  String get statistics_incomeShort => 'Inc';

  @override
  String get transaction_categoryFilter => 'Category Filter';

  @override
  String get transaction_dateFilter => 'Date Filter';

  @override
  String get transaction_allCategories => 'All Categories';

  @override
  String get transaction_applyFilters => 'APPLY FILTERS';

  @override
  String get sms_selectTransactions => 'Select Transactions';

  @override
  String get common_addLabel => 'Add';

  @override
  String get dashboard_removeLabel => 'Remove';

  @override
  String get dashboard_viewAllLabel => 'View All';

  @override
  String get common_noAccountsYet => 'No accounts yet';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_editLabel => 'Edit';

  @override
  String get common_deleteLabel => 'Delete';

  @override
  String get common_fromLabel => 'From';

  @override
  String get common_toLabel => 'To';

  @override
  String get theme_chooseThemeTitle => 'Choose Theme';

  @override
  String get theme_applyThemeLabel => 'Apply Theme';

  @override
  String get theme_themeAppliedMessage => 'Theme applied!';

  @override
  String get backup_backupRestoreTitle => 'Backup & Restore';

  @override
  String get backup_backupDataTitle => 'Backup Data';

  @override
  String get backup_backupDataSubtitle => 'Export all database and settings';

  @override
  String get backup_restoreBackupTitle => 'Restore Backup';

  @override
  String get backup_restoreBackupSubtitle => 'Import database and settings';

  @override
  String get backup_includeAttachmentsTitle => 'Include Attachments?';

  @override
  String get backup_includeAttachmentsMessage =>
      'Include receipt images in backup? This will increase file size.';

  @override
  String get backup_yesLabel => 'Yes';

  @override
  String get backup_noLabel => 'No';

  @override
  String get backup_completedMessage => 'Backup completed';

  @override
  String get backup_restoreSuccessMessage => 'Restore successful';

  @override
  String backup_lastBackupLabel(Object date) {
    return 'Last backup: $date';
  }

  @override
  String get backup_noBackupFoundLabel => 'No backup found';

  @override
  String get categories_manageCategoriesTitle => 'Manage Categories';

  @override
  String get categories_noCategoriesFound => 'No categories found.';

  @override
  String categories_transactionCount(Object count, Object plural) {
    return '$count transaction$plural';
  }

  @override
  String get categories_addCategoryLabel => 'Add Category';

  @override
  String get categories_deleteCategoryTitle => 'Delete Category';

  @override
  String get categories_deleteCategoryMessage =>
      'Are you sure you want to delete this category?\nAll associated transactions will also be removed.';

  @override
  String get categories_categoryDeletedMessage =>
      'Category and its transactions deleted';

  @override
  String get accounts_manageAccountsTitle => 'Manage Accounts';

  @override
  String get accounts_noAccountsAddedYet => 'No accounts added yet';

  @override
  String get accounts_addAccountLabel => 'Add Account';

  @override
  String get accounts_deleteAccountTitle => 'Delete Account';

  @override
  String accounts_deleteAccountMessage(Object accountName) {
    return 'Are you sure you want to delete \"$accountName\"?';
  }

  @override
  String get accounts_archiveAccountTitle => 'Archive Account';

  @override
  String accounts_archiveAccountMessage(Object accountName) {
    return 'Are you sure you want to archive \"$accountName\"?';
  }

  @override
  String get accounts_cancelLabel => 'Cancel';

  @override
  String get accounts_archiveLabel => 'Archive';

  @override
  String accounts_accountArchivedMessage(Object accountName) {
    return '\"$accountName\" archived';
  }

  @override
  String get accounts_atLeastOneAccountRequired =>
      'At least 1 account required to continue';

  @override
  String get transaction_tripLabel => 'TRIP';

  @override
  String get transaction_tripPartOfMessage =>
      'This transaction is part of below trip(s)';

  @override
  String get sms_autoAddTooltip => 'Auto Add';

  @override
  String get sms_clearAllTooltip => 'Clear All';

  @override
  String get sms_importedFromSmsDescription => 'Auto-imported';

  @override
  String get sms_selectAtLeastOneMessage =>
      'Please select at least one transaction';

  @override
  String get dashboard_allTimeLabel => 'All Time';

  @override
  String get transaction_editTransactionTitle => 'Edit Transaction';

  @override
  String get transaction_addExpenseTitle => 'Add Expense';

  @override
  String get transaction_addIncomeTitle => 'Add Income';

  @override
  String get transaction_accountRequired => 'Account is required';

  @override
  String get transaction_categoryRequired => 'Category is required';

  @override
  String get transaction_dateLabel => 'Date';

  @override
  String get transaction_addNoteHint => 'Add a note';

  @override
  String get transaction_enterValidAmountError =>
      'Please enter a valid amount.';

  @override
  String get sms_noPendingTransactions => 'No pending transactions';

  @override
  String get sms_approveLabel => 'Approve';

  @override
  String get sms_approveTransactionTitle => 'Approve Transaction';

  @override
  String get onboard_SmartSmsTracking => 'Smart SMS Tracking';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'Automatically detect and import transactions from your bank SMS messages.';

  @override
  String get onboard_InsightsAndAnalytics => 'Insights & Analytics';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'Understand your spending habits with detailed charts, trends, and smart insights.';

  @override
  String get onboard_SecureAndPrivate => 'Secure & Private';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'Your data stays on your device. No cloud, no tracking — just encrypted local storage.';

  @override
  String get onboard_SmartAutoTracking => 'Smart Auto Tracking';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Automatically detect and import transactions from your bank notifications.';

  @override
  String get nav_activity => 'Activity';

  @override
  String get nav_manage => 'Manage';

  @override
  String get nav_insights => 'Insights';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_next => 'Next';

  @override
  String get common_back => 'Back';

  @override
  String get common_undo => 'Undo';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_add => 'Add';

  @override
  String get common_done => 'Done';

  @override
  String get common_close => 'Close';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_archive => 'Archive';

  @override
  String get common_create => 'Create';

  @override
  String get common_update => 'Update';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_search => 'Search';

  @override
  String get common_filter => 'Filter';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_apply => 'Apply';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_noData => 'No data';

  @override
  String get common_error => 'Something went wrong';

  @override
  String get common_required => 'Required';

  @override
  String get title_budgets => 'Budgets';

  @override
  String get title_goals => 'Goals';

  @override
  String get title_bills => 'Bills';

  @override
  String get title_groups => 'Groups';

  @override
  String get title_trips => 'Trips';

  @override
  String get title_shared => 'Shared';

  @override
  String get title_achievements => 'Achievements';

  @override
  String get title_notifications => 'Notifications';

  @override
  String get title_appearance => 'Appearance';

  @override
  String get title_currency => 'Currency';

  @override
  String get title_security => 'Security';

  @override
  String get title_about => 'About';

  @override
  String get title_analytics => 'Analytics';

  @override
  String get title_netWorth => 'Net Worth';

  @override
  String get title_financialHealth => 'Financial Health';

  @override
  String get title_spendingPersonality => 'Spending Personality';

  @override
  String get title_monthlyRecap => 'Monthly Recap';

  @override
  String get title_compareMonths => 'Compare Months';

  @override
  String get title_smsImport => 'SMS Import';

  @override
  String get title_backupShare => 'Backup & Share';

  @override
  String get title_exchangeRates => 'Exchange Rates';

  @override
  String get title_recurringTransactions => 'Recurring Transactions';

  @override
  String get title_billControlCenter => 'Bill Control Center';

  @override
  String get title_plugins => 'Plugins';

  @override
  String get title_editCategory => 'Edit Category';

  @override
  String get title_allCategories => 'All Categories';

  @override
  String get title_exportOptions => 'Export Options';

  @override
  String get title_dashboardLayout => 'Dashboard Layout';

  @override
  String get section_activeMoney => 'Active Money';

  @override
  String get section_planning => 'Planning';

  @override
  String get section_insights => 'Insights';

  @override
  String get section_coreSettings => 'Core Settings';

  @override
  String get section_appData => 'App & Data';

  @override
  String get section_appearance => 'Appearance';

  @override
  String get section_advanced => 'Advanced';

  @override
  String get section_supportLegal => 'Support & Legal';

  @override
  String get section_active => 'Active';

  @override
  String get section_ongoing => 'Ongoing';

  @override
  String get section_archive => 'Archive';

  @override
  String get label_income => 'Income';

  @override
  String get label_expense => 'Expense';

  @override
  String get label_balance => 'Balance';

  @override
  String get label_savings => 'Savings';

  @override
  String get label_total => 'Total';

  @override
  String get label_amount => 'Amount';

  @override
  String get label_date => 'Date';

  @override
  String get label_category => 'Category';

  @override
  String get label_account => 'Account';

  @override
  String get label_description => 'Description';

  @override
  String get label_type => 'Type';

  @override
  String get label_transfer => 'Transfer';

  @override
  String get label_from => 'From';

  @override
  String get label_to => 'To';

  @override
  String get label_all => 'All';

  @override
  String get label_today => 'Today';

  @override
  String get label_yesterday => 'Yesterday';

  @override
  String get label_thisWeek => 'This Week';

  @override
  String get label_thisMonth => 'This Month';

  @override
  String get label_thisYear => 'This Year';

  @override
  String get label_custom => 'Custom';

  @override
  String get label_daily => 'Daily';

  @override
  String get label_weekly => 'Weekly';

  @override
  String get label_monthly => 'Monthly';

  @override
  String get label_yearly => 'Yearly';

  @override
  String get label_none => 'None';

  @override
  String get label_frequency => 'Frequency';

  @override
  String get label_repeatEvery => 'Repeat every';

  @override
  String get label_days => 'days';

  @override
  String get label_weeks => 'weeks';

  @override
  String get label_months => 'months';

  @override
  String get label_years => 'years';

  @override
  String get trip_expenses => 'Expenses';

  @override
  String get trip_settlements => 'Settlements';

  @override
  String get trip_balances => 'Balances';

  @override
  String get trip_report => 'Report';

  @override
  String get trip_createTrip => 'Create Trip';

  @override
  String get trip_createGroup => 'Create Shared Group';

  @override
  String get trip_editTrip => 'Edit Trip';

  @override
  String get trip_editGroup => 'Edit Group';

  @override
  String get trip_archiveTrip => 'Archive Trip';

  @override
  String get trip_archiveGroup => 'Archive Group';

  @override
  String get trip_allSettled => 'All settled up!';

  @override
  String get trip_archiveToSettle => 'Archive to settle up';

  @override
  String get trip_trackTravel => 'Track travel expenses with dates & budget';

  @override
  String get trip_splitBills => 'Split bills with friends';

  @override
  String get trip_live => 'Live';

  @override
  String get budget_spendingLimits => 'Spending limits';

  @override
  String get budget_savingsProgress => 'Savings progress';

  @override
  String get budget_upcomingRecurring => 'Upcoming & recurring';

  @override
  String get budget_tripsAndSplits => 'Trips & splits';

  @override
  String import_importing(int count) {
    return 'Importing $count transactions...';
  }

  @override
  String get import_dontClose => 'Please don\'t close the app';

  @override
  String get import_complete => 'Import Complete!';

  @override
  String get import_failed => 'Import Failed';

  @override
  String get import_imported => 'Imported';

  @override
  String get import_duplicatesSkipped => 'Duplicates skipped';

  @override
  String get import_errorsSkipped => 'Errors/skipped';

  @override
  String get import_categoriesCreated => 'Categories created';

  @override
  String get import_previewImport => 'Preview Import';

  @override
  String get recap_yourMonthAtGlance => 'Your month at a glance';

  @override
  String get recap_trackProgressOverTime => 'Track progress over time';

  @override
  String recap_transactions(int count) {
    return '$count transactions';
  }

  @override
  String get recap_downloadPdf => 'Download PDF';

  @override
  String get comparison_current => 'Current';

  @override
  String comparison_byDay(int day) {
    return 'By day $day';
  }

  @override
  String get comparison_topCategories => 'Top Categories';

  @override
  String get comparison_categoryImpact => 'CATEGORY IMPACT';

  @override
  String get comparison_dailySpendingPace => 'Daily Spending Pace';

  @override
  String comparison_projected(String amount) {
    return 'Projected: $amount this month';
  }

  @override
  String get utility_customizeUtilities => 'Customize Utilities';

  @override
  String get utility_addUtilities => 'Add Utilities';

  @override
  String get utility_analyticsSubtitle => 'Health score, trends & forecasts';

  @override
  String get utility_taxSubtitle => 'Estimate your income tax';

  @override
  String get profile_accounts => 'Accounts';

  @override
  String get profile_manageAccounts => 'Manage your accounts';

  @override
  String get profile_categories => 'Categories';

  @override
  String get profile_manageCategories => 'Manage your categories';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_notifications => 'Notifications';

  @override
  String get profile_dailyWeeklySummaries => 'Daily & weekly summaries';

  @override
  String get profile_autoImport => 'Auto Import';

  @override
  String get profile_autoImportDesc => 'Auto-import from bank notifications';

  @override
  String get profile_importExport => 'Import & Export';

  @override
  String get profile_importExportDesc => 'Excel import & export';

  @override
  String get profile_backupRestore => 'Backup & Restore';

  @override
  String get profile_manageData => 'Manage your data';

  @override
  String get profile_themeDisplay => 'Theme, tone & display';

  @override
  String get profile_customizeWidgets => 'Customize widgets & cards';

  @override
  String get profile_manageExtensions => 'Manage extensions';

  @override
  String get profile_helpSupport => 'Help & Support';

  @override
  String get profile_faqs => 'FAQs and feature guides';

  @override
  String get profile_aboutApp => 'About App';

  @override
  String get profile_versionInfo => 'Version & Info';

  @override
  String get profile_pinFingerprint => 'PIN or Fingerprint';

  @override
  String get profile_upgradePro => 'Upgrade to Pro';

  @override
  String get profile_unlimitedFeatures =>
      'Unlimited accounts, analytics & more';

  @override
  String get profile_freeTier => 'Free Tier';

  @override
  String get profile_fullAccess => 'Full Access';

  @override
  String get profile_proActive => 'Pro Active';

  @override
  String get profile_yourAchievements => 'Your Achievements';

  @override
  String get profile_bestStreak => 'Best Streak';

  @override
  String get trips_active => 'ACTIVE';

  @override
  String get trips_live => 'Live';

  @override
  String get trips_allSettled => 'All settled';

  @override
  String get tone_friendly_txnAdded =>
      'Done! Transaction saved ✨|Got it! All logged 👍|Saved! You\'re on top of it ✨|Noted! One more tracked 📝';

  @override
  String get tone_friendly_txnUpdated =>
      'Updated! Looking good 👍|Changes saved! ✓|All updated! 👌';

  @override
  String get tone_friendly_txnDeleted =>
      'Gone! Transaction removed 🗑️|Deleted! One less to track|Removed! Clean slate 🗑️';

  @override
  String get tone_friendly_txnFailed => 'Hmm, couldn\'t save that. Try again?';

  @override
  String get tone_friendly_enterAmount => 'How much was it? Enter an amount';

  @override
  String get tone_friendly_pickAccount => 'Which account? Pick one to continue';

  @override
  String get tone_friendly_pickCategory => 'What was it for? Choose a category';

  @override
  String get tone_friendly_fillAllFields =>
      'Almost there — fill in all the fields';

  @override
  String get tone_friendly_invalidAmount =>
      'That doesn\'t look right — enter a valid amount';

  @override
  String get tone_friendly_budgetCreated =>
      'Budget set! Let\'s stay on track 💪|Budget locked in! You\'re planning ahead 💪|Nice! Budget is ready to roll 📊';

  @override
  String get tone_friendly_budgetUpdated => 'Budget updated!';

  @override
  String get tone_friendly_budgetDeleted => 'Budget removed';

  @override
  String get tone_friendly_goalCreated =>
      'Goal set! You got this 🎯|New goal! Let\'s make it happen 🎯|Goal locked in! Eyes on the prize 🎯';

  @override
  String get tone_friendly_goalUpdated => 'Goal updated!';

  @override
  String get tone_friendly_goalDeleted => 'Goal removed';

  @override
  String get tone_friendly_accountCreated => 'Account added! 🏦';

  @override
  String get tone_friendly_billAdded => 'Bill tracked! I\'ll remind you 🔔';

  @override
  String get tone_friendly_billPaid =>
      'Nice, bill marked as paid! ✅|Bill done! One less to worry about ✅|Paid! That\'s a relief ✅';

  @override
  String get tone_friendly_backupSuccess =>
      'Backup done! Your data is safe 🛡️';

  @override
  String get tone_friendly_restoreSuccess => 'Restored! Welcome back 🎉';

  @override
  String get tone_friendly_noTransactions =>
      'Nothing here yet\nAdd your first transaction to get started|Empty for now\nStart tracking — it only takes a sec|No transactions yet\nYour financial journey starts with one entry';

  @override
  String get tone_friendly_noBudgets =>
      'No budgets yet\nSet one up to track your spending';

  @override
  String get tone_friendly_noGoals =>
      'No goals yet\nDream big — set your first goal!';

  @override
  String get tone_friendly_genericError => 'Something went wrong. Try again?';

  @override
  String get tone_friendly_smsImportEnabled =>
      'Auto import is on! I\'ll track your transactions 📩';

  @override
  String get tone_friendly_dashboardAllCaughtUp =>
      'You\'re all caught up! 🎉|Nothing needs your attention — nice! ✨|All good here! Enjoy your day 🎉';

  @override
  String get tone_friendly_dailySummaryEmpty =>
      'Nothing recorded yesterday — either a zero-spend win or time to catch up!|Quiet day yesterday — your wallet thanks you!|No transactions yesterday — fresh start today!';

  @override
  String tone_friendly_streakMessage(int days) {
    return '$days day streak! Keep it going! 🔥';
  }

  @override
  String tone_friendly_budgetExceededBy(String amount) {
    return 'You\'ve exceeded your budget by $amount 😬';
  }

  @override
  String get tone_professional_txnAdded =>
      'Transaction recorded.|Entry saved successfully.|Transaction logged.';

  @override
  String get tone_professional_txnUpdated =>
      'Transaction updated.|Changes applied.|Record updated successfully.';

  @override
  String get tone_professional_txnDeleted =>
      'Transaction deleted.|Record removed.|Entry deleted successfully.';

  @override
  String get tone_professional_txnFailed =>
      'Failed to save transaction. Please retry.';

  @override
  String get tone_professional_enterAmount => 'Please enter a valid amount.';

  @override
  String get tone_professional_pickAccount => 'Please select an account.';

  @override
  String get tone_professional_pickCategory => 'Please select a category.';

  @override
  String get tone_professional_fillAllFields =>
      'All required fields must be completed.';

  @override
  String get tone_professional_invalidAmount => 'Invalid amount entered.';

  @override
  String get tone_professional_budgetCreated =>
      'Budget created.|Budget configured successfully.|New budget is active.';

  @override
  String get tone_professional_budgetUpdated => 'Budget updated.';

  @override
  String get tone_professional_budgetDeleted => 'Budget deleted.';

  @override
  String get tone_professional_goalCreated =>
      'Goal created.|Savings goal configured.|New goal is active.';

  @override
  String get tone_professional_goalUpdated => 'Goal updated.';

  @override
  String get tone_professional_goalDeleted => 'Goal deleted.';

  @override
  String get tone_professional_accountCreated => 'Account added.';

  @override
  String get tone_professional_billAdded =>
      'Bill added. Reminders will be sent.';

  @override
  String get tone_professional_billPaid =>
      'Bill marked as paid.|Payment recorded.|Bill settled.';

  @override
  String get tone_professional_backupSuccess =>
      'Backup completed successfully.';

  @override
  String get tone_professional_restoreSuccess => 'Data restored successfully.';

  @override
  String get tone_professional_noTransactions =>
      'No transactions recorded.\nAdd your first entry.|No records found.\nBegin by adding a transaction.|Transaction history is empty.\nStart recording.';

  @override
  String get tone_professional_noBudgets => 'No budgets configured.';

  @override
  String get tone_professional_noGoals => 'No goals set.';

  @override
  String get tone_professional_genericError => 'An error occurred.';

  @override
  String get tone_professional_smsImportEnabled => 'Auto-import enabled.';

  @override
  String get tone_professional_dashboardAllCaughtUp =>
      'All items are up to date.|No pending actions.|Everything is current.';

  @override
  String get tone_professional_dailySummaryEmpty =>
      'No transactions recorded yesterday.|Yesterday had no recorded activity.|No entries for the previous day.';

  @override
  String tone_professional_streakMessage(int days) {
    return '$days consecutive days of tracking.';
  }

  @override
  String tone_professional_budgetExceededBy(String amount) {
    return 'Budget exceeded by $amount.';
  }

  @override
  String get tone_motivational_txnAdded =>
      'Great move! Transaction saved! 💪|Logged! You\'re on a roll 💪|Another one tracked! Keep the momentum! ✨|Saved! Every entry is a step forward! 🚀';

  @override
  String get tone_motivational_txnUpdated =>
      'Nice update! Staying sharp! ✨|Updated! Precision matters! ✨|Changes saved! You\'re on it! 👍';

  @override
  String get tone_motivational_txnDeleted =>
      'Cleared out! One less to worry about|Removed! Keeping things clean! 💪|Gone! Focus on what matters';

  @override
  String get tone_motivational_txnFailed =>
      'Didn\'t go through — give it another shot!';

  @override
  String get tone_motivational_enterAmount =>
      'Every rupee counts — enter the amount!';

  @override
  String get tone_motivational_pickAccount =>
      'Pick an account to keep things organized!';

  @override
  String get tone_motivational_pickCategory =>
      'Categorize it — you\'ll thank yourself later!';

  @override
  String get tone_motivational_fillAllFields =>
      'Almost there! Fill in everything to continue';

  @override
  String get tone_motivational_invalidAmount =>
      'That amount doesn\'t look right — try again!';

  @override
  String get tone_motivational_budgetCreated =>
      'Smart move! Budget is set! 💪|Budget locked in! You\'re taking control! 💪|That\'s discipline! Budget ready! 📊';

  @override
  String get tone_motivational_budgetUpdated =>
      'Budget adjusted — staying flexible!';

  @override
  String get tone_motivational_budgetDeleted => 'Budget removed';

  @override
  String get tone_motivational_goalCreated =>
      'Love the ambition! Goal set! 🎯|Big dreams start here! Goal locked in! 🎯|That\'s the spirit! New goal ready! 🚀';

  @override
  String get tone_motivational_goalUpdated => 'Goal refined — keep pushing!';

  @override
  String get tone_motivational_goalDeleted =>
      'Goal removed — new priorities, new plans';

  @override
  String get tone_motivational_accountCreated =>
      'Account added! You\'re getting organized! 🏦';

  @override
  String get tone_motivational_billAdded =>
      'Bill tracked! You\'re staying ahead! 🔔';

  @override
  String get tone_motivational_billPaid =>
      'Bill paid! One less thing to worry about! ✅|Crushed it! Bill is done! ✅|Paid and done! You\'re ahead of the game! 💪';

  @override
  String get tone_motivational_backupSuccess =>
      'Backed up! Your progress is safe! 🛡️';

  @override
  String get tone_motivational_restoreSuccess =>
      'Restored! Right back on track! 🎉';

  @override
  String get tone_motivational_noTransactions =>
      'Fresh start! 🌟\nAdd your first transaction — every journey begins with one step|Empty slate! 🌟\nYour first entry is waiting — let\'s go!|Nothing yet! 💪\nOne transaction and you\'re on your way!';

  @override
  String get tone_motivational_noBudgets =>
      'No budgets yet\nSet one up — your future self will thank you! 💪';

  @override
  String get tone_motivational_noGoals =>
      'No goals yet\nDream big — set your first goal! 🎯';

  @override
  String get tone_motivational_genericError =>
      'Something went wrong — try again!';

  @override
  String get tone_motivational_smsImportEnabled =>
      'Auto-import on! Your finances track themselves now! 📩';

  @override
  String get tone_motivational_dashboardAllCaughtUp =>
      'All caught up — you\'re ahead of the game! 🏆|Nothing pending — you\'re on top of it 💪|All clear! Keep this energy going 🏆';

  @override
  String get tone_motivational_dailySummaryEmpty =>
      'Zero spend yesterday — your wallet thanks you! ✨|Nothing spent yesterday — that\'s willpower! 💪|A no-spend day! That\'s a win! 🏆';

  @override
  String tone_motivational_streakMessage(int days) {
    return '$days day streak! Unstoppable! 🔥';
  }

  @override
  String tone_motivational_budgetExceededBy(String amount) {
    return 'Over by $amount — you can course-correct! 💪';
  }

  @override
  String get tone_calm_txnAdded => 'Noted.|Recorded.|Saved quietly.';

  @override
  String get tone_calm_txnUpdated => 'Updated.|Adjusted.|Changes saved.';

  @override
  String get tone_calm_txnDeleted => 'Released.|Removed.|Let go.';

  @override
  String get tone_calm_txnFailed => 'That didn\'t land. Try once more.';

  @override
  String get tone_calm_enterAmount => 'An amount is needed.';

  @override
  String get tone_calm_pickAccount => 'Choose where this belongs.';

  @override
  String get tone_calm_pickCategory => 'Give it a purpose.';

  @override
  String get tone_calm_fillAllFields => 'A few things are still empty.';

  @override
  String get tone_calm_invalidAmount => 'The amount needs adjusting.';

  @override
  String get tone_calm_budgetCreated =>
      'Boundary set.|Budget in place.|Limits defined.';

  @override
  String get tone_calm_budgetUpdated => 'Adjusted.';

  @override
  String get tone_calm_budgetDeleted => 'Released.';

  @override
  String get tone_calm_goalCreated =>
      'Intention set.|A new direction.|Goal planted.';

  @override
  String get tone_calm_goalUpdated => 'Refined.';

  @override
  String get tone_calm_goalDeleted => 'Released.';

  @override
  String get tone_calm_accountCreated => 'Account opened.';

  @override
  String get tone_calm_billAdded => 'Noted. You\'ll be reminded.';

  @override
  String get tone_calm_billPaid =>
      'Settled.|Paid. One less.|Done. Peace of mind.';

  @override
  String get tone_calm_backupSuccess => 'Safely stored.';

  @override
  String get tone_calm_restoreSuccess => 'Restored. Welcome back.';

  @override
  String get tone_calm_noTransactions =>
      'A clean slate.\nBegin when you\'re ready.|Nothing here yet.\nStart gently.|Empty.\nA fresh beginning awaits.';

  @override
  String get tone_calm_noBudgets =>
      'No boundaries yet.\nSet one when it feels right.';

  @override
  String get tone_calm_noGoals =>
      'No intentions yet.\nSet one when you\'re ready.';

  @override
  String get tone_calm_genericError => 'Something shifted. Try again.';

  @override
  String get tone_calm_smsImportEnabled =>
      'Quietly watching your transactions.';

  @override
  String get tone_calm_dashboardAllCaughtUp =>
      'Everything is in order.|Nothing needs attention.|All is well.';

  @override
  String get tone_calm_dailySummaryEmpty =>
      'A quiet day. Nothing recorded.|Yesterday was still. No entries.|Nothing spent. A restful day.';

  @override
  String tone_calm_streakMessage(int days) {
    return '$days days of mindful tracking.';
  }

  @override
  String tone_calm_budgetExceededBy(String amount) {
    return 'Over by $amount. A moment to reflect.';
  }

  @override
  String get tone_friendly_insightBillsDueSoon => 'Heads up — bills incoming';

  @override
  String get tone_friendly_insightOverBudget => 'Over budget';

  @override
  String get tone_friendly_insightNearBudget => 'Getting close...';

  @override
  String get tone_friendly_insightOverspending => 'Spending outpacing income';

  @override
  String get tone_friendly_insightSpendingSpike => 'Spending spike today';

  @override
  String get tone_friendly_insightWeekendAlert => 'Weekend spending alert';

  @override
  String get tone_friendly_insightGetStarted => 'Let\'s get started! 🚀';

  @override
  String get tone_friendly_insightGetStartedMessage =>
      'Add your first transaction — it only takes a sec';

  @override
  String tone_friendly_insightBillsDueMessage(int count) {
    return '$count bill(s) due soon, don\'t forget!';
  }

  @override
  String tone_friendly_insightOverBudgetMessage(int count) {
    return '$count budget(s) went over this month — worth a look';
  }

  @override
  String tone_friendly_insightNearBudgetMessage(int count) {
    return '$count budget(s) past 80% — still time to rein it in';
  }

  @override
  String tone_friendly_insightOverspendingMessage(String amount) {
    return 'You\'re $amount over your income this month — might want to slow down';
  }

  @override
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today) {
    return 'You usually spend $avg/day. Today\'s already $today.';
  }

  @override
  String tone_friendly_insightWeekendAlertMessage(String avg, String current) {
    return 'You usually spend $avg on weekends. This one\'s already $current.';
  }

  @override
  String get tone_professional_insightBillsDueSoon => 'Upcoming bills';

  @override
  String get tone_professional_insightOverBudget => 'Budget exceeded';

  @override
  String get tone_professional_insightNearBudget => 'Approaching budget limit';

  @override
  String get tone_professional_insightOverspending => 'Expenses exceed income';

  @override
  String get tone_professional_insightSpendingSpike =>
      'Elevated spending today';

  @override
  String get tone_professional_insightWeekendAlert =>
      'Weekend spending elevated';

  @override
  String get tone_professional_insightGetStarted => 'Get started';

  @override
  String get tone_professional_insightGetStartedMessage =>
      'Record your first transaction to begin tracking.';

  @override
  String tone_professional_insightBillsDueMessage(int count) {
    return '$count bill(s) due within the next few days.';
  }

  @override
  String tone_professional_insightOverBudgetMessage(int count) {
    return '$count budget(s) exceeded this month.';
  }

  @override
  String tone_professional_insightNearBudgetMessage(int count) {
    return '$count budget(s) above 80% utilization.';
  }

  @override
  String tone_professional_insightOverspendingMessage(String amount) {
    return 'Expenditure exceeds income by $amount this month.';
  }

  @override
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Daily average: $avg. Today: $today.';
  }

  @override
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend average: $avg. Current: $current.';
  }

  @override
  String get tone_motivational_insightBillsDueSoon => 'Bills coming up! 📋';

  @override
  String get tone_motivational_insightOverBudget =>
      'Over budget — time to regroup';

  @override
  String get tone_motivational_insightNearBudget => 'Almost at the limit';

  @override
  String get tone_motivational_insightOverspending =>
      'Spending exceeding income';

  @override
  String get tone_motivational_insightSpendingSpike => 'Spending spike today';

  @override
  String get tone_motivational_insightWeekendAlert => 'Weekend spending alert';

  @override
  String get tone_motivational_insightGetStarted =>
      'Let\'s build something great! 🚀';

  @override
  String get tone_motivational_insightGetStartedMessage =>
      'Add your first transaction — you\'re one step away!';

  @override
  String tone_motivational_insightBillsDueMessage(int count) {
    return '$count bill(s) due soon — stay ahead!';
  }

  @override
  String tone_motivational_insightOverBudgetMessage(int count) {
    return '$count budget(s) exceeded — you can course-correct!';
  }

  @override
  String tone_motivational_insightNearBudgetMessage(int count) {
    return '$count budget(s) past 80% — you\'ve got this, stay mindful!';
  }

  @override
  String tone_motivational_insightOverspendingMessage(String amount) {
    return '$amount over income — small adjustments make a big difference!';
  }

  @override
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Usually $avg/day. Today\'s $today — be intentional!';
  }

  @override
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend avg: $avg. This one\'s $current — stay aware!';
  }

  @override
  String get tone_calm_insightBillsDueSoon => 'Bills approaching';

  @override
  String get tone_calm_insightOverBudget => 'Over the line';

  @override
  String get tone_calm_insightNearBudget => 'Nearing the edge';

  @override
  String get tone_calm_insightOverspending => 'Outflow exceeds inflow';

  @override
  String get tone_calm_insightSpendingSpike => 'A heavier day';

  @override
  String get tone_calm_insightWeekendAlert => 'Weekend spending';

  @override
  String get tone_calm_insightGetStarted => 'A fresh start';

  @override
  String get tone_calm_insightGetStartedMessage =>
      'Begin with your first transaction.';

  @override
  String tone_calm_insightBillsDueMessage(int count) {
    return '$count bill(s) arriving soon.';
  }

  @override
  String tone_calm_insightOverBudgetMessage(int count) {
    return '$count budget(s) exceeded. Reflect and adjust.';
  }

  @override
  String tone_calm_insightNearBudgetMessage(int count) {
    return '$count budget(s) past 80%. Mindful spending helps.';
  }

  @override
  String tone_calm_insightOverspendingMessage(String amount) {
    return '$amount more spent than earned. A moment to pause.';
  }

  @override
  String tone_calm_insightSpendingSpikeMessage(String avg, String today) {
    return 'Usually $avg/day. Today, $today.';
  }

  @override
  String tone_calm_insightWeekendAlertMessage(String avg, String current) {
    return 'Usually $avg. This weekend, $current.';
  }

  @override
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count times this month, $total total — small hits add up';
  }

  @override
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg avg on ${worst}s vs $bAvg on ${best}s — that\'s $saving you could keep';
  }

  @override
  String tone_professional_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count transactions, $total total this month.';
  }

  @override
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg avg on ${worst}s vs $bAvg on ${best}s. Potential saving: $saving.';
  }

  @override
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count times, $total — small wins add up if you cut back!';
  }

  @override
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg on ${worst}s vs $bAvg on ${best}s — $saving potential savings!';
  }

  @override
  String tone_calm_insightMoneyLeak(String category, int count, String total) {
    return '$category: $count times, $total. Small streams form rivers.';
  }

  @override
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s: $wAvg. ${best}s: $bAvg. $saving to keep.';
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
  String get notif_quietDayTitle => '📊 Quiet day yesterday';

  @override
  String get notif_heresYesterdayTitle => '📊 Here\'s yesterday';

  @override
  String get notif_weekInReviewTitle => '📅 Week in review';

  @override
  String get notif_yourWeekInReviewTitle => '📅 Your week in review';

  @override
  String get notif_niceOneTitle => '🏆 Nice one!';

  @override
  String notif_streakDaysTitle(int days) {
    return '🔥 $days days straight!';
  }

  @override
  String notif_levelUpTitle(int level) {
    return '🎉 Level $level!';
  }

  @override
  String notif_budgetsOverLimitTitle(int count) {
    return '🚨 $count budget(s) over limit';
  }

  @override
  String notif_budgetsGettingTightTitle(int count) {
    return '⚠️ $count budget(s) getting tight';
  }

  @override
  String notif_billDueTitle(String name, String label) {
    return '📅 $name is due $label';
  }

  @override
  String get notif_fundsGettingLowTitle => '📉 Funds getting low';

  @override
  String notif_categoryCreepingUpTitle(String category) {
    return '💡 $category is creeping up';
  }

  @override
  String get notif_bigDayTitle => '📈 Whoa, big day';

  @override
  String notif_smsFoundTitle(int count) {
    return '📱 $count SMS transactions found';
  }

  @override
  String get notif_smallSpendsTitle => '💧 Small spends adding up';

  @override
  String get notif_missYouTitle => '👋 We miss you';

  @override
  String notif_daysUntrackedTitle(int days) {
    return '📊 $days days untracked';
  }

  @override
  String notif_streakEndedTitle(int days) {
    return '💔 $days-day streak ended';
  }

  @override
  String get notif_fewDaysUntrackedTitle => '📊 A few days untracked';

  @override
  String notif_budgetExceededBody(String name) {
    return '$name is over budget — time to review';
  }

  @override
  String notif_budgetExceededBodyMulti(String names) {
    return '$names are over budget';
  }

  @override
  String notif_budgetWarningBody(String name) {
    return '$name is nearing the limit';
  }

  @override
  String notif_budgetWarningBodyMulti(String names) {
    return '$names are nearing their limits';
  }

  @override
  String notif_budgetWarningPctBody(String name, String pct) {
    return '$name: $pct% used';
  }

  @override
  String notif_billPaidAutoTitle(String name) {
    return '✅ $name — auto-matched';
  }

  @override
  String notif_billPaidRecordedTitle(String name) {
    return '✅ $name — recorded';
  }

  @override
  String get notif_smsLoggedTitle => '✅ Transaction logged';

  @override
  String get notif_smsNeedsReviewTitle => '👀 Needs your review';

  @override
  String notif_smsLoggedBody(String amount, String sender) {
    return '$amount from $sender — auto-saved';
  }

  @override
  String notif_smsLoggedBodyNoAmount(String sender) {
    return 'From $sender — auto-saved';
  }

  @override
  String notif_smsNeedsReviewBody(String sender) {
    return 'Transaction from $sender — tap to review';
  }

  @override
  String get notif_smsGotItTitle => '✅ Got it!';

  @override
  String get notif_smsAllCaughtUpTitle => '✅ All caught up!';

  @override
  String get notif_smsAlmostThereTitle => '📋 Almost there!';

  @override
  String get notif_smsNeedHelpTitle => '👋 Hey, need your help!';

  @override
  String notif_streakOnLineTitle(int days) {
    return '🔥 $days-day streak on the line!';
  }

  @override
  String get notif_quickActionTitle => '⚡ 5 seconds is all it takes';

  @override
  String get notif_dailyReminderTitle => '📊 Your day in numbers';

  @override
  String get notif_dailyReminderBody =>
      'Here\'s how yesterday went — take a quick look';

  @override
  String get notif_weeklyReminderTitle => '📅 Your week wrapped up';

  @override
  String get notif_weeklyReminderBody =>
      'Let\'s see how the week went — tap to check';

  @override
  String get notif_goalStatusTitle => '🎯 Monthly Goal Status';

  @override
  String notif_goalStatusBody(int count, String name, String pct) {
    return 'You have $count active goals. $name is $pct% complete!';
  }

  @override
  String notif_streakCountingTitle(int days) {
    return '🔥 $days days and counting!';
  }

  @override
  String notif_achievementBody(String title, int xp) {
    return '$title — that\'s +$xp XP for you';
  }

  @override
  String get notif_levelUpBody => 'You just leveled up — keep going!';

  @override
  String get notif_streakMilestoneBody =>
      'That\'s dedication — your streak is on fire';

  @override
  String get notif_weeklyZeroBody =>
      'Zero expenses this week — that\'s impressive 💪';

  @override
  String get insight_moneyLeakTitle => 'Quiet money leak 💧';

  @override
  String insight_bestDayTitle(String day) {
    return '${day}s cost you the most';
  }

  @override
  String get bills_howBillsWorkTitle => 'How Bills Work';

  @override
  String get bills_howBillsWorkDesc =>
      'Track recurring bills like rent, subscriptions, and utilities. Get reminders before due dates and mark bills as paid.';

  @override
  String get bills_gotIt => 'Got it';

  @override
  String get bills_addBill => 'Add Bill';

  @override
  String get bills_markAsPaid => 'Mark as Paid';

  @override
  String get bills_deleteBill => 'Delete Bill';

  @override
  String get bills_addNewBill => 'Add New Bill';

  @override
  String get bills_billName => 'Bill Name';

  @override
  String get bills_amount => 'Amount';

  @override
  String get bills_frequency => 'Frequency';

  @override
  String get bills_monthly => 'Monthly';

  @override
  String get bills_quarterly => 'Quarterly';

  @override
  String get bills_yearly => 'Yearly';

  @override
  String get bills_dueDate => 'Due Date';

  @override
  String get goal_deleteGoalTitle => 'Delete Goal?';

  @override
  String get goal_editGoal => 'Edit Goal';

  @override
  String get goal_deleteGoal => 'Delete Goal';

  @override
  String get goal_saved => 'Saved';

  @override
  String get goal_target => 'Target';

  @override
  String get goal_quickDeposit => 'Quick Deposit';

  @override
  String get goal_targetDate => 'Target Date';

  @override
  String get goal_milestones => 'Milestones';

  @override
  String get goal_recentActivity => 'Recent Activity';

  @override
  String get goal_addToGoal => 'Add to Goal';

  @override
  String get goal_goalReached => 'Goal Reached!';

  @override
  String get goal_whatsThisAbout => 'What\'s this goal about?';

  @override
  String get goal_icon => 'Icon';

  @override
  String get goal_color => 'Color';

  @override
  String get dashboard_enableCards => 'Enable Cards';

  @override
  String get recurring_fixedExpenses => 'Fixed Expenses';

  @override
  String get goal_freePlanLimit =>
      'Free plan allows up to 2 goals. Upgrade to Pro for unlimited.';

  @override
  String get goal_editGoalTitle => 'Edit Goal';

  @override
  String get goal_newGoalTitle => 'New Goal';

  @override
  String get goal_yourGoal => 'Your Goal';

  @override
  String get goal_appearance => 'Appearance';

  @override
  String get goal_goalName => 'Goal Name';

  @override
  String get goal_giveGoalName => 'Give your goal a name';

  @override
  String get goal_targetAmount => 'Target Amount';

  @override
  String get goal_enterValidTarget => 'Enter a valid target amount';

  @override
  String get goal_alreadySaved => 'Already Saved';

  @override
  String get goal_targetDateLabel => 'Target Date';

  @override
  String get goal_setTargetDate => 'Set a target date (optional)';

  @override
  String get goal_smartInsight => 'Smart Insight';

  @override
  String get goal_onTrack => 'On Track';

  @override
  String get goal_onTrackDesc => 'This goal is very achievable 👍';

  @override
  String get goal_needsEffort => 'Needs Effort';

  @override
  String get goal_needsEffortDesc => 'Needs a bit more saving discipline';

  @override
  String get goal_ambitious => 'Ambitious';

  @override
  String get goal_ambitiousDesc => 'Consider extending the deadline';

  @override
  String get goal_addNote => 'Add a note (optional)';

  @override
  String get goal_note => 'Note';

  @override
  String get goal_updateGoal => 'Update Goal';

  @override
  String get goal_createGoal => 'Create Goal';

  @override
  String get profile_developerMode => 'Developer Mode Activated! 🚀';

  @override
  String get profile_couldNotOpenLink => 'Could not open link';

  @override
  String get profile_about => 'About';

  @override
  String get profile_unableToCheckUpdates => 'Unable to check for updates';

  @override
  String get profile_openSourceLicenses => 'Open Source Licenses';

  @override
  String get account_totalValue => 'Total Value';

  @override
  String get account_gainLoss => 'Gain/Loss';

  @override
  String get account_holdings => 'Holdings';

  @override
  String get account_addHolding => 'Add Holding';

  @override
  String get account_addMissingTransaction => 'Add Missing Transaction';

  @override
  String get account_whatWasThisFor => 'What was this transaction for?';

  @override
  String get budget_used => 'Used';

  @override
  String get budget_selectAtLeastOneTag => 'Please select at least one tag';

  @override
  String get budget_over => 'over';

  @override
  String get budget_left => 'left';

  @override
  String get budget_breakdown => 'BREAKDOWN';

  @override
  String get budget_basicInfo => 'Basic Information';

  @override
  String get budget_duration => 'Duration';

  @override
  String get budget_budgetType => 'Budget Type';

  @override
  String get budget_selectType => 'Select Type';

  @override
  String get budget_categoryAllocation => 'Category Allocation';

  @override
  String get budget_totalBudget => 'Total Budget';

  @override
  String get budget_allocated => 'Allocated';

  @override
  String get budget_remaining => 'Remaining';

  @override
  String get budget_overBudget => 'Over Budget';

  @override
  String get budget_safeToSpend => 'Safe to spend';

  @override
  String get budget_startDate => 'Start Date';

  @override
  String get budget_endDate => 'End Date';

  @override
  String get budget_selectTags => 'Select Tags';

  @override
  String get budget_tagInfo =>
      'All expenses with selected tags will count towards this budget.';

  @override
  String get budget_noTags =>
      'No tags yet. Add tags to your transactions first.';

  @override
  String get budget_freePlanLimit =>
      'Free plan allows up to 2 budgets. Upgrade to Pro for unlimited.';

  @override
  String budget_daysRemaining(Object count) {
    return '$count days';
  }

  @override
  String get budget_delete => 'Delete';

  @override
  String get budget_emotionUnderControl => 'Spending under control 💪';

  @override
  String get budget_emotionHalfway => 'Halfway through the month ✨';

  @override
  String get budget_emotionAlmostThere => 'Getting tight, stay careful ⚠️';

  @override
  String get budget_emotionExceeded => 'Budget exceeded, time to adjust 🔴';

  @override
  String get budget_highlightLabel => 'Needs attention';

  @override
  String get budget_overBudgetSection => 'Over budget';

  @override
  String get budget_activeBudgets => 'Active budgets';

  @override
  String get budget_onTrackSection => 'On track';

  @override
  String get budget_spendingPace => 'Spending pace';

  @override
  String budget_dailyActual(Object amount) {
    return '$amount/day actual';
  }

  @override
  String budget_dailyAllowed(Object amount) {
    return '$amount/day allowed';
  }

  @override
  String get budget_stepNote0 =>
      'Give your budget a name and set how much you want to spend.';

  @override
  String get budget_stepNote1 =>
      'Choose how often this budget repeats and pick the dates.';

  @override
  String get budget_stepNote2 =>
      'Pick which categories or tags this budget should track.';

  @override
  String get budget_autoDistributed => 'auto';

  @override
  String budget_categoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String budget_tagsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String get budget_typeCategoryWise => 'Category-wise';

  @override
  String get budget_typeTagWise => 'Tag-wise';

  @override
  String get budget_typeDayWise => 'Daily';

  @override
  String get budget_typeFestival => 'Festival';

  @override
  String get budget_typeTravel => 'Travel';

  @override
  String get budget_typeDescCategoryWise =>
      'Set budgets for specific spending categories';

  @override
  String get budget_typeDescTagWise => 'Set budgets for specific tags';

  @override
  String get budget_typeDescDayWise => 'Set a daily spending limit';

  @override
  String get budget_typeDescFestival =>
      'Budget for festivals and special events';

  @override
  String get budget_typeDescTravel => 'Budget for travel expenses';

  @override
  String get budget_reviewTitle => 'Review & Save';

  @override
  String get budget_selectCategories => 'Select Categories';

  @override
  String get budget_noActiveTrip =>
      'No active trip. Start a trip first to use travel budget.';

  @override
  String get budget_stepNote3 =>
      'Review everything before saving. Tap any section to edit.';

  @override
  String budget_categoryDeleteWarning(Object count) {
    return 'This category is used in $count budget(s). Deleting it will affect budget tracking.';
  }

  @override
  String get budget_invalidCategories =>
      'Some categories were deleted. Edit this budget to fix.';

  @override
  String budget_pastBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'budgets',
      one: 'budget',
    );
    return '$count past $_temp0';
  }

  @override
  String get category_categoryName => 'Category Name';

  @override
  String get category_keywords => 'Keywords (comma-separated)';

  @override
  String get category_noneTopLevel => 'None (Top-level)';

  @override
  String get common_searchCurrency => 'Search currency...';

  @override
  String get common_selectCategory => 'Select Category';

  @override
  String get common_noDescription => 'No description';

  @override
  String get common_errors => 'Errors';

  @override
  String get dashboard_enableCardsDesc =>
      'Enable dashboard cards to see your financial overview';

  @override
  String get dashboard_customizeDashboard => 'Customize Dashboard';

  @override
  String get dashboard_newToApp => 'New to Mudra Manager?';

  @override
  String get dashboard_tapToExploreHelp => 'Tap to explore the help guide';

  @override
  String get dashboard_tapToReviewTxn => 'Tap to review transactions';

  @override
  String get dashboard_autoImportPaused => 'Auto Import Paused';

  @override
  String get dashboard_enable => 'Enable';

  @override
  String get dashboard_enableAutoImport => 'Enable Auto Import';

  @override
  String get dashboard_autoTrackDesc =>
      'Auto-track transactions from bank notifications';

  @override
  String get profile_awesomeUser => 'Awesome User';

  @override
  String get profile_logout => 'Logout';

  @override
  String get profile_proActiveLabel => 'Pro Active';

  @override
  String get profile_freeTierLabel => 'Free Tier';

  @override
  String get profile_fullAccessLabel => 'Full Access';

  @override
  String get profile_upgradeToProLabel => 'Upgrade to Pro';

  @override
  String get profile_fullAccessEnjoy => 'Full access — enjoy all features!';

  @override
  String profile_fullAccessDaysRemaining(int days) {
    return 'Full access — $days days remaining';
  }

  @override
  String profile_fullAccessEndsIn(int days) {
    return 'Full access ends in $days days';
  }

  @override
  String get profile_trialEnded => 'Trial ended — upgrade to keep all features';

  @override
  String get profile_unlimitedDesc => 'Unlimited accounts, analytics & more';

  @override
  String get profile_expiredRenew => 'Expired — tap to renew';

  @override
  String get profile_expiresToday => 'Expires today';

  @override
  String get profile_renewsTomorrow => 'Renews tomorrow';

  @override
  String profile_renewsInDays(int days) {
    return 'Renews in $days days';
  }

  @override
  String get profile_activeSubscription => 'Active subscription';

  @override
  String get profile_unknown => 'Unknown';

  @override
  String get profile_accountsLabel => 'Accounts';

  @override
  String get profile_categoriesLabel => 'Categories';

  @override
  String get profile_budgetsLabel => 'Budgets';

  @override
  String get profile_bestStreakLabel => 'Best Streak';

  @override
  String get profile_yourAchievementsLabel => 'Your Achievements';

  @override
  String get profile_aboutMudra => 'About Mudra Manager';

  @override
  String get profile_aboutMudraDesc =>
      'Your personal finance companion. Track expenses, manage budgets, and gain insights into your spending habits.';

  @override
  String get txnList_searchHint => 'Search transactions...';

  @override
  String get txnList_category => 'Category';

  @override
  String get txnList_dateRange => 'Date Range';

  @override
  String get txnList_tag => 'Tag';

  @override
  String get txnList_allTransactions => 'All Transactions';

  @override
  String get txnList_tapStartEnd => 'Tap start and end date';

  @override
  String get txnList_scrollToLoad => 'Scroll to load more';

  @override
  String get txnList_month => 'Month';

  @override
  String get txnList_previousMonth => 'Previous Month';

  @override
  String get txnList_resetToCurrentMonth => 'Reset to Current Month';

  @override
  String get txnList_selectMonth => 'Select Month';

  @override
  String get txnList_nextMonth => 'Next Month';

  @override
  String get txnList_monthView => 'Month View';

  @override
  String get txnList_subscriptionTagRemoved => 'Subscription tag removed';

  @override
  String get txnList_filterByTag => 'Filter by Tag';

  @override
  String get txnList_noTagsYet =>
      'No tags yet. Add tags to your transactions first.';

  @override
  String get txnList_clear => 'Clear';

  @override
  String get txnList_filterOptions => 'Filter Options';

  @override
  String get txnList_transactionType => 'Transaction Type';

  @override
  String get txnList_allCategories => 'All Categories';

  @override
  String get txnList_selectDateRange => 'Select Date Range';

  @override
  String get txnList_clearDateRange => 'Clear Date Range';

  @override
  String get txnList_convertToTransfer => 'Convert to Transfer';

  @override
  String get txnList_convertToTransferDesc =>
      'This was actually a transfer between your accounts';

  @override
  String get txnList_convertedToTransfer => 'Converted to transfer';

  @override
  String get stats_today => 'Today';

  @override
  String get stats_week => 'Week';

  @override
  String get stats_month => 'Month';

  @override
  String get stats_year => 'Year';

  @override
  String get stats_custom => 'Custom';

  @override
  String get stats_unableToLoad => 'Unable to load statistics';

  @override
  String get stats_overview => 'Overview';

  @override
  String get stats_trends => 'Trends';

  @override
  String get stats_spendingByDay => 'Spending by Day';

  @override
  String get stats_insights => 'Insights';

  @override
  String get stats_nextMonthForecast => 'Next Month Forecast';

  @override
  String get stats_topSpending => 'Top Spending';

  @override
  String get stats_12MonthTrend => '12-Month Trend';

  @override
  String stats_trendUp(Object category, Object percent) {
    return '$category is trending up — $percent% of total spending';
  }

  @override
  String stats_trendDown(Object category) {
    return '$category is trending down this month 📉';
  }

  @override
  String stats_topCategory(Object category, Object percent) {
    return '$category is your top category — $percent% of spending';
  }

  @override
  String stats_weekendPeak(Object day) {
    return 'You spend more on weekends — $day is your peak day';
  }

  @override
  String stats_weekdayPeak(Object day) {
    return 'Weekdays cost more — $day is your biggest day';
  }

  @override
  String stats_peakAndQuiet(Object peak, Object quiet) {
    return '$peak is your peak spending day, $quiet is the quietest';
  }

  @override
  String get stats_categoryTrends => 'Category Trends';

  @override
  String get stats_spendingByTag => 'Spending by Tag';

  @override
  String get stats_netWorth => 'Net Worth';

  @override
  String get stats_savings => 'Savings';

  @override
  String get stats_categoryImpact => 'CATEGORY IMPACT';

  @override
  String get stats_income => 'Income';

  @override
  String get stats_expense => 'Expense';

  @override
  String get stats_net => 'Net';

  @override
  String get stats_dailySpendingPace => 'Daily Spending Pace';

  @override
  String get stats_topCategories => 'Top Categories';

  @override
  String stats_projectedThisMonth(Object amount) {
    return 'Projected: $amount this month';
  }

  @override
  String stats_byDay(Object day, Object amount, Object month) {
    return 'By day $day: $amount in $month';
  }

  @override
  String get stats_steadyHeadline => 'Steady as she goes';

  @override
  String get stats_steadyDetail =>
      'Your spending is consistent — that\'s discipline.';

  @override
  String get stats_doingGreatHeadline => 'You\'re doing great 🌟';

  @override
  String get stats_spendingUpHeadline => 'Heads up — spending is up';

  @override
  String get stats_downloadPdf => 'Download PDF';

  @override
  String get stats_generating => 'Generating...';

  @override
  String get recap_belowAvg => 'Below avg';

  @override
  String get recap_aboveAvg => 'Above avg';

  @override
  String get recap_recurring => 'Recurring';

  @override
  String get recap_oneTime => 'One-time';

  @override
  String get recap_recapTitle => 'Recap';

  @override
  String get notifSettings_dailySummary => 'Daily Summary';

  @override
  String get notifSettings_weeklySummary => 'Weekly Summary';

  @override
  String get notifSettings_comeBackNudges => 'Come-back Nudges';

  @override
  String get notifSettings_streakReminder => 'Streak Reminder';

  @override
  String get notifSettings_smartAlerts => 'Smart Alerts';

  @override
  String get notifSettings_selectDay => 'Select Day';

  @override
  String get notifSettings_summariesDesc =>
      'Summaries show spending, income, top category & balance';

  @override
  String get notifSettings_reminderTime => 'Reminder Time';

  @override
  String get notifSettings_sendTestNotif => 'Send Test Notification';

  @override
  String get notifSettings_testNotifSent => 'Test notification sent';

  @override
  String get notifSettings_dailyNudgeStreak =>
      'Daily nudge to keep your streak';

  @override
  String get notifSettings_summaryDay => 'Summary Day';

  @override
  String get notifSettings_gentleReminders =>
      'Gentle reminders if you haven\'t opened the app';

  @override
  String get notifSettings_budgetWarningsDesc =>
      'Budget warnings, spending spikes, bill reminders';

  @override
  String get notifSettings_localNotifDisclaimer =>
      'Notifications are delivered locally on your device. No data is sent to any server.';

  @override
  String get smsImport_autoImport => 'Auto Import';

  @override
  String get smsImport_permissions => 'Permissions';

  @override
  String get smsImport_notifAccess => 'Notification Access';

  @override
  String get smsImport_notifAccessEnabled => 'Notification access enabled';

  @override
  String get smsImport_allowReadingNotif => 'Allow reading bank notifications';

  @override
  String get smsImport_autoDetectTxn =>
      'Auto-detect transactions from notifications';

  @override
  String get smsImport_privacyNote =>
      'Notifications are read locally on your device to detect transactions. Nothing is uploaded or shared — ever.';

  @override
  String get smsImport_tools => 'Tools';

  @override
  String get smsImport_txnActivity => 'Transaction Activity';

  @override
  String get smsImport_viewDetectedTxn => 'View all detected transactions';

  @override
  String get smsImport_clearHistory => 'Clear Processing History';

  @override
  String get smsImport_resetDetection => 'Reset detection history';

  @override
  String get smsImport_howItWorks => 'How It Works';

  @override
  String get smsImport_readsBankNotif => 'Reads bank & wallet notifications';

  @override
  String get smsImport_dataStaysOnDevice => 'All data stays on your device';

  @override
  String get smsImport_autoCreatesTxn => 'Automatically creates transactions';

  @override
  String get smsImport_personalIgnored => 'Personal notifications are ignored';

  @override
  String get smsImport_noDataSent => 'No data sent to any server';

  @override
  String get smsImport_active => 'Active';

  @override
  String get smsImport_inactive => 'Inactive';

  @override
  String get smsImport_grantAccess =>
      'Grant notification access to get started';

  @override
  String get smsImport_notAvailableIos => 'Not Available on iOS';

  @override
  String get smsImport_enableAccessFirst => 'Enable notification access first';

  @override
  String get smsImport_notifAccessRequired => 'Notification Access Required';

  @override
  String get smsImport_notifAccessDesc =>
      'Mudra Manager needs notification access to automatically detect transactions from your bank and wallet apps.';

  @override
  String get smsImport_onlyBankRead =>
      'Only bank/wallet notifications are read';

  @override
  String get smsImport_personalNeverRead => 'Personal messages are never read';

  @override
  String get smsImport_openSettings => 'Open Settings';

  @override
  String get smsImport_clearHistoryConfirm => 'Clear Processing History?';

  @override
  String get smsImport_clearHistoryWarning =>
      'Previously detected notifications will be processed again, which may create duplicate transactions.';

  @override
  String get smsImport_tapAgainSettings => 'Tap again to open system settings';

  @override
  String get upgrade_purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get upgrade_purchasePending =>
      'Purchase pending. Pro will activate once payment completes.';

  @override
  String get upgrade_welcomePro => 'Welcome to Pro!';

  @override
  String get upgrade_allFeaturesUnlocked =>
      'All features are now unlocked. Thank you for your support!';

  @override
  String get upgrade_startExploring => 'Start Exploring';

  @override
  String get upgrade_yourProFeatures => 'Your Pro features';

  @override
  String get upgrade_manageSubscription =>
      'To manage your subscription, go to Google Play Store > Subscriptions.';

  @override
  String get upgrade_everythingInPro => 'Everything in Pro';

  @override
  String get upgrade_chooseYourPlan => 'Choose your plan';

  @override
  String get upgrade_yearly => 'Yearly';

  @override
  String get upgrade_save43 => 'Save 43%';

  @override
  String get upgrade_monthly => 'Monthly';

  @override
  String get upgrade_continue => 'Continue';

  @override
  String get upgrade_restorePurchases => 'Restore purchases';

  @override
  String get upgrade_renewsToday => 'Renews today';

  @override
  String get upgrade_mudraManagerPro => 'Mudra Manager Pro';

  @override
  String get upgrade_unlockFullPower =>
      'Unlock the full power of your finances';

  @override
  String get day_monday => 'Monday';

  @override
  String get day_tuesday => 'Tuesday';

  @override
  String get day_wednesday => 'Wednesday';

  @override
  String get day_thursday => 'Thursday';

  @override
  String get day_friday => 'Friday';

  @override
  String get day_saturday => 'Saturday';

  @override
  String get day_sunday => 'Sunday';

  @override
  String get recap_income => 'Income';

  @override
  String get recap_expense => 'Expense';

  @override
  String get recap_saved => 'Saved';

  @override
  String get recap_dailySpending => 'Daily Spending';

  @override
  String get recap_spendingPace => 'Spending Pace';

  @override
  String get recap_recurringVsOneTime => 'Recurring vs One-time';

  @override
  String get recap_topCategories => 'Top Categories';

  @override
  String get recap_mostFrequent => 'Most Frequent';

  @override
  String get recap_incomeSources => 'Income Sources';

  @override
  String get recap_byAccount => 'By Account';

  @override
  String get recap_budgetHealth => 'Budget Health';

  @override
  String get recap_biggestExpenses => 'Biggest Expenses';

  @override
  String get recap_biggestIncome => 'Biggest Income';

  @override
  String get recap_generating => 'Generating...';

  @override
  String get recap_avgPerDay => 'Avg/Day';

  @override
  String get recap_weekdayAvg => 'Weekday Avg';

  @override
  String get recap_weekendAvg => 'Weekend Avg';

  @override
  String get recap_budgets => 'Budgets';

  @override
  String get recap_badges => 'Badges';

  @override
  String get recap_streak => 'Streak';

  @override
  String get recap_best => 'Best';

  @override
  String get recap_savings => 'Savings';

  @override
  String get about_developerMode => 'Developer Mode Activated!';

  @override
  String get about_couldNotOpenLink => 'Could not open link';

  @override
  String get about_title => 'About';

  @override
  String get about_privacyDesc =>
      'Everything stays on your device. No accounts, no cloud, no data collection. Your finances are yours alone.';

  @override
  String get about_legalTransparency => 'Legal & Transparency';

  @override
  String get about_privacyPolicy => 'Privacy Policy';

  @override
  String get about_privacyPolicyDesc => 'How we protect your data';

  @override
  String get about_termsOfService => 'Terms of Service';

  @override
  String get about_termsDesc => 'App usage terms and conditions';

  @override
  String get about_openSourceLicenses => 'Open Source Licenses';

  @override
  String get about_openSourceDesc => 'Third-party libraries we use';

  @override
  String get about_supportConnect => 'Support & Connect';

  @override
  String get about_checkForUpdates => 'Check for Updates';

  @override
  String get about_checkForUpdatesDesc => 'Manually check app version';

  @override
  String get about_latestVersion => 'You are on the latest version';

  @override
  String get about_unableToCheck => 'Unable to check for updates';

  @override
  String get about_officialWebsite => 'Official Website';

  @override
  String get about_visitWebsite => 'Visit mudramanager.com';

  @override
  String get about_contactSupport => 'Contact Support';

  @override
  String get about_contactSupportDesc => 'Get help or report issues';

  @override
  String get about_rateApp => 'Rate the App';

  @override
  String get about_rateAppDesc => 'Share your experience on the store';

  @override
  String get about_developerModeSection => 'Developer Mode';

  @override
  String get about_mudraManager => 'Mudra Manager';

  @override
  String get about_secureFinancial => 'Secure Financial Command';

  @override
  String get about_loadingLicenses => 'Loading licenses...';

  @override
  String get appearance_title => 'Appearance';

  @override
  String get appearance_themeMode => 'Theme Mode';

  @override
  String get appearance_display => 'Display';

  @override
  String get appearance_toneVoice => 'Tone & Voice';

  @override
  String get appearance_changesApplyInstantly =>
      'Theme and display changes apply instantly.';

  @override
  String get appearance_darkAppearance => 'Dark appearance';

  @override
  String get appearance_lightAppearance => 'Light appearance';

  @override
  String get appearance_accountStyle => 'Account Style';

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
      'Improves readability for low vision';

  @override
  String get appearance_guestMode => 'Guest Mode';

  @override
  String get appearance_guestModeOnDesc => 'Real amounts are hidden';

  @override
  String get appearance_guestModeOffDesc => 'Hide sensitive financial data';

  @override
  String get appearance_lightMode => 'Light Mode';

  @override
  String get appearance_darkMode => 'Dark Mode';

  @override
  String get appearance_systemDefault => 'System Default';

  @override
  String get analytics_financialHealthScore => 'Financial Health Score';

  @override
  String get analytics_savingsRate => 'Savings Rate';

  @override
  String get analytics_expenseRatio => 'Expense Ratio';

  @override
  String get analytics_insights => 'Insights';

  @override
  String get analytics_spendingPrediction => 'Spending Prediction';

  @override
  String get analytics_nextMonth => 'Next Month';

  @override
  String get analytics_basedOnAvg => 'Based on last 3 months average';

  @override
  String get analytics_categoryTrends => 'Category Trends';

  @override
  String get analytics_spendingByDay => 'Spending by Day';

  @override
  String get trip_notFound => 'Trip Not Found';

  @override
  String get trip_notFoundMsg => 'Trip not found';

  @override
  String get trip_tripLabel => 'Trip';

  @override
  String get trip_groupLabel => 'Group';

  @override
  String get trip_archiveTripTitle => 'Archive Trip';

  @override
  String get trip_archiveMsg =>
      'This trip will be moved to archive. All data and settlements will be preserved.';

  @override
  String get trip_archiveConfirm => 'Archive';

  @override
  String get trip_totalSpent => 'Total Spent';

  @override
  String get trip_splitExpense => 'Split Expense';

  @override
  String get trip_allPeople => 'All People';

  @override
  String get trip_allCategories => 'All Categories';

  @override
  String get trip_uncategorized => 'Uncategorized';

  @override
  String get trip_removeExpense => 'Remove Expense';

  @override
  String get trip_removeFromTrip => 'Remove this expense from the trip?';

  @override
  String get trip_removeFromGroup => 'Remove this expense from the group?';

  @override
  String get trip_removeConfirm => 'Remove';

  @override
  String get trip_unknown => 'Unknown';

  @override
  String get trip_youPaid => 'You paid';

  @override
  String get trip_noPendingSettlements =>
      'No pending settlements for this trip';

  @override
  String get trip_everyoneSquare => 'Everyone is square';

  @override
  String get trip_archiveGroupTitle => 'Archive Group';

  @override
  String get trip_archiveGroupMsg =>
      'This group will be moved to archive. All data and settlements will be preserved.';

  @override
  String get editTrip_addParticipant => 'Add Participant';

  @override
  String get editTrip_name => 'Name';

  @override
  String get editTrip_enterName => 'Enter participant name';

  @override
  String get editTrip_finalizeTrip => 'Finalize Trip';

  @override
  String get editTrip_closeGroup => 'Close Group';

  @override
  String get editTrip_finalizeMsg =>
      'This will mark the trip as ended. You cannot add expenses after this.';

  @override
  String get editTrip_closeGroupMsg =>
      'This will close the group. You cannot add expenses after this.';

  @override
  String get editTrip_finalize => 'Finalize';

  @override
  String get editTrip_close => 'Close';

  @override
  String get editTrip_groupNotFound => 'Group Not Found';

  @override
  String get editTrip_groupNotFoundMsg => 'Group not found';

  @override
  String get editTrip_editTrip => 'Edit Trip';

  @override
  String get editTrip_editGroup => 'Edit Group';

  @override
  String get editTrip_editSplitGroup => 'Edit Split Group';

  @override
  String get editTrip_createTrip => 'Create Trip';

  @override
  String get editTrip_createSplitGroup => 'Create Split Group';

  @override
  String get editTrip_travelTrip => 'Travel Trip';

  @override
  String get editTrip_splitGroup => 'Split Group';

  @override
  String get editTrip_tripDetails => 'Trip Details';

  @override
  String get editTrip_groupDetails => 'Group Details';

  @override
  String get editTrip_tripName => 'Trip Name';

  @override
  String get editTrip_groupName => 'Group Name';

  @override
  String get editTrip_descriptionOptional => 'Description (Optional)';

  @override
  String get editTrip_tripHint => 'Beach vacation with friends';

  @override
  String get editTrip_groupHint => 'Split expenses with friends';

  @override
  String get editTrip_budgetOptional => 'Budget (Optional)';

  @override
  String get editTrip_currency => 'Currency';

  @override
  String get editTrip_baseCurrencyDefault => 'Base currency (default)';

  @override
  String get editTrip_duration => 'Duration';

  @override
  String get editTrip_warningDateChange => 'Warning: Date Change';

  @override
  String get expense_notFound => 'Not Found';

  @override
  String get expense_notFoundMsg => 'Expense not found';

  @override
  String get expense_details => 'Expense Details';

  @override
  String get expense_paidBy => 'Paid by';

  @override
  String get expense_you => 'You';

  @override
  String get expense_yourShare => 'Your share';

  @override
  String get expense_noteLabel => 'Note';

  @override
  String get expense_editSplit => 'Edit Split';

  @override
  String get expense_splitType => 'Split Type';

  @override
  String get expense_equal => 'Equal';

  @override
  String get expense_custom => 'Custom';

  @override
  String get expense_participants => 'Participants';

  @override
  String get expense_autoFillRemaining => 'Auto-fill remaining';

  @override
  String get expense_deleteExpense => 'Delete Expense';

  @override
  String get expense_deleteExpenseMsg =>
      'This will adjust everyones balance. Continue?';

  @override
  String get billCenter_overdue => 'Overdue';

  @override
  String get billCenter_thisWeek => 'This Week';

  @override
  String get billCenter_thisMonth => 'This Month';

  @override
  String get billCenter_later => 'Later';

  @override
  String get billCenter_totalUpcoming => 'Total upcoming';

  @override
  String get billCenter_today => 'Today';

  @override
  String get billCenter_tomorrow => 'Tomorrow';

  @override
  String get billCenter_afterUpcoming => 'After upcoming bills';

  @override
  String get billCenter_dueToday => 'Due today';

  @override
  String get billCenter_paid => 'Paid';

  @override
  String get billCenter_pay => 'Pay';

  @override
  String get billCenter_existingTxnFound => 'Existing Transaction Found';

  @override
  String get billCenter_linkTransaction => 'Link This Transaction';

  @override
  String get billCenter_createNewEntry => 'Create New Entry';

  @override
  String get comparison_steady => 'Steady as she goes';

  @override
  String get comparison_steadyDesc =>
      'Your spending is consistent — that is discipline.';

  @override
  String get comparison_doingGreat => 'You are doing great';

  @override
  String get comparison_headsUp => 'Heads up — spending is up';

  @override
  String get reconcile_title => 'Reconcile';

  @override
  String get reconcile_info =>
      'Enter the current balance shown in your bank app or passbook. We\'ll adjust the difference automatically.';

  @override
  String get reconcile_balanceInApp => 'Balance in App';

  @override
  String get reconcile_actualBalance => 'Actual Bank Balance';

  @override
  String get reconcile_balanced => 'Balanced!';

  @override
  String get reconcile_difference => 'Difference';

  @override
  String reconcile_incomeAdjustment(String amount) {
    return 'An income adjustment of $amount will be added.';
  }

  @override
  String reconcile_expenseAdjustment(String amount) {
    return 'An expense adjustment of $amount will be added.';
  }

  @override
  String get balanceHistory_currentBalance => 'Current Balance';

  @override
  String get balanceHistory_highest => 'Highest';

  @override
  String get balanceHistory_lowest => 'Lowest';

  @override
  String get balanceHistory_average => 'Average';

  @override
  String get common_errorLoading => 'Failed to load data';

  @override
  String get balanceHistory_trend => '30-Day Trend';

  @override
  String get balanceHistory_growing => 'Your balance is growing 📈';

  @override
  String get balanceHistory_declining =>
      'Balance has dipped — let\'s recover 💪';

  @override
  String get balanceHistory_steady => 'Holding steady ⚖️';

  @override
  String get account_editTitle => 'Edit Account';

  @override
  String get account_newTitle => 'New Account';

  @override
  String get account_name => 'Account Name';

  @override
  String get account_typeLabel => 'Account Type';

  @override
  String get account_detailsLabel => 'Details';

  @override
  String get account_colorLabel => 'Color';

  @override
  String get account_currencyLabel => 'Currency';

  @override
  String get account_balance => 'Balance';

  @override
  String get account_outstanding => 'Outstanding';

  @override
  String get account_last4 => 'Last 4 digits';

  @override
  String get account_last4Helper => 'For SMS auto-matching';

  @override
  String get account_initialBalance => 'Initial balance';

  @override
  String get account_cardPaidOff => 'Enter 0 if card is paid off';

  @override
  String get account_min4 => 'At least 4 digits';

  @override
  String get account_max4 => 'Only last 4 digits';

  @override
  String get iconPicker_title => 'Pick an Icon';

  @override
  String get iconPicker_search => 'Search icons...';

  @override
  String get iconPicker_noResults => 'No icons found';

  @override
  String get colorPicker_title => 'Pick a Color';

  @override
  String get color_red => 'Red';

  @override
  String get color_pink => 'Pink';

  @override
  String get color_purple => 'Purple';

  @override
  String get color_indigo => 'Indigo';

  @override
  String get color_blue => 'Blue';

  @override
  String get color_cyan => 'Cyan';

  @override
  String get color_teal => 'Teal';

  @override
  String get color_green => 'Green';

  @override
  String get color_orange => 'Orange';

  @override
  String get color_brown => 'Brown';

  @override
  String get color_grey => 'Grey';

  @override
  String get accounts_totalBalance => 'Total Balance';

  @override
  String get accounts_accountsCount => 'accounts';

  @override
  String get accounts_archived => 'Archived';

  @override
  String get accounts_howItWorks => 'How Accounts Work';

  @override
  String get accounts_howItWorksDesc =>
      'Manage all your bank accounts, wallets, and cash in one place. Track balances and transactions across multiple accounts.';

  @override
  String get accounts_primary => 'Primary';

  @override
  String get categories_label => 'categories';

  @override
  String get categories_transactionsLabel => 'transactions';

  @override
  String categories_deleteWithTransactions(String name, int count) {
    return 'This will permanently delete \"$name\" and $count linked transactions. This action cannot be undone.';
  }

  @override
  String get categories_deleteAll => 'Delete All';

  @override
  String get categories_edit => 'Edit Category';

  @override
  String get categories_delete => 'Delete Category';

  @override
  String get categories_deleteSubtitle => 'Removes all linked transactions';

  @override
  String get category_save => 'Save';

  @override
  String get category_detailsLabel => 'Details';

  @override
  String get category_parentLabel => 'Parent Category';

  @override
  String get category_nameHint => 'Category Name';

  @override
  String get category_keywordsHint => 'Keywords (comma-separated)';

  @override
  String get category_keywordsHelper =>
      'For SMS auto-detection (e.g. swiggy, zomato)';

  @override
  String get currency_title => 'Currency';

  @override
  String get currency_baseCurrency => 'Base Currency';

  @override
  String get currency_baseDescription =>
      'All totals, budgets, and analytics use this currency.';

  @override
  String get currency_exchangeRates => 'Exchange Rates';

  @override
  String get currency_exchangeRatesDesc => 'View and edit conversion rates';

  @override
  String get currency_archivedDesc =>
      'View transactions from previous currencies';

  @override
  String exchange_unitInfo(String base) {
    return 'unit of foreign currency = X $base. Tap any rate to edit.';
  }

  @override
  String get exchange_search => 'Search currency...';

  @override
  String exchange_rateUpdated(String code) {
    return '$code rate updated';
  }

  @override
  String exchange_editRate(String code) {
    return 'Edit $code Rate';
  }

  @override
  String get exchange_rateLabel => 'Rate';

  @override
  String get exchange_invalidRate => 'Enter a valid rate';

  @override
  String get archived_transaction => 'Transaction';

  @override
  String get currency_changingCurrency => 'Changing currency...';

  @override
  String get currency_pleaseWait =>
      'Archiving transactions and updating settings';

  @override
  String get security_title => 'Security';

  @override
  String get security_unprotected => 'Unprotected';

  @override
  String get security_basic => 'Basic';

  @override
  String get security_strong => 'Strong';

  @override
  String get security_unprotectedDesc =>
      'Enable PIN or biometrics to protect your data';

  @override
  String security_protectionsActive(int count, int total) {
    return '$count of $total protections active';
  }

  @override
  String get security_authentication => 'Authentication';

  @override
  String get security_pinLock => 'PIN Lock';

  @override
  String get security_pinActive => '4-digit PIN active';

  @override
  String get security_pinSet => 'Set a 4-digit PIN';

  @override
  String get security_biometric => 'Biometric Unlock';

  @override
  String get security_biometricDesc => 'Fingerprint or Face ID';

  @override
  String get security_manage => 'Manage';

  @override
  String get security_changePin => 'Change PIN';

  @override
  String get security_changePinDesc => 'Update your 4-digit PIN';

  @override
  String get security_enablePinFirst => 'Enable PIN first';

  @override
  String get security_biometricEnabled => 'Biometric enabled';

  @override
  String get security_biometricDisabled => 'Biometric disabled';

  @override
  String get security_infoText =>
      'Your PIN is stored securely on this device — it never touches a server. Digits are randomized on entry for extra protection.';

  @override
  String notifSettings_activeCount(int count) {
    return '$count of 5 active';
  }

  @override
  String get notifSettings_summaryDesc =>
      'Summaries show spending, income, top category & balance';

  @override
  String get notifSettings_dailySummaryDesc => 'Yesterday\'s spending overview';

  @override
  String notifSettings_weeklySchedule(String day) {
    return 'Every $day at 9:00 AM';
  }

  @override
  String get smsImport_autoImporting =>
      'Transactions are being imported automatically';

  @override
  String get smsImport_enableToStart => 'Enable auto import to start tracking';

  @override
  String get smsImport_iosRestriction =>
      'Auto import is only available on Android due to iOS platform restrictions.';

  @override
  String get common_change => 'Change';

  @override
  String get goal_whatSavingFor => 'What are you saving for?';

  @override
  String get netWorth_totalLabel => 'Total Net Worth';

  @override
  String get netWorth_notEnoughData => 'Not enough data yet';

  @override
  String get netWorth_assets => 'Assets';

  @override
  String get netWorth_liabilities => 'Liabilities';

  @override
  String get netWorth_composition => 'Wealth Composition';

  @override
  String get goal_milestoneStarted => 'Started';

  @override
  String get goal_milestoneStartedDesc => 'Your journey began';

  @override
  String get goal_milestone25 => '25%';

  @override
  String get goal_milestone25Desc => 'Quarter way there';

  @override
  String get goal_milestone50 => '50%';

  @override
  String get goal_milestone50Desc => 'Halfway done!';

  @override
  String get goal_milestone75 => '75%';

  @override
  String get goal_milestone75Desc => 'Almost there';

  @override
  String get goal_milestone100 => '100%';

  @override
  String get goal_milestone100Desc => 'Goal reached! 🎉';

  @override
  String get goal_flexibleTimeline => 'Flexible timeline';

  @override
  String get goal_amount => 'Amount';

  @override
  String get goal_emotionReached => 'Goal reached! 🎉';

  @override
  String get goal_emotionProgress => 'Great progress ✨';

  @override
  String goal_emotionMoreToGo(Object amount) {
    return 'Just $amount more to go 💪';
  }

  @override
  String get goal_emotionSetTarget => 'Set your target 🎯';

  @override
  String get goal_emotionWhatSaving => 'What are you saving for?';

  @override
  String get goal_exceededTarget => 'You\'ve exceeded your target! 🎉';

  @override
  String get goal_alreadyReached => 'Goal already reached! 🎉';

  @override
  String goal_progressLeft(Object percent, Object amount) {
    return '$percent% there • $amount left';
  }

  @override
  String goal_paceDaily(Object daily, Object monthly) {
    return 'At this pace, you need $daily/day to reach your goal.\nThat\'s $monthly/month.';
  }

  @override
  String goal_daysRemaining(Object count) {
    return '$count days remaining';
  }

  @override
  String goal_daysLeft(Object count) {
    return '$count days left';
  }

  @override
  String goal_startSaving(Object amount) {
    return 'Start saving $amount';
  }

  @override
  String goal_goalsInProgress(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals in progress',
      one: '1 goal in progress',
    );
    return '$_temp0';
  }

  @override
  String get goal_completedSection => 'Completed 🎉';

  @override
  String get goal_emotionAlmost => 'Almost there 🚀';

  @override
  String get goal_emotionHalfway => 'Halfway there 💪';

  @override
  String get goal_emotionEvery => 'Every bit counts 🌱';

  @override
  String get goal_emotionHalfwayDone => 'Halfway done ✨';

  @override
  String get goal_emotionKeepPushing => 'Keep pushing 🔥';

  @override
  String get goal_emotionJustStarted => 'Just getting started 🌱';

  @override
  String get goal_closestToCompletion => 'Closest to completion';

  @override
  String goal_acrossGoals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'across $count goals',
      one: 'across 1 goal',
    );
    return '$_temp0';
  }

  @override
  String get goal_suffixSaved => 'saved';

  @override
  String get goal_suffixLeft => 'left';

  @override
  String get goal_suffixDone => 'done';

  @override
  String get goal_suffixAchieved => 'achieved';

  @override
  String get goal_suffixToGo => 'to go';

  @override
  String get goal_needsAttention => 'Needs attention ⚠️';

  @override
  String get goal_aheadOfSchedule => 'Ahead of schedule 🎯';

  @override
  String goal_monthsLeft(Object count) {
    return '$count months left';
  }

  @override
  String get goal_emotionDidIt => 'You did it! 🎉';

  @override
  String get goal_emotionSoClose => 'So close, keep going! 💪';

  @override
  String get goal_emotionMomentum => 'Building momentum 🔥';

  @override
  String get goal_emotionCatchUp => 'Let\'s catch up ⚡';

  @override
  String get goal_finishGoal => 'Finish this goal! 🚀';

  @override
  String get goal_onTrackStatus => 'On Track ✅';

  @override
  String get goal_behindPace => 'Behind pace ⚠️';

  @override
  String goal_daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get common_amount => 'Amount';

  @override
  String get accounts_edit => 'Edit Account';

  @override
  String get accounts_balanceHistory => 'Balance History';

  @override
  String get accounts_matchBank => 'Match with bank statement';

  @override
  String get accounts_viewPortfolio => 'View Portfolio';

  @override
  String get accounts_setAsPrimary => 'Set as Primary';

  @override
  String get accounts_primaryDesc => 'Default account for splits & trips';

  @override
  String get accounts_archive => 'Archive';

  @override
  String get accounts_archiveDesc => 'Hide from active accounts';

  @override
  String get accounts_unarchive => 'Unarchive';

  @override
  String get accounts_unarchiveDesc => 'Restore to active accounts';

  @override
  String get accounts_deleteDesc => 'Permanently remove account';

  @override
  String get smsActivity_title => 'Transaction Activity';

  @override
  String get smsActivity_approved => 'Approved';

  @override
  String get smsActivity_pending => 'Pending';

  @override
  String get smsActivity_rejected => 'Rejected';

  @override
  String get smsActivity_needsReview => 'Needs Review';

  @override
  String get smsActivity_duplicates => 'Duplicates';

  @override
  String get smsActivity_filterByStatus => 'Filter by Status';

  @override
  String smsActivity_transactionCount(Object count) {
    return '$count Transactions';
  }

  @override
  String smsActivity_needsAttention(Object count) {
    return '$count needs attention';
  }

  @override
  String smsActivity_resultCount(Object count) {
    return '$count results';
  }

  @override
  String get smsActivity_noActivities => 'No matching activities';

  @override
  String get smsActivity_status => 'Status';

  @override
  String get smsActivity_confidence => 'Confidence';

  @override
  String get smsActivity_account => 'Account';

  @override
  String get smsActivity_bank => 'Bank';

  @override
  String get smsActivity_type => 'Type';

  @override
  String get smsActivity_merchant => 'Merchant';

  @override
  String get smsActivity_balance => 'Balance';

  @override
  String get smsActivity_reference => 'Reference';

  @override
  String get smsActivity_duplicateLabel => 'DUPLICATE';

  @override
  String get smsActivity_transferLabel => 'TRANSFER';

  @override
  String get smsActivity_reject => 'Reject';

  @override
  String get smsActivity_approve => 'Approve';

  @override
  String get smsActivity_transfer => 'Transfer';

  @override
  String get smsActivity_addAccount => 'Add A/C';

  @override
  String get smsActivity_duplicateWarning =>
      'This may be a duplicate transaction. Review carefully before approving.';

  @override
  String smsActivity_noAccountWarning(Object account) {
    return 'No account found matching \"$account\". Add one to approve.';
  }

  @override
  String get smsActivity_transferWarning =>
      'This looks like a transfer between your accounts. Approving will open the transfer screen.';

  @override
  String get common_all => 'All';

  @override
  String get backup_lastBackup => 'Last backup';

  @override
  String get backup_noBackups => 'No backups yet';

  @override
  String get backup_createFirst =>
      'Create your first backup to protect your data';

  @override
  String get backup_actions => 'Actions';

  @override
  String get backup_history => 'History';

  @override
  String get backup_noHistory => 'No backup history';

  @override
  String get backup_infoText =>
      'Backups are encrypted with your password and saved as .mudra files. Keep your password safe — it cannot be recovered.';

  @override
  String get backup_justNow => 'Just now';

  @override
  String backup_minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String backup_hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String backup_daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String backup_recordCount(int count) {
    return '$count records';
  }

  @override
  String get account_changeCurrency => 'Change Currency?';

  @override
  String account_resetTo(String code) {
    return 'Reset to $code';
  }

  @override
  String get account_baseCurrencyInfo =>
      'Transactions in this account use your base currency.';

  @override
  String account_foreignCurrencyInfo(String code, String base) {
    return 'Transactions will be recorded in $code and converted to $base for totals.';
  }

  @override
  String get account_warningNoConvert =>
      'Existing balances will NOT be converted automatically.';

  @override
  String get account_warningNewCurrency =>
      'New transactions will use the new currency.';

  @override
  String get account_warningManualAdjust =>
      'You may need to manually adjust the balance.';

  @override
  String get category_selectParent => 'Select Parent Category';

  @override
  String get appearance_colorTheme => 'Color Theme';

  @override
  String get appearance_amoledMode => 'AMOLED Mode';

  @override
  String appearance_toneActivated(String name) {
    return '$name tone activated';
  }

  @override
  String dashboard_cardsActive(int visible, int total) {
    return '$visible of $total cards active';
  }

  @override
  String get dashboard_dragToReorder =>
      'Drag to reorder, toggle to show or hide';

  @override
  String get dashboard_smartOrdering => 'Smart ordering';

  @override
  String get dashboard_catEssential => 'Essential';

  @override
  String get dashboard_catFinance => 'Finance';

  @override
  String get dashboard_catAnalytics => 'Analytics';

  @override
  String get dashboard_catActions => 'Actions';

  @override
  String get dashboard_catAI => 'AI Insights';

  @override
  String get dashboard_catContextual => 'Contextual';

  @override
  String get importExport_title => 'Import & Export';

  @override
  String get importExport_export => 'Export';

  @override
  String get importExport_import => 'Import';

  @override
  String get importExport_exportTitle => 'Export Transactions';

  @override
  String get importExport_exportDesc =>
      'Download your transactions as an Excel file.';

  @override
  String get importExport_exporting => 'Exporting...';

  @override
  String get importExport_exportAsExcel => 'Export as Excel';

  @override
  String get importExport_importTitle => 'Import from Excel';

  @override
  String get importExport_importDesc =>
      'Import transactions from an .xlsx file. You\'ll be able to preview and map columns before importing.';

  @override
  String get importExport_excelFormat => 'Excel (.xlsx)';

  @override
  String get importExport_bankStatement => 'Bank Statement';

  @override
  String get importExport_otherApps => 'Other Apps';

  @override
  String get importExport_pickFile => 'Pick Excel File';

  @override
  String get importExport_infoText =>
      'Export creates an Excel file with all transaction details. Import supports .xlsx files from other finance apps or manual spreadsheets.';

  @override
  String get plugins_subtitle => 'Extend Mudra Manager with powerful plugins';

  @override
  String get plugins_official => 'Official';

  @override
  String plugins_enabled(String name) {
    return '$name enabled';
  }

  @override
  String plugins_disabled(String name) {
    return '$name disabled';
  }

  @override
  String get plugins_configure => 'Configure Plugin';

  @override
  String plugins_activeCount(int active, int total) {
    return '$active of $total active';
  }

  @override
  String get plugins_toggleDesc => 'Toggle plugins to extend app features';

  @override
  String get plugins_default => 'Default';

  @override
  String get plugins_configureSettings => 'Configure plugin settings';

  @override
  String get plugins_creditCardReminders => 'Credit Card Reminders';

  @override
  String get plugins_remindBefore => 'Remind me before (days)';

  @override
  String get plugins_noCreditCards =>
      'No credit card accounts found. Add one first.';

  @override
  String get plugins_creditCardAccounts => 'Credit Card Accounts';

  @override
  String get plugins_billDay => 'Bill Day (1-31)';

  @override
  String get plugins_remindersConfigured => 'Credit card reminders configured';

  @override
  String get plugins_infoText =>
      'Plugins extend app features. Some plugins require additional permissions or configuration.';

  @override
  String get help_title => 'Help & Support';

  @override
  String get help_searchHint => 'Search help topics...';

  @override
  String get help_heroTitle => 'How can we help?';

  @override
  String get help_heroDesc => 'Browse guides or search for a topic';

  @override
  String get help_topics => 'Topics';

  @override
  String get help_tryDifferent => 'Try a different search term';

  @override
  String get help_howToUse => 'How to use';

  @override
  String get help_tips => 'Tips';

  @override
  String help_articleCount(int count) {
    return '$count articles';
  }

  @override
  String help_resultCount(int count) {
    return '$count results';
  }

  @override
  String get help_infoText =>
      'Can\'t find what you need? Visit About → Contact Support for direct help.';

  @override
  String get about_legalCount => '3 items';

  @override
  String get about_supportCount => '4 items';

  @override
  String about_packageCount(int count) {
    return '$count open source packages';
  }

  @override
  String get onboard_continue => 'Continue';

  @override
  String get onboard_restoreFromBackup => 'Restore from Backup';

  @override
  String get onboard_accountNameRequired => 'Account name is required';

  @override
  String get onboard_balanceRequired => 'Balance is required';

  @override
  String get onboard_enterValidNumber => 'Enter valid number';

  @override
  String get onboard_accountHint => 'e.g., Cash, Bank';

  @override
  String get onboard_browseAllCurrencies => 'Browse all currencies';

  @override
  String get onboard_toneTitle => 'How should Mudra talk to you?';

  @override
  String get onboard_toneDesc =>
      'Pick a personality. You can change this anytime.';

  @override
  String get onboard_categoriesTitle => 'Choose Your Categories';

  @override
  String get onboard_categoriesDesc =>
      'Pick packs that match your lifestyle. You can change these later.';

  @override
  String get onboard_startFresh => 'Start Fresh';

  @override
  String get onboard_startFreshDesc => 'No categories — add your own later';

  @override
  String get onboard_currencyWarning =>
      'Changing base currency later will archive existing transactions.';

  @override
  String get statistics_topCategory => 'Top Category';

  @override
  String get statistics_dailyAverage => 'Daily Average';

  @override
  String get statistics_perDay => 'per day';

  @override
  String statistics_percentOfExpenses(String percent) {
    return '$percent% of expenses';
  }

  @override
  String get sms_infoTitle => 'How SMS Import Works';

  @override
  String get sms_infoOnlyScans => 'Only scans bank and wallet SMS';

  @override
  String get sms_infoStaysOnDevice => 'All data stays on your device';

  @override
  String get sms_infoAutoCreates => 'Automatically creates transactions';

  @override
  String get sms_infoNoPersonal => 'No personal messages are read';

  @override
  String get dashboard_totalBalance => 'Total Balance';

  @override
  String get dashboard_netWorthLink => 'Net Worth';

  @override
  String get dashboard_showAccounts => 'Show accounts';

  @override
  String get dashboard_hideAccounts => 'Hide accounts';

  @override
  String dashboard_accountsTapExpand(int count) {
    return '$count accounts · Tap to expand';
  }

  @override
  String get notif_lowBalanceTitle => '⚠️ Low Balance Alert';

  @override
  String notif_lowBalanceBody(String account, String amount) {
    return 'Your balance in $account is $amount';
  }

  @override
  String get achieve_unlocked => 'Unlocked';

  @override
  String get achieve_inProgress => 'In Progress';

  @override
  String get achieve_trophyShelf => 'Trophy Shelf';

  @override
  String get achieve_streaks => 'Streaks';

  @override
  String get achieve_totalXP => 'Total XP';

  @override
  String get achieve_dailyCheckIn => 'Daily Check-in';

  @override
  String get achieve_budgetAdherence => 'Budget Adherence';

  @override
  String achieve_bestDays(int count) {
    return 'Best: $count days';
  }

  @override
  String achieve_noBadgesYet(String category) {
    return 'No $category badges yet';
  }

  @override
  String achieve_levelUpSnack(int level) {
    return '🎉 Level Up! You are now Level $level!';
  }

  @override
  String achieve_levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get achieve_catBudgeting => 'Budgeting';

  @override
  String get achieve_catSavings => 'Savings';

  @override
  String get achieve_catTracking => 'Tracking';

  @override
  String get achieve_catMilestones => 'Milestones';

  @override
  String get achieve_catEngagement => 'Engagement';

  @override
  String get achieve_catAll => 'All';

  @override
  String get alert_actionNeeded => 'Action Needed';

  @override
  String alert_billsDueTomorrow(int count) {
    return '$count bill(s) due tomorrow';
  }

  @override
  String get alert_upcomingBills => 'Upcoming Bills';

  @override
  String alert_billsDueInDays(int count) {
    return '$count bill(s) due in 2 days';
  }

  @override
  String get alert_budgetAlert => 'Budget Alert';

  @override
  String alert_budgetsExceeded(int count) {
    return '$count budget(s) exceeded';
  }

  @override
  String get alert_budgetWarning => 'Budget Warning';

  @override
  String alert_budgetsNearLimit(int count) {
    return '$count budget(s) near limit';
  }

  @override
  String get alert_goalProgress => 'Goal Progress';

  @override
  String alert_goalsAlmostComplete(int count) {
    return '$count goal(s) almost complete!';
  }

  @override
  String get analytics_cashFlowForecast => 'Cash Flow Forecast';

  @override
  String get analytics_thisMonthProjected => 'This month (projected)';

  @override
  String get analytics_savingOnAverage => 'You are saving on average';

  @override
  String get analytics_spendingExceedsIncome => 'Spending exceeds income';

  @override
  String get recap_vsLastYear => 'vs Last Year';

  @override
  String get common_income => 'Income';

  @override
  String get common_expense => 'Expense';

  @override
  String get common_transactions => 'Transactions';

  @override
  String get tax_title => 'Tax Estimation';

  @override
  String get tax_projected => 'Projected (year in progress)';

  @override
  String get tax_estimatedTax => 'Estimated Tax';

  @override
  String get tax_effectiveRate => 'Effective Rate';

  @override
  String get tax_monthlyTax => 'Monthly';

  @override
  String tax_fyProgress(int elapsed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$elapsed of $total $_temp0';
  }

  @override
  String get tax_slabBreakdown => 'Slab Breakdown';

  @override
  String get tax_totalSlabTax => 'Total Slab Tax';

  @override
  String get tax_computation => 'Tax Computation';

  @override
  String get tax_grossIncome => 'Gross Income';

  @override
  String get tax_standardDeduction => 'Standard Deduction';

  @override
  String get tax_taxableIncome => 'Taxable Income';

  @override
  String get tax_baseTax => 'Tax on Income';

  @override
  String get tax_rebate87A => 'Rebate u/s 87A';

  @override
  String get tax_cess => 'Health & Education Cess (4%)';

  @override
  String get tax_totalTax => 'Total Tax Payable';

  @override
  String get tax_incomeBreakdown => 'Income Sources';

  @override
  String get tax_disclaimer =>
      'This is an estimate based on New Tax Regime (FY 2025-26). Actual tax may vary. Consult a tax professional for accurate filing.';

  @override
  String get tax_noData => 'Not enough data to estimate tax';

  @override
  String get tax_viewDetails => 'View Tax Estimate';

  @override
  String get tax_zeroTax => 'No tax liability 🎉';

  @override
  String get tax_newRegime => 'New Regime';

  @override
  String get category_merge => 'Merge Category';

  @override
  String get category_mergeInto => 'Merge into';

  @override
  String get category_mergeConfirm => 'Merge';

  @override
  String category_mergePreview(int count, String target) {
    return '$count items will be moved to $target';
  }

  @override
  String get category_mergeSuccess => 'Categories merged successfully';

  @override
  String get category_mergeSameError => 'Cannot merge a category into itself';

  @override
  String get category_mergeSelectTarget => 'Select target category';

  @override
  String get notif_morningInsightTitle => '☀️ Your morning money minute';

  @override
  String get notif_weeklyRecapNudgeTitle => '📊 Your weekly recap is ready';

  @override
  String get notif_yesterdaySpendTitle => '💰 Yesterday\'s spending';

  @override
  String get notif_weeklyRecapReadyTitle => '📊 Your weekly recap is waiting';

  @override
  String notif_underBudgetStreakTitle(int days) {
    return '🔥 $days days under budget!';
  }

  @override
  String get dashboard_bgSyncIssueTitle => 'Background sync may not be working';

  @override
  String get dashboard_bgSyncIssueDesc =>
      'Bills and alerts may be delayed. Try reopening the app.';

  @override
  String get onboard_whatDidYouSpend => 'What did you spend today?';

  @override
  String get onboard_addFewToStart =>
      'Add a few to see your dashboard come alive';

  @override
  String get onboard_skipAddLater => 'Skip — I\'ll add later';

  @override
  String get onboard_starterCoffee => 'Coffee / Tea';

  @override
  String get onboard_starterTransport => 'Transport';

  @override
  String get onboard_starterLunch => 'Lunch / Dinner';

  @override
  String get onboard_starterGroceries => 'Groceries';

  @override
  String onboard_starterAdded(int count) {
    return '$count expenses added!';
  }

  @override
  String get dashboard_listeningTitle => 'Listening for transactions...';

  @override
  String get dashboard_waitingForSms =>
      'Your next bank notification will appear here automatically';

  @override
  String get dashboard_meanwhile => 'Meanwhile, try:';

  @override
  String get dashboard_addExpense => 'Add Expense';

  @override
  String get dashboard_setBudget => 'Set Budget';

  @override
  String get dashboard_createGoal => 'Create Goal';

  @override
  String get dashboard_addAccount => 'Add Account';

  @override
  String get dashboard_testTip =>
      '💡 Tip: Send a small UPI payment to see auto-import in action!';

  @override
  String get dashboard_addFirstExpense => 'Add your first expense';

  @override
  String get dashboard_addFirstExpenseDesc =>
      'Tap to quickly log what you spent today';

  @override
  String get quickAdd_title => 'Quick Add';

  @override
  String get quickAdd_recentCategories => 'Recent categories';

  @override
  String get quickAdd_moreOptions => 'More options';

  @override
  String get mode_simple => 'Simple';

  @override
  String get mode_full => 'Full';

  @override
  String get mode_simpleDesc => 'Expenses, budgets & SMS tracking';

  @override
  String get mode_fullDesc =>
      'Everything — trips, goals, analytics, gamification';

  @override
  String get mode_switchToFull => 'Switch to Full Mode';

  @override
  String get mode_switchToSimple => 'Switch to Simple Mode';

  @override
  String get mode_pickTitle => 'How do you want to use Mudra?';

  @override
  String get mode_pickDesc => 'You can change this anytime in settings';

  @override
  String get backup_cloudBackup => 'Cloud Backup';

  @override
  String get backup_cloudRestore => 'Restore from Cloud';

  @override
  String get backup_signInGoogle => 'Sign in with Google';

  @override
  String backup_signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get backup_uploadingToDrive => 'Uploading to Google Drive...';

  @override
  String get backup_uploadSuccess => 'Backup uploaded to Google Drive';

  @override
  String get backup_uploadFailed => 'Failed to upload backup';

  @override
  String get backup_cloudBackups => 'Cloud Backups';

  @override
  String get backup_noCloudBackups => 'No cloud backups found';

  @override
  String get backup_downloading => 'Downloading from Google Drive...';

  @override
  String get backup_signInRequired => 'Sign in to Google to use cloud backup';

  @override
  String get backup_signOut => 'Sign out';

  @override
  String get backup_cloudSubtitle => 'Encrypted backup to Google Drive';

  @override
  String get backup_autoBackup => 'Auto Backup';

  @override
  String get backup_autoBackupDesc =>
      'Automatic local backups, keeps last 7 days';

  @override
  String get backup_autoFrequency => 'Backup frequency';

  @override
  String get backup_autoNever => 'Off';

  @override
  String get backup_autoDaily => 'Daily';

  @override
  String get backup_autoWeekly => 'Weekly';

  @override
  String get backup_autoSetPassword =>
      'Set a backup password to enable auto backup';

  @override
  String backup_autoEnabled(String frequency) {
    return 'Auto backup enabled ($frequency)';
  }

  @override
  String backup_autoLastRun(String date) {
    return 'Last auto backup: $date';
  }

  @override
  String get backup_proRequired => 'Pro feature';

  @override
  String get onboard_skip => 'Skip';

  @override
  String get onboard_languages => 'Languages';

  @override
  String get onboard_smartTrackingMergedDesc =>
      'Auto-import from bank SMS, set budgets, track goals — all in one place.';

  @override
  String get sms_celebrationTitle => 'Your first SMS transaction! 🎉';

  @override
  String get sms_celebrationBody =>
      'Mudra just auto-imported a transaction from your bank SMS. From now on, your expenses track themselves.';

  @override
  String get sms_celebrationCta => 'Awesome, let\'s go!';

  @override
  String get milestone_shareButton => 'Share to Story';

  @override
  String get milestone_goalReachedTitle => 'Goal Reached!';

  @override
  String milestone_goalReachedDesc(String amount) {
    return 'Saved $amount and hit the target 🌟';
  }

  @override
  String milestone_streakTitle(int days) {
    return '$days-Day Streak!';
  }

  @override
  String milestone_streakDesc(int days) {
    return 'Tracked expenses every day for $days days straight';
  }

  @override
  String get milestone_underBudgetTitle => 'Under Budget!';

  @override
  String get milestone_underBudgetDesc =>
      'Stayed within budget for the entire month 💪';

  @override
  String get account_creditLimit => 'Credit Limit';

  @override
  String get account_statementDay => 'Statement Day';

  @override
  String get account_dueDay => 'Due Day';

  @override
  String account_daysUntilDue(int days) {
    return '$days days until due';
  }

  @override
  String get account_dueToday => 'Due today!';

  @override
  String account_overdue(int days) {
    return 'Overdue by $days days';
  }

  @override
  String get subscription_title => 'Detected Subscriptions';

  @override
  String subscription_monthlyTotal(String amount) {
    return '$amount/month total';
  }

  @override
  String subscription_occurrences(int count) {
    return '$count charges in 4 months';
  }

  @override
  String get subscription_none => 'No recurring subscriptions detected yet';

  @override
  String subscription_dayOfMonth(int day) {
    return 'Around the ${day}th of each month';
  }
}
