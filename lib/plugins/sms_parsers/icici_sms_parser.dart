import '../sms_parser_plugin.dart';

class IciciSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'icici_sms_parser';

  @override
  String get name => 'ICICI Bank SMS Parser';

  @override
  String get version => '1.1.0';

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

  // ── Amount regexes ──
  static final _amountRs =
      RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);
  static final _amountInr =
      RegExp(r'INR\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);

  // ── Account regexes ──
  static final _accountSavings = RegExp(r'a/c\s*[xX]*([\d]{4})');
  static final _accountCard =
      RegExp(r'Card\s*[xX]*([\d]{4})', caseSensitive: false);

  // ── Savings account patterns ──
  static final _savingsDebitCredit =
      RegExp(r'(debited|credited)', caseSensitive: false);
  static final _savingsInfo = RegExp(r'Info:\s*(.+?)(?:\.|$)');
  static final _savingsBalance =
      RegExp(r'Avl\s*bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);

  // ── Credit card patterns ──
  static final _ccSpent = RegExp(
    r'INR\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*spent\s*on\s*ICICI\s*Bank\s*Card\s*[xX]*([\d]{4})\s*on\s*([\d\-\w]+)\s*at\s*(.+?)\.?\s*Avl\s*Lmt',
    caseSensitive: false,
  );
  static final _ccRefund = RegExp(
    r'refund\s*of\s*INR\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*from\s*(.+?)\s*has\s*been\s*credited\s*to\s*your\s*ICICI\s*Bank\s*Credit\s*Card\s*[xX]*([\d]{4})',
    caseSensitive: false,
  );
  static final _ccPayment = RegExp(
    r'[Pp]ayment\s*of\s*INR\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*(?:towards|has\s*been\s*received\s*towards)\s*your\s*ICICI\s*Bank\s*Credit\s*Card\s*[xX]*([\d]{4})',
    caseSensitive: false,
  );
  static final _ccBill = RegExp(
    r'statement\s*for\s*ICICI\s*Bank\s*Credit\s*Card\s*[xX]*([\d]{4}).*?(?:Total\s*amount\s*of\s*)?Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _ccAvlLimit = RegExp(
    r'Avl\s*Lmt[:\s]*INR\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedSms? parseSms(String sender, String body) {
    // Try credit card patterns first (more specific)
    final cc = _parseCreditCard(body);
    if (cc != null) return cc;

    // Fall back to savings account patterns
    return _parseSavingsAccount(body);
  }

  ParsedSms? _parseCreditCard(String body) {
    // CC Debit: "INR xxx spent on ICICI Bank Card XX1234 ... at MERCHANT"
    final spentMatch = _ccSpent.firstMatch(body);
    if (spentMatch != null) {
      return ParsedSms(
        amount: _parseAmount(spentMatch.group(1))!,
        isIncome: false,
        account: spentMatch.group(2),
        merchant: _cleanMerchant(spentMatch.group(4)),
        balance: _extractAmount(_ccAvlLimit, body),
      );
    }

    // CC Refund: "refund of INR xxx from Merchant ... credited to ... Card XX1234"
    final refundMatch = _ccRefund.firstMatch(body);
    if (refundMatch != null) {
      return ParsedSms(
        amount: _parseAmount(refundMatch.group(1))!,
        isIncome: true,
        account: refundMatch.group(3),
        merchant: _cleanMerchant(refundMatch.group(2)),
      );
    }

    // CC Payment received: "payment of INR xxx towards ... Card XX1234"
    final paymentMatch = _ccPayment.firstMatch(body);
    if (paymentMatch != null) {
      return ParsedSms(
        amount: _parseAmount(paymentMatch.group(1))!,
        isIncome: true,
        account: paymentMatch.group(2),
        merchant: 'Credit Card Payment',
      );
    }

    // CC Bill statement: "statement for ... Card XX1234 ... Rs xxxxx"
    // Not a transaction — skip
    if (_ccBill.hasMatch(body)) return null;

    return null;
  }

  ParsedSms? _parseSavingsAccount(String body) {
    if (!_hasSavingsKeywords(body)) return null;

    final amount = _extractAmount(_amountRs, body) ??
        _extractAmount(_amountInr, body);
    final account = _accountSavings.firstMatch(body)?.group(1) ??
        _accountCard.firstMatch(body)?.group(1);
    final type = _savingsDebitCredit.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant = _cleanMerchant(_savingsInfo.firstMatch(body)?.group(1));
    final balance = _extractAmount(_savingsBalance, body);
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

  bool _hasSavingsKeywords(String body) {
    final lower = body.toLowerCase();
    return ['debited', 'credited', 'spent', 'received', 'paid']
        .any(lower.contains);
  }

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
