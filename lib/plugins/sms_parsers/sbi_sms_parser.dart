import '../sms_parser_plugin.dart';

class SbiSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'sbi_sms_parser';
  
  @override
  String get name => 'SBI SMS Parser';
  
  @override
  String get version => '1.0.0';
  
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
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited|withdrawn)', caseSensitive: false);
    final vpaRegex = RegExp(r'to\s+(?:VPA\s+)?([^\s\.]+@[^\s\.]+)');
    final balanceRegex = RegExp(r'Avl\s*Bal[:\s]*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final vpa = vpaRegex.firstMatch(body)?.group(1);
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      transactionType: type == 'withdrawn' ? 'ATM' : (vpa != null ? 'UPI' : 'Card'),
      merchant: vpa,
      balance: balance,
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final keywords = ['debited', 'credited', 'spent', 'received', 'paid', 'withdrawn'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }
}