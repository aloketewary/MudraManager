import '../sms_parser_plugin.dart';

/// European bank SMS parser.
/// Handles French, German, and pan-European transaction SMS.
/// Currencies: EUR, GBP, CHF, SEK, NOK, PLN, CZK, HUF, RON, TRY.
/// Decimal format: 1.234,56 (most of continental Europe).
class EuropeSmsParser extends SmsParserPlugin {
  @override
  String get id => 'europe_sms_parser';

  @override
  String get name => 'Europe Bank SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'Europe Banks';

  @override
  List<String> get senderNames => [
    // France
    'BNPPARIBAS', 'SOCGEN', 'CREDITAGRICOLE', 'BOURSORAMA',
    // Germany
    'SPARKASSE', 'COMMERZBANK', 'DKB', 'ING', 'N26',
    // Pan-European
    'REVOLUT', 'WISE', 'MONZO', 'BUNQ',
    // Turkey
    'GARANTI', 'ISBANK', 'AKBANK', 'YAPIKREDI',
    // Netherlands
    'ABN', 'RABOBANK',
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
      // French
      'ACHAT', 'PAIEMENT', 'VIREMENT', 'RETRAIT',
      'REMBOURSEMENT', 'PRELEVEMENT', 'CARTE',
      // German
      'ABBUCHUNG', 'ZAHLUNG', 'LASTSCHRIFT',
      'GUTSCHRIFT', 'ERSTATTUNG', 'UBERWEISUNG',
      // Turkish
      'HARCAMA', 'ODEME', 'HAVALE', 'PARA', 'ISLEM',
      // English (used by neobanks)
      'PAYMENT', 'PURCHASE', 'TRANSFER', 'REFUND',
      'DEBITED', 'CREDITED',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const credit = [
      'CREDITED', 'GUTSCHRIFT', 'ERSTATTUNG', 'REMBOURSEMENT',
      'RECEIVED', 'VIREMENT RECU',
    ];
    const debit = [
      'DEBITED', 'ABBUCHUNG', 'ZAHLUNG', 'LASTSCHRIFT',
      'ACHAT', 'PAIEMENT', 'RETRAIT', 'PRELEVEMENT',
      'HARCAMA', 'ODEME', 'PURCHASE', 'PAYMENT',
    ];
    final ci = credit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    final di = debit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    return ci < di;
  }

  double? _extractAmount(String body) {
    // Euro symbol: €32,50 or € 1.234,56
    final euroComma = RegExp(r'€\s*([\d.]+,\d{2})');
    var match = euroComma.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    // Euro symbol dot decimal: €32.50
    final euroDot = RegExp(r'€\s*([\d,]+(?:\.\d{1,2})?)');
    match = euroDot.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    // Turkish Lira: ₺150,00 or TRY 150,00
    final tryPattern = RegExp(r'(?:₺|TRY)\s*([\d.]+,\d{2})', caseSensitive: false);
    match = tryPattern.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    // Currency code with comma decimal: EUR 89,90 | GBP 50,00 | CHF 120,50
    final codeComma = RegExp(
      r'(?:EUR|GBP|CHF|SEK|NOK|PLN|CZK|HUF|RON|TRY)\s*([\d.]+,\d{2})',
      caseSensitive: false,
    );
    match = codeComma.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    // Currency code with dot decimal: EUR 89.90
    final codeDot = RegExp(
      r'(?:EUR|GBP|CHF|SEK|NOK|PLN|CZK|HUF|RON|TRY)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    match = codeDot.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    // Pound: £100.00
    final gbpPattern = RegExp(r'£\s*([\d,]+(?:\.\d{1,2})?)');
    match = gbpPattern.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    return null;
  }

  String? _detectCurrency(String body) {
    if (body.contains('₺')) return 'TRY';
    if (body.contains('€')) return 'EUR';
    if (body.contains('£')) return 'GBP';
    final upper = body.toUpperCase();
    const codes = ['EUR', 'GBP', 'CHF', 'SEK', 'NOK', 'PLN', 'CZK', 'HUF', 'RON', 'TRY'];
    for (final code in codes) {
      if (upper.contains(code)) return code;
    }
    return null;
  }

  String? _extractAccount(String body) {
    final pattern = RegExp(
      r'(?:carte|karte|card|kart)\s*(?:ending\s*|no\.?\s*)?[*xX]*(\d{4})',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    final pattern = RegExp(
      r'(?:chez|bei|at|to)\s+([A-Z][A-Za-z0-9\s&\-]{2,25})(?:\s+le|\s+am|\s+on|\.|,)',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1)?.trim();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
