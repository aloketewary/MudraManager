import '../sms_parser_plugin.dart';

class YesBankSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'yesbank_sms_parser';
  @override
  String get name => 'Yes Bank SMS Parser';
  @override
  String get version => '1.0.1';
  @override
  String get bankName => 'YES';

  @override
  List<String> get senderNames => ['YESBNK', 'YESBANK'];

  @override
  String get iconPath => 'assets/logo/banks/yes.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('YESBNK') || s.contains('YESBANK');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final balanceRegex =
        RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
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
}

class IndusIndSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'indusind_sms_parser';
  @override
  String get name => 'IndusInd Bank SMS Parser';
  @override
  String get version => '1.0.1';
  @override
  String get bankName => 'INDUSIND';

  @override
  List<String> get senderNames => ['INDUS', 'INDUSIND'];

  @override
  String get iconPath => 'assets/logo/banks/indusind.svg';

  @override
  bool canParse(String sender) => sender.toUpperCase().contains('INDUS');

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    // Updated regex to handle formats like "Rs 10000.00" and "Rs. 10000.00"
    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    // Updated to handle *XX6988 format
    final accountRegex =
        RegExp(r'A/C?\s*\*?[xX]*([xX]*\d{4})', caseSensitive: false);
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    // Extract UPI ID from "from 891223@jupiteraxis" format
    final upiRegex = RegExp(r'from\s+([\w.-]+@[\w.-]+)');
    final merchantRegex = RegExp(r'at\s+(.+?)\s+on');
    // Updated to handle "Avl bal:676767.27" format
    final balanceRegex = RegExp(
      r'Avl\s*(?:bal|Bal|Lmt)[:\s]*Rs?\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      caseSensitive: false,
    );

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final upiId = upiRegex.firstMatch(body)?.group(1);
    final merchant =
        _cleanMerchantName(merchantRegex.firstMatch(body)?.group(1)) ?? upiId;
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
      transactionType: type == 'credited' ? 'Income' : 'Expense',
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

class IdfcSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'idfc_sms_parser';
  @override
  String get name => 'IDFC Bank SMS Parser';
  @override
  String get version => '1.0.1';
  @override
  String get bankName => 'IDFC';

  @override
  List<String> get senderNames => ['IDFC', 'IDFCFB'];

  @override
  String get iconPath => 'assets/logo/banks/idfc.svg';

  @override
  bool canParse(String sender) => sender.toUpperCase().contains('IDFC');

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final balanceRegex =
        RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
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
}

class AuBankSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'aubank_sms_parser';
  @override
  String get name => 'AU Bank SMS Parser';
  @override
  String get version => '1.0.1';
  @override
  String get bankName => 'AU';

  @override
  List<String> get senderNames => ['AUBANK', 'AUSFB'];

  @override
  String get iconPath => 'assets/logo/banks/au.svg';

  @override
  bool canParse(String sender) => sender.toUpperCase().contains('AUBANK');

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final balanceRegex =
        RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
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
}
