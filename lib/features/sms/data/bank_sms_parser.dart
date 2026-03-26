import 'package:mudra_manager/core/logging/app_log.dart';
import 'package:mudra_manager/core/logging/logger_provider.dart';
import 'package:mudra_manager/plugins/sms_parser_manager.dart';
import 'package:mudra_manager/plugins/sms_parser_plugin.dart';

class BankSmsParser {
  static final _log = AppLog(getLogger(), 'BankSmsParser');

  static Future<ParsedSms?> parse(String sender, String body) async {
    // Try plugin-based parsing first
    final pluginResult = await SmsParserManager.instance.parseSms(sender, body);
    if (pluginResult != null) {
      _log.i('SMS parsed by plugin for sender: $sender');
      return pluginResult;
    }

    // Fallback to legacy parsing
    _log.i('Using legacy parser for sender: $sender');
    return _parseLegacy(sender, body);
  }

  static ParsedSms? _parseLegacy(String sender, String body) {

    // Filter out promotional SMS
    if (_isPromotionalSms(body)) {
      _log.i('Rejected promotional SMS from $sender');
      return null;
    }

    final bank = _detectBank(sender);
    _log.i('Legacy parsing SMS from $sender (Bank: ${bank ?? "Unknown"})');

    return _parseGeneric(body);
  }

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
    if (s.contains('RBL')) return 'RBL';
    return null;
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

