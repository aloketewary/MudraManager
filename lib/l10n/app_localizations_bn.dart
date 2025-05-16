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
}
