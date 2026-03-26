import '../sms_parser_plugin.dart';

class IciciSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'icici_sms_parser';

  @override
  String get name => 'ICICI Bank SMS Parser';

  @override
  String get version => '1.0.1';

  @override
  String get bankName => 'ICICI';

  @override
  List<String> get senderNames => ['ICICI', 'ICICIB'];

  @override
  String get iconPath => 'assets/logo/banks/icici.svg';

  @override
  bool canParse(String sender) {
    return sender.toUpperCase().contains('ICICI');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'a/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final infoRegex = RegExp(r'Info:\s*(.+?)(?:\.|$)');
    final balanceRegex =
        RegExp(r'Avl\s*bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant = _cleanMerchantName(infoRegex.firstMatch(body)?.group(1));
    final balance = _extractAmount(balanceRegex, body);
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer = bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs') ||
        bodyLower.contains('transfer');

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
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
    final keywords = ['debited', 'credited', 'spent', 'received', 'paid'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }

  String? _cleanMerchantName(String? merchant) {
    if (merchant == null) return null;
    final cleaned = merchant.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length >= 2 ? cleaned : null;
  }
}
