import 'package:intl/intl.dart';

/// Safe date formatting that avoids non-Latin numerals.
///
/// Locales like bn, mr, ar, fa render native numerals (০১২৩, ०१२३, ٠١٢٣)
/// which break chart labels and compact UI. This utility falls back to 'en'
/// for those locales while preserving month/day names for supported locales.
///
/// Usage:
/// ```dart
/// final formatted = safeDateFormat('dd MMM', ctxt.localeName).format(date);
/// ```
DateFormat safeDateFormat(String pattern, [String? locale]) {
  return DateFormat(pattern, _safeDateLocale(locale));
}

/// Returns a locale safe for DateFormat (Western digits + Latin month names).
///
/// - hi → hi (Hindi month names are fine, digits are Latin)
/// - bn → en (Bengali renders ০১২৩ numerals)
/// - ar, fa, mr, ne, pa, as, ks → en (non-Latin numerals)
/// - null → en
String _safeDateLocale(String? locale) {
  if (locale == null) return 'en';
  final lang = locale.split('_').first;
  const nonLatinNumeralLocales = {'bn', 'mr', 'ar', 'fa', 'ne', 'pa', 'as', 'ks'};
  if (nonLatinNumeralLocales.contains(lang)) return 'en';
  return locale;
}
