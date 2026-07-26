import '../sms_parser_plugin.dart';

/// Brazilian bank SMS parser.
/// Handles Portuguese-language transaction SMS from major Brazilian banks.
/// Currency: BRL (R$). Decimal format: 1.234,56 (dot=thousands, comma=decimal).
class BrazilSmsParser extends SmsParserPlugin {
  @override
  String get id => 'brazil_sms_parser';

  @override
  String get name => 'Brazil Bank SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'Brazil Banks';

  @override
  List<String> get senderNames => [
    'NUBANK', 'ITAU', 'BRADESCO', 'BB', 'CAIXA', 'SANTANDER',
    'C6BANK', 'INTER', 'PICPAY', 'MERCADOPAGO',
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
      currency: 'BRL',
    );
  }

  bool _hasKeyword(String upper) {
    const keywords = [
      'COMPRA', 'PAGAMENTO', 'TRANSFERENCIA', 'SAQUE',
      'DEPOSITO', 'PIX', 'ESTORNO', 'DEBITO', 'CREDITO',
      'RECEBEU', 'ENVIOU', 'APROVADA', 'FATURA',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const credit = ['CREDITO', 'DEPOSITO', 'RECEBEU', 'ESTORNO', 'RECEBIDO'];
    const debit = ['COMPRA', 'PAGAMENTO', 'SAQUE', 'DEBITO', 'ENVIOU', 'FATURA'];
    final ci = credit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    final di = debit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    return ci < di;
  }

  double? _extractAmount(String body) {
    // R$ 1.234,56 or R$45,99
    final rPattern = RegExp(r'R\$\s*([\d.]+,\d{2})');
    final match = rPattern.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    // BRL 1234,56
    final codePattern = RegExp(r'BRL\s*([\d.]+,\d{2})', caseSensitive: false);
    final codeMatch = codePattern.firstMatch(body);
    if (codeMatch != null) {
      final raw = codeMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(raw);
    }
    return null;
  }

  String? _extractAccount(String body) {
    final pattern = RegExp(r'(?:cartao|conta|card)\s*(?:final\s*)?[*xX]*(\d{4})', caseSensitive: false);
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    final pattern = RegExp(r'(?:em|no|na|para)\s+([A-Z][A-Za-z0-9\s]{2,25})(?:\s+em|\.|,)', caseSensitive: false);
    return pattern.firstMatch(body)?.group(1)?.trim();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
