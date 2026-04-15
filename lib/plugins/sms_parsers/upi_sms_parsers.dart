import '../sms_parser_plugin.dart';

class PaytmSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'paytm_sms_parser';
  @override
  String get name => 'Paytm SMS Parser';
  @override
  String get version => '1.1.0';
  @override
  String get bankName => 'PAYTM';

  @override
  List<String> get senderNames => ['PAYTM'];

  @override
  String get iconPath => 'assets/logo/banks/paytm.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('PAYTM') || s.contains('PPBL');
  }

  static final _amountRs =
      RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);
  static final _accountRegex =
      RegExp(r'a/c\s*(\d{2}[xX]+\d{3,5})', caseSensitive: false);

  // "Rs.xxx sent to merchant@bank from BANKNAME a/c 91XX1234"
  static final _upiSent = RegExp(
    r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s+sent\s+to\s+(\S+)\s+from\s+.+?a/c\s*(\d{2}[xX]+\d{3,5})',
    caseSensitive: false,
  );

  // "Paid Rs.xxx via a/c 91XX1234 to Merchant Name on dd-mm-yyyy"
  static final _paidTo = RegExp(
    r'Paid\s+Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s+via\s+a/c\s*(\d{2}[xX]+\d{3,5})\s+to\s+(.+?)\s+on\s+',
    caseSensitive: false,
  );

  // "Rs.xxxx withdrawn at ATM NAME on dd-mm-yyyy ... Avl Bal:Rs.xxxx"
  static final _atmWithdraw = RegExp(
    r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s+withdrawn\s+at\s+(.+?)\s+on\s+',
    caseSensitive: false,
  );
  static final _atmBalance = RegExp(
    r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // "Rs.xxxx received from Sender Name in your Paytm ... a/c 91XX01234"
  static final _received = RegExp(
    r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s+received\s+from\s+(.+?)\s+in\s+your\s+.+?a/c\s*(\d{2}[xX]+\d{3,5})',
    caseSensitive: false,
  );

  @override
  ParsedSms? parseSms(String sender, String body) {
    // UPI sent: "Rs.xxx sent to merchant@bank from ... a/c 91XX1234"
    final upiMatch = _upiSent.firstMatch(body);
    if (upiMatch != null) {
      return ParsedSms(
        amount: _parseAmount(upiMatch.group(1))!,
        isIncome: false,
        account: upiMatch.group(3),
        merchant: _cleanMerchant(upiMatch.group(2)),
        transactionType: 'UPI',
      );
    }

    // Paid to: "Paid Rs.xxx via a/c ... to Merchant Name on ..."
    final paidMatch = _paidTo.firstMatch(body);
    if (paidMatch != null) {
      return ParsedSms(
        amount: _parseAmount(paidMatch.group(1))!,
        isIncome: false,
        account: paidMatch.group(2),
        merchant: _cleanMerchant(paidMatch.group(3)),
      );
    }

    // ATM withdrawal: "Rs.xxxx withdrawn at ATM NAME on ..."
    final atmMatch = _atmWithdraw.firstMatch(body);
    if (atmMatch != null) {
      return ParsedSms(
        amount: _parseAmount(atmMatch.group(1))!,
        isIncome: false,
        merchant: _cleanMerchant(atmMatch.group(2)),
        balance: _extractAmount(_atmBalance, body),
        transactionType: 'ATM',
      );
    }

    // Received: "Rs.xxxx received from Sender in your ... a/c ..."
    final recvMatch = _received.firstMatch(body);
    if (recvMatch != null) {
      return ParsedSms(
        amount: _parseAmount(recvMatch.group(1))!,
        isIncome: true,
        account: recvMatch.group(3),
        merchant: _cleanMerchant(recvMatch.group(2)),
        transactionType: 'UPI',
      );
    }

    // Fallback: generic debited/credited
    return _parseFallback(body);
  }

  ParsedSms? _parseFallback(String body) {
    final lower = body.toLowerCase();
    if (!['sent', 'received', 'credited', 'debited', 'paid', 'withdrawn']
        .any(lower.contains)) {
      return null;
    }

    final amount = _extractAmount(_amountRs, body);
    if (amount == null) return null;

    final typeMatch =
        RegExp(r'(sent|debited|paid|withdrawn|received|credited)',
                caseSensitive: false,)
            .firstMatch(body)
            ?.group(1)
            ?.toLowerCase();
    final isIncome = typeMatch == 'received' || typeMatch == 'credited';
    final account = _accountRegex.firstMatch(body)?.group(1);

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
      transactionType: 'UPI',
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    return _parseAmount(match?.group(1));
  }

  double? _parseAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', ''));
  }

  String? _cleanMerchant(String? merchant) {
    if (merchant == null) return null;
    final cleaned = merchant.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length >= 2 ? cleaned : null;
  }
}

class PhonePeSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'phonepe_sms_parser';
  @override
  String get name => 'PhonePe SMS Parser';
  @override
  String get version => '1.0.1';
  @override
  String get bankName => 'PHONEPE';

  @override
  List<String> get senderNames => ['PHONEPE'];

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
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer = bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs') ||
        bodyLower.contains('transfer');

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'received',
      transactionType: 'UPI',
      merchant: merchant,
      isLikelyTransfer: isLikelyTransfer,
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
  String get version => '1.0.1';
  @override
  String get bankName => 'GPAY';

  @override
  List<String> get senderNames => ['GPAY', 'GOOGLE PAY'];

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
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer =
        bodyLower.contains('transfer') || bodyLower.contains('sent to bank');

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'received',
      transactionType: 'UPI',
      merchant: merchant,
      isLikelyTransfer: isLikelyTransfer,
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
