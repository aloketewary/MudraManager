import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CurrencyMeta {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  /// True if symbol is a single recognizable character ($, €, £, etc.)
  final bool cleanSymbol;

  const CurrencyMeta(this.code, this.symbol, this.name, {this.decimalDigits = 2, this.cleanSymbol = false});
}

const kCurrencies = <String, CurrencyMeta>{
  'INR': CurrencyMeta('INR', '₹', 'Indian Rupee', cleanSymbol: true),
  'USD': CurrencyMeta('USD', '\$', 'US Dollar', cleanSymbol: true),
  'EUR': CurrencyMeta('EUR', '€', 'Euro', cleanSymbol: true),
  'GBP': CurrencyMeta('GBP', '£', 'British Pound', cleanSymbol: true),
  'JPY': CurrencyMeta('JPY', '¥', 'Japanese Yen', decimalDigits: 0, cleanSymbol: true),
  'AED': CurrencyMeta('AED', 'AED', 'UAE Dirham'),
  'SGD': CurrencyMeta('SGD', '\$', 'Singapore Dollar', cleanSymbol: true),
  'AUD': CurrencyMeta('AUD', '\$', 'Australian Dollar', cleanSymbol: true),
  'CAD': CurrencyMeta('CAD', '\$', 'Canadian Dollar', cleanSymbol: true),
  'CHF': CurrencyMeta('CHF', 'CHF', 'Swiss Franc'),
  'CNY': CurrencyMeta('CNY', '¥', 'Chinese Yuan', cleanSymbol: true),
  'HKD': CurrencyMeta('HKD', '\$', 'Hong Kong Dollar', cleanSymbol: true),
  'MYR': CurrencyMeta('MYR', 'RM', 'Malaysian Ringgit'),
  'THB': CurrencyMeta('THB', '฿', 'Thai Baht', cleanSymbol: true),
  'NZD': CurrencyMeta('NZD', '\$', 'New Zealand Dollar', cleanSymbol: true),
  'SAR': CurrencyMeta('SAR', '﷼', 'Saudi Riyal', cleanSymbol: true),
  'KRW': CurrencyMeta('KRW', '₩', 'South Korean Won', decimalDigits: 0, cleanSymbol: true),
  'BDT': CurrencyMeta('BDT', '৳', 'Bangladeshi Taka', cleanSymbol: true),
  'NPR': CurrencyMeta('NPR', 'रू', 'Nepalese Rupee'),
  'LKR': CurrencyMeta('LKR', 'Rs', 'Sri Lankan Rupee'),
  'PKR': CurrencyMeta('PKR', '₨', 'Pakistani Rupee', cleanSymbol: true),
  'MMK': CurrencyMeta('MMK', 'K', 'Myanmar Kyat'),
  'IDR': CurrencyMeta('IDR', 'Rp', 'Indonesian Rupiah', decimalDigits: 0),
  'PHP': CurrencyMeta('PHP', '₱', 'Philippine Peso', cleanSymbol: true),
  'VND': CurrencyMeta('VND', '₫', 'Vietnamese Dong', decimalDigits: 0, cleanSymbol: true),
  'TWD': CurrencyMeta('TWD', '\$', 'Taiwan Dollar', cleanSymbol: true),
  'ZAR': CurrencyMeta('ZAR', 'R', 'South African Rand'),
  'BRL': CurrencyMeta('BRL', 'R\$', 'Brazilian Real'),
  'MXN': CurrencyMeta('MXN', '\$', 'Mexican Peso', cleanSymbol: true),
  'TRY': CurrencyMeta('TRY', '₺', 'Turkish Lira', cleanSymbol: true),
  'RUB': CurrencyMeta('RUB', '₽', 'Russian Ruble', cleanSymbol: true),
  'SEK': CurrencyMeta('SEK', 'kr', 'Swedish Krona'),
  'NOK': CurrencyMeta('NOK', 'kr', 'Norwegian Krone'),
  'DKK': CurrencyMeta('DKK', 'kr', 'Danish Krone'),
  'PLN': CurrencyMeta('PLN', 'zł', 'Polish Zloty'),
  'CZK': CurrencyMeta('CZK', 'Kč', 'Czech Koruna'),
  'HUF': CurrencyMeta('HUF', 'Ft', 'Hungarian Forint', decimalDigits: 0),
  'ILS': CurrencyMeta('ILS', '₪', 'Israeli Shekel', cleanSymbol: true),
  'QAR': CurrencyMeta('QAR', '﷼', 'Qatari Riyal', cleanSymbol: true),
  'KWD': CurrencyMeta('KWD', 'KWD', 'Kuwaiti Dinar', decimalDigits: 3),
  'BHD': CurrencyMeta('BHD', 'BHD', 'Bahraini Dinar', decimalDigits: 3),
  'OMR': CurrencyMeta('OMR', '﷼', 'Omani Rial', decimalDigits: 3, cleanSymbol: true),
  'EGP': CurrencyMeta('EGP', 'E£', 'Egyptian Pound'),
};

String currencySymbol(String? code) =>
    kCurrencies[code ?? 'INR']?.symbol ?? code ?? '₹';

String currencyName(String? code) =>
    kCurrencies[code ?? 'INR']?.name ?? code ?? 'Indian Rupee';

int currencyDecimalDigits(String? code) =>
    kCurrencies[code ?? 'INR']?.decimalDigits ?? 2;

/// Returns an appropriate icon for the given currency code.
IconData currencyIcon(String? code) {
  switch (code ?? 'INR') {
    case 'INR':
      return LucideIcons.indianRupee;
    case 'USD':
      return LucideIcons.dollarSign;
    case 'EUR':
      return LucideIcons.euro;
    case 'GBP':
      return LucideIcons.poundSterling;
    case 'JPY' || 'CNY':
      return LucideIcons.japaneseYen;
    case 'CHF':
      return LucideIcons.swissFranc;
    case 'RUB':
      return LucideIcons.russianRuble;
    case 'BTC':
      return LucideIcons.bitcoin;
    default:
      return LucideIcons.coins;
  }
}

/// Formats amount as plain text string for non-widget contexts
/// (notifications, PDFs, exports, logs).
///
/// Clean symbol: `₹8,350` / `$100.00`
/// No clean symbol: `AED 367.00` / `CHF 95.00`
/// Locale-aware grouped number with symbol. e.g. "₹1,23,456" or "$1,234"
/// No decimals by default. Use for display in non-widget contexts.
String formatCurrency(double amount, {String? code, int decimals = 0, String locale = 'en'}) {
  final effectiveCode = code ?? 'INR';
  final meta = kCurrencies[effectiveCode];
  final effectiveLocale = (effectiveCode == 'INR') ? 'hi_IN' : locale;
  final fmt = NumberFormat.currency(
    locale: effectiveLocale,
    symbol: meta?.symbol ?? effectiveCode,
    decimalDigits: decimals,
  );
  return fmt.format(amount);
}

/// Full display: symbol + grouped number + code. e.g. "₹12,34,567 INR", "$12,234 SGD"
/// For non-clean symbols (AED, CHF), shows "AED 3,000" without duplication.
/// Use in sentences where the badge widget can't be used.
String formatCurrencyFull(double amount, {String? code, int decimals = 0, String locale = 'en'}) {
  final effectiveCode = code ?? 'INR';
  final meta = kCurrencies[effectiveCode];
  final effectiveLocale = (effectiveCode == 'INR') ? 'hi_IN' : locale;
  final fmt = NumberFormat.currency(
    locale: effectiveLocale,
    symbol: '',
    decimalDigits: decimals,
  );
  final formatted = fmt.format(amount.abs());
  if (meta?.cleanSymbol ?? false) {
    return '${meta!.symbol}$formatted $effectiveCode';
  }
  return '$effectiveCode $formatted';
}

/// Compact display for non-widget contexts.
/// INR: "₹12.5K", "₹2.3L", "₹1.1Cr"
/// Other: "$12.5K", "$1.2M", "$1.1B"
String formatCurrencyCompact(double amount, {String? code, int decimals = 1}) {
  final effectiveCode = code ?? 'INR';
  final meta = kCurrencies[effectiveCode];
  final symbol = (meta?.cleanSymbol ?? false) ? meta!.symbol : '$effectiveCode ';
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  final isIndian = effectiveCode == 'INR';

  if (isIndian) {
    if (abs >= 10000000) {
      return '$sign$symbol${_trimTrailing((abs / 10000000).toStringAsFixed(decimals))}Cr';
    } else if (abs >= 100000) {
      return '$sign$symbol${_trimTrailing((abs / 100000).toStringAsFixed(decimals))}L';
    } else if (abs >= 10000) {
      return '$sign$symbol${_trimTrailing((abs / 1000).toStringAsFixed(decimals))}K';
    }
  } else {
    if (abs >= 1000000000) {
      return '$sign$symbol${_trimTrailing((abs / 1000000000).toStringAsFixed(decimals))}B';
    } else if (abs >= 1000000) {
      return '$sign$symbol${_trimTrailing((abs / 1000000).toStringAsFixed(decimals))}M';
    } else if (abs >= 10000) {
      return '$sign$symbol${_trimTrailing((abs / 1000).toStringAsFixed(decimals))}K';
    }
  }
  return formatCurrency(amount, code: code, decimals: 0);
}

String _trimTrailing(String value) {
  if (!value.contains('.')) return value;
  var trimmed = value.replaceAll(RegExp(r'0+$'), '');
  if (trimmed.endsWith('.')) trimmed = trimmed.substring(0, trimmed.length - 1);
  return trimmed;
}
