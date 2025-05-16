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
}
