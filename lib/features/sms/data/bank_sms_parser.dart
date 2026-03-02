import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';

class BankSmsParser {
  static final _log = AppLog(getLogger(), 'BankSmsParser');

  // Promotional/marketing keywords that indicate non-transaction SMS
  static final _promotionalKeywords = [
    'shop for',
    'get best deals',
    'offer',
    'discount',
    'cashback',
    'sale',
    'buy now',
    'limited time',
    'hurry',
    'click here',
    'visit',
    'download',
    'install',
    'register',
    'sign up',
    'win',
    'prize',
    'congratulations',
    'free',
    'bonus',
    'loan facility',
    'has been enabled',
    'based on your',
    'eligible for',
    'pre-approved',
    'apply now',
    'avail',
  ];

  static bool _isPromotionalSms(String body) {
    final bodyLower = body.toLowerCase();
    return _promotionalKeywords.any((keyword) => bodyLower.contains(keyword));
  }

  static ParsedSms? parse(String sender, String body) {
    // Filter out promotional SMS
    if (_isPromotionalSms(body)) {
      _log.i('Rejected promotional SMS from $sender');
      return null;
    }

    final bank = _detectBank(sender);
    _log.i('Parsing SMS from $sender (Bank: ${bank ?? "Unknown"})');

    switch (bank) {
      case 'HDFC':
        return _parseHDFC(body);
      case 'ICICI':
        return _parseICICI(body);
      case 'SBI':
        return _parseSBI(body);
      case 'AXIS':
        return _parseAxis(body);
      case 'KOTAK':
        return _parseKotak(body);
      case 'YES':
        return _parseYesBank(body);
      case 'INDUSIND':
        return _parseIndusInd(body);
      case 'IDFC':
        return _parseIDFC(body);
      case 'AU':
        return _parseAU(body);
      case 'PAYTM':
        return _parsePaytm(body);
      case 'PHONEPE':
        return _parsePhonePe(body);
      case 'GPAY':
        return _parseGPay(body);
      case 'AMAZONPAY':
        return _parseAmazonPay(body);
      default:
        return _parseGeneric(body);
    }
  }

  static String? _detectBank(String sender) {
    final s = sender.toUpperCase();
    if (s.contains('HDFC')) return 'HDFC';
    if (s.contains('ICICI')) return 'ICICI';
    if (s.contains('SBI') || s.contains('SBIINB')) return 'SBI';
    if (s.contains('AXIS')) return 'AXIS';
    if (s.contains('KOTAK')) return 'KOTAK';
    if (s.contains('YESBNK') || s.contains('YESBANK')) return 'YES';
    if (s.contains('INDUS')) return 'INDUSIND';
    if (s.contains('IDFC')) return 'IDFC';
    if (s.contains('AUBANK')) return 'AU';
    if (s.contains('PAYTM')) return 'PAYTM';
    if (s.contains('PHONEPE') || s.contains('PHPEPE')) return 'PHONEPE';
    if (s.contains('GPAY') || s.contains('GOOGLE')) return 'GPAY';
    if (s.contains('AMAZON') && s.contains('PAY')) return 'AMAZONPAY';
    return null;
  }

  static ParsedSms? _parseHDFC(String body) {
    // HDFC Format: "Rs.1234.56 debited from A/c XX1234 on 01-Jan-23 to VPA merchant@paytm"
    // Must contain transaction keywords
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final vpaRegex = RegExp(r'to\s+VPA\s+([^\s\.]+)');
    final merchantRegex =
        RegExp(r'(?:at|to)\s+([A-Z][A-Z0-9\s]{2,30})(?:\s+on|\.|$)');
    final balanceRegex =
        RegExp(r'Avl\s*Bal[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final vpa = vpaRegex.firstMatch(body)?.group(1);
    final merchant = vpa ?? _extractMerchantName(merchantRegex, body);
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      transactionType: vpa != null ? 'UPI' : 'Card',
      merchant: merchant,
      balance: balance,
    );
  }

  static ParsedSms? _parseICICI(String body) {
    // ICICI Format: "Rs 1,234.56 debited from a/c XX1234 on 01-Jan-23. Info: merchant"
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

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      merchant: merchant,
      balance: balance,
    );
  }

  static ParsedSms? _parseSBI(String body) {
    // SBI Format: "INR 1234.56 debited from A/c XX1234 on 01JAN23 to VPA merchant@paytm"
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'A/c\s*[xX]*(\d{4})');
    final typeRegex =
        RegExp(r'(debited|credited|withdrawn)', caseSensitive: false);
    final vpaRegex = RegExp(r'to\s+(?:VPA\s+)?([^\s\.]+@[^\s\.]+)');
    final balanceRegex =
        RegExp(r'Avl\s*Bal[:\s]*(?:INR|Rs\.?)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

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
      transactionType:
          type == 'withdrawn' ? 'ATM' : (vpa != null ? 'UPI' : 'Card'),
      merchant: vpa,
      balance: balance,
    );
  }

  static ParsedSms? _parseAxis(String body) {
    // Axis Format: "Rs.1234.56 spent on Axis Bank Card XX1234 at MERCHANT on 01-Jan"
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'Card\s*[xX]*(\d{4})');
    final typeRegex =
        RegExp(r'(spent|received|credited)', caseSensitive: false);
    final merchantRegex = RegExp(r'at\s+(.+?)\s+on');
    final balanceRegex =
        RegExp(r'Avl\s*Lmt[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant =
        _cleanMerchantName(merchantRegex.firstMatch(body)?.group(1));
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited' || type == 'received',
      account: account,
      transactionType: 'Card',
      merchant: merchant,
      balance: balance,
    );
  }

  static ParsedSms? _parseKotak(String body) {
    // Kotak Format: "Rs 1234.56 debited from A/c XX1234 on 01-Jan-23"
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

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      balance: balance,
    );
  }

  static ParsedSms? _parsePaytm(String body) {
    // Paytm Format: "Rs.1234.56 sent to merchant via Paytm"
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final typeRegex =
        RegExp(r'(sent|received|credited|debited)', caseSensitive: false);
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

  static ParsedSms? _parsePhonePe(String body) {
    // PhonePe Format: "Rs.1234.56 sent to merchant via PhonePe"
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

  static ParsedSms? _parseGPay(String body) {
    // GPay Format: "You sent Rs.1234.56 to merchant"
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

  static ParsedSms? _parseYesBank(String body) {
    // Yes Bank Format: "Rs 1234.56 debited from A/c XX1234 on 01-Jan-23"
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

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      balance: balance,
    );
  }

  static ParsedSms? _parseIndusInd(String body) {
    // IndusInd Format: "Rs.1234.56 debited from Card XX1234 on 01-Jan-23"
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'(?:Card|A/c)\s*[xX]*(\d{4})');
    final typeRegex = RegExp(r'(debited|credited)', caseSensitive: false);
    final merchantRegex = RegExp(r'at\s+(.+?)\s+on');
    final balanceRegex =
        RegExp(r'Avl\s*(?:Bal|Lmt)[:\s]*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)');

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);
    final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
    final merchant =
        _cleanMerchantName(merchantRegex.firstMatch(body)?.group(1));
    final balance = _extractAmount(balanceRegex, body);

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      merchant: merchant,
      balance: balance,
    );
  }

  static ParsedSms? _parseIDFC(String body) {
    // IDFC Format: "Rs 1234.56 debited from A/c XX1234 on 01-Jan-23"
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

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      balance: balance,
    );
  }

  static ParsedSms? _parseAU(String body) {
    // AU Bank Format: "Rs 1234.56 debited from A/c XX1234 on 01-Jan-23"
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

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: type == 'credited',
      account: account,
      balance: balance,
    );
  }

  static ParsedSms? _parseAmazonPay(String body) {
    // Amazon Pay Format: "Rs.1234.56 sent to merchant via Amazon Pay"
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

  static bool _hasTransactionKeywords(String body) {
    final bodyLower = body.toLowerCase();
    final transactionKeywords = [
      'debited',
      'credited',
      'spent',
      'received',
      'recieved', // Common misspelling
      'paid',
      'withdrawn',
      'sent',
      'transferred',
    ];
    return transactionKeywords.any((keyword) => bodyLower.contains(keyword));
  }

  static ParsedSms? _parseGeneric(String body) {
    // Generic fallback parser
    if (!_hasTransactionKeywords(body)) return null;

    final amountRegex = RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final accountRegex = RegExp(r'(?:A/c|Card|a/c)\s*[xX]*(\d{4})');

    // Check for transfer patterns (money going OUT)
    final transferOutRegex = RegExp(
        r'(?:received|transferred|sent).*from\s+(?:your\s+)?(?:A/c|a/c)',
        caseSensitive: false);
    final transferInRegex = RegExp(
        r'(?:received|credited).*(?:to|in)\s+(?:your\s+)?(?:A/c|a/c)',
        caseSensitive: false);

    // Standard debit/credit patterns
    final typeRegex = RegExp(
        r'(debited|credited|spent|received|paid|withdrawn)',
        caseSensitive: false);

    final amount = _extractAmount(amountRegex, body);
    final account = accountRegex.firstMatch(body)?.group(1);

    // Determine transaction direction
    bool isIncome;
    if (transferOutRegex.hasMatch(body)) {
      // "received from your A/c" = money going OUT (debit)
      isIncome = false;
    } else if (transferInRegex.hasMatch(body)) {
      // "received to your A/c" = money coming IN (credit)
      isIncome = true;
    } else {
      // Fall back to standard keywords
      final type = typeRegex.firstMatch(body)?.group(1)?.toLowerCase();
      isIncome = type == 'credited' || type == 'received';
    }

    if (amount == null) return null;

    return ParsedSms(
      amount: amount,
      isIncome: isIncome,
      account: account,
    );
  }

  static double? _extractAmount(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    if (match == null) return null;

    final amountStr = match.group(1)?.replaceAll(',', '');
    return double.tryParse(amountStr ?? '');
  }

  static String? _extractMerchantName(RegExp regex, String body) {
    final match = regex.firstMatch(body);
    return _cleanMerchantName(match?.group(1));
  }

  static String? _cleanMerchantName(String? merchant) {
    if (merchant == null) return null;

    // Remove common noise words and clean up
    final cleaned = merchant
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .replaceAll(
            RegExp(r'[^a-zA-Z0-9\s@\-]'), '') // Remove special chars except @-
        .trim();

    // Return null if too short or empty
    return cleaned.length >= 2 ? cleaned : null;
  }
}

class ParsedSms {
  final double amount;
  final bool isIncome;
  final String? account;
  final String? transactionType;
  final String? merchant;
  final double? balance;

  ParsedSms({
    required this.amount,
    required this.isIncome,
    this.account,
    this.transactionType,
    this.merchant,
    this.balance,
  });
}
