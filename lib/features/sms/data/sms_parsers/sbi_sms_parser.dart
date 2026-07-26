import '../sms_parser_plugin.dart';

class SbiSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'sbi_sms_parser';
  @override
  String get name => 'SBI SMS Parser';
  @override
  String get version => '1.2.0';
  @override
  String get bankName => 'SBI';

  @override
  List<String> get senderNames => ['SBI', 'STATE BANK'];

  @override
  String get iconPath => 'assets/logo/banks/sbi.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('SBI') || s.contains('STATE BANK');
  }

  // Matches: Rs.1234.56, Rs 1234.56, Rs1234.5, INR 1234.56, INR1234.56
  static final _amountRegex = RegExp(
    r'(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Matches: a/c no. XXXXXXXX0000, A/C XXXXX123456, A/c X1234, A/cX1234, frm A/c x0000
  static final _accountRegex = RegExp(
    r'[Aa]/[Cc]\s*(?:no\.?\s*)?[xX]*([\dxX]{4,12})',
  );

  static final _balanceRegex = RegExp(
    r'(?:Avl\s*Bal|Bal)[:\s]*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasKeywords(body)) return null;

    final amount = _extractAmount(_amountRegex, body);
    if (amount == null) return null;

    final isDebit = _isDebit(body);
    final isCredit = !isDebit && _isCredit(body);
    // If neither detected, skip
    if (!isDebit && !isCredit) return null;

    final account = _extractAccount(body);
    final balance = _extractAmount(_balanceRegex, body);
    final merchant = _extractMerchant(body);
    final transactionType = _detectType(body);
    final isLikelyTransfer = _isLikelyTransfer(body);

    return ParsedSms(
      amount: amount,
      isIncome: isCredit,
      account: account,
      merchant: merchant,
      balance: balance,
      transactionType: transactionType,
      isLikelyTransfer: isLikelyTransfer,
    );
  }

  @override
  void onLoad() {}
  @override
  void onStart() {}

  bool _hasKeywords(String body) {
    final l = body.toLowerCase();
    return l.contains('debit') ||
        l.contains('credit') ||
        l.contains('withdrawn') ||
        l.contains('txn');
  }

  bool _isDebit(String body) {
    final l = body.toLowerCase();
    return l.contains('debited') ||
        l.contains('debit by') ||
        l.contains('withdrawn') ||
        (l.contains('txn') && l.contains('frm'));
  }

  bool _isCredit(String body) {
    final l = body.toLowerCase();
    return l.contains('credited') || l.contains('credit by');
  }

  String? _extractAccount(String body) {
    final match = _accountRegex.firstMatch(body);
    if (match == null) return null;
    final raw = match.group(1)!;
    // Return last 4-6 meaningful digits
    final digits = raw.replaceAll(RegExp(r'[xX]'), '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return raw.length >= 4 ? raw.substring(raw.length - 4) : raw;
  }

  String? _extractMerchant(String body) {
    // "transfer to Merchant Ref No"
    final transferTo = RegExp(
      r'transfer\s+to\s+(.+?)\s+Ref',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (transferTo != null && transferTo.length >= 2) return transferTo;

    // "frm A/c x0000 to ICICI Bank"
    final toBank = RegExp(
      r'to\s+([A-Z][A-Za-z\s]+Bank)',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (toBank != null) return toBank;

    // "Deposit by transfer from FIRSTNAME LASTNAME"
    final depositFrom = RegExp(
      r'(?:transfer|Deposit)\s+(?:by\s+transfer\s+)?from\s+([A-Z][A-Za-z\s]{2,40}?)(?:\.\s|Avl|Ref|\s*$)',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (depositFrom != null && depositFrom.length >= 2) return depositFrom;

    // "by a/c linked to mobile 9XXXXXX999-BANK NAME"
    final linkedBank = RegExp(
      r'linked\s+to\s+mobile\s+\S+-(.+?)(?:\s*\(|\s*\.|\s*If)',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (linkedBank != null && linkedBank.length >= 2) return linkedBank;

    // "credited by ... by Bank"
    final byBank = RegExp(
      r'by\s+([A-Z][A-Za-z\s]+?)(?:\.\s|Avl|\s*$)',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (byBank != null &&
        byBank.length >= 3 &&
        !byBank.toLowerCase().contains('transfer') &&
        !byBank.toLowerCase().contains('rs')) {
      return byBank;
    }

    // "Service Charge for forex trans"
    final serviceCharge = RegExp(
      r'-\s*(.+?)(?:\.\s*Avl)',
      caseSensitive: false,
    ).firstMatch(body)?.group(1)?.trim();
    if (serviceCharge != null &&
        serviceCharge.toLowerCase().contains('service charge')) {
      return serviceCharge;
    }

    return null;
  }

  String? _detectType(String body) {
    final l = body.toLowerCase();
    if (l.contains('upi')) return 'UPI';
    if (l.contains('withdrawn') || l.contains('atm')) return 'ATM';
    if (l.contains('imps')) return 'IMPS';
    if (l.contains('neft')) return 'NEFT';
    if (l.contains('rtgs')) return 'RTGS';
    if (l.contains('inb txn')) return 'Net Banking';
    if (l.contains('transfer')) return 'Transfer';
    return null;
  }

  bool _isLikelyTransfer(String body) {
    final l = body.toLowerCase();
    return l.contains('imps') ||
        l.contains('neft') ||
        l.contains('rtgs') ||
        l.contains('transfer') ||
        l.contains('inb txn');
  }

  double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;
    return double.tryParse(match.group(1)?.replaceAll(',', '') ?? '');
  }
}
