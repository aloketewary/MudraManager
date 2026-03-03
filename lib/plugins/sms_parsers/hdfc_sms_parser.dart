import '../sms_parser_plugin.dart';

class HdfcSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'hdfc_sms_parser';
  
  @override
  String get name => 'HDFC Bank SMS Parser';
  
  @override
  String get version => '1.0.0';
  
  @override
  String get bankName => 'HDFC';

  @override
  List<String> get senderNames => ['HDFC', 'HDFCBK'];

  @override
  String get iconPath => 'assets/logo/banks/hdfc.svg';

  @override
  bool canParse(String sender) {
    return sender.toUpperCase().contains('HDFC');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final vpaRegex = RegExp(r'to\s+VPA\s+([^\s\.]+)');
    final merchantRegex = RegExp(r'(?:at|to)\s+([A-Z][A-Z0-9\s]{2,30})(?:\s+on|\.|$)');
    final balanceRegex = RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final vpa = vpaRegex.firstMatch(body)?.group(1);
    final merchant = vpa ?? _extractMerchantName(merchantRegex, body);
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      transactionType: vpa != null ? 'UPI' : 'Card',
      merchant: merchant,
      balance: balance,
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final keywords = ['debited', 'credited', 'spent', 'received', 'paid'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }

  String? _extractMerchantName(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    return match?.group(1)?.trim();
  }
}