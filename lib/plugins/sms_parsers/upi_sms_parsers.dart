import '../sms_parser_plugin.dart';

class PaytmSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'paytm_sms_parser';
  @override
  String get name => 'Paytm SMS Parser';
  @override
  String get version => '1.0.0';
  @override
  String get bankName => 'PAYTM';

  @override
  List<String> get senderNames => ['PAYTM', 'PYTM'];

  @override
  String get iconPath => 'assets/logo/banks/paytm.svg';

  @override
  bool canParse(String sender) => sender.toUpperCase().contains('PAYTM');

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final typeRegex = RegExp(r'(sent|received|credited|debited)', caseSensitive: false);
    final merchantRegex = RegExp(r'(?:to|from)\s+([^\s]+)');

    final amount = _extractAmount(amountRegex, body);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant = merchantRegex.firstMatch(body)?.group(1);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'received' || type == 'credited',
      transactionType: 'UPI',
      merchant: merchant,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final keywords = ['sent', 'received', 'credited', 'debited', 'paid'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }
}

class PhonePeSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'phonepe_sms_parser';
  @override
  String get name => 'PhonePe SMS Parser';
  @override
  String get version => '1.0.0';
  @override
  String get bankName => 'PHONEPE';

  @override
  List<String> get senderNames => ['PHONEPE', 'PHPEPE'];

  @override
  String get iconPath => 'assets/logo/banks/phonepe.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('PHONEPE') || s.contains('PHPEPE');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final typeRegex = RegExp(r'(sent|received|paid)', caseSensitive: false);
    final merchantRegex = RegExp(r'(?:to|from)\s+([^\s]+)');

    final amount = _extractAmount(amountRegex, body);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant = merchantRegex.firstMatch(body)?.group(1);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'received',
      transactionType: 'UPI',
      merchant: merchant,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final keywords = ['sent', 'received', 'paid'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }
}

class GpaySmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'gpay_sms_parser';
  @override
  String get name => 'Google Pay SMS Parser';
  @override
  String get version => '1.0.0';
  @override
  String get bankName => 'GPAY';

  @override
  List<String> get senderNames => ['GPAY', 'GOOGLE'];

  @override
  String get iconPath => 'assets/logo/banks/gpay.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('GPAY') || s.contains('GOOGLE');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final typeRegex = RegExp(r'(sent|received)', caseSensitive: false);
    final merchantRegex = RegExp(r'(?:to|from)\s+([^\s]+)');

    final amount = _extractAmount(amountRegex, body);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant = merchantRegex.firstMatch(body)?.group(1);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'received',
      transactionType: 'UPI',
      merchant: merchant,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final keywords = ['sent', 'received'];
    return keywords.any((keyword) => bodyLower.contains(keyword));
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }
}