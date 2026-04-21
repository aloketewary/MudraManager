import '../sms_parser_plugin.dart';

/// Latin America bank SMS parser.
/// Handles Spanish-language transaction SMS from major LatAm banks.
/// Currencies: MXN, COP, ARS, PEN, CLP.
class LatamSmsParser extends SmsParserPlugin {
  @override
  String get id => 'latam_sms_parser';

  @override
  String get name => 'Latin America SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'LatAm Banks';

  @override
  List<String> get senderNames => [
    // Mexico
    'BBVA', 'BANAMEX', 'BANCOMER', 'BANORTE', 'HSBC',
    // Colombia
    'BANCOLOMBIA', 'DAVIVIENDA', 'NEQUI',
    // Argentina
    'GALICIA', 'SANTANDER', 'MACRO', 'MERCADOPAGO',
    // Peru
    'BCP', 'INTERBANK', 'YAPE',
    // Chile
    'BCHILE', 'BANCOESTADO', 'SCOTIABANK',
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
      'COMPRA', 'PAGO', 'TRANSFERENCIA', 'RETIRO',
      'DEPOSITO', 'CARGO', 'ABONO', 'COBRO',
      'OPERACION', 'MOVIMIENTO', 'TRANSACCION',
      'RECIBISTE', 'ENVIASTE', 'APROBADA',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const credit = ['ABONO', 'DEPOSITO', 'RECIBISTE', 'DEVOLUCION'];
    const debit = ['COMPRA', 'PAGO', 'RETIRO', 'CARGO', 'COBRO', 'ENVIASTE'];
    final ci = credit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    final di = debit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    return ci < di;
  }

  double? _extractAmount(String body) {
    // $ with comma decimal (Argentina, Chile): $1.234,56
    final commaDecimal = RegExp(r'\$\s*([\d.]+,\d{2})');
    var match = commaDecimal.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    // $ with dot decimal (Mexico, Colombia): $1,234.56
    final dotDecimal = RegExp(r'\$\s*([\d,]+(?:\.\d{1,2})?)');
    match = dotDecimal.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    // Currency code: MXN 1,234.56
    final codePattern = RegExp(
      r'(?:MXN|COP|ARS|PEN|CLP)\s*([\d.,]+)',
      caseSensitive: false,
    );
    match = codePattern.firstMatch(body);
    if (match != null) {
      var raw = match.group(1)!;
      if (RegExp(r',\d{2}$').hasMatch(raw)) {
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        raw = raw.replaceAll(',', '');
      }
      return double.tryParse(raw);
    }
    return null;
  }

  String? _detectCurrency(String body) {
    final upper = body.toUpperCase();
    const currencies = {
      'MXN': 'MXN', 'COP': 'COP', 'ARS': 'ARS',
      'PEN': 'PEN', 'CLP': 'CLP',
    };
    for (final entry in currencies.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractAccount(String body) {
    final pattern = RegExp(
      r'(?:tarjeta|cuenta|card)\s*(?:terminacion\s*|final\s*)?[*xX]*(\d{4})',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    final pattern = RegExp(
      r'(?:en|a|de|para)\s+([A-Z][A-Za-z0-9\s]{2,25})(?:\s+el|\.|,)',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1)?.trim();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
