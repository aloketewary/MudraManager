import 'package:flutter/material.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;

extension AppLocalizationsHelper on AppLocalizations {
  String translate(String key) {
    switch (key) {
      case 'welcome_to_app':
        return onboard_welcomeToApp('Mudra Manager');
      case 'manageYourMoneyDescription':
        return onboard_manageYourMoneyDescription;
      default:
        return key;
    }
  }
}

extension LocalizationExtension on Locale {
  String displayName() {
    switch (languageCode.toUpperCase()) {
      case 'EN':
        return 'English';
      case 'HI':
        return 'हिंदी';
      case 'BN':
        return 'বাংলা';
      default:
        return 'English';
    }
  }
}
