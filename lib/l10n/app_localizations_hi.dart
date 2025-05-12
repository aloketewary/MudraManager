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
}
