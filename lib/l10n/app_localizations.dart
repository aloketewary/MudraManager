import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi')
  ];

  /// Manage your money smartly & effortlessly.
  ///
  /// In en, this message translates to:
  /// **'Manage your money smartly & effortlessly.'**
  String get onboard_manageYourMoneyDescription;

  /// Welcome to Application
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String onboard_welcomeToApp(Object appName);

  /// This is title of screen page
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get app_settings_appbar_title;

  /// This is title of Choose Language page
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get language_settings_appbar_title;

  /// This is title of Language tile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get app_settings_language_title;

  /// This is subtitle of Language tile
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get app_settings_language_subtitle;

  /// This is title of Theme Mode tile
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get app_settings_theme_mode_title;

  /// This is text of Theme Mode light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get app_settings_theme_mode_light;

  /// This is text of Theme Mode dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get app_settings_theme_mode_dark;

  /// This is text of Theme Mode system default
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get app_settings_theme_mode_system_default;

  /// This is text of Daily reminder title
  ///
  /// In en, this message translates to:
  /// **'Daily Expense Reminder'**
  String get app_settings_daily_reminder_title;

  /// This is title of Home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_screen_title;

  /// This is title of Activity screen
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get transaction_screen_title;

  /// This is title of Statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics_screen_title;

  /// This is title of Profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_screen_title;

  /// This is title of Add Transaction screen
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get add_edit_transaction_screen_title;

  /// This is title of Transaction List screen
  ///
  /// In en, this message translates to:
  /// **'Transaction List'**
  String get transaction_list_screen_title;

  /// This is text of Good Morning
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greeting_good_morning_text;

  /// This is text of Good Afternoon
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greeting_good_afternoon_text;

  /// This is text of Good Evening
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greeting_good_evening_text;

  /// This is text of Good Night
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get greeting_good_night_text;

  /// This is text of Hello
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting_hello_text;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transaction_type_income;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transaction_type_expense;

  /// This is text of add transaction button
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get dashboard_add_transaction_text;

  /// This is text of add Transfer button
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get dashboard_add_transfer_text;

  /// This is text of Cash Flow
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get dashboard_cash_flow_text;

  /// This is text of Day
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get cash_flow_filter_type_day;

  /// This is text of Week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get cash_flow_filter_type_week;

  /// This is text of Month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get cash_flow_filter_type_month;

  /// This is text of Year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get cash_flow_filter_type_year;

  /// This is text of Budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get dashboard_mini_budget_text;

  /// This is text of budget not found
  ///
  /// In en, this message translates to:
  /// **'No Budgets Defined, Add One!'**
  String get dashboard_mini_budget_not_found_text;

  /// This is text of add budget
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get dashboard_mini_budget_add_text;

  /// This is title of Transactions List from cash flow screen
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transaction_list_cash_flow_screen_title;

  /// This is text of All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transaction_list_filter_all;

  /// This is text of Income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transaction_list_filter_income;

  /// This is text of Expense
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transaction_list_filter_expense;

  /// This is text of pending transaction message
  ///
  /// In en, this message translates to:
  /// **'⚡ New transactions found! Review now'**
  String get transaction_list_pending_transaction_message_text;

  /// This is text of Monday initial
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get calendar_week_monday_initial_text;

  /// This is text of Tuesday initial
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendar_week_tuesday_initial_text;

  /// This is text of Wednesday initial
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get calendar_week_wednesday_initial_text;

  /// This is text of Thursday initial
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendar_week_thursday_initial_text;

  /// This is text of Friday initial
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get calendar_week_friday_initial_text;

  /// This is text of Saturday initial
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendar_week_saturday_initial_text;

  /// This is text of Sunday initial
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendar_week_sunday_initial_text;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
