// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription => 'अपने पैसे को स्मार्ट तरीके से और सहजता से प्रबंधित करें।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return ' $appName में आपका स्वागत है';
  }

  @override
  String get app_settings_appbar_title => 'ऐप सेटिंग्स';

  @override
  String get language_settings_appbar_title => 'भाषा चुनें';

  @override
  String get app_settings_language_title => 'भाषा';

  @override
  String get app_settings_language_subtitle => 'अपनी भाषा चुनें';

  @override
  String get app_settings_theme_mode_title => 'थीम मोड';

  @override
  String get app_settings_theme_mode_light => 'प्रकाश';

  @override
  String get app_settings_theme_mode_dark => 'गहरा';

  @override
  String get app_settings_theme_mode_system_default => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get app_settings_daily_reminder_title => 'दैनिक व्यय अनुस्मारक';

  @override
  String get home_screen_title => 'होम';

  @override
  String get transaction_screen_title => 'गतिविधि';

  @override
  String get statistics_screen_title => 'आँकड़े';

  @override
  String get profile_screen_title => 'प्रोफाइल';

  @override
  String get add_edit_transaction_screen_title => 'लेन-देन जोड़ें';

  @override
  String get transaction_list_screen_title => 'लेनदेन सूची';

  @override
  String get greeting_good_morning_text => 'सुप्रभात';

  @override
  String get greeting_good_afternoon_text => 'सुसंध्या';

  @override
  String get greeting_good_evening_text => 'शुभ संध्या';

  @override
  String get greeting_good_night_text => 'शुभ रात्रि';

  @override
  String get greeting_hello_text => 'नमस्ते';

  @override
  String get transaction_type_income => 'आय';

  @override
  String get transaction_type_expense => 'खर्च';

  @override
  String get dashboard_add_transaction_text => 'लेन-देन जोड़ें';

  @override
  String get dashboard_add_transfer_text => 'स्थानांतरण';

  @override
  String get dashboard_cash_flow_text => 'नकदी प्रवाह';

  @override
  String get cash_flow_filter_type_day => 'दिन';

  @override
  String get cash_flow_filter_type_week => 'सप्ताह';

  @override
  String get cash_flow_filter_type_month => 'महीना';

  @override
  String get cash_flow_filter_type_year => 'वर्ष';

  @override
  String get dashboard_mini_budget_text => 'बजट';

  @override
  String get dashboard_mini_budget_not_found_text => 'कोई बजट परिभाषित नहीं है, एक जोड़ें!';

  @override
  String get dashboard_mini_budget_add_text => 'बजट जोड़ें';

  @override
  String get transaction_list_cash_flow_screen_title => 'लेनदेन';

  @override
  String get transaction_list_filter_all => 'सभी';

  @override
  String get transaction_list_filter_income => 'आय';

  @override
  String get transaction_list_filter_expense => 'व्यय';

  @override
  String get transaction_list_pending_transaction_message_text => '⚡ नए लेनदेन मिले! अभी समीक्षा करें';

  @override
  String get calendar_week_monday_initial_text => 'सो';

  @override
  String get calendar_week_tuesday_initial_text => 'मं';

  @override
  String get calendar_week_wednesday_initial_text => 'बु';

  @override
  String get calendar_week_thursday_initial_text => 'गु';

  @override
  String get calendar_week_friday_initial_text => 'शु';

  @override
  String get calendar_week_saturday_initial_text => 'श';

  @override
  String get calendar_week_sunday_initial_text => 'र';
}
