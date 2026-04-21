import '../sms_parser_plugin.dart';

/// Indonesian bank SMS parser.
/// Handles Bahasa Indonesia transaction SMS from major Indonesian banks.
/// Currency: IDR (Rp). Format: Rp 250.000 (dot=thousands, no decimal).
class IndonesiaSmsParser extends SmsParserPlugin {
  @override
  String get id => 'indonesia_sms_parser';

  @override
  String get name => 'Indonesia Bank SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'Indonesia Banks';

  @override
  List<String> get senderNames => [
    'BCA', 'MANDIRI', 'BNI', 'BRI', 'CIMB', 'DANAMON',
    'GOPAY', 'OVO', 'DANA', 'SHOPEEPAY', 'LINKAJA',
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
      currency: 'IDR',
    );
  }

  bool _hasKeyword(String upper) {
    const keywords = [
      'PEMBELIAN', 'PEMBAYARAN', 'TRANSFER', 'PENARIKAN',
      'SETORAN', 'TRANSAKSI', 'BERHASIL', 'DITERIMA',
      'TERKIRIM', 'MASUK', 'KELUAR', 'SALDO',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const credit = ['DITERIMA', 'MASUK', 'SETORAN', 'TERIMA'];
    const debit = ['PEMBELIAN', 'PEMBAYARAN', 'PENARIKAN', 'KELUAR', 'TERKIRIM'];
    final ci = credit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    final di = debit.map((k) => upper.indexOf(k)).where((i) => i >= 0).fold<int>(999999, (a, b) => a < b ? a : b);
    return ci < di;
  }

  double? _extractAmount(String body) {
    // Rp 250.000 or Rp250.000 or Rp 1.500.000
    final rpPattern = RegExp(r'Rp\.?\s*([\d.]+)', caseSensitive: false);
    final match = rpPattern.firstMatch(body);
    if (match != null) {
      final raw = match.group(1)!.replaceAll('.', '');
      return double.tryParse(raw);
    }
    // IDR 250000
    final codePattern = RegExp(r'IDR\s*([\d.]+)', caseSensitive: false);
    final codeMatch = codePattern.firstMatch(body);
    if (codeMatch != null) {
      final raw = codeMatch.group(1)!.replaceAll('.', '');
      return double.tryParse(raw);
    }
    return null;
  }

  String? _extractAccount(String body) {
    final pattern = RegExp(r'(?:rek|rekening|no\.?\s*rek)\s*[*xX]*(\d{4})', caseSensitive: false);
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    final pattern = RegExp(r'(?:di|ke|dari|untuk)\s+([A-Z][A-Za-z0-9\s]{2,25})(?:\s+pada|\.|,)', caseSensitive: false);
    return pattern.firstMatch(body)?.group(1)?.trim();
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
