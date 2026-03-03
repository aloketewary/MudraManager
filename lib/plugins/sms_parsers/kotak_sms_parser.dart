import '../sms_parser_plugin.dart';

class KotakSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'kotak_sms_parser';
  
  @override
  String get name => 'Kotak Bank SMS Parser';
  
  @override
  String get version => '1.0.0';
  
  @override
  String get bankName => 'KOTAK';

  @override
  List<String> get senderNames => ['KOTAK', 'KOTAKB'];

  @override
  String get iconPath => 'assets/logo/banks/kotak.svg';

  @override
  bool canParse(String sender) {
    return sender.toUpperCase().contains('KOTAK');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final balanceRegex = RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
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
}