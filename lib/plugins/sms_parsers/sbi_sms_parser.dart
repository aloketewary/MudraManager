import '../sms_parser_plugin.dart';

class SbiSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'sbi_sms_parser';
  @override
  String get name => 'SBI SMS Parser';
  @override
  String get version => '1.1.0';
  @override
  String get bankName => 'SBI';

  @override
  List<String> get senderNames => ['SBI', 'SBIINB', 'SBIPSG'];

  @override
  String get iconPath => 'assets/logo/banks/sbi.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('SBI') || s.contains('SBIINB');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex =
        RegExp(r'A/c\s*[xX]*([\dxX]{4})', caseSensitive: false);
    final typeRegex =
        RegExp(r'(debited|credited|withdrawn)', caseSensitive: false);
    final vpaRegex = RegExp(r'(?:to|from)\s+(?:VPA\s+)?([\w.-]+@[\w.-]+)');
    final transferNameRegex = RegExp(
        r'transfer\s+from\s+([A-Z][A-Z\s]{2,40})(?:\s+Ref|\s*$)',
        caseSensitive: false);
    final toNameRegex = RegExp(
        r'(?:transferred\s+to|paid\s+to)\s+([A-Z][A-Z\s]{2,40})(?:\s+Ref|\s+on|\s*$)',
        caseSensitive: false);
    final balanceRegex = RegExp(
        r'(?:Avl\s*Bal|Bal)[:\s]*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        caseSensitive: false);
    final refRegex = RegExp(r'Ref\s*(?:No\.?\s*)?(\d+)');

    final amount = _extractAmount(amountRegex, body);
    if (amount == null) return null;

    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final vpa = vpaRegex.firstMatch(body)?.group(1);
    final transferName = transferNameRegex.firstMatch(body)?.group(1)?.trim();
    final toName = toNameRegex.firstMatch(body)?.group(1)?.trim();
    final balance = _extractAmount(balanceRegex, body);
    final ref = refRegex.firstMatch(body)?.group(1);

    // Merchant priority: VPA > transfer name > to name
    final merchant = vpa ?? transferName ?? toName;

    // Transaction type detection
    String? transactionType;
    if (type == 'withdrawn') {
      transactionType = 'ATM';
    } else if (vpa != null) {
      transactionType = 'UPI';
    } else if (transferName != null ||
        toName != null ||
        (ref != null && ref.length >= 10)) {
      transactionType = 'Transfer';
    }
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer = transferName != null ||
        toName != null ||
        bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs') ||
        (bodyLower.contains('transfer') && (ref != null && ref.length >= 10));

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      transactionType: transactionType,
      merchant: merchant,
      balance: balance,
      isLikelyTransfer: isLikelyTransfer,
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    const keywords = [
      'debited',
      'credited',
      'spent',
      'received',
      'paid',
      'withdrawn'
    ];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
  }
}
