import '../sms_parser_plugin.dart';

/// Generic international bank SMS parser.
/// Catches common patterns used by banks worldwide when no
/// dedicated parser matches. Supports multiple currency formats.
class GenericInternationalSmsParser extends SmsParserPlugin {
  @override
  String get id => 'generic_international_parser';

  @override
  String get name => 'Generic Bank SMS Parser';

  @override
  String get version => '1.0.0';

  @override
  String get bankName => 'Bank';

  @override
  List<String> get senderNames => [];

  @override
  String get iconPath => 'assets/logo/banks/generic.svg';

  @override
  bool canParse(String sender) {
    // Fallback parser — matches any sender that looks like a bank/financial service.
    // Short sender IDs (< 12 chars, alphanumeric) are typically bank shortcodes.
    final upper = sender.toUpperCase();
    if (sender.length > 20) return false; // personal messages have long names
    if (RegExp(r'^[A-Z0-9\-]{2,12}$').hasMatch(upper)) return true;
    // Known financial keywords in sender
    const bankKeywords = ['BANK', 'PAY', 'CARD', 'CREDIT', 'DEBIT', 'FIN', 'MONEY'];
    return bankKeywords.any((k) => upper.contains(k));
  }

  @override
  ParsedSms? parseSms(String sender, String body) {
    final upper = body.toUpperCase();

    // Must have a transaction keyword
    if (!_hasTransactionKeyword(upper)) return null;

    // Extract amount with various currency formats
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // Determine transaction type
    final isIncome = _isCredit(upper);

    // Extract account
    final account = _extractAccount(body);

    // Extract merchant/recipient
    final merchant = _extractMerchant(body);

    // Detect currency
    final currency = _detectCurrency(body);

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
      transactionType: isIncome ? 'credit' : 'debit',
      merchant: merchant,
      currency: currency,
    );
  }

  bool _hasTransactionKeyword(String upper) {
    const keywords = [
      // English
      'DEBITED', 'CREDITED', 'DEBIT', 'CREDIT',
      'WITHDRAWN', 'DEPOSITED', 'TRANSFERRED',
      'PURCHASE', 'PAYMENT', 'SPENT', 'RECEIVED',
      'CHARGED', 'REFUND', 'CASHBACK',
      'TRANSACTION', 'TXN', 'PAID', 'SENT',
      // Spanish
      'COMPRA', 'PAGO', 'TRANSFERENCIA', 'RETIRO',
      'DEPOSITO', 'COBRO', 'CARGO', 'ABONO',
      // Portuguese
      'COMPRA', 'PAGAMENTO', 'SAQUE', 'DEPOSITO',
      'TRANSFERENCIA', 'ESTORNO',
      // French
      'ACHAT', 'PAIEMENT', 'VIREMENT', 'RETRAIT',
      'REMBOURSEMENT', 'PRELEVEMENT',
      // German
      'ABBUCHUNG', 'ZAHLUNG', 'LASTSCHRIFT',
      'GUTSCHRIFT', 'ERSTATTUNG',
      // Arabic (transliterated — banks often use Latin script)
      'MASHTRIAT', 'TAHWIL', 'SAHB',
      // Turkish
      'HARCAMA', 'ODEME', 'HAVALE', 'PARA',
      // Indonesian / Malay
      'PEMBELIAN', 'PEMBAYARAN', 'TRANSFER', 'PENARIKAN',
      // Swahili
      'MALIPO', 'UMETUMA', 'UMEPOKEA',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  bool _isCredit(String upper) {
    const creditKeywords = [
      'CREDITED', 'CREDIT', 'DEPOSITED', 'RECEIVED',
      'REFUND', 'CASHBACK', 'ADDED',
      // Spanish/Portuguese
      'ABONO', 'DEPOSITO', 'ESTORNO',
      // French
      'REMBOURSEMENT',
      // German
      'GUTSCHRIFT', 'ERSTATTUNG',
      // Indonesian
      'DITERIMA',
      // Swahili
      'UMEPOKEA',
    ];
    const debitKeywords = [
      'DEBITED', 'DEBIT', 'WITHDRAWN', 'PURCHASE',
      'PAYMENT', 'SPENT', 'CHARGED', 'PAID', 'SENT',
      'TRANSFERRED',
      // Spanish/Portuguese
      'COMPRA', 'PAGO', 'PAGAMENTO', 'CARGO', 'COBRO', 'RETIRO', 'SAQUE',
      // French
      'ACHAT', 'PAIEMENT', 'RETRAIT', 'PRELEVEMENT',
      // German
      'ABBUCHUNG', 'ZAHLUNG', 'LASTSCHRIFT',
      // Turkish
      'HARCAMA', 'ODEME',
      // Indonesian
      'PEMBELIAN', 'PEMBAYARAN', 'PENARIKAN',
      // Swahili
      'MALIPO', 'UMETUMA',
    ];

    final creditIdx = creditKeywords
        .map((k) => upper.indexOf(k))
        .where((i) => i >= 0)
        .fold<int>(999999, (a, b) => a < b ? a : b);
    final debitIdx = debitKeywords
        .map((k) => upper.indexOf(k))
        .where((i) => i >= 0)
        .fold<int>(999999, (a, b) => a < b ? a : b);

    return creditIdx < debitIdx;
  }

  double? _extractAmount(String body) {
    final patterns = [
      // R$ prefix (Brazilian Real) - must match before generic $ symbol
      RegExp(r'R\$\s*([\d.]+,\d{2})'),
      // Symbol prefix: $1,234.56 | ₹1234 | €50 | £100
      RegExp(r'[\$₹€£¥₩]\s*([\d,]+(?:\.\d{1,2})?)'),
      // Code prefix: USD 1234.56 | INR 1,234 | BRL 45,99
      RegExp(r'(?:USD|EUR|GBP|INR|AUD|CAD|SGD|AED|JPY|KRW|BRL|MXN|ZAR|NGN|KES|GHS|EGP|PKR|BDT|LKR|NPR|MMK|THB|VND|IDR|MYR|PHP|TRY|COP|PEN|ARS)\s*([\d.,]+)', caseSensitive: false),
      // Rs/Rs. prefix (South Asia)
      RegExp(r'Rs\.?\s*([\d,]+(?:\.\d{1,2})?)'),
      // Rp prefix (Indonesian Rupiah): Rp 50.000
      RegExp(r'Rp\.?\s*([\d.]+)', caseSensitive: false),
      // Amount with code suffix: 1234.56 USD
      RegExp(r'([\d.,]+)\s*(?:USD|EUR|GBP|INR|AUD|CAD|SGD|AED|BRL|TRY|IDR)', caseSensitive: false),
      // Multilingual amount keywords
      RegExp(r'(?:of|for|amount|amt|valor|montant|betrag|monto|jumlah)\s*:?\s*([\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        var raw = match.group(1)!;
        // Detect number format:
        // European/Brazilian: 1.234,56 or 45,99 (comma = decimal)
        // Indonesian/some EU: 250.000 (dot = thousands, no decimal)
        // English: 1,234.56 (comma = thousands, dot = decimal)
        final commaDecimal = RegExp(r',\d{2}$').hasMatch(raw);
        final dotThousands = !raw.contains(',') &&
            raw.contains('.') &&
            RegExp(r'\.\d{3}').hasMatch(raw);
        if (commaDecimal) {
          raw = raw.replaceAll('.', '').replaceAll(',', '.');
        } else if (dotThousands) {
          raw = raw.replaceAll('.', '');
        } else {
          raw = raw.replaceAll(',', '');
        }
        final value = double.tryParse(raw);
        if (value != null && value > 0 && value < 100000000) {
          return value;
        }
      }
    }
    return null;
  }

  String? _extractAccount(String body) {
    // Common patterns: a/c XX1234, account ending 5678, card *1234
    final pattern = RegExp(
      r'(?:a/c|account|card|acct)[\s.:]*(?:ending\s*|no\.?\s*|[xX*]+)(\d{4})',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1);
  }

  String? _extractMerchant(String body) {
    // Common patterns: "at MERCHANT", "to MERCHANT", "from MERCHANT"
    final pattern = RegExp(
      r'(?:at|to|from|towards)\s+([A-Z][A-Za-z0-9\s&\-]{2,25})(?:\s+on|\.|,|\s+for)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(body);
    return match?.group(1)?.trim();
  }

  String? _detectCurrency(String body) {
    // Check compound symbols first (before single-char)
    if (body.contains('R\$')) return 'BRL';
    if (body.contains('Rp')) return 'IDR';
    // Single-char symbols
    if (body.contains('\$')) return 'USD';
    if (body.contains('€')) return 'EUR';
    if (body.contains('£')) return 'GBP';
    if (body.contains('₹')) return 'INR';
    if (body.contains('¥')) return 'JPY';
    if (body.contains('₩')) return 'KRW';
    if (body.contains('₺')) return 'TRY';

    const codes = [
      'USD', 'EUR', 'GBP', 'INR', 'AUD', 'CAD', 'SGD', 'AED',
      'JPY', 'KRW', 'BRL', 'MXN', 'ZAR', 'NGN', 'KES', 'GHS',
      'EGP', 'PKR', 'BDT', 'LKR', 'NPR', 'THB', 'VND', 'IDR',
      'MYR', 'PHP', 'MMK', 'TRY', 'COP', 'PEN', 'ARS',
    ];
    final upper = body.toUpperCase();
    for (final code in codes) {
      if (upper.contains(code)) return code;
    }
    return null;
  }

  @override
  void onLoad() {}

  @override
  void onStart() {}
}
