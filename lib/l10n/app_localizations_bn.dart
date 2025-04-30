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
}
