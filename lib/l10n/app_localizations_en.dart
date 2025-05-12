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
}
