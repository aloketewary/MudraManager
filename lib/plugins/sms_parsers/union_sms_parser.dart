import '../sms_parser_plugin.dart';

class UnionBankSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'unionbank_sms_parser';
  @override
  String get name => 'Union Bank SMS Parser';
  @override
  String get version => '1.0.0';
  @override
  String get bankName => 'UNION';

  @override
  List<String> get senderNames => ['UNION', 'UNIBNK', 'UBOI'];

  @override
  String get iconPath => 'assets/logo/banks/union.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('UNION') ||
        s.contains('UNIBNK') ||
        s.contains('UBOI');
  }

  static final _amountRegex = RegExp(
    r'(?:INR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final _accountRegex = RegExp(
    r'(?:[Aa]/[Cc]|[Aa]ccount|A/C)\s*(?:no\.?\s*)?[xX*]*([\d]{4})',
  );

  static final _balanceRegex = RegExp(
    r'(?:Avl\s*Bal|Bal|balance)[:\s]*(?:INR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amount = _extractAmount(_amountRegex, body);
    if (amount == null) return null;

    final isIncome = _isCredit(body);
    final isDebit = _isDebit(body);
    if (!isIncome && !isDebit) return null;

    final account = _extractAccount(body);
    final balance = _extractAmount(_balanceRegex, body);
    final merchant = _extractMerchant(body);
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer = bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs') ||
        bodyLower.contains('transfer');

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
      merchant: merchant,
      balance: balance,
      transactionType: _detectType(body),
      isLikelyTransfer: isLikelyTransfer,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final b = body.toLowerCase();
    return b.contains('debited') ||
        b.contains('credited') ||
        b.contains('withdrawn') ||
        b.contains('deposited') ||
        b.contains('txn') ||
        b.contains('spent') ||
        b.contains('received');
  }

  bool _isDebit(String body) {
    final b = body.toLowerCase();
    return b.contains('debited') ||
        b.contains('withdrawn') ||
        b.contains('spent') ||
        b.contains('paid');
  }

  bool _isCredit(String body) {
    final b = body.toLowerCase();
    return b.contains('credited') ||
        b.contains('deposited') ||
        ParsedSms.isReceivedCredit(body);
  }

  String? _extractAccount(String body) {
    final m = _accountRegex.firstMatch(body);
    if (m != null) return m.group(1);
    final xx = RegExp(r'XX(\d{4})').firstMatch(body);
    return xx?.group(1);
  }

  String? _extractMerchant(String body) {
    final vpa = RegExp(r'to\s+VPA\s+([^\s.]+)').firstMatch(body);
    if (vpa != null) return vpa.group(1)?.trim();

    final toMatch =
        RegExp(r'\bto\s+([A-Z][A-Za-z\s]{2,30}?)(?:\.|on|Ref)', caseSensitive: false)
            .firstMatch(body);
    if (toMatch != null) return toMatch.group(1)?.trim();

    final fromMatch =
        RegExp(r'\bfrom\s+([A-Z][A-Za-z\s]{2,30}?)(?:\.|on|Ref)', caseSensitive: false)
            .firstMatch(body);
    if (fromMatch != null) return fromMatch.group(1)?.trim();

    return null;
  }

  String? _detectType(String body) {
    final b = body.toLowerCase();
    if (b.contains('upi')) return 'UPI';
    if (b.contains('atm') || b.contains('withdrawn')) return 'ATM';
    if (b.contains('imps')) return 'IMPS';
    if (b.contains('neft')) return 'NEFT';
    if (b.contains('rtgs')) return 'RTGS';
    if (b.contains('transfer')) return 'Transfer';
    return null;
  }

  double? _extractAmount(RegExp regex, String body) {
    final m = regex.firstMatch(body);
    if (m == null) return null;
    return double.tryParse(m.group(1)?.replaceAll(',', '') ?? '');
  }
}
