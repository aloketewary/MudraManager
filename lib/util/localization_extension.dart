import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/l10n/app_localizations.dart'
    show AppLocalizations;

extension AppLocalizationsHelper on AppLocalizations {
  String translate(String key) {
    switch (key) {
      case 'welcome_to_app':
        return onboard_welcomeToApp('Mudra Manager');
      case 'manageYourMoneyDescription':
        return onboard_manageYourMoneyDescription;
      case 'good_morning':
        return greeting_good_morning_text;
      case 'good_afternoon':
        return greeting_good_afternoon_text;
      case 'good_evening':
        return greeting_good_evening_text;
      case 'good_night':
        return greeting_good_night_text;
      case 'day':
        return cash_flow_filter_type_day;
      case 'week':
        return cash_flow_filter_type_week;
      case 'month':
        return cash_flow_filter_type_month;
      case 'year':
        return cash_flow_filter_type_year;
      default:
        return key;
    }
  }

  NumberFormat formatLocalizedCurrency(String localeCode, int fixedStringLength) {
    final locale = localeCode == 'hi' ? 'hi_IN' : localeCode;
    var format = NumberFormat.currency(
      locale: locale,
      symbol: "₹", // Or separate sign and symbol if needed
      decimalDigits: fixedStringLength,
      customPattern: '¤#,##,##0.00',
    );
    return format;
  }

  NumberFormat formatCompactLocalizedCurrency(
    String localeCode,
    int fixedStringLength,
  ) {
    final locale = localeCode == 'hi' ? 'hi_IN' : localeCode;
    var format = NumberFormat.compactCurrency(
      locale: locale,
      symbol: "₹", // Or separate sign and symbol if needed
      decimalDigits: fixedStringLength,
    );
    return format;
  }

  String formatLocalizedNumberWithSign(
    int fixedStringLength,
    String localeCode,
    double amount, {
    bool compact = false,
  }) {
    var format =
        compact
            ? formatCompactLocalizedCurrency(localeCode, fixedStringLength)
            : formatLocalizedCurrency(localeCode, fixedStringLength);
    return format.format(amount);
  }

  NumberFormat formatLocalizedNumber(String localeCode) {
    final locale = localeCode == 'hi' ? 'hi_IN' : localeCode;
    var format = NumberFormat.compact(
      locale: locale,
      explicitSign: false
    );
    return format;
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
