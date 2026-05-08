import '../sms_parser_plugin.dart';

/// Middle East & Africa bank SMS parser.
/// Handles transaction SMS from banks in UAE, Saudi, Egypt, Nigeria, Kenya, South Africa.
/// Most banks in these regions send SMS in English, but with local currency codes.
class MeaRegionSmsParser extends SmsParserPlugin {
  @override
  String get id => 'mea_region_sms_parser';

  @override
  String get name => 'Middle East & Africa SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'MEA Banks';

  @override
  List<String> get senderNames => [
    // UAE
    'ENBD', 'ADCB', 'FAB', 'MASHREQ', 'DIB',
    // Saudi
    'ALRAJHI', 'SNB', 'SABB', 'ALINMA',
    // Egypt
    'CIB', 'NBE', 'BANQUEMISR',
    // Nigeria
    'GTBANK', 'ZENITH', 'ACCESS', 'UBA', 'FIRSTBANK',
    // Kenya
    'MPESA', 'EQUITY', 'KCB', 'COOP',
    // South Africa
    'FNB', 'ABSA', 'NEDBANK', 'CAPITEC',
  ];

  @override
  String get iconPath => 'assets/logo/banks/generic.svg';

  @override
  bool canParse(String sender) {
    final upper = sender.toUpperCase();
    return senderNames.any((s) => upper.contains(s));
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    final upper = body.toUpperCase();
    if (!_hasKeyword(upper)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    return ParsedSms(
      amount: amount,
      isIncome: _isCredit(upper),
      account: _extractAccount(body),
      transactionType: _isCredit(upper) ? 'credit' : 'debit',
      merchant: _extractMerchant(body),
      currency: _detectCurrency(body),
    );
  }

  bool _hasKeyword(String upper) {
    const keywords = [
      // English (used by most MEA banks)
      'DEBITED', 'CREDITED', 'PURCHASE', 'PAYMENT', 'TRANSFER',
      'WITHDRAWN', 'DEPOSITED', 'RECEIVED', 'SENT', 'PAID',
      // M-Pesa (Kenya)
      'CONFIRMED', 'UMETUMA', 'UMEPOKEA', 'MALIPO',
      // Arabic transliterated
      'MASHTRIAT', 'TAHWIL', 'SAHB', 'EIDAA',
      // Swahili
      'IMETHIBITISHWA',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const credit = ['CREDITED', 'DEPOSITED', 'RECEIVED', 'UMEPOKEA', 'REFUND', 'EIDAA'];
    const debit = ['DEBITED', 'PURCHASE', 'PAYMENT', 'WITHDRAWN', 'SENT', 'UMETUMA', 'MALIPO', 'SAHB'];
    final ci = credit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    final di = debit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    return ci < di;
  }

  double? _extractAmount(String body) {
    // Currency code prefix: AED 350.00, NGN 15,000, KES 5,000, ZAR 1,200
    final codePattern = RegExp(
      r'(?:AED|SAR|EGP|NGN|KES|ZAR|GHS)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final match = codePattern.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    // Fallback: any number near transaction keywords
    final fallback = RegExp(r'(?:of|for|amount)\s*:?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
    final fbMatch = fallback.firstMatch(body);
    if (fbMatch != null) {
      final raw = fbMatch.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    return null;
  }

  String? _detectCurrency(String body) {
    final upper = body.toUpperCase();
    const currencies = {
      'AED': 'AED', 'SAR': 'SAR', 'EGP': 'EGP',
      'NGN': 'NGN', 'KES': 'KES', 'ZAR': 'ZAR', 'GHS': 'GHS',
    };
    for (final entry in currencies.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractAccount(String body) {
    final pattern = RegExp(
      r'(?:a/c|account|card|acct)[\s.:]*(?:ending\s*|no\.?\s*|[xX*]+)(\d{4})',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    final pattern = RegExp(
      r'(?:at|to|from|towards)\s+([A-Z][A-Za-z0-9\s&\-]{2,25})(?:\s+on|\.|,)',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1)?.trim();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
