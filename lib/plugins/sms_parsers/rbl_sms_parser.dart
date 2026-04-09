import '../sms_parser_plugin.dart';

class RblSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'rbl_sms_parser';
  @override
  String get name => 'RBL Bank SMS Parser';
  @override
  String get version => '1.0.0';
  @override
  String get bankName => 'RBL';

  @override
  List<String> get senderNames => ['RBLBNK', 'RBLBK', 'RBL'];

  @override
  String get iconPath => 'assets/logo/banks/rbl.svg';

  @override
  bool canParse(String sender) => sender.toUpperCase().contains('RBL');

  static final _promoKeywords = [
    'missed call',
    'increase credit limit',
    'upgrade',
    'apply now',
    'pre-approved',
    'eligible',
    'offer',
    'discount',
    'cashback',
    'emi',
    'loan',
    'no extra cost',
    'click here',
    'visit',
    'download',
  ];

  @override
  ParsedSms? parseSms(String sender, String body) {
    final bodyLower = body.toLowerCase();

    // Reject promos
    if (_promoKeywords.any((k) => bodyLower.contains(k))) return null;
    if (!_hasTransactionKeywords(bodyLower)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(
        r'(?:A/c|Card|a/c)\s*(?:ending\s*)?[xX]*([\dxX]{4})',
        caseSensitive: false);
    final typeRegex =
        RegExp(r'(debited|credited|spent|received|paid)', caseSensitive: false);
    final merchantRegex =
        RegExp(r'(?:at|to)\s+([A-Za-z][A-Za-z0-9\s&\-]{2,30})(?:\s+on|\.|$)');
    final vpaRegex = RegExp(r'(?:to|from)\s+([\w.-]+@[\w.-]+)');
    final balanceRegex = RegExp(
        r'(?:Avl\s*(?:Bal|Lmt)|Balance)[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false);

    final amount = _extractAmount(amountRegex, body);
    if (amount == null) return null;

    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final vpa = vpaRegex.firstMatch(body)?.group(1);
    final merchant = vpa ?? merchantRegex.firstMatch(body)?.group(1)?.trim();
    final balance = _extractAmount(balanceRegex, body);

    final isIncome = type == 'credited' || type == 'received';
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
      transactionType:
          vpa != null ? 'UPI' : (bodyLower.contains('card') ? 'Card' : null),
      isLikelyTransfer: isLikelyTransfer,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasTransactionKeywords(String bodyLower) {
    const keywords = [
      'debited',
      'credited',
      'spent',
      'received',
      'paid',
      'withdrawn'
    ];
    return keywords.any((k) => bodyLower.contains(k));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
  }
}
