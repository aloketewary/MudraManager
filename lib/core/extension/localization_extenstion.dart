import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';

extension AppLocalizationsHelper on AppLocalizations {
  String translate(String key) {
    switch (key) {
      case 'welcome_to_app':
        return onboard_welcomeToApp('Mudra Manager');
      case 'manageYourMoneyDescription':
        return onboard_manageYourMoneyDescription;
      case 'onboard_TrackYourTransactions':
        return onboard_TrackYourTransactions;
      case 'onboard_SeeWhereYourMoneyGoes':
        return onboard_SeeWhereYourMoneyGoes;
      case 'onboard_SetBudgetsAndGoals':
        return onboard_SetBudgetsAndGoals;
      case 'onboard_stayOnTrackAndAchieveYourDream':
        return onboard_stayOnTrackAndAchieveYourDream;
      case 'onboard_GetStarted':
        return onboard_GetStarted;
      case 'onboard_letsSetupYourAccount':
        return onboard_letsSetupYourAccount;
      case 'onboard_howShouldWeCallYou':
        return onboard_howShouldWeCallYou;
      case 'onboard_enterYourNameToPersonalizeYourExperience':
        return onboard_enterYourNameToPersonalizeYourExperience;
      case 'onboard_enterYourName':
        return onboard_enterYourName;
      case 'onboard_setupYourFirstAccount':
        return onboard_setupYourFirstAccount;
      case 'onboard_letsCreateYourFirstAccount':
        return onboard_letsCreateYourFirstAccount;
      case 'onboard_accountName':
        return onboard_accountName;
      case 'onboard_youAreAllSet':
        return onboard_youAreAllSet;
      case 'onboard_letsStartManagingYourMoneyWisely':
        return onboard_letsStartManagingYourMoneyWisely;
      case 'app_settings_appbar_title':
        return app_settings_appbar_title;
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
      case 'none':
        return budget_recurrenceNoneText;
      case 'daily':
        return budget_recurrenceDailyText;
      case 'weekly':
        return budget_recurrenceWeeklyText;
      case 'monthly':
        return budget_recurrenceMonthlyText;
      case 'yearly':
        return budget_recurrenceYearlyText;
      case 'Today':
        return statistics_selectPeriodTodayText;
      case 'Week':
        return statistics_selectPeriodWeekText;
      case 'Month':
        return statistics_selectPeriodMonthText;
      case 'Year':
        return statistics_selectPeriodYearText;
      case 'onboard_SmartSmsTracking':
        return onboard_SmartSmsTracking;
      case 'onboard_SmartSmsTrackingDesc':
        return onboard_SmartSmsTrackingDesc;
      case 'onboard_InsightsAndAnalytics':
        return onboard_InsightsAndAnalytics;
      case 'onboard_InsightsAndAnalyticsDesc':
        return onboard_InsightsAndAnalyticsDesc;
      case 'onboard_SecureAndPrivate':
        return onboard_SecureAndPrivate;
      case 'onboard_SecureAndPrivateDesc':
        return onboard_SecureAndPrivateDesc;
      case 'onboard_SmartAutoTracking':
        return onboard_SmartAutoTracking;
      case 'onboard_SmartAutoTrackingDesc':
        return onboard_SmartAutoTrackingDesc;

      default:
        return key;
    }
  }

  NumberFormat formatLocalizedCurrency(int fixedStringLength) {
    final locale = localeName == 'hi' ? 'hi_IN' : localeName;
    final format = NumberFormat.currency(
      locale: locale,
      symbol: BaseCurrency.symbol,
      decimalDigits: fixedStringLength,
      customPattern: '¤#,##,##0.00',
    );
    return format;
  }

  NumberFormat formatCompactLocalizedCurrency(int fixedStringLength) {
    final locale = localeName == 'hi' ? 'hi_IN' : localeName;
    final format = NumberFormat.compactCurrency(
      locale: locale,
      symbol: '', // Or separate sign and symbol if needed
      decimalDigits: fixedStringLength,
    );
    return format;
  }

  String formatCurrencyWithSign(int fixedStringLength, double amount,
      {bool compact = false}) {
    final format = compact
        ? formatCompactLocalizedCurrency(fixedStringLength)
        : formatLocalizedCurrency(fixedStringLength);
    return "${compact ? BaseCurrency.symbol : ""}${format.format(amount)}";
  }

  String formatCompactCurrency(double amount, {int fixedStringLength = 2}) {
    final s = BaseCurrency.symbol;
    if (amount.abs() >= 10000000) {
      return '$s${_trimTrailingZeros((amount / 10000000).toStringAsFixed(fixedStringLength))}$currency_crore_short';
    } else if (amount.abs() >= 100000) {
      return '$s${_trimTrailingZeros((amount / 100000).toStringAsFixed(fixedStringLength))}$currency_lakh_short';
    } else if (amount.abs() >= 10000) {
      return '$s${_trimTrailingZeros((amount / 1000).toStringAsFixed(fixedStringLength))}$currency_thousand_short';
    }
    return formatCurrencyWithSign(0, amount);
  }

  String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    var trimmed = value.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.endsWith('.'))
      trimmed = trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  NumberFormat formatCompactNumber() {
    final locale = localeName == 'hi' ? 'hi_IN' : localeName;
    final format = NumberFormat.compact(locale: locale, explicitSign: false);
    return format;
  }

  String formatPercentNumber(num value) {
    final locale = localeName == 'hi' ? 'hi_IN' : localeName;
    final format = NumberFormat.percentPattern(locale);
    return format.format(value);
  }

  NumberFormat formatLocaleNumber() {
    final locale = localeName == 'hi' ? 'hi_IN' : localeName;
    final format = NumberFormat('#,##,##0.00', locale);
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
