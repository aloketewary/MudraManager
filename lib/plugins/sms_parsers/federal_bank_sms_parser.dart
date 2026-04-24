import '../sms_parser_plugin.dart';

class FederalBankSmsParserPlugin extends SmsParserPlugin {
  @override
  String get id => 'federal_bank_sms_parser';

  @override
  String get name => 'Federal Bank SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'FEDERAL';

  @override
  List<String> get senderNames => ['FEDERAL'];

  @override
  String get iconPath => 'assets/logo/banks/generic.svg';

  @override
  bool canParse(String sender) {
    final s = sender.toUpperCase();
    return s.contains('FEDERAL') || s.contains('FEDBNK');
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    if (!_hasTransactionKeywords(body)) return null;

    final amount = _extractAmount(body);
    if (amount == null) return null;

    final account = _extractAccount(body);
    final isIncome = _isCredit(body);
    final merchant = _extractMerchant(body);
    final bodyLower = body.toLowerCase();
    final isLikelyTransfer = bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs') ||
        bodyLower.contains('transfer');

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
      merchant: merchant,
      isLikelyTransfer: isLikelyTransfer,
    );
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}

  bool _hasTransactionKeywords(String body) {
    final b = body.toLowerCase();
    return b.contains('debited') ||
        b.contains('credited') ||
        b.contains('sent') ||
        b.contains('received') ||
        b.contains('spent') ||
        b.contains('paid') ||
        b.contains('withdrawn');
  }

  double? _extractAmount(String body) {
    // Rs 70.00 / Rs.500.00 / INR 1,200.00
    final patterns = [
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{2})?)'),
      RegExp(r'INR\s*([\d,]+(?:\.\d{2})?)'),
      RegExp(r'₹\s*([\d,]+(?:\.\d{2})?)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        return double.tryParse(m.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  String? _extractAccount(String body) {
    final patterns = [
      RegExp(r'[Aa]/[Cc]\s*[xX]*([\d]{4})'),
      RegExp(r'[Aa]ccount\s*[xX]*([\d]{4})'),
      RegExp(r'XX(\d{4})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) return m.group(1);
    }
    return null;
  }

  bool _isCredit(String body) {
    final b = body.toLowerCase();
    if (b.contains('credited') || b.contains('received')) return true;
    if (b.contains('debited') || b.contains('sent') || b.contains('spent') || b.contains('paid')) return false;
    return false;
  }

  String? _extractMerchant(String body) {
    // "to Bansi Pan Shop" pattern
    final toMatch = RegExp(r'\bto\s+([A-Z][A-Za-z\s]+?)\.').firstMatch(body);
    if (toMatch != null) return toMatch.group(1)?.trim();

    // "from XYZ" pattern for credits
    final fromMatch = RegExp(r'\bfrom\s+([A-Z][A-Za-z\s]+?)\.').firstMatch(body);
    if (fromMatch != null) return fromMatch.group(1)?.trim();

    return null;
  }
}
